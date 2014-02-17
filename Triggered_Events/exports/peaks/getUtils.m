% Matlab doesn't allow multiple functions to be accessed from a single
% *.m file.  A way around that is to return the functions as fields of a 
% 'struct'; this makes 'getUtils' function somewhat like a Python module.
function funs = getUtils
    funs.hexavigesimal = @hexavigesimal;
    funs.alphabetical_cast = @alphabetical_cast;
end

% conversion to hexavigesimal (base 26)
function string = hexavigesimal(number)
    quotient = round(number/26);
    remainder = mod(number,26);
    string = '';
    while true  % since, matlab has no do-while loop
        string(end+1) = alphabetical_cast(remainder);
        if quotient==0
            break
        end
        remainder = mod(quotient,26);
        quotient = round(quotient/26); 
    end
    string = fliplr(string);
end

% convert numbers 1-26 to chars
function c = alphabetical_cast(number)
    c = char(97+str2num(sprintf('%i',number)));
end