% 221022 validation w Mo

apPath = ['F:\21-06-05_AD25_RRITSingles1_g0\' ...
          '21-06-05_AD25_RRITSingles1_g0_imec1\' ...
          '21-06-05_AD25_RRITSingles1_g0_t0.imec1.ap.bin'];

rez = SortSpikes(apPath, 'NBLOCKS', 1, ...
                         'SPKTHRESH', [9 9], ...
                         'NTFACTOR', 8);%, ...



%%

apPath = ['F:\21-06-05_AD25_Spontaneous_g0\' ...
          '21-06-05_AD25_Spontaneous_g0_imec2\' ...
          '21-06-05_AD25_Spontaneous_g0_t0.imec2.ap.bin'];

rez = SortSpikes(apPath, 'NBLOCKS', 1, ...
                         'SPKTHRESH', [12 12], ... % use this for PAG probe
                         'NTFACTOR', 9, ...
                         'SKIPCATGT'); % use this for PAG probe
       
                     
                     
                     
                     
                     
% % F:\21-06-05_AD25_Spontaneous_g0\21-06-05_AD25_Spontaneous_g0_imec2
% apPath = ['F:\21-06-05_AD25_Spontaneous_g0\' ...
%           '21-06-05_AD25_Spontaneous_g0_imec3\' ...
%           '21-06-05_AD25_Spontaneous_g0_t0.imec3.ap.bin'];
% 
% rez = SortSpikes(apPath, 'NBLOCKS', 1, ...
%                          'SPKTHRESH', [9 9], ...
%                          'NTFACTOR', 9);%, ...
%                      
% apPath = ['F:\21-06-05_AD25_Spontaneous_g0\' ...
%           '21-06-05_AD25_Spontaneous_g0_imec1\' ...
%           '21-06-05_AD25_Spontaneous_g0_t0.imec1.ap.bin'];
% 
% rez = SortSpikes(apPath, 'NBLOCKS', 1, ...
%                          'SPKTHRESH', [9 9], ...
%                          'NTFACTOR', 9);%, ...

