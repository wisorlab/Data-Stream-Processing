function [sleepstates] = importFFTPowerFile(fileToRead1)
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

newData = importdata(fileToRead1, DELIMITER, HEADERLINES);
sleeptext = newData.textdata(3:end,2);
sleepstates = zeros(size(sleeptext));
for i = 1:length(sleeptext)
    if strcmpi(sleeptext(i),'w')
        sleepstates(i) = 1;
    elseif strcmpi(sleeptext(i),'r')
        sleepstates(i) = 2;
    elseif strcmpi(sleeptext(i),'s')
        sleepstates(i) = 3;
    elseif strcmpi(sleeptext(i),'x')
        sleepstates(i) = 5;
    else 
        sleepstates(i) = 4;
    end
end


