function UnitFilter(fileName, numChannels, sRate, medWindow)
fileInfo=dir(fileName);
fid1=fopen(fileName,'r');
fid2=fopen([fileName(1:(end-4)) '.fil'],'w');
fid3=fopen([fileName(1:(end-4)) '_t.fil'],'w');
fid4=fopen([fileName(1:(end-4)) '_t.dat'],'r');

if (fid4 == -1)
    disp('No _t file, ignoring.');
    tTable = [];
else
    fseek(fid4, 0, -1);
    tTable = fread(fid4, inf, 'double');
end

winStep = 60;
sampStep = round(sRate*winStep);
fileSize=fileInfo.bytes;
% 
% [b, a] = iircomb(sRate/500, (500/(sRate/2))/200,'notch');

edgeSpace = round(0.1*sRate);
if mod(edgeSpace,2) == 1
    edgeSpace = edgeSpace - 1;
end
overSpace = edgeSpace/2;


fileTime=fileSize/(numChannels*2*sRate); %file time in seconds

% generate mapping between indices for original dat file and the resampled
% .eeg file. Also, create list of indicies to resample so that the signal
% is decimated evenly across window steps
tList = 1:(fileSize/(numChannels*2));
fseek(fid3, 0, -1);
if isempty(tTable)
    resampTMap = uint64(tList);
    fwrite(fid3, resampTMap, 'uint64');
else
    resampTMap = tTable(tList);
    fwrite(fid3, resampTMap, 'double');
end

min=0;
edgeSig = [];
for i=0:(floor(fileTime/winStep)-2) %cycle through the file minute by minute
    min=min+1
    startInd = i*sampStep*numChannels*2;
    fseek(fid1, startInd,-1);
    origSig=fread(fid1,[numChannels,sampStep],'int16'); %use this for filtered
    if isempty(edgeSig)
        filtSig = origSig-movmedian(origSig,medWindow,2);
        writeWin = true(1,size(filtSig,2));
        writeWin((end-overSpace+1):end) = false;
        fwrite(fid2,filtSig(:,writeWin),'int16');
    else
        filtSig = [edgeSig origSig]-movmedian([edgeSig origSig],medWindow,2);
        writeWin = true(1,size(filtSig,2));
        writeWin(1:overSpace) = false;
        writeWin((end-overSpace+1):end) = false;
        fwrite(fid2,filtSig(:,writeWin),'int16');
    end
    
    edgeSig = origSig(:,(end-edgeSpace+1):end);
end

i=i+1

min=min+1
startInd = i*sampStep*numChannels*2;
fseek(fid1,startInd,-1);
origSig=fread(fid1,[numChannels,inf],'int16'); %use this for filtered
filtSig = [edgeSig origSig]-movmedian([edgeSig origSig],medWindow,2);
writeWin = true(1,size(filtSig,2));
writeWin(1:overSpace) = false;
fwrite(fid2,filtSig(:,writeWin),'int16');
fclose('all');