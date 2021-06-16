function spkStruct = ImportSortedRez(rezFilePath)
    load(rezFilePath, '-mat');
    for j = 1:numel(rez.SortaSort.ClusterID)
        spkStruct(j).Name = ['Unit_' rez.SortaSort.ClusterID{j}];
        spkStruct(j).PeakElec = rez.ops.chanMap(rez.SortaSort.DistData.PeakInds(j));
        spkStruct(j).Type = char(rez.SortaSort.ClusterType(j));
        spkStruct(j).SpikeInds = rez.SortaSort.GroupedSpikes{j};
    end
    