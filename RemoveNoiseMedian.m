function fName = RemoveNoiseMedian(fileName, chanNum, sRate, refList)

% fileName is the full file path and name
% chanNum is the number of channels in the recording
% sRate is the sample Rate
% refList is list of numbers specifying how to group channels together when
% calculating the median. Groups are integers greater than one. Zero is 
% reserved for channels that are to be excluded from the median calculation.
% For example, if your first four channels were not used for extracellular 
% recording, the next 32 were tetrodes, then 16 sites on a silicon probe,
% then 12 disconnected inputs, your refList would be:
% [zeros(4,1); ones(32,1); 2*ones(16,1); zeros(12,1)]

fileInfo=dir(fileName);
fid1=fopen(fileName,'r');
fName = [fileName(1:(end-4)) '_New.fil'];
fid2=fopen(fName,'w');


fileSize=fileInfo.bytes;
fileTime=fileSize/(chanNum*2*sRate); %file time in seconds

if isempty(refList)
    refList = zeros(chanNum,1);
end

refGrps = unique(refList);
numGrps = length(refGrps);

min=0;
for i=0:floor(fileTime/60)-1 %cycle through the file minute by minute
    clear A
    clear B
    min=min+1
    fseek(fid1,i*sRate*60*chanNum*2,-1);
    A=fread(fid1,[chanNum,sRate*60],'int16'); %use this for filtered
    B=zeros(size(A));
    sr = zeros(size(A));
    
    for j = 1:numGrps
        currGrp = refGrps(j);
        grpInds = refList == currGrp;
        grpSize = sum(grpInds);
        if (currGrp == 0)
            continue;
        else
            sr(grpInds,:) = repmat(median(A(grpInds,:),1), grpSize, 1);  
        end
    end
    B=A-sr;
    
    % clip outlier datapoints (with intan voltages whose magnitude exceeds
    % 390 uV.
    B(B>2000) = 2000;
    B(B<-2000) = -2000;
    fwrite(fid2,[B],'int16');
    
end

i=i+1

clear A
clear B
min=min+1
fseek(fid1,i*60*sRate*chanNum*2,-1);
A=fread(fid1,[chanNum,inf],'int16'); %reads next minute of data
sr = zeros(size(A));

for j = 1:numGrps
    currGrp = refGrps(j);
    grpInds = refList == currGrp;
    grpSize = sum(grpInds);
    if (currGrp == 0)
        continue;
    else
        sr(grpInds,:) = repmat(median(A(grpInds,:),1), grpSize, 1);
    end
end
B=A-sr;
B(B>2000) = 2000;
B(B<-2000) = -2000;
fwrite(fid2,[B],'int16');
fclose('all');