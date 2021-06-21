function np2datmap(selDir, fName, prb, artRem)
  
%% process AP file
    % get file names
    fList = dir(selDir);
    fNames = {fList.name};

    if ~any(strcmp([fName '.ap.bin'],fNames))
        error([fName '.ap.bin file not present']);
    end

    % get recording parameters from meta file.
    params = ReadNPMeta([fName '.ap.meta'], selDir);

    numChans = str2num(params.nSavedChans);
    numTPts = str2num(params.fileSizeBytes)/(2*numChans);
    sampRate = str2num(params.imSampRate);
    chanList = str2num(params.snsApLfSy);
    apChans = 1:chanList(1);
    syChan = sum(chanList);

    % CREATE FIL FILE HERE
    selDirParts = strsplit(selDir,filesep);
    catgtDir = [strjoin(selDirParts(1:(end-3)),filesep) filesep];
    % remove _g0 part, since catgt appends it
    catgtRun = selDirParts{end-2}(1:(end-3));
    if artRem
        catgtCmd = ['CatGT -dir=' catgtDir ' -run=' catgtRun ' -prb=' prb ...
                    ' -prb_fld -g=0 -t=0 -ap -aphipass=300 -aplopass=9000 ' ...
                    '-gfix=1,0,0.1 -gbldmx'];
    else
        catgtCmd = ['CatGT -dir=' catgtDir ' -run=' catgtRun ' -prb=' prb ...
                    ' -prb_fld -g=0 -t=0 -ap -aphipass=300 -aplopass=9000 ' ...
                    ' -gbldmx'];
    end
    dos(catgtCmd);
    
    % rename file to fil
    % fil file will only be used by kilosort, so we will not create a _t or
    % _ch file that makes it accessible to datmap.
    newFList = dir(selDir);
    filFileInd = find(cellfun(@(x)contains(x,'_tcat')&contains(x,'.bin'),{newFList.name}));
    origFilPath = fullfile(newFList(filFileInd).folder,newFList(filFileInd).name);
    if artRem
        InfillCatGTGFix(origFilPath, 0.05);
    end
    
    newFilName = [fName '.fil'];
    renameCmd = ['ren ' origFilPath ' ' newFilName];
    dos(renameCmd);    
    
    
    
    % construct t
    newT = (1:numTPts)/sampRate;

    % process amplifier dat file
    if rem(numTPts,1)~=0
        error('Meta file is imcorrect');
    end

    apChanMap = [num2cell(apChans)' arrayfun(@(x)['chan' num2str(x)],(apChans)','UniformOutput',false)];

    selChans = cell2mat(apChanMap(:,1));

    % Create time data files
    % for amplifier data
    fidT=fopen([selDir fName '_t.dat'],'w');
    fwrite(fidT,newT,'double');
    fclose(fidT);

    % for sy data
    fidT=fopen([selDir fName '.sy_t.dat'],'w');
    fwrite(fidT,newT,'double');
    fclose(fidT);

    % Create chan data file
    % for amplifier data
    chPath = [selDir fName '_ch.csv'];
    chFID = fopen(chPath, 'w');
    for j = 1:size(apChanMap,1)
        fprintf(chFID, '%u,%s\r\n', j, apChanMap{j,2});
    end
    fclose(chFID);

    % for sy data
    chPath = [selDir fName '.sy_ch.csv'];
    chFID = fopen(chPath, 'w');
    fprintf(chFID, '%u,%s\r\n', 1,'sy');
    fclose(chFID);


    % Create amplifier and sy data file
    dataMap = memmapfile(fullfile(selDir, [fName '.ap.bin']), ...
        'Format', {'int16' [numChans numTPts] 'traces'});

    chunks = 0:30000:(numTPts-1);
    if chunks(end) ~= numTPts
        chunks(end+1) = numTPts;
    end

    ampPath = [selDir fName '.dat'];
    ampFID = fopen(ampPath, 'w');
    syPath = [selDir fName '.sy.dat'];
    syFID = fopen(syPath, 'w');


    for j = 2:length(chunks)
        fwrite(ampFID, dataMap.data.traces(selChans,(chunks(j-1)+1):chunks(j)), 'int16');
        fwrite(syFID, dataMap.data.traces(syChan,(chunks(j-1)+1):chunks(j)), 'int16');
    end
    fclose(ampFID);
    fclose(syFID);
  
    
    
%% process LF file
    % get file names
    fList = dir(selDir);
    fNames = {fList.name};

    if ~any(strcmp([fName '.lf.bin'],fNames))
        error([fName '.lf.bin file not present']);
    end

    % get recording parameters from meta file.
    params = ReadNPMeta([fName '.lf.meta'], selDir);

    numChans = str2num(params.nSavedChans);
    numTPts = str2num(params.fileSizeBytes)/(2*numChans);
    sampRate = str2num(params.imSampRate);
    chanList = str2num(params.snsApLfSy);
    lfChans = 1:chanList(2);
    syChan = sum(chanList);

%     % CREATE FIL FILE HERE
%     selDirParts = strsplit(selDir,filesep);
%     catgtDir = [strjoin(selDirParts(1:(end-3)),filesep) filesep];
%     % remove _g0 part, since catgt appends it
%     catgtRun = selDirParts{end-2}(1:(end-3));
%     if artRem
%         catgtCmd = ['CatGT -dir=' catgtDir ' -run=' catgtRun ' -prb=' prb ...
%                     ' -prb_fld -g=0 -t=0 -ap -aphipass=300 -aplopass=9000 ' ...
%                     '-gfix=1,0,0.1 -gbldmx'];
%     else
%         catgtCmd = ['CatGT -dir=' catgtDir ' -run=' catgtRun ' -prb=' prb ...
%                     ' -prb_fld -g=0 -t=0 -ap -aphipass=300 -aplopass=9000 ' ...
%                     ' -gbldmx'];
%     end
%     dos(catgtCmd);
%     
%     % rename file to fil
%     % fil file will only be used by kilosort, so we will not create a _t or
%     % _ch file that makes it accessible to datmap.
%     newFList = dir(selDir);
%     filFileInd = find(cellfun(@(x)contains(x,'_tcat')&contains(x,'.bin'),{newFList.name}));
%     origFilPath = fullfile(newFList(filFileInd).folder,newFList(filFileInd).name);
%     if artRem
%         InfillCatGTGFix(origFilPath, 0.05);
%     end
%     
%     newFilName = [fName '.fil'];
%     renameCmd = ['ren ' origFilPath ' ' newFilName];
%     dos(renameCmd);    
%     
    
    
    % construct t
    newT = (1:numTPts)/sampRate;

    % process amplifier dat file
    if rem(numTPts,1)~=0
        error('Meta file is imcorrect');
    end

    lfChanMap = [num2cell(lfChans)' arrayfun(@(x)['chan' num2str(x)],(lfChans)','UniformOutput',false)];

    selChans = cell2mat(lfChanMap(:,1));

    % Create time data files
    % for amplifier data
    fidT=fopen([selDir fName '.lf_t.dat'],'w');
    fwrite(fidT,newT,'double');
    fclose(fidT);

    % for sy data
    fidT=fopen([selDir fName '.sy.lf_t.dat'],'w');
    fwrite(fidT,newT,'double');
    fclose(fidT);

    % Create chan data file
    % for amplifier data
    chPath = [selDir fName '.lf_ch.csv'];
    chFID = fopen(chPath, 'w');
    for j = 1:size(apChanMap,1)
        fprintf(chFID, '%u,%s\r\n', j, lfChanMap{j,2});
    end
    fclose(chFID);

    % for sy data
    chPath = [selDir fName '.sy.lf_ch.csv'];
    chFID = fopen(chPath, 'w');
    fprintf(chFID, '%u,%s\r\n', 1,'sy');
    fclose(chFID);


    % Create amplifier and sy data file
    dataMap = memmapfile(fullfile(selDir, [fName '.lf.bin']), ...
        'Format', {'int16' [numChans numTPts] 'traces'});

    chunks = 0:30000:(numTPts-1);
    if chunks(end) ~= numTPts
        chunks(end+1) = numTPts;
    end

    ampPath = [selDir fName '.lf.dat'];
    ampFID = fopen(ampPath, 'w');
    syPath = [selDir fName '.sy.lf.dat'];
    syFID = fopen(syPath, 'w');


    for j = 2:length(chunks)
        fwrite(ampFID, dataMap.data.traces(selChans,(chunks(j-1)+1):chunks(j)), 'int16');
        fwrite(syFID, dataMap.data.traces(syChan,(chunks(j-1)+1):chunks(j)), 'int16');
    end
    fclose(ampFID);
    fclose(syFID);
  