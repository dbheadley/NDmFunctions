% This example shows how to use ProcessRawRecordingKilosort to preprocess
% and spike sort the data sent out by the intan.

%% Configure each processing step
% procConfig is a structure that stores the settings for each processing
% step. If you do not want to perform a particular step, just omit its
% field from procConfig. Note that some processing steps depend on previous
% ones, such as spike sorting depending upon unit filtering. 

procConfig.BaseName = '17-09-16_BLA-8x8-1_Spontaneous';
procConfig.RawRate = 30000;

procConfig.Intan2Datmap = {};

procConfig.UnitFilter.MedianFilterWidth = 64;
procConfig.UnitFilter.RefGroups = ones(64,1);


procConfig.LFPFilter.CutoffFreq = 300;
procConfig.LFPFilter.ResampleRate = 1000;


% This is the spatial arrangement of my 8x8 silicon probe
eXeMap2 = [17 22 16 23 19 20 18 21; ...
25 30 24 31 27 28 26 29; ...
0  9  1  8  2  6  4  5; ...
10 3  12 7  13 11 14 15; ...
61 52 57 50 53 51 49 48; ...
55 62 54 63 56 60 59 58; ...
32 39 33 38 34 37 35 36; ...
40 47 41 46 42 45 43 44;];
colMat = cumsum(ones(8,8),2);
rowMat = cumsum(ones(8,8),1);
% generate a channel group for each shank
for j = 1:8
    procConfig.SpikeSort(j).SiteName = num2str(j);
    procConfig.SpikeSort(j).SiteChans = eXeMap2(j,:)+1;
    procConfig.SpikeSort(j).XCoords = ones(1,8);
    procConfig.SpikeSort(j).YCoords = 1:8;
    procConfig.SpikeSort(j).KCoords = ones(1,8);
end    


% settings for Klusters
procConfig.Klusters.WaveformWindow = 32;
procCongif.Klusters.PCNumber = 3;