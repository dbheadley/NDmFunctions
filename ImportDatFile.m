function wbs = ImportDatFile(datFile, elecNum, selElecs, startT, winT)
%% ImportDatFile
% Loads data from an .dat file

%% Syntax
%# wbs = ImportDatFile(datFile, elecNum, selElecs, startT, winT)

%% Description
% Extracts wideband traces from a .dat file at particular time points and
% electrodes. Looks for a corresponding _t.dat file to obtain time stamps.
% If a particular time point is not present, then the closest time point is
% obtained that will keep all returned wideband traces the same length.

%% INPUT
% * datFile - a string, the name of the .dat file
% * elecNum - an integer, the number of channels that were recorded
% * selElecs - an Mx1 integer vector, the indices of channels to be retrieved
% * startT - an Nx1 numeric vector, the starting time points for sampling
% windows
% * winT - a numeric vector Nx1 or scalar, if a vector than the duration of
% each sampling window. If a scalar than the duration of all sampling
% windows

%% OUTPUT
% * wbs - a structure with the following fields:
%     * traces - an Nx1 cell array, each cell contains the wideband traces across the
%     selected electrodes in an MxT array, with each row containing the trace
%     from a different electrode
%     * tPts - an Nx1 cell array, each cell contains a 1xT numeric vector of
%     timestamps
%     * tOff - an Nx2 numeric array, each row is a different sample window.
%     Column 1 is the error in the startT time point, while column 2 is the
%     error for the duration of the window
%% Example

%% Executable code
wbs = struct();

% format inputs
numTraces = length(startT);
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

% get file ids and check for length consistency
tFile = [datFile(1:(end-4)) '_t.dat'];
datFID = fopen(datFile, 'r');

fidT = fopen(tFile, 'r');
if fidT == -1
    error('No corresponding _t.dat file, exiting');
end

fDatProps = dir(datFile);
fDatLength = fDatProps.bytes;
datLen = fDatLength/(2*elecNum); % number of eeg samples
fTProps = dir(tFile);
fTLength = fTProps.bytes;
tLen = fTLength/8; % number of time stamps


if datLen ~= tLen
    disp('WARNING: dat and t.dat files are unmatched');
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
    datInd = startInd(j)*elecNum*2;
    stepSize = winLen(j);
    fseek(datFID, datInd, -1);
    traces{j} = fread(datFID, [elecNum,stepSize], 'int16');
    traces{j} = traces{j}(selElecs+1,:);
    tPts{j} = tStamps(startInd(j):(startInd(j)+winLen(j)-1))';
end

wbs.traces = traces;
wbs.tPts = tPts;
wbs.tOff = tOff;
fclose('all');
end

