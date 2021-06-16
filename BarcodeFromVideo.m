function bcSeqFNames = BarcodeFromVideo(vidDir)
    
    vidFList = dir(fullfile(vidDir,'*.avi'));

    numVids = length(vidFList);
    
    % determine ROIs for barcode
    roiVidFName = fullfile(vidFList(1).folder, vidFList(1).name);
    roiFrames = LoadVid(roiVidFName);
    
    meanFrame = mean(double(roiFrames),3);
    sdFrame = std(double(roiFrames),1,3);
    
    roiCount = 1;
    figure;
    while roiCount < 6
        subplot(1,2,1);
        image(sdFrame);
        subplot(1,2,2);
        image(meanFrame);
        
        roiPt = drawpoint();
%         rois(:,:,roiCount) = roipoly;
        roiPos(roiCount,:) = round(roiPt.Position);
        roiSers(:,roiCount) = squeeze(roiFrames(roiPos(roiCount,2),roiPos(roiCount,1),:));
%         
%         mean(uint8(rois(:,:,roiCount)).*roiFrames,[1 2])./...
%             std(double(rois(:,:,roiCount)).*double(roiFrames),1,[1 2]);

        plot(roiSers(:,roiCount));
        
        acceptROI = input('Are these ROIs acceptable (yes/no)');
        if strcmp('yes',lower(acceptROI))
            roiCount = roiCount + 1;
        else
            disp('Try again');
        end
    end
    
    % extract all LED pulse series
    %allFrames = [];
    for j = 1:numVids
        disp(['Processing video ' num2str(j) ' of ' num2str(numVids)]);
        vidFName = fullfile(vidFList(j).folder, vidFList(j).name);
        currFrames = LoadVid(vidFName);
        %allFrames = cat(3,allFrames,currFrames);
        for k = 1:5
            pulseSer{j}(:,k) = squeeze(currFrames(roiPos(k,2),roiPos(k,1),:));
%             mean(uint8(rois(:,:,k)).*currFrames,[1 2])./...
%                             std(double(rois(:,:,k)).*double(currFrames),1,[1 2]);
        end
    end
        
    % Set threshold for detecting significant pulses
    fullSer = cell2mat(pulseSer');
    roiCount = 1;
    while roiCount < 6
        histogram(fullSer(:,roiCount));
        thresh(roiCount) = input('Enter pulse threshold: ');
        binSer(:,roiCount) = fullSer(:,roiCount)>thresh(roiCount);
        
        histogram(fullSer(~binSer(:,roiCount),roiCount)); hold on;
        histogram(fullSer(binSer(:,roiCount),roiCount)); hold off;
        
        acceptThresh = input('Is this threshold acceptable (yes/no)');
        if strcmp('yes',lower(acceptThresh))
            roiCount = roiCount + 1;
        else
            disp('Try again');
        end
    end
    
    
    % Construct table of barcodes for frames
    for j = 1:numVids
        [~, vidRoot] = fileparts(vidFList(j).name);
        vidCSVFName = fullfile(vidFList(j).folder, [vidRoot '.csv']);
        csvData = csvread(vidCSVFName);
        bcSeq = (pulseSer{j}>thresh)*[1; 2; 4; 8; 16];   
        if length(bcSeq) ~= size(csvData,1)
            error(['Disagreement in barcode count for file ' vidCSVFName]);
        end
        bcSeqFNames{j} = fullfile(vidFList(j).folder, [vidRoot '_BCSeq.csv']);
        bcFID = fopen(bcSeqFNames{j}, 'w');
        for k = 1:size(bcSeq,1)
            fprintf(bcFID, '%u,%u,%u,%s\r\n', bcSeq(k), csvData(k,1), ...
                    csvData(k,2), vidFList(j).name);
        end
        fclose(bcFID);
    end
    
     