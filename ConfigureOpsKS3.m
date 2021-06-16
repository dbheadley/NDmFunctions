function ops = ConfigureOpsKS3(fPath, datName, chanMapName, batchSize, numChans)

ops.chanMap  = fullfile(fPath, chanMapName); % make this file using createChannelMapFile.m
ops.fbinary             = datName; % will be created for 'openEphys'		
ops.fproc               = fullfile(fPath, 'temp_wh.dat'); % residual from RAM of preprocessed data		
ops.root                = fPath; % 'openEphys' only: where raw files are	
ops.NchanTOT = numChans;

% sample rate
ops.fs = 30000;  

% frequency for high pass filtering (150)
ops.fshigh = 300;   

% threshold on projections (like in Kilosort1, can be different for last pass like [10 4])
ops.Th = [9 9];  

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
ops.nblocks = 5;


%% danger, changing these settings can lead to fatal errors
% options for determining PCs
ops.spkTh           = -6;      % spike threshold in standard deviations (-6)
ops.reorder         = 1;       % whether to reorder batches for drift correction. 
ops.nskip           = 25;  % how many batches to skip for determining spike PCs

ops.GPU                 = 1; % has to be 1, no CPU version yet, sorry
% ops.Nfilt               = 1024; % max number of clusters
ops.nfilt_factor        = 4; % max number of clusters per good channel (even temporary ones)
ops.ntbuff              = 64;    % samples of symmetrical buffer for whitening and spike detection
ops.NT                  = 64*batchSize+ ops.ntbuff; % must be multiple of 32 + ntbuff. This is the batch size (try decreasing if out of memory). 
ops.whiteningRange      = 32; % number of channels to use for whitening each channel
ops.nSkipCov            = 25; % compute whitening matrix from every N-th batch
ops.scaleproc           = 200;   % int16 scaling of whitened data
ops.nPCs                = 3; % how many PCs to project the spikes into
ops.useRAM              = 0; % not yet available

% time range to sort
ops.trange = [0 Inf]; 