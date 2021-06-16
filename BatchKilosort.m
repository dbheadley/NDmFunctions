function rezFiles = BatchKilosort(rootDir, datFName, numChans, fs, chanData)
    % rootDir - a string, the directory containing the data to be sorted
    % datFName - a string, the name of the dat file
    % numChans - an integer, the number of channels recorded from
    % fs - a scalar, the sample rate in Hz
    % chanData - an Nx1 structure array, fields are:
    %               SiteName: a string, the name of the recording site
    %               SiteChans: an Mx1 vector, start index of 1, the 
    %               channels that go together for for a recording site
    %               XCoords: an Mx1 vector, the positions of the channels
    %               along the 'x-axis'
    %               YCoords: an Mx1 vector, the positions of the channels
    %               along the 'y-axis'
    %               KCoords: an Mx1 vector, the groups that recording sites
    %               belong to
    %               BatchSize: an integer power of 2 (e.g. 1024, 4096), the
    %               size of the batches used in kilosort. Adjust if running
    %               into memory problems.
    %               ChunkNum: an integer, specifies the number of chunks to
    %               divide the binary file in to. Each chunk is processed
    %               separately by kilosort, then recombined. Set this
    %               greater than 1 if you are running out of memory during
    %               the drift correction step.
    
    for j = 1:length(chanData)
        numSites = length(chanData(j).SiteChans(:));
        chanMap = [chanData(j).SiteChans setdiff(1:numChans, chanData(j).SiteChans)];
        chanMap0ind = chanMap - 1;
        connected = [true(numSites, 1); false(numChans-numSites,1)];
        xcoords = [chanData(j).XCoords nan(1,numChans-numSites)];
        ycoords = [chanData(j).YCoords nan(1,numChans-numSites)];
        kcoords = [chanData(j).KCoords nan(1,numChans-numSites)];
        batchSize = chanData(j).BatchSize;
        currDir = fullfile(rootDir, 'Spikes', chanData(j).SiteName);
        mkdir(currDir);
        save(fullfile(currDir, 'ChanTemp.mat'), 'chanMap', 'chanMap0ind', 'connected', 'xcoords', 'ycoords', 'kcoords', 'fs')
        
        
        ops = ConfigureOpsKSDS(currDir, datFName, 'ChanTemp.mat', batchSize);
        
        % preprocess data to create temp_wh.dat
        rez = preprocessDataSub(ops);
        
        % % NEW STEP TO DO DATA REGISTRATION
        rez = datashift2(rez);
        %
        % % ORDER OF BATCHES IS NOW RANDOM, controlled by random number generator
        iseed = 1;
        
        % % TO SKIP DATA SHIFTING USE THESE FUNCTIONS INSTEAD (UNTESTED)
        % rng(iseed);
        % Nbatches = rez.ops.Nbatch;
        % rez.iorig = randperm(Nbatches);
        % rez = learnTemplates(rez, iorder);
        % rez.ops.fig = 0;
        % rez = runTemplates(rez);
        
        % % main tracking and template matching algorithm
        rez = learnAndSolve8b(rez, iseed);
        
        % final merges
        rez = find_merges(rez, 1);
        
        % final splits by SVD
        rez = splitAllClusters(rez, 1);
        
        % decide on cutoff
        rez = set_cutoff(rez);
        rez.good2 = get_good_units(rez);
        
        % final time sorting of spikes, for apps that use st3 directly
        [~, isort]   = sortrows(rez.st3);
        rez.st3      = rez.st3(isort, :);
        
        rezFiles{j} = fullfile(currDir, 'rez.mat');
        save(rezFiles{j}, 'rez');
        
        rezToPhy(rez, currDir);
    end