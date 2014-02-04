function [hdr,data] = mcBinRead(filename,path)
% [header,data] = mcBinRead(filename);
%
% Function mcBinRead reads the binary information of a .raw file converted
% with MC_DataTool. The variable 'data' contains the channel data, while
% the variable 'header' contains the recording information given in the
% .raw file. This function has only been tested for MC_DataTool Version
% 2.6.10.

if nargin < 1
    [filename,path] = uigetfile({'*.raw','Binary Files (*.raw)';'*.*','All Files';},... % Open the user interface for opening files
    'Select Data File');
    if ~iscell(filename)
        if length(filename) <= 1 && filename == 0
            return;
        end
    end
end

if exist('path','var')
    file = [path,filename];
else
    file = filename;
end

fid = fopen(file,'r');
% Check if it is an MC_DataTool Binary file
if strcmp(reshape(fread(fid,29,'*char'),1,29),'MC_DataTool binary conversion');
    header = [];
    header(1:3) = fread(fid,1,'*char');
    i = 3;
    % Find the end of the header and grab the header information
    while true
        header(i) = fread(fid,1,'*char');
        if strcmp(char(header(end-2:end)),'EOH')
            fread(fid,2,'*char');
            break;
        end
        i = i+1;
    end
    header = char(header);
    hdr.version = strtrim(header(strfind(lower(header),'version ')+7:strfind(lower(header),'mc')-1));
    hdr.filename = strtrim(header(strfind(lower(header),'mc_rec file =')+14:strfind(lower(header),'sample rate')-1));
    if strcmp(hdr.filename(1),'"')
        hdr.filename = hdr.filename(2:end);
    end
    if strcmp(hdr.filename(end),'"')
        hdr.filename = hdr.filename(1:end-1);
    end
    hdr.sampleRate = str2double(strtrim(header(strfind(lower(header),'sample rate =')+13:strfind(lower(header),'adc zero')-1)));  
   
    ElIndeces = strfind(header(strfind(lower(header),'adc zero =')+10:end),'El')+strfind(lower(header),'adc zero =')+8;
    DiIndeces = strfind(header(strfind(lower(header),'adc zero =')+10:end),'Di')+strfind(lower(header),'adc zero =')+8;
    if ElIndeces(1) < DiIndeces(1)
        hdr.ADRange = str2double(strtrim(header(strfind(lower(header),'adc zero =')+10:ElIndeces(1))));
        hdr.ElFactor = str2double(strtrim(header(ElIndeces(1)+5:ElIndeces(1)+strfind(header(ElIndeces(1):DiIndeces(1)),'AD')-5)));
        hdr.ElFactorUnits = strtrim(header(ElIndeces(1)+strfind(header(ElIndeces(1):DiIndeces(1)),'AD')-4:ElIndeces(1)+strfind(header(ElIndeces(1):DiIndeces(1)),'AD')));
        hdr.DiFactor = str2double(strtrim(header(DiIndeces(1)+5:DiIndeces(1)+strfind(header(DiIndeces(1):end),'AD')-5)));
        hdr.DiFactorUnits = strtrim(header(DiIndeces(1)+strfind(header(DiIndeces(1):end),'AD')-4:DiIndeces(1)+strfind(header(DiIndeces(1):end),'AD')));
    else
        hdr.ADRange = str2double(strtrim(header(strfind(lower(header),'adc zero =')+10:DiIndeces(1))));
        hdr.DiFactor = str2double(strtrim(header(DiIndeces(1)+5:DiIndeces(1)+strfind(header(DiIndeces(1):ElIndeces(1)),'AD')-5)));
        hdr.DiFactorUnits = strtrim(header(DiIndeces(1)+strfind(header(DiIndeces(1):ElIndeces(1)),'AD')-4:DiIndeces(1)+strfind(header(DiIndeces(1):ElIndeces(1)),'AD')));
        hdr.ElFactor = str2double(strtrim(header(ElIndeces(1)+5:ElIndeces(1)+strfind(header(ElIndeces(1):end),'AD')-5)));
        hdr.ElFactorUnits = strtrim(header(ElIndeces(1)+strfind(header(ElIndeces(1):end),'AD')-4:ElIndeces(1)+strfind(header(ElIndeces(1):end),'AD')));
    end
    hdr.label = splitstring(strtrim(header(strfind(lower(header),'streams =')+9:strfind(lower(header),'eoh')-1)),';');
    data = fread(fid,'int16');
    data = reshape(data,numel(hdr.label),length(data)/numel(hdr.label));
    data = data';
    ElColumns = find(not(cellfun('isempty', strfind(hdr.label, 'El'))));
    DiColumns = find(not(cellfun('isempty', strfind(hdr.label, 'Di'))));
    if hdr.ElFactor ~= 0
        data(:,ElColumns) = data(:,ElColumns).*hdr.ElFactor;
    end
    if hdr.DiFactor ~= 0
        data(:,DiColumns) = data(:,DiColumns).*hdr.DiFactor;
    else 
        data(:,DiColumns) = rem(data(:,DiColumns),2); 
    end
else
    error(['File ''', filename, ''' does not appear to have been'... 
           'constructed by MC_DataTool. Potential source of error: when using MC_DataTool''s '...
           '''Converting to binary file format'' dialog box, ensure the checkboxes '...
           '''Write header'' and ''Signed 16Bit'' are selected.']);

end
fclose(fid);
end
