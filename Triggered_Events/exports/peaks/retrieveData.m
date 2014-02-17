function [varargout] = retrieveData(filename,path)
% Function retrieve data opens a dialog box 
% if no arguments are passed in or if a filename
% is specified, directly imports data from .edf 
% or Multi Channel Systems .txt files.
%
% For EDF usage the following format applies
% [header,data] = retrieveData
%
% For MCD .txt file 
% [data] = retrieveData

if nargin < 1
    [filename,path] = uigetfile({'*.*','All Files';'*.edf','EDF Files (*.edf)';'*.txt','Text Files (*.txt)';},... % Open the user interface for opening files
    'Select Data File');
    if ~iscell(filename)
        if length(filename) <= 1 && filename == 0
            return;
        end
    end
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
        varargout = {matrix, hdr, samplingFrequencies(1)};
    end
elseif strcmp(ext,'.txt')
    disp(['Loading MCD data from ''', filename,'''...']);
    [matrix, format, fs] = mcRead(file);
    varargout = {matrix, format, fs};
end 

end

