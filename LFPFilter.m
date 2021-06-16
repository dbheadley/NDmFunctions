function LFPFilter(fileName, numChannels, sRate, highCutoff, resampRate)
fileInfo=dir(fileName);
fid1=fopen(fileName,'r');
fid2=fopen([fileName(1:(end-4)) '.lfp'],'w');
fid3=fopen([fileName(1:(end-4)) '_t.lfp'],'w');
fid4=fopen([fileName(1:(end-4)) '_t.dat'],'r');

if (fid4 == -1)
    disp('No _t file, ignoring.');
    tTable = [];
else
    fseek(fid4, 0, -1);
    tTable = fread(fid4, inf, 'double');
end

% sRate=30030.03003; %sample rate in Hz
winStep = 60;
sampStep = round(sRate*winStep);
fileSize=fileInfo.bytes;
% numChannels=64;
resampStep = round(sRate/resampRate);

[b, a] = butter(2, highCutoff/(sRate/2), 'low');

edgeSpace = round(0.1*sRate);
if mod(edgeSpace,2) == 1
    edgeSpace = edgeSpace - 1;
end
overSpace = edgeSpace/2;


fileTime=fileSize/(numChannels*2*sRate); %file time in seconds

% generate mapping between indices for original dat file and the resampled
% .lfp file. Also, create list of indicies to resample so that the signal
% is decimated evenly across window steps
resampPoints = zeros(1,(fileSize/(numChannels*2)));
resampPoints(1:resampStep:end) = 1; 
tList = 1:(fileSize/(numChannels*2));
tListSamp = tList(logical(resampPoints));
fseek(fid3, 0, -1);
if isempty(tTable)
    resampTMap = uint64(tListSamp);
    fwrite(fid3, resampTMap, 'uint64');
else
    resampTMap = tTable(tListSamp);
    fwrite(fid3, resampTMap, 'double');
end




min=0;
edgeSig = [];
for i=0:(floor(fileTime/winStep)-2) %cycle through the file minute by minute
    min=min+1
    startInd = i*sampStep*numChannels*2;
    tSampInd = startInd/(numChannels*2);
    fseek(fid1, startInd,-1);
    origSig=fread(fid1,[numChannels,sampStep],'int16'); %use this for filtered
    currRSPts = logical(resampPoints((tSampInd+1):(tSampInd+sampStep)));
    if isempty(edgeSig)
        filtSig = filtfilt(b,a,origSig')';
        writeWin = true(1,size(filtSig,2));
        writeWin((end-overSpace+1):end) = false;
        fwrite(fid2,filtSig(:,writeWin & currRSPts),'int16');
    else
        filtSig = filtfilt(b,a,[edgeSig origSig]')';
        writeWin = true(1,size(filtSig,2));
        writeWin(1:overSpace) = false;
        writeWin((end-overSpace+1):end) = false;
        fwrite(fid2,filtSig(:,writeWin & [edgeRSPts currRSPts]),'int16');
    end
    
    edgeSig = origSig(:,(end-edgeSpace+1):end);
    edgeRSPts = currRSPts((end-edgeSpace+1):end);
end

i=i+1

min=min+1
startInd = i*sampStep*numChannels*2;
tSampInd = startInd/(numChannels*2);
fseek(fid1,startInd,-1);
origSig=fread(fid1,[numChannels,inf],'int16'); %use this for filtered
currRSPts = logical(resampPoints((tSampInd+1):end));
filtSig = filtfilt(b,a,[edgeSig origSig]')';
writeWin = true(1,size(filtSig,2));
writeWin(1:overSpace) = false;
fwrite(fid2,filtSig(:,writeWin & [edgeRSPts currRSPts]),'int16');
fclose('all');