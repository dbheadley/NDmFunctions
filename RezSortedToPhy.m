function RezSortedToPhy(rsFPath, phyFPath)
    % Loads a rez file that has been sorted and returns a collection of
    % .py and .npy files that mimic the files used by Phy and can be read 
    % in to python for subsequent analysis.
    % rsFPath is the full file path for the rezSorted file.
    % phyFPath is the directory to save the phy file to.
    
    % much of this code is derived from rezToPhy.m
    
    load(rsFPath,'-mat','rez');
    
    mkdir(phyFPath)
    
    % remove noise spikes
    goodClusters = find(~(rez.SortaSort.ClusterType=='Noise'));
    spks = rez.SortaSort.GroupedSpikes(goodClusters);
    types = rez.SortaSort.ClusterType(goodClusters);
    ids = rez.SortaSort.ClusterID(goodClusters);
    peakChans = rez.SortaSort.DistData.PeakChans(goodClusters)-1;
    
    
    % save files
    
    % params.py
    fid = fopen(fullfile(phyFPath,'params.py'), 'w');
    [~, fname, ext] = fileparts(rez.ops.fbinary);
    fprintf(fid,['dat_path = ''',fname ext '''\n']);
    fprintf(fid,'n_channels_dat = %i\n',rez.ops.NchanTOT);
    fprintf(fid,'dtype = ''int16''\n');
    fprintf(fid,'offset = 0\n');
    if mod(rez.ops.fs,1)
        fprintf(fid,'sample_rate = %i\n',rez.ops.fs);
    else
        fprintf(fid,'sample_rate = %i.\n',rez.ops.fs);
    end
    fprintf(fid,'hp_filtered = False\n');
    fprintf(fid,'n_samples_dat = %i', rez.ops.sampsToRead)
    fclose(fid);
    
    % channel_map.npy
    chanMap0ind = int32(rez.ops.chanMap-1)';
    writeNPY(chanMap0ind, fullfile(phyFPath, 'channel_map.npy'));
    
    % cluster_info.tsv
    fid = fopen(fullfile(phyFPath, 'cluster_info.tsv'), 'w');
    fprintf(fid,'cluster_id\tgroup\tsh\n');
    for j = 1:length(goodClusters)
        fprintf(fid,'%u\tgood\t%u\n',j-1,j-1);
    end
    fclose(fid);
    
    % cluster_props.tsv
    fid = fopen(fullfile(phyFPath, 'cluster_props.tsv'), 'w');
    fprintf(fid,'cluster_id\ttype\tpeak_chan\n');
    for j = 1:length(goodClusters)
        fprintf(fid,'%u\t%s\t%u\n',j-1,types(j),peakChans(j));
    end
    fclose(fid);
    
    % spike times
    writeNPY(uint64(vertcat(spks{:})), fullfile(phyFPath, 'spike_times.npy'))
    
    % spike clusters
    spikeClusters = repelem(uint32((1:length(ids))-1),cellfun(@numel,spks))';
    writeNPY(spikeClusters, fullfile(phyFPath, 'spike_clusters.npy'));
    
    % channel positions
    xcoords = rez.xcoords(:);
    ycoords = rez.ycoords(:);
    writeNPY([xcoords ycoords], fullfile(phyFPath, 'channel_positions.npy'));
    
    % spike waveforms
    if isfield(rez.SortaSort, 'SpkWaves')
        waves = rez.SortaSort.SpkWaves(goodClusters);
        for j = 1:length(waves)
            % nan pad if needed
            waves{j} = cat(3,waves{j},nan(size(waves{j},1),size(waves{j},2),100-size(waves{j},3)));
            % rearrange for concatenation
            waves{j} = permute(waves{j},[4, 1, 2, 3]);
        end
        
        sampWaves = cat(1, waves{:});
        meanWaves = median(sampWaves,4);
        writeNPY(int16(sampWaves), fullfile(phyFPath, 'sample_waves.npy'));
    elseif isfield(rez.SortaSort, 'dWU')
        wMatInv = (rez.Wrot/rez.ops.scaleproc)^-1;
        dWU = permute(rez.SortaSort.dWU,[3,1,2]);
        meanWaves = zeros(size(dWU));
        for t = 1:size(meanWaves,1)
            meanWaves(t,:,:) = squeeze(dWU(t,:,:))*wMatInv;
        end
        meanWaves = meanWaves(goodClusters,:,:);
    end
    writeNPY(int16(meanWaves), fullfile(phyFPath, 'templates.npy'));
