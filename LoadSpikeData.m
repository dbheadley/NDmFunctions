function spksStr = LoadSpikeData(selDir)
%% LoadSpikeData
% Generates a structure containing spike data from the selected directory

%% Syntax
%# spksStr = LoadSpikePData(selDir)

%% Description
% Loads and organizes spike data files from 'selDir' into a structure.
% Automatically detects the number of electrode groups, the corresponding
% unit waveforms, spike times, and unit groups. The name of the terminal
% directory that selDir points to is assumed to be the root file name for
% all spike files. The number of electrode groups is also determined
% automatically by the suffixes of the .fet files.
% 
%% INPUT
% * selDir - a string, the name of the directory containing the spike data

%% OUTPUT
% * spksStr - a structure, the spike data


%% Example



%% Executable code


% ensure proper formatting of selDir name
if ~strcmp(selDir(end), '/')
    selDir(end+1) = '/';
end

% access properties from ND manager config file
fSlashInds = strfind(selDir, '/');
rootName = selDir((fSlashInds(end-1)+1):(fSlashInds(end)-1));

% get timestamps
tFID = fopen([selDir rootName '_t.dat'], 'r');
fseek(tFID, 0, -1);
tTable = fread(tFID, inf, 'double');

% config file is assumed to be in directory one step above spike data directory
chPData = CreateChannelInfoPData([selDir(1:fSlashInds(end-1)) 'SpikeExtract_Process.xml']); 
chPData = mergerowpd(chPData, {'ChanID' 'SpkNumSamples'}, 'GrpID');
spkCount = 0;
grpCol = colindpd(chPData, 'GrpID');
chanCol = colindpd(chPData, 'ChanID');
numSampCol = colindpd(chPData, 'SpkNumSamples');

for j = 2:size(chPData,1)
  currGrp = num2str(chPData{j, grpCol});
  numElec = numel(chPData{j, chanCol});
  numSampPerSpk = chPData{j, numSampCol}{1};
  fetData = dlmread([selDir rootName '.fet.' currGrp], ' ');
  cluData = dlmread([selDir rootName '.clu.' currGrp], '');
  spkData = ImportSpkFile([selDir rootName '.spk.' currGrp], numSampPerSpk, numElec);
  spkIndStamps = fetData(2:end, end); % we only want the spike times
  cluData(1) = [];
  cluIDs = unique(cluData); % list the unit IDs
  
  % verify that the number of spikes agree across files
  if ~isequal(size(spkIndStamps,1), size(cluData,1), size(spkData,1))
    error('Number of spikes disagree across files, terminating');
  end
  
  for k = 1:length(cluIDs)
    spkCount = spkCount + 1;
    currClu = cluIDs(k);
    cluInds = cluData == currClu;
    
    spksStr(spkCount).Directory = selDir;
    spksStr(spkCount).FileRoot = rootName;
    spksStr(spkCount).GrpID = currGrp;
    spksStr(spkCount).UnitID = num2str(currClu);
    spksStr(spkCount).TraceIndices = spkIndStamps(cluInds);
    spksStr(spkCount).TimeStamps = tTable(spkIndStamps(cluInds));

    cluWaves = spkData(cluInds,:);
    meanWave = mean(cluWaves,1);
    spksStr(spkCount).WaveformDistribution = prctile(cluWaves, [2.5 50 97.5], 1);    
    
    peakToTrough = max(meanWave)-min(meanWave);
    remainder = cluWaves-repmat(meanWave, size(cluWaves,1), 1);
    spksStr(spkCount).SpikeSNR = peakToTrough/(2*std(remainder(:))); % Joshua SNR
  end
end