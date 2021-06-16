function bcSeqFName = BarcodeFromBinary(binFileName, varargin)
    waitFig = uifigure;
    pD = uiprogressdlg(waitFig,'Title','Processing barcodes from binary file',...
                       'Message', 'Opening binary file');
                   
    if any(strcmp(varargin, 'SELCHAN'))
        selChan = varargin{find(strcmp(varargin,'SELCHAN'))+1};
        syData = readdat(binFileName, 'selchans', selChan);
    else
        syData = readdat(binFileName);
    end
    
    
    syTrace = syData.traces{1};
    syTimes = syData.tPts{1};
    
    % ensure trace is binary
    syTrace = syTrace > 0;
    
    % get bit length
    onsets = find(diff(syTrace)>0)+1;
    offsets = find(diff(syTrace)<0)+1;
    bitLen = mode(diff(sort([onsets offsets])));
    halfLen = round(bitLen/2);
    
    % trim incomplete bits
    if (offsets(1)<onsets(1))
        offsets(1) = [];
    end
    
    if (onsets(end)>offsets(end))
        onsets(end) = [];
    end
    
    
    % create sequence of discrete bits
    bitCount = 0;
    bitSeq = false(ceil(offsets(end)/bitLen),1);
    indSeq = zeros(ceil(offsets(end)/bitLen),1);
    pD.Message = 'Extracting bit sequence from raw recording';
    for j = 1:(length(onsets)-1)
        pD.Value = j/(length(onsets)-1);
        highNum = round((offsets(j)-onsets(j))/bitLen);
        bitSeq(bitCount+(1:highNum)) = true;
        indSeq(bitCount+(1:highNum)) = (onsets(j)+halfLen)+((0:(highNum-1))*bitLen);
        bitCount = bitCount+highNum;
        
        lowNum = round((onsets(j+1)-offsets(j))/bitLen);
        bitSeq(bitCount+(1:lowNum)) = false;
        indSeq(bitCount+(1:lowNum)) = (offsets(j)+halfLen)+((0:(lowNum-1))*bitLen);
        bitCount = bitCount+lowNum;
    end
    
    
    % identify barcodes
    bcSeq = [];
    bcChnkLen = 99; % odd number for how many barcodes to look foward when confirming offset
    j = 1;
    offset = 0;
    pD.Message = 'Collecting barcodes';
    while j < (length(bitSeq)-(5*(bcChnkLen+1)))
        % set offset by identifying the 'constant' pulse which is high at
        % the start of each cycle and the clock pulse that oscillates with
        % each cycle
        pD.Value = j/(length(bitSeq)-(5*bcChnkLen));
        if ~all(bitSeq(j+offset+(5*(0:bcChnkLen)))) || ...
            ~all(bitSeq(1+j+offset+(0:10:(5*bcChnkLen))) ~= ...
                 bitSeq(1+j+offset+(5:10:(5*bcChnkLen))))
            offset = offset + 1;
            if (offset > 4)
                pB.Message = ['Lost synchronization pulse at index ' num2str(indSeq(j))];
                offset = 0;
                j = j + 1;
            end
            continue;
        end
        
        % extract chunks when valid offset is found, compute barcode value
        currChunk = reshape(bitSeq(j+offset+(0:((5*bcChnkLen)-1))),5,bcChnkLen);
        indChunk = indSeq(j+offset+(0:5:((5*bcChnkLen)-1)));    
        bcSeq = [bcSeq; [indChunk ([1 2 4 8 16]*currChunk)']];
        j = j+offset+(5*bcChnkLen)-3;
    end
    
    % Diplay percentage of data that could be decoded
    numBCs = size(bcSeq,1);
    disp([num2str(numBCs/(length(bitSeq)/5)*100,3) '% of potential barcodes were detected']);
    bcSeq = [bcSeq(:,[2 1]) syTimes(bcSeq(:,1))'];
    
    % Export csv with barcode info
    [fPath, fRoot] = fileparts(binFileName);
    bcSeqFName = fullfile(fPath, [fRoot '_BCSeq.csv']);
    writematrix(bcSeq,bcSeqFName)
    
    close(pD);