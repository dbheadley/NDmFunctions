function fName = BlankDatFile(fnDat, fnDigital, datChans, digChans, blankOp)

    datProps = datinfo(fnDat);
    digProps = datinfo(fnDigital);
    
    if datProps.TimeStampCount ~= digProps.TimeStampCount
        error('Dat and digital files do not share the same number of timesteps');
    end
    
    if isempty(datChans)
        datChans = 1:datProps.ChannelCount;
    end
    
    if isempty(digChans)
        digChans = 1:digProps.ChannelCount;
    end
    
    if ~any(strcmp(blankOp,{'AND' 'OR'}))
        error('blankOp is invalid');
    end
    
    mmfDat = memmapfile(fnDat, 'Formation', {'int16' [datProps.ChannelCount ...
        datProps.TimeStampCount] 'data'}, 'Writable', true);
    mmfDig = memmapfile(fnDigital, 'Formation', {'int16' [digProps.ChannelCount ...
        digProps.TimeStampCount] 'data'});
    
    windows = unique([1:2000:datProps.TimeStampCount datProps.TimeStampCount]);
    numWindows = length(windows);
    for j = 2:numWindows
        winInds = windows(j-1):windows(j);
        digSigs = mmfDig.Data.data(digChans,winInds);
        
        switch blankOp
            case 'AND'
                blankInds = all(digSigs,1);
            case 'OR'
                blankInds = any(digSigs,1);
        end
        
        mmfDat.Data.data(datChans,blankInds) = 0;
    end
    