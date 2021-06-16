function sers = ImportSerFile(serFile, elecNum, selElecs, startT, winT, varargin)
%% ImportSerFile
% Loads data from binary file

%% Syntax
%# sers = ImportSerFile(selFile, elecNum, selElecs, startT, winT)
%# sers = ImportSerFile(selFile, elecNum, selElecs, startT, winT, ... 'Precision')

%% Description
% Extracts series traces from a binary file at particular time points and
% electrodes. Looks for a corresponding _t.* file to obtain time stamps.
% If a particular time point is not present, then the closest time point is
% obtained that will keep all returned series traces the same length.

%% INPUT
% * serFile - a string, the name of the binary file
% * elecNum - an integer, the number of channels that were recorded
% * selElecs - an Mx1 integer vector, the indices of channels to be
% retrieved, starting from 0
% * startT - an Nx1 numeric vector, the starting time points for sampling
% windows
% * winT - a numeric vector Nx1 or scalar, if a vector than the duration of
% each sampling window. If a scalar than the duration of all sampling
% windows

%% OPTIONAL
% * 'Precision' - the data format in the time series, the same as the
% precision setting on 'fread'. Default is 'int16'.
% * 'TimeFileName' - the file name for the associated time file

%% OUTPUT
% * sers - a structure with the following fields:
%     * traces - an Nx1 cell array, each cell contains the series traces across the
%     selected electrodes in an MxT array, with each row containing the trace
%     from a different electrode
%     * tPts - an Nx1 cell array, each cell contains a 1xT numeric vector of
%     timestamps
%     * tOff - an Nx2 numeric array, each row is a different sample window.
%     Column 1 is the error in the startT time point, while column 2 is the
%     error for the duration of the window
%% Example

%% Executable code

% format inputs


numTraces = length(startT);

if any(strcmp(varargin, 'TimeFileName'))
    tFName = varargin{find(strcmp(varargin,'TimeFileName'))+1};
else
    tFName = [];
end

eqDur = false; % a flag for whether each trace should be the same length
if length(winT) == 1
    winT = repmat(winT, numTraces, 1);
    eqDur = true;
elseif length(winT) ~= numTraces
    error('Number of start times is different from number of window sizes');
end

if size(startT,1) < size(startT,2);
    startT = startT';
end
if size(winT,1) < size(winT,2);
    winT = winT';
end


if any(strcmp(varargin, 'Precision'))
    prec = varargin{find(strcmp(varargin,'Precision'))+1};
else
    prec = 'int16';
end

byteNum = ByteSizeLUT(prec);


% get file ids and check for length consistency
if isempty(tFName)
    dotInds = strfind(serFile, '.');
    tFile = [serFile(1:(dotInds(end)-1)) '_t' serFile(dotInds(end):end)];
else
    tFile = tFName;
end

serFID = fopen(serFile, 'r');
fidT = fopen(tFile, 'r');
fSerProps = dir(serFile);
fSerLength = fSerProps.bytes;
serLen = fSerLength/(byteNum*elecNum); % number of samples
fTProps = dir(tFile);
fTLength = fTProps.bytes;
tLen = fTLength/8; % number of time stamps

if serLen ~= tLen
    error('Unmatached t file for selected series data, exiting');
end

% load time stamps
fseek(fidT, 0, -1);
tStamps = fread(fidT, inf, 'double');

% calculate all start points and durations
badTraces = false(numTraces,1);
for j = 1:numTraces
    currStartT = startT(j);
    currWinT = winT(j);
    if isinf(currWinT)
        currWinT = tStamps(end)-currStartT;
    end
    
    if (currStartT+currWinT) > tStamps(end)
        badTraces(j) = true;
        tOff(j,:) = nan;
        startInd(j,1) = nan;
        stopInd(j,1) = nan;
        continue;
    end
    [tOff(j,1) startInd(j,1)] = min(abs(tStamps-currStartT));
    [tOff(j,2) stopInd(j,1)] = min(abs(tStamps-(currStartT+currWinT)));
end

winLen = stopInd-startInd;

% if all trace durations must be equal, than find the median duration
if eqDur
    winLen = repmat(nanmedian(winLen), length(winLen), 1);
    %recalculate tOff
    tOff(:,2) = abs(tStamps(startInd+winLen) - (startT+winT));
end

for j = 1:numTraces
    if badTraces(j)
        traces{j} = nan;
        tPts{j} = nan;
        continue;
    end
    serInd = (startInd(j)-1)*elecNum*byteNum;
    stepSize = winLen(j);
    fseek(serFID, serInd, -1);
    traces{j} = fread(serFID, [elecNum,stepSize], prec);
    traces{j} = traces{j}(selElecs+1,:);
    tPts{j} = tStamps(startInd(j):(startInd(j)+winLen(j)-1))';
end

sers.traces = traces;
sers.tPts = tPts;
sers.tOff = tOff;
fclose('all');
end

