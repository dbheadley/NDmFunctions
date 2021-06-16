function plotData = PlotElectrode(selDir, elecNum, selElec, startT, winT, varargin)
%% PlotElectrode
% Plots data associated with a particular electrode

%% Syntax
%# [plotH dataObj] = PlotElectrode(selDir, elecNum, selElec, startT, winT)
%# [plotH dataObj] = PlotElectrode(selDir, elecNum, selElec, startT, winT... 'Series', {serExt1 serExt2...})
%# [plotH dataObj] = PlotElectrode(selDir, elecNum, selElec, startT, winT... 'Events', {evtExt1 evtExt2...})
%# [plotH dataObj] = PlotElectrode(selDir, elecNum, selElec, startT, winT... 'Spikes', elecGrp)

%% Description
% Plots the time series and event data associated with a particular
% electrode during the specfied time window.

%% INPUT
% * selDir - a string, the directory containing the data
% * elecNum - an integer scalar, the number of electrodes stored in the files
% * selElec - an integer scalar, the electrode to be plotted
% * startT - an scalar, the starting time point for the sampling window
% * winT - a scalar, the duration of the sampling windows

%% Optional
% * 'Overlay' - sets traces to overlay on top of one another
% * 'Series' - a list of file extensions for different series files to
% include
% * 'Events' - a list of extensions for files with a .evt format
% * 'Spikes' - include spike times, .fet and .clu files, followed by an
% integer argument that indicates the electrode group.

%% OUTPUT
% * plotData - a structure with the following fields
%     * plotH - a structure with the handle for the figure and each trace
%     * dataObj - a structure with the data used to plot

%% Example

%% Executable code
plotH = struct;
dataObj = struct;
% ensure proper formatting of selDir name
if ~strcmp(selDir(end), '/')
    selDir(end+1) = '/';
end

if any(strcmp(varargin, 'Overlay'))
    overlayYes = true;
else
    overlayYes = false;
end

if any(strcmp(varargin, 'Series'))
    serList = varargin{find(strcmp(varargin, 'Series'))+1};
    if ischar(serList)
        serList = {serList};
    end
    serYes = true;
else
    serYes = false;
end

if any(strcmp(varargin, 'Events'))
    evtList = varargin{find(strcmp(varargin, 'Events'))+1};
    if ischar(evtList)
        evtList = {evtList};
    end
    evtYes = true;
else
    evtYes = false;
end

if any(strcmp(varargin, 'Spikes'))
    elecGrp = num2str(varargin{find(strcmp(varargin, 'Spikes'))+1});
    spikesYes = true;
else
    spikesYes = false;
end


% determine the root file name and the number of electrode groups
slashInds = strfind(selDir, '/');
rootName = selDir((slashInds(end-1)+1):(end-1));

datFName = [selDir rootName '.dat'];
eegFName = [selDir rootName '.eeg'];
filFName = [selDir rootName '.fil'];
tFName = [selDir rootName '_t.dat'];

% get continuous data, and plot
wbs = ImportDatFile(datFName, elecNum, selElec, startT, winT);
lfps = ImportEEGFile(eegFName, elecNum, selElec, startT, winT);
hps = ImportFilFile(filFName, elecNum, selElec, startT, winT);
maxVal = max(abs([wbs.traces{1} lfps.traces{1} hps.traces{1}]));

if overlayYes
    sep = 0;
else
    sep = maxVal;
end

currOffset = 0;


% plot series data 
if serYes
    numSer = length(serList);
    for j = 1:numSer
        currSer = serList{j};
        serColor = hsv2rgb([j/(numSer+1) 1 .7]);
        serFName = [selDir rootName '.' currSer];
        sers = ImportSerFile(serFName, elecNum, selElec, startT, winT);
        traceScale = maxVal/max(abs(sers.traces{1}));
        plot(sers.tPts{1}, (sers.traces{1}*traceScale)-currOffset, 'color', serColor);
        hold on;
        currOffset = currOffset + sep;
    end
end
        
%keep a running tab of the offset
plot(wbs.tPts{1}, wbs.traces{1}-currOffset, 'color', [.5 .5 .5])
hold on;
plot(lfps.tPts{1}, lfps.traces{1}-currOffset, 'color', [1 0 0])
currOffset = currOffset + sep;
plot(hps.tPts{1}, hps.traces{1}-currOffset, 'color', [0 0 0])


% get spike times, if selected, and plot
if spikesYes
    tFID = fopen(tFName, 'r');
    fseek(tFID, 0, -1);
    tTable = fread(tFID, inf, 'double');
    fetData = dlmread([selDir rootName '.fet.' elecGrp], ' ');
    cluData = dlmread([selDir rootName '.clu.' elecGrp], '');
    spkIndStamps = fetData(2:end, end); % we only want the spike times
    cluData(1) = [];
    cluIDs = unique(cluData);
    numCluIDs = length(cluIDs);
    spkTimes = tTable(spkIndStamps);
    validTimes = (spkTimes>=startT) & (spkTimes<(startT+winT));
    spkTimes(~validTimes) = [];
    cluData(~validTimes) = [];
    rastHeight = maxVal/10;
    spkTimes = reshape(spkTimes, 1, numel(spkTimes));
    cluData = reshape(cluData, 1, numel(cluData));
    currOffset = currOffset + rastHeight;
    for j = 1:numCluIDs
        currClu = cluIDs(j);
        currCluSpks = spkTimes(cluData==currClu);
        szCurrSpks = size(currCluSpks);
        cluColor = hsv2rgb([j/(numCluIDs+1) 1 1]);
        tVals = reshape([currCluSpks; currCluSpks; nan(szCurrSpks)], ...
            numel(currCluSpks)*3, 1);
        rastVals = reshape([currOffset*ones(szCurrSpks); ...
                (currOffset+rastHeight)*ones(szCurrSpks); nan(szCurrSpks)], ...
            numel(currCluSpks)*3, 1);
        line(tVals, -rastVals, 'color', cluColor);
        hold on;
        currOffset = currOffset + rastHeight;
    end
end

% plot EVT data here, add option for "tall" lines
if evtYes
    numEvt = length(evtList);
    for j = 1:numEvt
        currEvt = evtList{j};
        evtColor = hsv2rgb([j/(numEvt+1) .5 1]);
        evtFName = [selDir rootName '_' num2str(selElec) '.' currEvt];
        evtTimes = dlmread(evtFName);
        validTimes = (evtTimes>=startT) & (evtTimes<(startT+winT));
        evtTimes(~validTimes) = [];
        evtTimes = reshape(evtTimes, 1, numel(evtTimes));
        szEvtTimes = size(evtTimes);
        tVals = reshape([evtTimes; evtTimes; nan(szEvtTimes)], ...
            numel(evtTimes)*3, 1);
        rastVals = reshape([maxVal * ones(szEvtTimes); ...
                -currOffset*ones(szEvtTimes); nan(szEvtTimes)], ...
            numel(evtTimes)*3, 1);
        line(tVals, rastVals, 'color', evtColor);
        hold on;
    end
end

xlim([min(wbs.tPts{1}) max(wbs.tPts{1})]);