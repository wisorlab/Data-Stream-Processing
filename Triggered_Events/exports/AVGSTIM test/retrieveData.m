function [varargout] = retrieveData(filename,path)
% [data,format,fs] = retrieveData
% Function retrieve data opens a dialog box 
% if no arguments are passed in or if a filename
% is specified, directly imports data from .edf 
% or Multi Channel Systems .txt files.


if nargin < 1
    [filename,path] = uiGetFilesInCellArray();
end

if exist('path','var')
    file = [path,filename];
end
[~,~,ext] = fileparts(file);

if strcmp(ext,'.edf')
    disp(['Loading EDF data from ''', filename,'''...']);
    [hdr,data] = edfread(file);
    differentSampleLengths = find(diff(hdr.samples) ~= 0);
    samplingFrequencies = hdr.samples/hdr.duration;
    if differentSampleLengths
        % MAKE DIFFERENT TIME VECTORS FOR SAMPLES OF DIFFERENT FREQUENCIES
        disp('Not all channels were sampled at the same frequency.')
        disp(['Channels: ', hdr.labels]);
        disp(['Sampling Frequencies: ',samplingFrequencies]);
    else
        time = 0:1/samplingFrequencies(1):hdr.records*hdr.duration-1/samplingFrequencies(1);
        matrix = [time',data];
        hdr.timeColumnAdded = 1;
        varargout = {matrix, hdr, samplingFrequencies(1)};
    end
elseif strcmp(ext,'.txt')
    disp(['Loading MCD data from ''', filename,'''...']);
    [matrix, format, fs] = mcRead(file);
    varargout = {matrix, format, fs};
elseif strcmp(ext,'.raw')
    disp(['Loading binary data from ''',filename,'''...']);
    [hdr,data] = mcBinRead(file);
    t = 0:1/hdr.sampleRate:length(data)/hdr.sampleRate-1/hdr.sampleRate;
    matrix = [t',data];
    hdr.label = ['t',hdr.label];
    varargout = {matrix,hdr,hdr.sampleRate};
end 

end

