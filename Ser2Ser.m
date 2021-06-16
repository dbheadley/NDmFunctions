function fName = Ser2Ser(selFile, procFunc, varargin)
%% Ser2Ser
% Processes time series data from a file

%% Syntax
%# fName = Ser2Ser(selFile, procFunc)
%# fName = Ser2Ser(selFile, procFunc, ... 'WinDur', [integer])
%# fName = Ser2Ser(selFile, procFunc, ... 'WinOver', [integer])
%# fName = Ser2Ser(selFile, procFunc, ... 'Index', [true or false])
%# fName = Ser2Ser(selFile, procFunc, ... 'Precision', [string])
%# fName = Ser2Ser(selFile, procFunc, ... 'TraceNum', [integer])
%# fName = Ser2Ser(selFile, procFunc, ... 'ResampRate', [numeric])
%# fName = Ser2Ser(selFile, procFunc, ... 'SelTraces', [integers])
%# fName = Ser2Ser(selFile, procFunc, ... 'FileType', [string])
%# fName = Ser2Ser(selFile, procFunc, ... 'ProcPeriod', [numeric numeric])

%% Description
% Processes the timeseries in selFile with procFunc and returns the result
% in a new file. procFunc should accept an NxM matrix as input, and
% return a matrix of the same size, although it can also return a matrix 
% with fewer rows (channels) if so desired. Each row is assumed to be a different
% time series trace. By default, files are returned with a .proc suffix.
% Assumes time series has a constant sampling rate and is uninterrupted.

%% INPUT
% * selFile - a string, the name of the file to be processed file
% * procFunc - a function handle, the function to run.

%% OPTIONAL
% * 'WinDur' - duration of the sampling window in seconds. When the 'Index'
% setting is true, 'WinDur' is interpreted as indices. By default it is 60.
% * 'WinOver' - the amount of overlap between sampling windows. Must be an
% even number. Is 0 by default.
% * 'Index' - specifies whether to use the time stamps in the accompanying
% _t file. If not, then all time related parameters are interpreted as
% indices. Default is false
% * 'Precision' - the data format in the time series, the same as the
% precision setting on 'fread'. Default is 'int16'.
% * 'TraceNum' - number of time series in a given file. Default is 1.
% * 'ResampRate' - Resamples the output of procFunc at new rate, which is
% slower than the rate of the original time series. By default, the resamp
% rate is equal to the original sample rate.
% * 'SampRate' - the sample rate of the time series in selFile. Only used
% if no _t file is present.
% * 'SelTraces' - a vector of integers indicating the traces to process.
% Only these traces will be returned in the new file. Each included trace
% will be indicated in the filename with a '.[num]' notation. All traces
% are processed by default.
% * 'FileType' - specifies the file type suffix for the returned file. By
% default it is '.proc'.
% * 'ProcPeriod' - the start and stop times for the data to be processed.

%% OUTPUT
% * fName - a cell array of strings, the name of the file containing the processed data is 
% the first cell, while an associated time file is the second cell.

%% Example

%% Executable code

% set operating parameters
if any(strcmp(varargin, 'WinDur'))
    winStep = varargin{find(strcmp(varargin,'WinDur'))+1};
else
    winStep = 60;
end

if any(strcmp(varargin, 'WinOver'))
    edgeOver = varargin{find(strcmp(varargin,'WinOver'))+1};
else
    edgeOver = 0;
end

if any(strcmp(varargin, 'Precision'))
    prec = varargin{find(strcmp(varargin,'Precision'))+1};
else
    prec = 'int16';
end

byteNum = ByteSizeLUT(prec);


if any(strcmp(varargin, 'TraceNum'))
    numChannels = varargin{find(strcmp(varargin,'TraceNum'))+1};
else
    numChannels = 1;
end


if any(strcmp(varargin, 'SampRate'))
    sampRate = varargin{find(strcmp(varargin,'SampRate'))+1};
else
    sampRate = [];
end

if any(strcmp(varargin, 'Index'))
    indexYes = varargin{find(strcmp(varargin,'Index'))+1};
    sampRate = 1;
else
    indexYes = false;
end

if any(strcmp(varargin, 'ResampRate'))
    resampYes = true;
    resampRate = varargin{find(strcmp(varargin,'ResampRate'))+1};
else
    resampYes = false;
    resampRate = sampRate;
end

if any(strcmp(varargin, 'FileType'))
    fType = varargin{find(strcmp(varargin,'FileType'))+1};
else
    fType = 'proc';
end

if any(strcmp(varargin, 'SelTraces'))
    selTraces = varargin{find(strcmp(varargin,'SelTraces'))+1};
    selTraces = reshape(selTraces, 1, numel(selTraces));
    traceStr = cell2mat(arrayfun(@(x)['_' num2str(x)], selTraces, 'UniformOutput', false));
else
    selTraces = 0:(numChannels-1);
    traceStr = '';
end



% setup files to read from and write to
fileInfo=dir(selFile);
fileSize=fileInfo.bytes;
inSerFID=fopen(selFile,'r');
fName{1} = [selFile(1:(end-4)) traceStr '.' fType];
outSerFID=fopen(fName{1},'a');

if ~indexYes
    inTFID=fopen([selFile(1:(end-4)) '_t' selFile((end-3):end)],'r');
    if (inTFID == -1)
        sRate = sampRate;
        tTable = [];
    else
        fseek(inTFID, 0, -1);
        tTable = fread(inTFID, inf, 'double');
        sRate = 1/(tTable(2)-tTable(1));
    end
    if ~resampYes
        resampRate = sRate;
    end
    fName{2} = [selFile(1:(end-4)) traceStr '_t.' fType];
    outTFID=fopen(fName{2},'a');
else
    sRate = sampRate;
    tTable = [];
end

fileTime=fileSize/(numChannels*byteNum*sRate); %file time in seconds
if isinf(winStep)
    winStep = fileTime;
    sampStep = fileSize;
else
    sampStep = floor(sRate*winStep); %changed from round to floor 6/13/13
end

resampStep = round(sRate/resampRate);

edgeSpace = round(edgeOver*sRate);
if mod(edgeSpace,2) == 1
    edgeSpace = edgeSpace - 1;
end
overSpace = edgeSpace/2;



if any(strcmp(varargin, 'ProcPeriod'))
    procPeriod = varargin{find(strcmp(varargin,'ProcPeriod'))+1};
else
    procPeriod = [0 fileTime];
end

startFileInd = floor(procPeriod(1)*sRate)+1;
lastFileInd = floor(procPeriod(2)*sRate);
% generate mapping between indices for original ser file and the processed
% resampled ser file. Also, create list of indicies to resample so that the 
% signalis decimated evenly across window steps
resampPoints = zeros(1,(fileSize/(numChannels*byteNum)));
resampPoints(startFileInd:resampStep:lastFileInd) = 1;
tList = 1:(fileSize/(numChannels*byteNum));
tListSamp = tList(logical(resampPoints));
fseek(outTFID, 0, -1);
if isempty(tTable)
    resampTMap = uint64(tListSamp);
    fwrite(outTFID, resampTMap, 'uint64');
else
    resampTMap = tTable(tListSamp);
    fwrite(outTFID, resampTMap, 'double');
end




min=procPeriod(1);
edgeSig = [];
for i=floor(procPeriod(1)/winStep):floor(procPeriod(2)/winStep)-1 %cycle through the file minute by minute
    min=min+1
    startInd = i*sampStep*numChannels*byteNum;
    tSampInd = startInd/(numChannels*byteNum);
    fseek(inSerFID, startInd,-1);
    origSig=fread(inSerFID,[numChannels,sampStep],prec); 
    origSig=origSig(selTraces+1,:);
    currRSPts = logical(resampPoints((tSampInd+1):(tSampInd+sampStep)));
    if isempty(edgeSig)
        procSig = procFunc(origSig);
        writeWin = true(1,size(procSig,2));
        writeWin((end-overSpace+1):end) = false;
        fwrite(outSerFID,procSig(:,writeWin & currRSPts),prec);
    else
        procSig = procFunc([edgeSig origSig]);
        writeWin = true(1,size(procSig,2));
        writeWin(1:overSpace) = false;
        writeWin((end-overSpace+1):end) = false;
        fwrite(outSerFID,procSig(:,writeWin & [edgeRSPts currRSPts]),prec);
    end
    
    edgeSig = origSig(:,(end-edgeSpace+1):end);
    edgeRSPts = currRSPts((end-edgeSpace+1):end);
end

if ~isempty(edgeRSPts)
    i=i+1

    min=min+1
    startInd = i*sampStep*numChannels*byteNum;
    tSampInd = startInd/(numChannels*byteNum);
    fseek(inSerFID,startInd,-1);
    origSig = fread(inSerFID,[numChannels,lastFileInd-tSampInd],prec);
    origSig = origSig(selTraces+1,:);
    currRSPts = logical(resampPoints((tSampInd+1):end));
    procSig = procFunc([edgeSig origSig]);
    writeWin = true(1,size(procSig,2));
    writeWin(1:overSpace) = false;
    fwrite(outSerFID,procSig(:,writeWin & [edgeRSPts currRSPts]),prec);
end

fclose('all');