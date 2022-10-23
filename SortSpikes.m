function rez = SortSpikes(apFilePath, varargin)
    % Runs CatGT and Kilosort3 on ap file
    % apFilePath: a string, the full path for the .ap file
    
    % OPTIONAL ARGUMENTS
    % NBLOCKS: an integer, the number of blocks to use for datashift. A
    % default value of 1 usually works.
    % SPKTHRESH: a 1x2 array, spike detection thresholds. Default should be
    % [9 9].
    % NTFACTOR: an integer (between 8-12), sets the size of data chunks
    % used for processing.
    % SKIPCATGT: if this argument is present, then the CatGT processing
    % step is skipped. Assumes it was already run in a previous iteration.
    
    
    if any(strcmp(varargin, 'NBLOCKS'))
        nBlocks = varargin{find(strcmp(varargin, 'NBLOCKS'))+1};
    else
        nBlocks = 1;
    end
    
    if nBlocks ~= 0
        doShift = true;
    else
        doShift = false;
    end
    
    if any(strcmp(varargin, 'SPKTHRESH'))
        spkThresh = varargin{find(strcmp(varargin, 'SPKTHRESH'))+1};
    else
        spkThresh = [9 9];
    end
    
    if any(strcmp(varargin, 'NTFACTOR'))
        NTFactor = varargin{find(strcmp(varargin, 'NTFACTOR'))+1};
    else
        NTFactor = 10;
    end

    if any(strcmp(varargin, 'SKIPCATGT'))
        runCatGT = false;
    else
        runCatGT = true;
    end

%% Run CatGT on AP file to remove common noise
    [dirPath, fileName, ext] = fileparts(apFilePath);
    fileName = [fileName ext];
    
    prbNum = regexp(fileName, 'imec([0-9])','TOKENS');
    prbNum = prbNum{1}{1};
    
    pathParts = strsplit(dirPath, filesep);
    dataDir = [pathParts{1:(end-2)}];
    
    runName = regexp(fileName, '(^.+)_g0', 'TOKENS');
    runName = runName{1}{1};
    
    if runCatGT
        catgtCmd = ['CatGT -dir=' dataDir ' -run=' runName ' -prb=' prbNum ...
                        ' -prb_fld -g=0 -t=0 -ap -apfilter=butter,2,300,9000 ' ...
                        ' -gblcar']; 
        dos(catgtCmd);
    end
    
    binPath = strrep(apFilePath, '_t0', '_tcat'); 
    metaPath = [binPath(1:(end-3)) 'meta'];
    
    currDir = pwd;
    cd(dirPath)
    SGLXMetaToCoordsNoPrompt(metaPath)
    cd(currDir)
    coordPath = [binPath(1:(end-4)) '_kilosortChanMap.mat'];
    
    [tcatPath, tcatFName, tcatExt] = fileparts(binPath); 
    metaParams = ReadNPMeta([tcatFName tcatExt], tcatPath);
%     coordInfo = load(coordPath);
    
%% Configure options for kilosort3

    ops.chanMap  = coordPath; % make this file using SGLXMetaToCoordsNoPrompt.m
    ops.fbinary             = binPath;  		
    ops.fproc               = fullfile(dirPath, 'temp_wh.dat'); % residual from RAM of preprocessed data		
    ops.root                = binPath; % 'openEphys' only: where raw files are	
    ops.NchanTOT = str2num(metaParams.nSavedChans);

    % sample rate
    ops.fs = str2num(metaParams.imSampRate);  

    % frequency for high pass filtering (150)
    ops.fshigh = 300;   

    % threshold on projections (like in Kilosort1, can be different for last pass like [10 4])
    ops.Th = spkThresh;  

    % how important is the amplitude penalty (like in Kilosort1, 0 means not used, 10 is average, 50 is a lot) 
    ops.lam = 20;  

    % splitting a cluster at the end requires at least this much isolation for each sub-cluster (max = 1)
    ops.AUCsplit = 0.8; 

    % minimum spike rate (Hz), if a cluster falls below this for too long it gets removed
    ops.minFR = 1/100; 

    % spatial constant in um for computing residual variance of spike
    ops.sigmaMask = 30; 

    % threshold crossings for pre-clustering (in PCA projection space)
    ops.ThPre = 8; 

    % spatial scale for datashift kernel
    ops.sig = 20;

    % type of data shifting (0 = none, 1 = rigid, 2 = nonrigid)
    ops.nblocks = nBlocks;


    %% danger, changing these settings can lead to fatal errors
    % options for determining PCs
    ops.spkTh           = -6;      % spike threshold in standard deviations (-6)
    ops.reorder         = 1;       % whether to reorder batches for drift correction. 
    ops.nskip           = 25;  % how many batches to skip for determining spike PCs

    ops.GPU                 = 1; % has to be 1, no CPU version yet, sorry
    % ops.Nfilt               = 1024; % max number of clusters
    ops.nfilt_factor        = 4; % max number of clusters per good channel (even temporary ones)
    ops.ntbuff              = 64;    % samples of symmetrical buffer for whitening and spike detection
    ops.NT                  = 64*(2^NTFactor)+ ops.ntbuff; % must be multiple of 32 + ntbuff. This is the batch size (try decreasing if out of memory). 
    ops.whiteningRange      = 32; % number of channels to use for whitening each channel
    ops.nSkipCov            = 25; % compute whitening matrix from every N-th batch
    ops.scaleproc           = 200;   % int16 scaling of whitened data
    ops.nPCs                = 3; % how many PCs to project the spikes into
    ops.useRAM              = 0; % not yet available

    % time range to sort
    ops.trange = [0 Inf]; 

%% Run Kilosort

    % set random seed to minimize differences between runs (on different
    % computers or matlab run histories)
    rng(0)
    
    % preprocess data to create temp_wh.dat
    rez = preprocessDataSub(ops);

    % Perform shift correction
    rez = datashift2(rez,doShift);

    % Identify and sort spikes
    [rez, st3, tF]     = extract_spikes(rez);
    rez                = template_learning(rez, tF, st3);
    [rez, st3, tF]     = trackAndSort(rez);
    rez                = final_clustering(rez, tF, st3);
    rez                = find_merges(rez, 1);

    
%% Save the results of Kilosort
    rezFiles = fullfile(dirPath, 'rez.mat');
    save(rezFiles, 'rez');
