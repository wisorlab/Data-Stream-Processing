%=========================================================================
% Main analysis script for the 'US Varying Pulse Duration' experiment
%
% created by @jonbrennecke / http://github.com/jonbrennecke
%=========================================================================

clear 

% predeclare the array of offsets (in seconds)
% NOTE: these values were calculated by Michele Moore and Dr. Wisor as the 
% best representation of the effect that we're looking at.
offsets = [0.01 0.012 0.014 0.016 0.018 0.020 0.022 0.024];

% add path to mcBinRead.m
addpath ../../../Matlab/etc/;

% add path to the XL class 
addpath ../../../Matlab/etc/matlab-utils/;

% instantiate an XL ActiveX object
xl = XL;
sheets = xl.addSheets({ 'Test' });
xl.setCells(sheets{1}, [1,1], { 'Offset ms', 'Animal 1', 'Animal 2' });
xl.setCells(sheets{1}, [1,2], offsets');

% open the file modal and get some '.raw' files
[files,path] = uigetfile({'*raw','Binary MCS Files (*.raw)';'*.*','All Files'; },'Select Data File(s)','MultiSelect','On');
if isstr(files), files = {files}; end

for i=1:length(files)

	% exstract values from the file name into a struct
	nameparts = regexp(files{i}, [
		'(?<date>\d+-\d+-\d+)'...		% date like M-D-Y
		'\s+'...						% space(s)						 
		'(?<stimtype>LED|Opto|US)'...	% stimtype LED | Opto | US
		'\s+'...						% space(s)
		'(?<freq>[+-]?\d*[.]?\d+)'... 	% frequency (float or integer)
		'(.*?)(?:\w+)\s+' ...			% noncapturing group for 'ms'
		'(?<Hz>[+-]?\d*[.]?\d+)'...		% Hz (float or int)
		'\s+(?:\w+)(.*?)'...			% non capturing group for 'Hz'
		'(?<ext>\.\w+)'...				% file extension
		],'names');

	% import the data as 'matrix'
	% copy/pasted from one of Jon Loft's programs
	[hdr,data] = mcBinRead([ path files{i} ]);
	t = 0:1/hdr.sampleRate:length(data)/hdr.sampleRate-1/hdr.sampleRate;
	matrix = [ t', data ];

	% the TTL track is the second column in 'matrix'
	ttl = logical( matrix(:,2) );

	% find TTL onsets
	onsets = find( diff(ttl) == 1 );
	% onsets = matrix( diff(ttl) == 1, 1 );

	% find the indexes in matrix where 
	idxs = ( ones(length(offsets),1) * onsets' )' + ( ones(length(onsets),1) * ( offsets * hdr.sampleRate ) );


end