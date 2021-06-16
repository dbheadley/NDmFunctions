function newNDMXML = CreateNDMXML(filDir, baseName, chanNum, sampRate, lfpSampRate, ...
    chanGrps, waveWindow, pcNum)
    
    % filDir = directory containing the fil file
    % baseName = the common name shared by all the data files, used to name
    % the xml file.
    % chanNum = overall number of channels recorded from
    % sampRate = sampling rate of fil file.
    % lfpSampRate = sampling rate of .lfp file
    % chanGrps = the configuration of the channel groupings. The same as
    % used for the SpikeSort configuration in ProcessRawRecordingKilosort.


    xmlFID = fopen('NDMBare.xml','r');
    xmlBase = char(fread(xmlFID)');
    

    % fill in acquisition system properties, ACQHEREFILLIN
% number of channels
% <acquisitionSystem>
%   <nBits>16</nBits>
%   <nChannels>FILLIN</nChannels>
%   <samplingRate>FILLIN</samplingRate>
%   <voltageRange>20</voltageRange>
%   <amplification>1000</amplification>
%   <offset>0</offset>
%  </acquisitionSystem>
    acqText = ['<acquisitionSystem>' char(10) ...
               '<nBits>16</nBits>' char(10) ...
               '<nChannels>' num2str(chanNum) '</nChannels>' char(10) ...
               '<samplingRate>' num2str(sampRate) '</samplingRate>' char(10) ...
               '<voltageRange>20</voltageRange>' char(10) ...
               '<amplification>1000</amplification>' char(10) ...
               '<offset>0</offset>' char(10) ...
               '</acquisitionSystem>'];
    xmlBase = strrep(xmlBase, 'ACQHEREFILLIN', acqText);


% fill in lfp sampling rate in field potentials field, LFPHEREFILLIN
% <fieldPotentials>
%   <lfpSamplingRate>FILLIN</lfpSamplingRate>
%  </fieldPotentials>
    lfpText = ['<fieldPotentials>' char(10) ...
               '<lfpSamplingRate>' num2str(lfpSampRate) '</lfpSamplingRate>' char(10) ...
               '</fieldPotentials>'];
    xmlBase = strrep(xmlBase, 'LFPHEREFILLIN', lfpText);



% fill in fil file sampling rate in files, FILHEREFILLIN
% <file>
%    <samplingRate>FILLIN</samplingRate>
%    <extension>fil</extension>
%   </file>
    filText = ['<file>' char(10) ...
               '<samplingRate>' num2str(sampRate) '</samplingRate>' char(10) ...
               '<extension>fil</extension>' char(10) ...
               '</file>'];
    xmlBase = strrep(xmlBase, 'FILHEREFILLIN', filText);





% put in channel groups using the format below, CHANGRPFILLIN
% channel numbers start at 0
% <group>
%     <channel skip="0">FILLIN</channel>
%     <channel skip="0">FILLIN</channel>
%     <channel skip="0">FILLIN</channel>
%     <channel skip="0">FILLIN</channel>
%    </group>
    grpText = [];
    for j = 1:length(chanGrps)
        currText = ['<group>' char(10)];
        chanList = chanGrps(j).SiteChans(~isnan(chanGrps(j).SiteChans));
        for k = 1:length(chanList)
            currText = [currText '<channel skip="0">' num2str(chanList(k)-1) ...
                '</channel>' char(10)];
        end
        currText = [currText '</group>' char(10)];
        grpText = [grpText currText];
    end
    
    xmlBase = strrep(xmlBase, 'CHANGRPFILLIN', grpText);


% put in channel groups for spike detection using the format below,
% SPKGRPFILLIN
% channel numbers start at 0
% <group>
%     <channels>
%      <channel>FILLIN</channel>
%      <channel>FILLIN</channel>
%      <channel>FILLIN</channel>
%      <channel>FILLIN</channel>
%     </channels>
%     <nSamples>FILLIN</nSamples>
%     <peakSampleIndex>FILLIN</peakSampleIndex>
%     <nFeatures>FILLIN</nFeatures>
%    </group>

    grpText = [];
    for j = 1:length(chanGrps)
        currText = ['<group>' char(10) '<channels>' char(10)];
        chanList = chanGrps(j).SiteChans(~isnan(chanGrps(j).SiteChans));
        for k = 1:length(chanList)
            currText = [currText '<channel>' num2str(chanList(k)-1) ...
                '</channel>' char(10)];
        end
        currText = [currText '</channels>' char(10)];
        currText = [currText '<nSamples>' num2str(waveWindow) '</nSamples>' ...
            char(10)];
        currText = [currText '<peakSampleIndex>' num2str(round(waveWindow/2)) ...
            '</peakSampleIndex>' char(10)];
        currText = [currText '<nFeatures>' num2str(pcNum) ...
            '</nFeatures>' char(10)];
        grpText = [grpText currText '</group>' char(10)];
    end
    
    xmlBase = strrep(xmlBase, 'SPKGRPFILLIN', grpText);
    
    % write out new xml file
    xmlOutFID = fopen(fullfile(filDir,[baseName '.xml']),'w');
    fwrite(xmlOutFID,xmlBase);
    
    fclose(xmlFID);
    fclose(xmlOutFID);