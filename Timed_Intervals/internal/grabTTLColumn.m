function [ m ] = grabTTLColumn( ttl_file )
% m = grabTTLColumn(ttl_file);
% Extracts the TTL data from an annotations file


[fid,message] = fopen(ttl_file);
if fid == -1
    error(message);
end
textscan(fid,'%s',7,'delimiter','\n');
m = zeros(20000000,1);
i = 1;
while ~feof(fid)
    textscan(fid,'%f %f%c%f%c%f %f%c%f%c%f %f%c%f%c%f %f%c%f%c%f',1,'delimiter',' ');
    c = textscan(fid,'%f',1,'delimiter','\n');
    if ~isempty(c{1})
        m(i) = c{1};
    end
    textscan(fid,'%s',1,'delimiter','\n');
    i = i+1;
end
m = m(m ~= 0);
m = m(1:end-1);
end

