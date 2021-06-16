function intan2datmap(selDir, fName, varargin)
  
  % get file names
  
  fList = dir(selDir);
  fNames = {fList.name};
  
  if ~any(strcmp('amplifier.dat',fNames))
      warning('Amplifier file not present');
      ampYes = false;
  else
      ampYes = true;
  end
  if any(strcmp('AMPLIFIER', varargin))
      ampChanMap = varargin{find(strcmp('AMPLIFIER',varargin))+1};
      
  else
      ampChanMap = [];
  end
  
  if ~any(strcmp('digitalin.dat',fNames))
      warning('Digital in file not present');
      digYes = false;
  else
      digYes = true;
  end
  if any(strcmp('DIGITALIN', varargin))
      
      dInChanMap = varargin{find(strcmp('DIGITALIN',varargin))+1};
      
  else
      dInChanMap = [];
  end
  
  if ~any(strcmp('auxiliary.dat',fNames))
      warning('Auxiliary file not present');
      auxYes = false;
  else
      auxYes = true;
  end
  if any(strcmp('AUXILIARY', varargin))
      auxChanMap = varargin{find(strcmp('AUXILIARY',varargin))+1};
      
  else
      auxChanMap = [];
  end
  
  if ~any(strcmp('analogin.dat',fNames))
      warning('Analog in file not present');
      anaYes = false;
  else
      anaYes = true;
  end
  if any(strcmp('ANALOGIN', varargin))
      aInChanMap = varargin{find(strcmp('ANALOGIN',varargin))+1};
      
  else
      aInChanMap = [];
  end
  mf = memmapfile([selDir 'time.dat'],'Format','int32');
  newT = (1:length(mf.Data))/30000; % assumes 30k sample rate, should use .rhd file instead
  numTPts = length(newT);
  
  % process amplifier dat file
  if ampYes
    numChan = (fList(strcmp('amplifier.dat',fNames)).bytes)/(2*numTPts);
    if rem(numChan,1)~=0
      error('Amplifier or time files are improperly specified');
    end
    
    if isempty(ampChanMap)
      ampChanMap = [num2cell(1:numChan)' arrayfun(@(x)['chan' num2str(x)],(1:numChan)','UniformOutput',false)];
    elseif numChan < max(cell2mat(ampChanMap(:,1)))
      error('Amplifier channel mapping is incorrect')
    end
    
    selChans = cell2mat(ampChanMap(:,1));
    
    % process time data
    
    fidT=fopen([selDir fName '_t.dat'],'w');
    fwrite(fidT,newT,'double');
    fclose(fidT);
    
    chPath = [selDir fName '_ch.csv'];
    chFID = fopen(chPath, 'w');
    for j = 1:size(ampChanMap,1)
      fprintf(chFID, '%u,%s\r\n', j, ampChanMap{j,2});
    end
    fclose(chFID);
    
    dataMap = memmapfile([selDir 'amplifier.dat'], 'Format', {'int16' [numChan numTPts] 'traces'});
    
    chunks = 0:30000:(numTPts-1);
    if chunks(end) ~= numTPts
      chunks(end+1) = numTPts;
    end
    
    ampPath = [selDir fName '.dat'];
    ampFID = fopen(ampPath, 'w');

    for j = 2:length(chunks)
      fwrite(ampFID, dataMap.data.traces(selChans,(chunks(j-1)+1):chunks(j)), 'int16');
    end
    fclose(ampFID);
  end
  
  % process digital in dat file
  if digYes
    dmf = memmapfile([selDir 'digitalin.dat'],'Format','uint16');
    numSamps = length(dmf.Data);
    if numSamps ~= numTPts
      error('Digital in or time files are improperly specified');
    end
    
    % process time data
    
    fidT=fopen([selDir fName '_digitalin_t.dat'],'w');
    fwrite(fidT,newT,'double');
    fclose(fidT);
    
    
    
    if isempty(dInChanMap)
      dInChanMap = [num2cell(1:16)' arrayfun(@(x)['chan' num2str(x)],(1:16)','UniformOutput',false)];
    end
    
    selChans = cell2mat(dInChanMap(:,1));
    
    chPath = [selDir fName '_digitalin_ch.csv'];
    chFID = fopen(chPath, 'w');
    for j = 1:size(dInChanMap,1)
      fprintf(chFID, '%u,%s\r\n', j, dInChanMap{j,2});
    end
    fclose(chFID);
    
    chunks = 0:30000:(numTPts-1);
    if chunks(end) ~= numTPts
      chunks(end+1) = numTPts;
    end
    
    dInPath = [selDir fName '_digitalin.dat'];
    dInFID = fopen(dInPath, 'w');

    for j = 2:length(chunks)
      temp = int16(de2bi(dmf.Data((chunks(j-1)+1):chunks(j)),16));
      fwrite(dInFID, temp(:,selChans)', 'int16');
    end
    fclose(dInFID);

  end
  
  % process auxiliary dat file
  if auxYes
    numChan = (fList(strcmp('auxiliary.dat',fNames)).bytes)/(2*numTPts);
    if rem(numChan,1)~=0
      error('Auxiliary or time files are improperly specified');
    end
    
    if isempty(auxChanMap)
      auxChanMap = [num2cell(1:numChan)' arrayfun(@(x)['chan' num2str(x)],(1:numChan)','UniformOutput',false)];
    elseif numChan < max(cell2mat(auxChanMap(:,1)))
      error('Auxiliary channel mapping is incorrect')
    end
    
    selChans = cell2mat(auxChanMap(:,1));
    
    % process time data
   
    fidT=fopen([selDir fName '_auxiliary_t.dat'],'w');
    fwrite(fidT,newT,'double');
    fclose(fidT);
    
    
    chPath = [selDir fName '_auxiliary_ch.csv'];
    chFID = fopen(chPath, 'w');
    for j = 1:size(auxChanMap,1)
      fprintf(chFID, '%u,%s\r\n', j, auxChanMap{j,2});
    end
    fclose(chFID);
    
    dataMap = memmapfile([selDir 'auxiliary.dat'], 'Format', {'uint16' [numChan numTPts] 'traces'});
    
    chunks = 0:30000:(numTPts-1);
    if chunks(end) ~= numTPts
      chunks(end+1) = numTPts;
    end
    
    auxPath = [selDir fName '_auxiliary.dat'];
    auxFID = fopen(auxPath, 'w');

    for j = 2:length(chunks)
      fwrite(auxFID, dataMap.data.traces(selChans,(chunks(j-1)+1):chunks(j)), 'uint16');
    end
    fclose(auxFID);
  end
  
% process analog in dat file
  if anaYes
    numChan = (fList(strcmp('analogin.dat',fNames)).bytes)/(2*numTPts);
    if rem(numChan,1)~=0
      error('Analog in or time files are improperly specified');
    end
    
    if isempty(aInChanMap)
      aInChanMap = [num2cell(1:numChan)' arrayfun(@(x)['chan' num2str(x)],(1:numChan)','UniformOutput',false)];
    elseif numChan < max(cell2mat(aInChanMap(:,1)))
      error('Analog in channel mapping is incorrect')
    end
    
    selChans = cell2mat(aInChanMap(:,1));
    
    % process time data
    
    fidT=fopen([selDir fName '_analogin_t.dat'],'w');
    fwrite(fidT,newT,'double');
    fclose(fidT);
    
    
    chPath = [selDir fName '_analogin_ch.csv'];
    chFID = fopen(chPath, 'w');
    for j = 1:size(aInChanMap,1)
      fprintf(chFID, '%u,%s\r\n', j, aInChanMap{j,2});
    end
    fclose(chFID);
    
    dataMap = memmapfile([selDir 'analogin.dat'], 'Format', {'uint16' [numChan numTPts] 'traces'});
    
    chunks = 0:30000:(numTPts-1);
    if chunks(end) ~= numTPts
      chunks(end+1) = numTPts;
    end
    
    aInPath = [selDir fName '_analogin.dat'];
    aInFID = fopen(aInPath, 'w');

    for j = 2:length(chunks)
      fwrite(aInFID, dataMap.data.traces(selChans,(chunks(j-1)+1):chunks(j)), 'uint16');
    end
    fclose(aInFID);
  end
  