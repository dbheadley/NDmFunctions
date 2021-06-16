function t = ImportTFiles(selDir, rootName)
%% ImportTFiles
% Loads data from _t files

%% Syntax
%# t = ImportTFile(rootName)

%% Description
% Extracts time stamps from each of the _t files to obtain time stamps.

%% INPUT
% * selDir - a string, the directory containg the time stamp files
% * rootname - a string, the root file name

%% OUTPUT
% * t - a structure containing the time stamps for each _t file, with the
% field name being the file type

%% Example

%% Executable code
t = struct();

% format inputs
if ~strcmp(selDir(end), '/')
    selDir = [selDir '/'];
end

fList = dir(selDir);
fNames = {fList.name};

% find _t files
tNames = fNames(cellfun(@(x)~isempty(strfind(x, '_t')), fNames));
if isempty(tNames)
    return;
end

% find file types of t files
fTypes = cellfun(@(x)regexp(x, '\.(\w+)$', 'tokens'), tNames, 'UniformOutput', false);
numFTypes = numel(fTypes);

for j = 1:numFTypes
    currFT = [selDir tNames{j}];
    currFID = fopen(currFT, 'r');
    fseek(currFID, 0, -1);
    t.(fTypes{j}{1}{1}) = fread(currFID, inf, 'double');
    fclose(currFID);
end
