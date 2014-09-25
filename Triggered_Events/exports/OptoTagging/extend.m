function dest = extend(dest,src)

    % Copy all of the properties in the source objects over to the destination object, 
    % and return the destination object. It's in-order, so the last source will override
    % properties of the same name in previous arguments.

    names = fieldnames(src);
    
    for i=1:length(names)
        dest.(names{i}) = src.(names{i});
    end
    
end