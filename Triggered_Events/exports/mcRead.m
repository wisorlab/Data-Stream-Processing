function [ matrix, format, fs ] = mcRead( filename, nseconds )
% [matrix, format] = mcRead(filename, numberOfSeconds)
% Imports the data from an MC rack .txt file.

try
    fid = fopen(filename);
catch err  
    error(['The file could not be loaded. '...
        'Be sure your file name is correct '...
        'and you are in the correct working directory.']);
end

title = textscan(fid,'%s',2,'delimiter','\n'); % Grabs the first two lines of the document.
if ~strcmp(title{1,1},'MC_DataTool ASCII conversion') % Verifies the .txt file came from MC_DataTool
    error('This text file does not appear to be a text file converted from a .mcd file with MC_DataTool.');
end

head = textscan(fid,'%s',2,'delimiter','\n');  %Retrieves information in 2nd two lines
format.units = sscanf(head{1}{2},'%s'); % Extracts the unit information
openbracks = strfind(sscanf(format.units,'%s'),'[');
closebracks = strfind(sscanf(format.units,'%s'),']');

% The number of columns equals the number of open brackets minus the number
% of closing brackets that are not immediately preceded by an open bracket,
% which indicates a bracket exists within the name of a channel.
ncol = length(openbracks)-length(find(openbracks(2:end)-closebracks(1:end-1) ~= 1));
colformat = '';
for i=1:ncol
    colformat = [colformat, '%f '];   % Creates the format specifier for textscan
end

% Turns the format line of the .txt file into a cell array of column labels
format.label{1} = strtrim(head{1}{1}(1:13));
for i=2:ncol-1
    format.label{i} = strtrim(head{1}{1}(13*i+1:13*i+12));
end

if strfind(sscanf(format.units,'%s'),'[ms]');
    timeunits = 1000;
elseif strfind(sscanf(format.units,'%s'),'[s]');
    timeunits = 1;
elseif strfind(sscanf(format.units,'%s'),'[m]');
    timeunits = 1/60;
elseif strfind(sscanf(format.units,'%s'),'[h]');
    timeunits = 1/3600;
else
    error('Units of time can not be determined. Sampling frequency unknown.')
end
matrix = textscan(fid,colformat,501,'CollectOutput',1,'delimiter','\n');    % Returns first two rows of data to
matrix = matrix{1};
fs = ones(500,1);
for i = 1:500
    fs(i) = matrix(i+1,1)-matrix(i,1);   % determine the sampling frequency.
end
fs = timeunits*1/mean(fs);
frewind(fid);   % Moves back to the beginning of the file
textscan(fid,'%s',4,'delimiter','\n'); %Skips the first four lines of the document

if nargin == 1
    matrix = textscan(fid,colformat,'CollectOutput',1);
elseif nargin == 2 
    matrix = textscan(fid,colformat,nseconds*round(fs),'CollectOutput',1);
end
matrix = matrix{1};

%IDENTIFY AND REMOVE JUNK DATA

% Removes the junk columns of data e.g. 'Di D1' which can be seen with
% uiimport.
junkcolumns = length(strfind(sscanf(format.units,'%s'),'[]'));
for i = 1:junkcolumns
    
end
fclose('all');

end