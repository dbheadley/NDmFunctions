function fName = Ser2Evt(selFile, procFunc, varargin)
%% Ser2Evt
% Processes time series data from a file, returns time stamps

%% Syntax
%# fName = Ser2Evt(selFile, procFunc)
%# fName = Ser2Evt(selFile, procFunc, ... 'WinDur', [integer])
%# fName = Ser2Evt(selFile, procFunc, ... 'WinOver', [integer])
%# fName = Ser2Evt(selFile, procFunc, ... 'Index', [true or false])
%# fName = Ser2Evt(selFile, procFunc, ... 'Precision', [string])
%# fName = Ser2Evt(selFile, procFunc, ... 'TraceNum', [integer])
%# fName = Ser2Evt(selFile, procFunc, ... 'SelTraces', [integers])
%# fName = Ser2Evt(selFile, procFunc, ... 'FileType', [string])
%# fName = Ser2Evt(selFile, procFunc, ... 'FileNumOverride', [true or false])
%# fName = Ser2Evt(selFile, procFunc, ... 'ReadData', [cell array])

%% Description
% Processes the timeseries in selFile with procFunc and returns timestamps
% in a new file. procFunc should accept an NxM matrix as input, and
% return a cell array of indices. Each cell is treated as a different
% time series trace. By default, files are returned with a .evt suffix.
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
% * 'SampRate' - the sample rate of the time series in selFile. Only used
% if no _t file is present.
% * 'SelTraces' - a vector of integers starting at 0 indicating the traces to process.
% Only these traces will be returned in the new file. Each included trace
% will be indicated in the filename with a '.[num]' notation. All traces
% are processed by default.
% * 'FileType' - specifies the file type suffix for the returned file. By
% default it is '.proc'.
% * 'FileNumOverride' - Indicates whether automatic numbering of output 
% filenames should take place.
% * 'TimeFileName' - the file name for the associated time file
% * 'ReadData' - use the ReadData function to load data, with the adjoining
% cell array specifying the arguments to pass.

%% OUTPUT
% * fName - a string, the name of the file containing the time stamp data.
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

if any(strcmp(varargin, 'FileNumOverride'))
    numOverride = varargin{find(strcmp(varargin,'FileNumOverride'))+1};
else
    numOverride = false;
end

if any(strcmp(varargin, 'FileType'))
    fType = varargin{find(strcmp(varargin,'FileType'))+1};
else
    fType = 'proc';
end

if any(strcmp(varargin, 'SelTraces'))
    selTraces = varargin{find(strcmp(varargin,'SelTraces'))+1};
    selTraces = reshape(selTraces, 1, numel(selTraces));
else
    selTraces = 0:(numChannels-1);
end

if any(strcmp(varargin, 'TimeFileName'))
    tFName = varargin{find(strcmp(varargin,'TimeFileName'))+1};
else
    tFName = [];
end

% setup files to read from
fileInfo=dir(selFile);
fileSize=fileInfo.bytes;
inSerFID=fopen(selFile,'r');

if ~indexYes
    if ~isempty(tFName)
        inTFID=fopen(tFName,'r');
    else
        inTFID=fopen([selFile(1:(end-4)) '_t' selFile((end-3):end)],'r');
    end
    if (inTFID == -1)
        sRate = sampRate;
        tTable = [];
    else
        fseek(inTFID, 0, -1);
        tTable = fread(inTFID, inf, 'double');
        sRate = 1/(tTable(2)-tTable(1));
    end
else
    sRate = sampRate;
    tTable = [];
end

fileTime=fileSize/(numChannels*byteNum*sRate); %file time in seconds
if isinf(winStep)
    winStep = fileTime;
    sampStep = fileSize;
else
    sampStep = floor(sRate*winStep);
end


edgeSpace = round(edgeOver*sRate);
if mod(edgeSpace,2) == 1
    edgeSpace = edgeSpace - 1;
end
overSpace = edgeSpace/2;


if isempty(tTable)
    tPrec = 'uint64';
else
    tPrec = 'double';
end


min=0;
edgeSig = [];
for i=0:floor(fileTime/winStep)-1 
    min=min+1
    startInd = i*sampStep*numChannels*byteNum;
    tSampInd = startInd/(numChannels*byteNum);
    fseek(inSerFID, startInd,-1);
    origSig=fread(inSerFID,[numChannels,sampStep],prec); 
    origSig=origSig(selTraces+1,:);
    lenOrigSig = size(origSig,2);
    if isempty(edgeSig)
        procEvt = procFunc(origSig);
        procEvt = RemOutCell(procEvt, 0, lenOrigSig-overSpace);
        procEvt = cellfun(@(x)x, procEvt, 'UniformOutput', false);
    else
        procEvt = procFunc([edgeSig origSig]);
        procEvt = RemOutCell(procEvt, overSpace, lenOrigSig-overSpace);
        procEvt = cellfun(@(x)x+(tSampInd-edgeSpace)+1, procEvt, 'UniformOutput', false);
    end
    
    evtCell(i+1, :) = procEvt;
    edgeSig = origSig(:,((end-edgeSpace)+1):end);
end

i=i+1

min=min+1
startInd = i*sampStep*numChannels*byteNum;
tSampInd = startInd/(numChannels*byteNum);
fseek(inSerFID,startInd,-1);
origSig = fread(inSerFID,[numChannels,inf],prec);
if ~isempty(origSig)
    origSig = origSig(selTraces+1,:);
    procEvt = procFunc([edgeSig origSig]);
    procEvt = RemOutCell(procEvt, overSpace, lenOrigSig+1);
    procEvt = cellfun(@(x)x+(tSampInd-edgeSpace)+1, procEvt, 'UniformOutput', false);
    evtCell(i+1, :) = procEvt;
end

% ALLOW FOR TIMESTAMP DESCRIPTION, OUTPUT AS MULTIPLE FILES, ONE FOR EACH
% TRACE

numTraces = length(selTraces);
for j = 1:numTraces
    currTrace = selTraces(j);
    if numOverride
        fName{j} = [selFile(1:(end-4)) '.' fType];
    else
        fName{j} = [selFile(1:(end-4)) '_' num2str(currTrace) '.' fType];
    end
    evtList = cell2mat(cellfun(@(x) reshape(x,numel(x),1), evtCell(:,j), 'UniformOutput', false));    
    if indexYes
        dlmwrite(fName{j}, evtList, 'precision', '%d')
    else
        dlmwrite(fName{j}, tTable(evtList), 'precision', '%f')
    end
end


fclose('all');
end

function windCell = RemOutCell(cArr, botEdge, topEdge)
    for j = 1:numel(cArr)
        badInds = (cArr{j}<botEdge) | (cArr{j}>topEdge);
        windCell{j} = cArr{j}(~badInds);
    end
    windCell = reshape(windCell, size(cArr));
end