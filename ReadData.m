function data = ReadData(fPath, varargin)
%% ReadData
% Loads data from binary file

%% Syntax
%# data = ReadData(fPath)
%# data = ReadData(fPath, ... 'chmapname', chMapFName)
%# data = ReadData(fPath, ... 'tmapname', tMapFName)
%# data = ReadData(fPath, ... 'precision', prec)
%# data = ReadData(fPath, ... 'twindows', tWinds)
%# data = ReadData(fPath, ... 'selchan', selChan)
%# data = ReadData(fPath, ... 'EQUDUR')

%% Description
% Extracts time series from a binary file at particular time points and
% electrodes. Looks for a corresponding _t.* and _cm.* files to obtain time
% stamps and electrode maps.


%% INPUT
% * fPath - a string, the name of the binary file

%% OPTIONAL
% * 'chmapname' - the name of the file containing the channel mapping
% * 'tmapname' - the name of the file containing the time stamps
% * 'twindows - an Nx2 array specifying the segments that will be returned
% each row is a different segment, with the first column being the start
% time and the second the finish
% * 'selchan' - a vector of the channels to return. If numeric, then
% channels are specified by the chan index column in the chan map file. If
% instead it is a cell array of strings, than the chan names are used.
% * 'precision' - the data format in the time series, the same as the
% precision setting on 'fread'. Default is 'int16'.
% * 'EQUDUR' - specified that all windows should have the same length.
% Uses the median length to set to window length for all segments

%% OUTPUT
% * data - a structure with the following fields:
%     * traces - an Nx1 cell array, each cell contains the series traces across the
%     selected electrodes in an MxT array, with each row containing the trace
%     from a different electrode
%     * chans - an Mx1 cell array of channel names based on chan file
%     * tPts - an Nx1 cell array, each cell contains a 1xT numeric vector of
%     timestamps
%     * tOff - an Nx2 numeric array, each row is a different sample window.
%     Column 1 is the error in the startT time point, while column 2 is the
%     error for the duration of the window
%% Example

%% Executable code

% format inputs

if any(strcmp(varargin, 'tmapname'))
    tFName = varargin{find(strcmp(varargin,'tmapname'))+1};
else
    tFName = [];
end

if any(strcmp(varargin, 'chmapname'))
    chFName = varargin{find(strcmp(varargin,'chmapname'))+1};
else
    chFName = [];
end

if any(strcmp(varargin, 'precision'))
    prec = varargin{find(strcmp(varargin,'precision'))+1};
else
    prec = 'int16';
end
byteNum = ByteSizeLUT(prec);

if any(strcmp(varargin, 'twindows'))
    winT = varargin{find(strcmp(varargin,'twindows'))+1};
else
    winT = [0 inf];
end
numWin = size(winT,1);

if any(strcmp(varargin, 'selchan'))
    selChans = varargin{find(strcmp(varargin,'selchan'))+1};
    specChanYes = true;
else
    specChanYes = false;
end

if any(strcmp(varargin, 'EQUDUR'))
    eqDurYes = true;
else
    eqDurYes = false;
end


% get file ids and check for length consistency
if isempty(tFName)
    dotInds = strfind(fPath, '.');
    tFile = [fPath(1:(dotInds(end)-1)) '_t' fPath(dotInds(end):end)];
else
    tFile = tFName;
end

if isempty(chFName)
    dotInds = strfind(fPath, '.');
    chFile = [fPath(1:(dotInds(end)-1)) '_ch' fPath(dotInds(end):end)];
else
    chFile = chFName;
end

% get timestamps and channel info
tMap = memmapfile(tFile, 'Format', 'double');
chFID = fopen(chFile, 'r');
chNames = textscan(chFID, '%u %s', 'delimiter', ',');
fclose(chFID);

numChan = size(chNames{1},1);
numTPts = length(tMap.data);

% make sure number of channels and time points agrees with file size
datFProps = dir(fPath);
numSamps = datFProps.bytes/byteNum;
if numSamps ~= (numChan * numTPts)
    error('Chan map and time stamp files disagree with data file');
end

% create datamap, should throw an error if sizes do not agree
dataMap = memmapfile(fPath, 'Format', {prec [numChan numTPts] 'traces'});


% calculate all start points and durations
badTraces = false(numWin,1);
for j = 1:numWin
    currStartT = winT(j,1);
    currFinishT = winT(j,2);
    
    if isinf(currFinishT)
        currFinishT = tMap.data(end);
    end
    
    [tOff(j,1) startInd(j,1)] = min(abs(tMap.data-currStartT));
    [tOff(j,2) stopInd(j,1)] = min(abs(tMap.data-currFinishT));
end



% if all trace durations must be equal, than find the median duration
if eqDurYes
    winLen = stopInd-startInd;
    winLen = repmat(nanmedian(winLen), length(winLen), 1);
    stopInd = startInd+winLen;
    %recalculate tOff
    tOff(:,2) = abs(tMap.Data(stopInd) - winT(:,2));
end

% if specific channels are requested, than find their indices
if specChanYes
    if iscell(selChans)
        if length(unique(chNames{2})) < length(chNames{2})
            error('Redundant channel names');
        end
        
        retChans = cellfun(@(x)find(strcmp(x, chNames{2})), selChans, ...
            'UniformOutput', false);
        if any(cellfun(@(x)isempty(x), retChans))
            error('Unmatched channel name');
        end
        retChans = cell2mat(retChans)-1;
    else
        retChans = selChans;
    end
else
    retChans = 0:(numChan-1);
end
data.chans = {chNames{1}(retChans+1) chNames{2}(retChans+1)};
data.settings.precision = prec;
% get data
for j = 1:numWin
    data.traces{j} = dataMap.data.traces(retChans+1, startInd(j):stopInd(j));
    data.tPts{j} = tMap.data(startInd(j):stopInd(j));
    data.tOff{j} = tOff(j,:);
end

