function status = CatBinFilesWin(binDir,catBinFNames,outBinFName)
    %UNTESTED
    
    % Ensure correct formating, and presence, of binary files
    if ~iscell(catBinFNames)
        catBinFNames = {catBinFNames};
    end
    
    numBinFiles = numel(catBinFNames);
    if numBinFiles == 1
        warning('Only 1 file specified for concatenation, skipping step');
        status = true;
        return;
    end
    
    fList = dir(binDir);
    fList = {fList.name};
    for j = 1:numBinFiles
        currFile = catBinFNames{j};
        if any(strcmp(currFile, fList))
            if ~strcmp(currFile(1), '"')
                catBinFNames{j} = ['"' currFile];
            end
            if ~strcmp(catBinFNames{j},'"')
                catBinFNames{j} = [catBinFNames{j} '"'];
            end
        else
            error([currFile ' is not present, not concatenating files.']);
        end
    end
    
    if ~strcmp(outBinFName(1), '"')
        outBinFName = ['"' outBinFName];
    end
    if ~strcmp(outBinFName(end),'"')
        outBinFName = [outBinFName '"'];
    end
            
    origDir = cd(binDir);
        
    if strcmp(computer, 'PCWIN64')
        status = system(['copy /b ' strjoin(catBinFNames, '+') ' ' outBinFName], '-echo');
    else
        warning('CatBinFilesWin only works on 64bit Windows system');
        status = false;
    end
    
    cd(origDir);
    
    