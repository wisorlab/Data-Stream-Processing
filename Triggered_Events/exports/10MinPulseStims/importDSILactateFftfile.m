function importDSILactateFftfile(fileToRead1)
%IMPORTFILE(FILETOREAD1)
%  Imports data from the specified txt file
%  FILETOREAD1:  file to read
%outputs data to two arrays.  Textdata is a cell array that contains all
%data recognized as non-numeric.  data is an array of type double (numeric).
DELIMITER = '\t';
HEADERLINES = 2;

% Import the file into an array called newData1 using the function
% importdata.  Importdata requires the flename, the delimiter (here a tab)
% and number of lines to skip before starting data input ("HEADERLINES").

newData1 = importdata(fileToRead1, DELIMITER, HEADERLINES);

%embedded within newData1 are the cell array textdata and the double array data. 

vars = fieldnames(newData1);  %Collate the fieldnames of variables from input file into a cell array called vars.

for i = 1:length(vars)  % for each variable in the input file...
    assignin('base', vars{i}, newData1.(vars{i})); % ...create new variables in the 'base' workspace 
    %(that is the universal Matlab workspace that one sees on one's desktop, as opposed to the workspace assigned to the function within which assignin is called).
    %New variables are given the variable fieldnames specified in the cell array vars.
end

