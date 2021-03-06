function rezFiles = BatchKilosort3(rootDir, datFName, chanData)
    % rootDir - a string, the directory containing the data to be sorted
    % datFName - a string, the name of the dat file
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
    %               OtherOps: an optional structure with each fieldname corresponding
    %               to one of the configuration arguments in ops and its
    %               value the desired setting for that configuration.
    
    for j = 1:length(chanData)
        numChans = chanData(j).TotalChans;
        numSites = length(chanData(j).SiteChans(:));
        chanMap = [chanData(j).SiteChans; setdiff(1:numChans, chanData(j).SiteChans)];
        chanMap0ind = chanMap - 1;
        connected = [true(numSites, 1); false(numChans-numSites,1)];
        xcoords = [chanData(j).XCoords; nan(1,numChans-numSites)];
        ycoords = [chanData(j).YCoords; nan(1,numChans-numSites)];
        kcoords = [chanData(j).KCoords; nan(1,numChans-numSites)];
        fs = chanData(j).FS;
        batchSize = chanData(j).BatchSize;
        datashiftOpt = chanData(j).DataShift;
        
        % include access to all other op configs here
        otherOps = {};
        if isfield(chanData(j),'OtherOps')
            if ~isempty(chanData(j).OtherOps)
                opNames = fieldnames(chanData(j).OtherOps);
                for k = 1:length(opNames)
                    otherOps{end+1} = opNames{k};
                    otherOps{end+1} = chanData(j).OtherOps.(opNames{k});
                end
            end
        end
        currDir = fullfile(rootDir, 'Spikes', chanData(j).SiteName);
        mkdir(currDir);
        save(fullfile(currDir, 'ChanTemp.mat'), 'chanMap', 'chanMap0ind', 'connected', 'xcoords', 'ycoords', 'kcoords', 'fs')
        
        
        ops = ConfigureOpsKS3(currDir, datFName, 'ChanTemp.mat', batchSize, numChans,datashiftOpt, otherOps{:});
        
        % preprocess data to create temp_wh.dat
        rez = preprocessDataSub(ops);
        
        % % NEW STEP TO DO DATA REGISTRATION
        rez = datashift2(rez,true);
        
        [rez, st3, tF]     = extract_spikes(rez);

        rez                = template_learning(rez, tF, st3);

        [rez, st3, tF]     = trackAndSort(rez);

        rez                = final_clustering(rez, tF, st3);

        rez                = find_merges(rez, 1);
        
        rezFiles{j} = fullfile(currDir, 'rez.mat');
        save(rezFiles{j}, 'rez');
        
        rezToPhy(rez, currDir);
    end