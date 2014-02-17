% Matlab doesn't allow multiple functions to be accessed from a single
% *.m file.  A way around that is to return the functions as fields of a 
% 'struct'; this makes 'getUtils' function somewhat like a Python module.
function funs = getXlUtils
    funs.size = @size;
    funs.getRow = @getRow;
end

% return the size of a worksheet
function [numcols,numrows] = size(sheet)
    numcols = sheet.Range('A1').End('xlToRight').Column;
    numrows = sheet.Range('A1').End('xlDown').Row;
end

function cells = getRow(sheet,index)
    [numcols,~] = size(sheet);
    utils = getUtils;
    cells = sheet.Range(strcat('A',num2str(index),':',upper(utils.hexavigesimal(numcols)),num2str(index)));
end