% apPath = ['F:\21-06-05_AD25_Spontaneous_g0\' ...
%           '21-06-05_AD25_Spontaneous_g0_imec2\' ...
%           '21-06-05_AD25_Spontaneous_g0_t0.imec2.ap.bin'];
% 
% rez = SortSpikes(apPath, 'NBLOCKS', 1, ...
%                          'SPKTHRESH', [12 12], ... % use this for PAG probe
%                          'NTFACTOR', 9, ...
%                          'SKIPCATGT');
%                      
% % % F:\21-06-05_AD25_Spontaneous_g0\21-06-05_AD25_Spontaneous_g0_imec2
% % apPath = ['F:\21-06-05_AD25_Spontaneous_g0\' ...
% %           '21-06-05_AD25_Spontaneous_g0_imec3\' ...
% %           '21-06-05_AD25_Spontaneous_g0_t0.imec3.ap.bin'];
% % 
% % rez = SortSpikes(apPath, 'NBLOCKS', 1, ...
% %                          'SPKTHRESH', [9 9], ...
% %                          'NTFACTOR', 9);%, ...
%                      
% % apPath = ['F:\21-06-05_AD25_Spontaneous_g0\' ...
% %           '21-06-05_AD25_Spontaneous_g0_imec1\' ...
% %           '21-06-05_AD25_Spontaneous_g0_t0.imec1.ap.bin'];
% % 
% % rez = SortSpikes(apPath, 'NBLOCKS', 1, ...
% %                          'SPKTHRESH', [9 9], ...
% %                          'NTFACTOR', 9);%, ...
% 
% 
%%

spiketrain = [0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0 0 0 0 0 0 1 1 1 0 1 1 1]

for idx = find(spiketrain == 1)
    autocorrelation = autocorrelation + circshift(spiketrain, -idx)
end

spiketrain= [0 1 1 1 0 1 1 1 0 0 1 1 1 0 1 1 1];
idx = find(spiketrain==1);
auto=0;
for i = idx
    auto=auto+circshift(spiketrain,spiketrain(end-(i-1):end));   
end
plot(auto)
xlabel('time(ms)')
ylabel('Frequency')


%%
% 
% figure
% SpkTrain = [1 0 0 1 1 0 0 1];
% 
% for count = 1:numel(SpkTrain)
% 
%     train1 = SpkTrain(count+1:end);
%     train2 = -1*(SpkTrain(1:count));
%     modSpkTrain(count,:) = [train2 train1];
% 
% end
% 
% bar(abs(sum(modSpkTrain)))


% from reference point 1, I want +1 @ index 4,5,7
% from reference point 2 (find when SpkTrain == 1), I want +1 @ index -3,1,4
% figure;
% SpkTrain = [1 0 0 1 1 0 0 1];
% idx_when_1 = find(SpkTrain==1);
% auto = 0;
% for idx = idx_when_1
%     auto = auto + 
% end


spike = [0 0 1 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 1 0 0 0 1]
spikeTime = find(spike==1)
NumberofSpike = length(spikeTime)

C = combntns([1:NumberofSpike],2)
C_reverse = [C(:,2) C(:,1)]
C = [C ; C_reverse];

delay = [];
for i=1:length(C)
  delay = [delay spikeTime(C(i,1)) - spikeTime(C(i,2))]
end

N = histc(delay,[-100:1:100]); N(end)=[];




