function bcMastFName = CreateBCMasterFile(rootBCFN, recBCFN, vidBCDir)
    % rootBCFN is a file name that should be a barcode sequence file from a
    % recording that will supply the reference times for all other recordings
    % recBCFN is a file name that contains a barcode sequence file from
    % another recording system (NOT IMPLEMENTED YET)
    % vidBCDir is a cell array containing directories for video files
    % barcodes
    
    matchGain = 3; % match score increase for Smith-Waterman sequence alignment
    mismatchPenalty = -1; % mismatch score penalty for Smith-Waterman
    maxChkSize = 1000; % chunk sizes to process for fast alignment
    fastAlignLen = 30; % minimum length of perfect match run for fast alignment
    
    matchOpts = [matchGain mismatchPenalty maxChkSize fastAlignLen];
    
    
    
    
    
    % put in check to ensure that root file ends in _BCSeq.csv
    
    
    
    
   
    % load root barcode sequence file that other files will be aligned to
    waitFig = uifigure;
    pD = uiprogressdlg(waitFig,'Title','Creating master alignment file',...
                       'Message', 'Opening root barcode file');
    rootBC = readcell(rootBCFN);
    rootBCSeq = cell2mat(rootBC(:,1));
    rootBCLen = length(rootBCSeq);
    
    % initialize master alignment
    mastBC = rootBC;
    mastBCHead = {'Root_Barcode' 'Root_Ind' 'Root_Time'};
        
    % align recording data
    pD.Message = 'Aligning other binary files with root';
    
    % align video data
    startCol = size(mastBC,2);
    for j = 1:length(vidBCDir)
        
        vidBCFN = arrayfun(@(x)fullfile(x.folder,x.name),...
                           dir(fullfile(vidBCDir{j},'*_BCSeq.csv')), ...
                           'uniformoutput',false);
        vidDirName = strsplit(vidBCFN{1},{'\' '/'});
        vidDirName = vidDirName{end-1};
        pD.Message = ['Aligning ' vidDirName ' videos with root'];
        numVids = length(vidBCFN);
        mastBCHead = [mastBCHead {[vidDirName '_Barcode'] [vidDirName '_Epoch'] ...
                      [vidDirName '_Frame'] [vidDirName '_VideoName']}];
        for k = 1:numVids
            pD.Value = k/numVids;
            currVidBC = readcell(vidBCFN{k});
            currVidBCSeq = cell2mat(currVidBC(:,1));
            currVidBCLen = length(currVidBCSeq);
            if (currVidBCLen < 30)
                continue;
            end
        
            % align video to root
            alignTbl = AlignSeqs(currVidBCSeq,rootBCSeq, matchOpts);
            
            mastBC(alignTbl(:,2),startCol+((j-1)*4)+(1:4))=currVidBC(alignTbl(:,1),:);
        end
    end
    
    % output master barcode alignment
    pD.Message = 'Saving master alignment file';
    bcMastFName = [rootBCFN(1:(end-9)) 'MasterAlign.csv'];
    writecell([mastBCHead; mastBC], bcMastFName);
    
end

%  use Smith-Waterman algorithm to find best match
function alignTbl = AlignSeqs(seq1,seq2,matchOpts)
    matchGain = matchOpts(1);
    mismatchPenalty = matchOpts(2);
    maxChkSize = matchOpts(3);
    fastAlignLen = matchOpts(4);
    
    seq1Len = length(seq1);
    seq2Len = length(seq2);
    
    
    % Perform fast alignment to identify promising regions
    seq1ChkSize = min([maxChkSize seq1Len]);
    seq2ChkSize = min([maxChkSize seq2Len]);
    
    seq1Chks = unique([1:seq1ChkSize:seq1Len seq1Len]);
    seq2Chks = unique([1:seq2ChkSize:seq2Len seq2Len]);

    fastMatchMat = sparse(seq1Len,seq2Len);
    for j = 2:length(seq1Chks)
        seq1Inds = seq1Chks(j-1):seq1Chks(j);
        for k = 2:length(seq2Chks)
            seq2Inds = seq2Chks(k-1):seq2Chks(k);
            % finds perfect matchs
            currFMatch = seq1(seq1Inds) == (seq2(seq2Inds)');
                     
            % keep only match runs longer than fastAlignLen
            fastMatchMat(seq1Inds,seq2Inds) = sparse(conv2(currFMatch,eye(fastAlignLen),'same')==fastAlignLen);
        end
    end
    
    % identify breaks in the match that need to be repaired with
    % Smith-Waterman
    [rowInds, colInds] = find(fastMatchMat);
    edgeInds = (rowInds==1)|(rowInds==seq1Len)|(colInds==1)|(colInds==seq2Len);
    rowInds(edgeInds) = [];
    colInds(edgeInds) = [];
    startCoords = [];
    endCoords = [];
    for j = 1:length(rowInds)
        if ~(fastMatchMat(rowInds(j)-1,colInds(j)-1)) % start of run, upper diagonal
            startCoords = [startCoords; [rowInds(j) colInds(j)]];
        end
        if ~(fastMatchMat(rowInds(j)+1,colInds(j)+1)) % end of run, lower diagonal
            endCoords = [endCoords; [rowInds(j) colInds(j)]];
        end
    end
    
    % Apply Smith-Waterman algorithm to resolve breaks
    for j = 1:size(startCoords,1)
        % sequences at starts are mirror flipped to track
        seq1SubStart = max([startCoords(j,1)-((maxChkSize-fastAlignLen)-1) 1]);
        seq1SubEnd = min([startCoords(j,1)+(fastAlignLen) seq1Len]);
        seq1SubInds = seq1SubEnd:-1:seq1SubStart;
        
        seq2SubStart = max([startCoords(j,2)-((maxChkSize-fastAlignLen)-1) 1]);
        seq2SubEnd = min([startCoords(j,2)+(fastAlignLen) seq2Len]);
        seq2SubInds = seq2SubEnd:-1:seq2SubStart;
        
        startSubSeq1 = seq1(seq1SubInds);
        startSubSeq2 = seq2(seq2SubInds);
        
        startSubAlign = SmithWatermanAlign(startSubSeq1,startSubSeq2, ...
                                           matchGain, mismatchPenalty);
        fastMatchMat(seq1SubInds,seq2SubInds) = fastMatchMat(seq1SubInds,seq2SubInds)|startSubAlign;                              
    end
    
    for j = 1:size(endCoords,1)
        % sequences at starts are mirror flipped to track
        seq1SubStart = max([endCoords(j,1)-fastAlignLen 1]);
        seq1SubEnd = min([endCoords(j,1)+((maxChkSize-fastAlignLen)-1) seq1Len]);
        seq1SubInds = seq1SubStart:seq1SubEnd;
        
        seq2SubStart = max([endCoords(j,2)-fastAlignLen 1]);
        seq2SubEnd = min([endCoords(j,2)+((maxChkSize-fastAlignLen)-1) seq2Len]);
        seq2SubInds = seq2SubStart:seq2SubEnd;
        
        startSubSeq1 = seq1(seq1SubInds);
        startSubSeq2 = seq2(seq2SubInds);
        
        startSubAlign = SmithWatermanAlign(startSubSeq1,startSubSeq2, ...
                                           matchGain, mismatchPenalty);
        fastMatchMat(seq1SubInds,seq2SubInds) = fastMatchMat(seq1SubInds,seq2SubInds)|startSubAlign;                              
    end
    
    % generate alignment table
    % determine if duplicate matches are present, and for safety void if so
    if any(sum(fastMatchMat>0,2)>1)
        alignTbl = double.empty(0,2);
    else
        [alignTbl(:,1), alignTbl(:,2)] = find(fastMatchMat);
    end    
end


function alignMat = SmithWatermanAlign(seq1, seq2, matchGain, mismatchPenalty)
    % matchGain is score increase for matches
    % mismatchPenalty is score penalty mismatches 

    seq1Len = length(seq1);
    seq2Len = length(seq2);
    
    % build score matrix
    scoreMat = zeros(seq1Len+1,seq2Len+1);
    for a = 2:(seq1Len+1)
        for b = 2:(seq2Len+1)
            topLeft = scoreMat(a-1,b-1)+(matchGain*(seq1(a-1)==seq2(b-1)));
            top = scoreMat(a-1,b)+mismatchPenalty;
            left = scoreMat(a,b-1)+mismatchPenalty;
            scoreMat(a,b) = max([topLeft top left 0]);
        end
    end
    
    % traceback maximum sequence
    alignMat = sparse(seq1Len,seq2Len);
    [maxVal, startInd] = max(scoreMat(:));
    if maxVal == 0
        return;
    else
        [alignTbl(1,1), alignTbl(1,2)] = ind2sub(size(scoreMat),startInd);
        alignMat(alignTbl(end,1)-1,alignTbl(end,2)-1) = 1;
    end
    
    moveMat = [-1 0; -1 -1; 0 -1;];
    while all(alignTbl(end,:)>1)
        [maxVal, maxPos] = max([scoreMat(alignTbl(end,1)-1,alignTbl(end,2)) ...
                           scoreMat(alignTbl(end,1)-1,alignTbl(end,2)-1) ...
                           scoreMat(alignTbl(end,1),alignTbl(end,2)-1)]);
        if (maxVal == 0)
            break;
        end
        alignTbl(end+1,:) = alignTbl(end,:) + moveMat(maxPos,:);
        if (maxPos == 2)
            alignMat(alignTbl(end,1)-1,alignTbl(end,2)-1) = 1;
        end
    end
    
end
