function pData = CreateSpikePData(selDir)
%% CreateSpikePData
% Generates a pData cell array containing spike data from the selected
% directory

%% Syntax
%# [pData fNames] = CreateSpikePData(selDir)

%% Description
% Loads and organizes spike data files from 'selDir' into a pData array.
% Automatically detects the number of electrode groups, the corresponding
% unit waveforms, spike times, and unit groups. The name of the terminal
% directory that selDir points to is assumed to be the root file name for
% all spike files. The number of electrode groups is also determined
% automatically by the suffixes of the .fet files.
% 
%% INPUT
% * selDir - a string, the name of the directory containing the spike data

%% OUTPUT
% * pData - a pData cell array, each row is a different unit


%% Example



%% Executable code
sRate = 30030.03003; % data acquisition rate in Hz

% ensure proper formatting of selDir name
if ~strcmp(selDir(end), '/')
    selDir(end+1) = '/';
end

% determine the root file name and the number of electrode groups
slashInds = strfind(selDir, '/');
rootName = selDir((slashInds(end-1)+1):(end-1));

dirInfo = dir(selDir);
dirFiles = {dirInfo.name};
fetFiles = dirFiles(cellfun(@(x) ~isempty(x), strfind(dirFiles, '.fet')));
spkFiles = dirFiles(cellfun(@(x) ~isempty(x), strfind(dirFiles, '.spk')));
cluFiles = dirFiles(cellfun(@(x) ~isempty(x), strfind(dirFiles, '.clu')));
grpIDs = regexp(fetFiles, '\.(\w+)$', 'tokens');
grpIDs = [grpIDs{:}]; grpIDs = [grpIDs{:}]; %kludgy
chanInfo = CreateChannelInfoPData(selDir);

% create look up table for grpID and number of electrodes
grpCountLUT = RetrievePDataColumns(CountTypes(chanInfo, 'GrpID'), ...
    {'GrpID' 'Count'}, 'NoHeader', 'RetMat', 1);

% if a _t file is present, use that to set the time for spikes
tFiles = dirFiles(cellfun(@(x) ~isempty(x), strfind(dirFiles, '_t.dat')));

tTable = [];
if ~isempty(tFiles)
    if length(tFiles)>1
        disp('Multiple _t files, unclear priority, ignoring.');
    else
        tFID = fopen([selDir tFiles{1}], 'r');
        fseek(tFID, 0, -1);
        tTable = fread(tFID, inf, 'double');
    end
end



% create cell arrays for unit data
dirEnts = {};
fileEnts = {};
grpEnts = {};
unitEnts = {};
indEnts = {};
timeEnts = {};
waveEnts = {};
snrEnts = {};


for j = 1:length(grpIDs)
    currGrp = grpIDs{j};
    numElec = grpCountLUT(grpCountLUT(:,1)==str2num(currGrp),2);
    
    % load data
    fetData = dlmread([selDir rootName '.fet.' currGrp], ' ');
    cluData = dlmread([selDir rootName '.clu.' currGrp], '');
    spkData = ImportSpkFile([selDir rootName '.spk.' currGrp], 32, numElec); %Add automatic detection of sampNum and elecNum
    
    spkIndStamps = fetData(2:end, end); % we only want the spike times
    cluData(1) = [];
    cluIDs = unique(cluData); % list the unit IDs
    
    % verify that the number of spikes agree across files
    if ~isequal(size(spkIndStamps,1), size(cluData,1), size(spkData,1))
        error('Number of spikes disagree across files, terminating');
    end
    
    for k = 1:length(cluIDs)
        currClu = cluIDs(k);
        cluInds = cluData == currClu;
        
        dirEnts{end+1,1} = selDir;
        fileEnts{end+1,1} = rootName;
        grpEnts{end+1,1} = currGrp;
        unitEnts{end+1,1} = num2str(currClu);
        indEnts{end+1,1} = spkIndStamps(cluInds);
        
        if ~isempty(tTable)
            timeEnts{end+1,1} = tTable(indEnts{end});
        else
            timeEnts{end+1,1} = indEnts{end}/sRate;
        end
        
        cluWaves = spkData(cluInds,:);
        meanWave = mean(cluWaves,1);
        waveEnts{end+1,1} = prctile(cluWaves, [2.5 50 97.5], 1);
        peakToTrough = max(meanWave)-min(meanWave);
        remainder = cluWaves-repmat(meanWave, size(cluWaves,1), 1);
        snrEnts{end+1,1} = peakToTrough/(2*std(remainder(:))); % Joshua SNR
    end
    
end
pData = MakeCellTableCol([], {'Directory' 'FileRoot' 'GrpID' 'UnitID' ...
    'TraceIndices' 'TimeStamps' 'WaveformDistribution' 'SpikeSNR'});
pData = [pData; [dirEnts fileEnts grpEnts unitEnts indEnts timeEnts waveEnts snrEnts]];
