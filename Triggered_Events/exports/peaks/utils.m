% Matlab doesn't allow multiple functions to be accessed from a single
% *.m file.  A way around that is to return the functions as fields of a 
% 'struct'
function funs = getUtils
    funs.hexavigesimal = @hexavigesimal;
end

function string = hexavigesimal(number)
end