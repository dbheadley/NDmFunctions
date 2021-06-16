function [chPData fName] = CreateChannelInfoPData(selDir)
%% CreateChannelInfoPData
% Generates a pData cell array containing acquisition and ND manager
% information for each channel
%% Syntax
%# [chPData fNames] = CreateChannelInfoPData(selDir)

%% Description
% Reads the ndm xml file in selDir that has the same name as the terminal
% directory. Channel information from the xml file is used to generate a
% row for each recording channel that describes recording and analysis
% parameters.
% 
%% INPUT
% * selDir - a string, the name of the directory containing the xml file,
% or the path to the particular xml file to access

%% OUTPUT
% * pData - a pData cell array, each row is a different channel


%% Example



%% Executable code
% ensure proper formatting of selDir name
if strcmp(selDir((end-2):end), 'xml')
    rootName = '';
    fName = selDir;
elseif ~strcmp(selDir(end), '/')
    slashInds = strfind(selDir, '/');
    rootName = selDir((slashInds(end)+1):end);
    fName = [selDir '/' rootName '.xml'];
else
    slashInds = strfind(selDir, '/');
    rootName = selDir((slashInds(end-1)+1):(end-1));
    fName = [selDir rootName '.xml'];
end




xmlData = xml2struct(fName);
xmlData = xmlData.parameters;

chPData = MakeCellTableCol([], {'Directory' 'FileRoot' 'ChanID' 'GrpID' ...
    'SampleRate' 'VoltageRange' 'Offset' 'Amplification' ...
    'nBits' 'SpkNumSamples' 'SpkPeakSample' 'SpkNFeatures' 'Color' 'NumChans'});

% get acquisition system settings that apply to all channels
chanNum = str2num(xmlData.acquisitionSystem.nChannels.Text);
sampRate = str2num(xmlData.acquisitionSystem.samplingRate.Text);
voltRange = str2num(xmlData.acquisitionSystem.voltageRange.Text);
offset = str2num(xmlData.acquisitionSystem.offset.Text);
amp = str2num(xmlData.acquisitionSystem.amplification.Text);
nBits = str2num(xmlData.acquisitionSystem.nBits.Text);

% create LUT for color properties
chanListCol = cellfun(@(x)str2num(x.channel.Text), ...
    xmlData.neuroscope.channels.channelColors);
colorList = cellfun(@(x)rgbconv(x.color.Text(2:7)), ...
    xmlData.neuroscope.channels.channelColors, 'UniformOutput', false);


numGrps = length(xmlData.spikeDetection.channelGroups.group);

% create cell arrays for channel data
dirEnts = {};
fileEnts = {};
chanEnts = {};
grpEnts = {};
sRateEnts = {};
voltRangeEnts = {};
offsetEnts = {};
ampEnts = {};
nBitEnts = {};
spkNumSampEnts = {};
spkPeakSampEnts = {};
spkNFeatEnts = {};
colorEnts = {};
numChansEnts = {};

for j = 1:numGrps
    currGrp = j;
    if iscell(xmlData.spikeDetection.channelGroups.group)
        grpXML = xmlData.spikeDetection.channelGroups.group{j};
    else
        grpXML = xmlData.spikeDetection.channelGroups.group;
    end
    spkNumSamples = str2num(grpXML.nSamples.Text);
    spkPeakSample = str2num(grpXML.peakSampleIndex.Text);
    spkNFeatures = str2num(grpXML.nFeatures.Text);
    numChans = length(grpXML.channels.channel);
    for k = 1:numChans
        if iscell(grpXML.channels.channel)
            currChan = str2num(grpXML.channels.channel{k}.Text);
        else
            currChan = str2num(grpXML.channels.channel.Text);
        end
        chanColor = colorList{chanListCol == currChan};
        dirEnts{end+1,1} = selDir;
        fileEnts{end+1,1} = rootName;
        chanEnts{end+1,1} = currChan;
        grpEnts{end+1,1} = currGrp;
        sRateEnts{end+1,1} = sampRate;
        voltRangeEnts{end+1,1} = voltRange;
        offsetEnts{end+1,1} = offset;
        ampEnts{end+1,1} = amp;
        nBitEnts{end+1,1} = nBits;
        spkNumSampEnts{end+1,1} = spkNumSamples;
        spkPeakSampEnts{end+1,1} = spkPeakSample;
        spkNFeatEnts{end+1,1} = spkNFeatures;
        colorEnts{end+1,1} = chanColor;
        numChansEnts{end+1,1} = chanNum;
    end
end


chPData = [chPData; [dirEnts fileEnts chanEnts grpEnts sRateEnts voltRangeEnts ...
    offsetEnts ampEnts nBitEnts spkNumSampEnts spkPeakSampEnts spkNFeatEnts ...
    colorEnts numChansEnts]];
