function [apCatFile, metaCatFile] = CatSpikeGLXApFiles(selDir, selBase, selProbe)
    % UNTESTED
    % selDir should contain all of the files you want to concatenate
    % selBase should be the first portion of the file name that all files
    % to be concatenated share.
    % selProbe is a string that specifies the probe from which the files
    % were acquired. 
    
    
    % Make sure that all the files sharing the same basename were acquired
    % with the same parameters.
    fSearchExp = [fullfile(selDir, selBase) '*.' selProbe '.ap.bin'];
    
    filesToCat = dir(fSearchExp);
    filesToCat = {filesToCat.name};
    apCatFile = [selBase '.' selProbe '.ap.bin'];
    metaCatFile = [selBase '.' selProbe '.ap.meta'];
    
    numFiles = numel(filesToCat);
    if numFiles == 1
        warning('Only one matching ap.bin file found')
        return;
    end
    
    % run concatenation
    status = CatBinFilesWin(selDir,filesToCat,apCatFile);
    if ~status
        error('Concatenation of SpikeGLX ap.bin files failed');
    end