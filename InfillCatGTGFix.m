function InfillCatGTGFix(fNameBin, infillSpanSec)
    fNameMeta = [fNameBin(1:(end-4)) '.meta'];
    
    [fPath, fNameMeta, metaExt] = fileparts(fNameMeta);
    params = ReadNPMeta([fNameMeta metaExt], fPath);

    numChans = str2num(params.nSavedChans);
    numTPts = str2num(params.fileSizeBytes)/(2*numChans);
    sampRate = str2num(params.imSampRate);
    chanList = str2num(params.snsApLfSy);
    apChans = 1:chanList(1);
    syChan = sum(chanList);
    
    gFixStrel = ones(round(sampRate*0.001),1);
    infillStrel = ones(round(sampRate*infillSpanSec),1);
    binFID = fopen(fNameBin,'r+');
    fseek(binFID,0,'bof');
    
    disp('Loading data for detecting gFix areas');
    rec = fread(binFID, numTPts, 'int16', 2*(numChans-1));
    
    disp('Identifying gFix areas');
    gFixAreas = imopen(rec==0,gFixStrel);
    infillAreas = imclose(gFixAreas, infillStrel);
    infillRegions = regionprops(infillAreas,{'BoundingBox'});
    numRegions = length(infillRegions);
    disp('Infilling gFix areas');
    for k = 1:numRegions
        fprintf('Infilling %u of %u.\n', k, numRegions);
        startTPt = round(infillRegions(k).BoundingBox(2));
        startFInd = startTPt*2*numChans;
        infillDur = infillRegions(k).BoundingBox(4);
        
        % get sy chan data to avoid overwriting with 0 fill
        fseek(binFID, startFInd+(2*(syChan-1)), 'bof');
        syRec = fread(binFID, infillDur, 'int16', 2*(numChans-1));
        infillData = zeros(numChans,infillDur,'int16');
        infillData(syChan,:) = syRec;
        
        fseek(binFID, startFInd, 'bof');
        fwrite(binFID,infillData(:),'int16');
    end
    
    disp('Infilling gFix areas');
    fclose(binFID);