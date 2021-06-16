function status = ProcessRawRecording(selDirs, varargin)
    % to avoid conflicts between the currently selected folder and selDirs,
    % the inputted directories should be entered as a full paths
    status = true;
    
    if any(strcmp('References', varargin))
        refTbl = varargin{find(strcmp('References', varargin))+1};
    else
        refTbl = [];
    end
        
    if any(strcmp('SampleRate', varargin))
      sampRate = varargin{find(strcmp('SampleRate', varargin))+1};
      sampRateOverride = true;
    else
      sampRateOverride = false;
    end
        
    % format input
    if ischar(selDirs)
        selDirs = {selDirs};
    end
    numDirs = length(selDirs);
    
    for k = 1:numDirs
        currDir = selDirs{k};
        if ~strcmp(currDir(end), '/')
            currDir(end+1) = '/';
            selDirs{k} = currDir;
        end
    end
    
    % test that all directories are properly configured
    for k = 1:numDirs
        currDir = selDirs{k};
        disp(['Testing: ' currDir]);
        badEnt(k) = true;
        
        % check that directory is valid
        try 
            cd(currDir);
        catch err
            disp(['     Failed: bad directory']);
            continue;
        end
        
        % get directory contents, eliminate entries for upper level folders
        dirContents = dir();
        conNames = {dirContents.name};
        badNames = strcmp(conNames, '.') | strcmp(conNames, '..');
        dirContents(badNames) = [];
        conNames = {dirContents.name};
        dirDirs = [dirContents.isdir];
        fNames = conNames(~dirDirs);
        dirNames = conNames(dirDirs);
 
        
        % check for spike filter/extraction ndm xml
        if ~any(strcmp(fNames, 'SpikeExtract_Process.xml'))
            disp(['     Failed: no spike extraction xml']);
            continue;
        elseif ~any(strcmp(fNames, 'SpikeFilter_Process.xml'))
            disp(['     Failed: no spike filter xml']);
            continue;
        end
        
        % check for agreement between data directories and dat file names
        numSubDirs = length(dirNames);
        for p = 1:numSubDirs
            currSubDir = dirNames{p};
            subDirFiles = dir(currSubDir);
            datDirTest(p) = ~any(strcmp([currSubDir '.dat'], {subDirFiles.name}));
        end
        
        if any(datDirTest)
            disp(['     Failed: bad dat/folder name agreement']); 
            continue;
        end
        
        disp(['     Passed']);
        badEnt(k) = false;
    end
    
    % prompt user if they wish to continue with bad entries
    if any(badEnt)
        resp = input('Bad directories detected, run anyway? Y/N [Y]', 's');
        if isempty(resp)
            resp = 'Y';
        end
        if strcmp(resp, 'Y')
            selDirs(badEnt) = [];
        else
            status = false;
            return;
        end
    end
    
    % start processing
    disp('Beginning processing');
    
    

    
    for k = 1:numDirs
        currDir = selDirs{k};
        disp(['Running: ' currDir]);
        cd(currDir);
        
        % get file info
        % assumes that numElec and samp rate are consistent across channels
        xmlData = xml2struct([currDir 'SpikeFilter_Process.xml']);
        xmlData = xmlData.parameters;
        chanNum = str2num(xmlData.acquisitionSystem.nChannels.Text);
        if ~sampRateOverride
          sampRate = str2num(xmlData.acquisitionSystem.samplingRate.Text);
        end
        voltRange = str2num(xmlData.acquisitionSystem.voltageRange.Text);
        offset = str2num(xmlData.acquisitionSystem.offset.Text);
        amp = str2num(xmlData.acquisitionSystem.amplification.Text);
        nBits = str2num(xmlData.acquisitionSystem.nBits.Text);

        % get directory contents, eliminate entries for upper level folders
        dirContents = dir();
        conNames = {dirContents.name};
        badNames = strcmp(conNames, '.') | strcmp(conNames, '..');
        dirContents(badNames) = [];
        conNames = {dirContents.name};
        dirDirs = [dirContents.isdir];
        fNames = conNames(~dirDirs);
        dirNames = conNames(dirDirs);
        
        numSubDirs = length(dirNames);
        for p = 1:numSubDirs
            currSubDir = dirNames{p};
            cd(currDir);
            % run spike filter
            disp(['Running spike filter for ' currSubDir]);
            didItWork = system(['ndm_start SpikeFilter_Process.xml ' ...
                currSubDir], '-echo');
            if didItWork == 0
                disp('It worked');
            else
                disp('It failed');
            end
            
            system(['rm ' currSubDir '/' currSubDir '.xml']);
            
            
            % run noise median filter
            disp(['Running median noise filter for ' currSubDir]);
            newFilName = RemoveNoiseMedian([currDir currSubDir '/' currSubDir '.fil'], chanNum, sampRate, refTbl);
            system(['mv ' newFilName ' ' currSubDir '/' currSubDir '.fil']);
            
            % run spike extract
            disp(['Running spike extract for ' currSubDir]);
            didItWork = system(['ndm_start SpikeExtract_Process.xml ' ...
                currSubDir], '-echo');
            if didItWork == 0
                disp('It worked');
            else
                disp('It failed');
            end
            
            % run LFP filter
            disp(['Running LFP filter for ' currSubDir]);
            LFPFilter([currDir currSubDir '/' currSubDir '.dat'], chanNum, sampRate)
            
            % run KlustaKwik
            disp(['Running spike clustering for ' currSubDir]);
            chanGrps = unique(RetrievePDataColumns(CreateChannelInfoPData([currDir 'SpikeExtract_Process.xml']),...
                'GrpID', 'NoHeader', 'RetMat', 1));
            cd(currSubDir);
            for j = chanGrps'
                didItWork = system(['KlustaKwik  ' currSubDir ' ' num2str(j)], '-echo');
                if didItWork == 0
                    disp('It worked');
                else
                    disp('It failed');
                end
            end
        end
    end