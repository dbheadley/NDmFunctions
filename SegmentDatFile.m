function fNames = SegmentDatFile(fPathIn, fPathOut, varargin)
%% SegmentDatFile
% Extracts and resaves a segment of a dat file

%% Syntax
%# fNames = SegmentDatFile(fPath, tWindow, selChan, newFName)

%% Description
% Retrieves a particular time window and subset of channels from the dat
% file specified by fPathIn, and then saves that as a new dat file called
% fPathOut with corresponding chan map and time stamp files. Arguments can
% be added to tell 'ReadData' what to do.

%% INPUT
% * fPathIn - a string, the name of the file to be processed file
% * fPathOut - a string, the name of the file to be returned file

%% OPTIONAL

%% OUTPUT
% * fNames - a structure with fields:
%               * dat, the name of the dat file, newFName
%               * t, the name of the time stamp file
%               * ch, the name of the channel map file

%% Example

%get data
data = ReadData(fPathIn, varargin{:});

%write data out
dotInds = strfind(fPathOut, '.');

fPathOutT = [fPathOut(1:(dotInds(end)-1)) '_t' fPathOut(dotInds(end):end)];
fPathOutCh = [fPathOut(1:(dotInds(end)-1)) '_ch' fPathOut(dotInds(end):end)];
outDatFID = fopen(fPathOut,'a');
outTFID = fopen(fPathOutT, 'a');

fwrite(outDatFID,cell2mat(data.traces),data.settings.precision);

fseek(outTFID, 0, -1);
tVals = cell2mat(data.tPts');
fwrite(outTFID, tVals, 'double');
fclose(outTFID);

chMap = [num2cell(data.chans{1}) data.chans{2}];
cell2csv(fPathOutCh, chMap, ',');

fNames.dat = fPathOut;
fNames.t = fPathOutT;
fNames.ch = fPathOutCh;


