function spkWaves = ImportSpkFile(selFile, sampNum, elecNum)
%% ImportSpkFile
% Creates an array of spike waveforms from a .spk file.

%% Syntax
%# spkWaves = ImportSpkFile(selFile)

%% Description
% Loads spike waveforms from the binary .spk file specified by selFile.
% This entails reordering the indices of the .spk file, since waves are
% not stored in sequence with respect to the electrode they were recorded
% from.

%% INPUT
% * selFile - a string, the name of the file containing spike waveforms
% * sampNum - an integer, the number of samples acquired for each waveform
% * elecNum - an integer, the number of electrodes that made up the
% 'tetrode'

%% OUTPUT
% * spkWaves - an NxM numeric array, the spike waveforms, each row has the
% waveforms for a given spike across the tetrode.
%% Example

%% Executable code

fidSpk = fopen(selFile, 'r');
fProps = dir(selFile);
fLength = fProps.bytes;
spkNum = fLength/(2*sampNum*elecNum); % the number of waveforms
fseek(fidSpk, 0, -1);
sampleTbl = fread(fidSpk, inf, 'int16');

spkWaves = permute(...
            reshape(...
             permute(...
              reshape(sampleTbl,[elecNum sampNum spkNum]), ...
             [2 1 3]), ...
            [elecNum*sampNum spkNum]), ...
           [2 1]);

end

