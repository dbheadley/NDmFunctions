function RemoveSpikeTraces(fileName)
fileInfo=dir(fileName);
fid1=fopen(fileName,'r');
fidFil=fopen([fileName(1:(end-4)) '.fil'],'r');
fid2=fopen([fileName(1:(end-4)) '_New.dat'],'a');


fileSize=fileInfo.bytes;
numChannels=64;
sRate=30030; %sample rate in Hz

fileTime=fileSize/(numChannels*2*sRate); %file time in seconds

min=0;
for i=0:floor(fileTime/60)-1 %cycle through the file minute by minute
    clear A
    clear B
    min=min+1
    fseek(fid1,i*sRate*60*numChannels*2,-1);
    A=fread(fid1,[numChannels,sRate*60],'int16'); %wideband signal
    B=fread(fidFil,[numChannels,sRate*60],'int16'); %unit filtered signal
    size(A)
    size(B)
    out=A-B;
    fwrite(fid2,[out],'int16');
    
end

i=i+1

clear A
clear B
min=min+1
fseek(fid1,i*60*sRate*numChannels*2,-1);
A=fread(fid1,[numChannels,inf],'int16'); %reads next minute of data
B=fread(fidFil,[numChannels,inf],'int16'); 
out=A-B;
fwrite(fid2,[out],'int16');
