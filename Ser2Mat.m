%% STILL IN DEVELOPMENT STILL IN DEVELOPMENT STILL IN DEVELOPMENT
function fName = Ser2Mat(selFile, procFunc, varargin)
%% Ser2Mat
% Processes time series data from a file, returns a cell array

%% Syntax
%# fName = Ser2Mat(selFile, procFunc)
%# fName = Ser2Mat(selFile, procFunc, ... 'WinDur', [integer])
%# fName = Ser2Mat(selFile, procFunc, ... 'WinOver', [integer])
%# fName = Ser2Mat(selFile, procFunc, ... 'Index', [true or false])
%# fName = Ser2Mat(selFile, procFunc, ... 'Precision', [string])
%# fName = Ser2Mat(selFile, procFunc, ... 'TraceNum', [integer])
%# fName = Ser2Mat(selFile, procFunc, ... 'SelTraces', [integers])
%# fName = Ser2Mat(selFile, procFunc, ... 'FileType', [string])

%% Description
% Processes the timeseries in selFile with procFunc and returns a cell 
% array. procFunc should accept an NxM matrix as input, whose results should be
% formatted as a cell array with dimension AxB, where each row is a different
% 'channel' and each column is a diffent time window. 
% Assumes time series has a constant sampling rate and is uninterrupted.
% The file put out by this function contains two variables, matCell, a cell
% array of the calculated results, and tPts, a 2xT array with the top
% row being time point starting the window and the bottow the final point.

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
% * 'SelTraces' - a vector of integers indicating the traces to process.
% Only these traces will be returned in the new file. Each included trace
% will be indicated in the filename with a '.[num]' notation. All traces
% are processed by default.
% * 'FileType' - specifies the file type suffix for the returned file. By
% default it is '.proc'.

%% OUTPUT
% * fName - the name of the file containing the data

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

if any(strcmp(varargin, 'FileType'))
    fType = varargin{find(strcmp(varargin,'FileType'))+1};
else
    fType = 'matProc';
end

if any(strcmp(varargin, 'SelTraces'))
    selTraces = varargin{find(strcmp(varargin,'SelTraces'))+1};
    selTraces = reshape(selTraces, 1, numel(selTraces));
    traceStr = cell2mat(arrayfun(@(x)['_' num2str(x)], selTraces, 'UniformOutput', false));
else
    selTraces = 0:(numChannels-1);
    traceStr = '';
end

% setup files to read from
fileInfo=dir(selFile);
inSerFID=fopen(selFile,'r');

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
else
    sRate = sampRate;
    tTable = [];
end


sampStep = round(sRate*winStep);
fileSize=fileInfo.bytes;

edgeSpace = round(edgeOver*sRate);
if mod(edgeSpace,2) == 1
    edgeSpace = edgeSpace - 1;
end
overSpace = edgeSpace/2;


fileTime=fileSize/(numChannels*byteNum*sRate); %file time in seconds

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
        procMat = procFunc(origSig);
    else
        procMat = procFunc([edgeSig origSig]);
    end
    matCell(:, i+1) = procMat;
    edgeSig = origSig(:,(end-edgeSpace+1):end);
    tPts(:,i+1) = tTable([tSampInd; tSampInd+sampStep]+1);
end

i=i+1

min=min+1
startInd = i*sampStep*numChannels*byteNum;
tSampInd = startInd/(numChannels*byteNum);
fseek(inSerFID,startInd,-1);
origSig = fread(inSerFID,[numChannels,inf],prec);
origSig = origSig(selTraces+1,:);
procMat = procFunc([edgeSig origSig]);
matCell(:, i+1) = procMat;
tPts(:,i+1) = tTable([tSampInd+1; end]);

fName = [selFile(1:(end-4)) traceStr '.' fType '.mat'];
save(fName, 'matCell', 'tPts');

fclose('all');
end