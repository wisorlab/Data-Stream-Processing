%=========================================================================
% Main analysis script for the 'US Varying Pulse Duration' experiment
%
% created by @jonbrennecke
%=========================================================================

offsets = {0.01;0.012;0.014;0.016;0.018;0.020;0.022;0.024};

addpath ./etc/matlab-utils;
utils = getUtils;
[Excel, Workbooks, Sheets] = utils.xl.new();
sheets = utils.xl.addSheets(Excel,{ 'Test' });
utils.xl.set(sheets{1}, [1,1], { 'Offset Hz', 'Animal 1', 'Animal 2' });
utils.xl.set(sheets{1}, [1,2], offsets);


% open the file modal and get some '.raw' files
[files,path] = uigetfile({'*raw','Binary MCS Files (*.raw)';'*.*','All Files'; },'Select Data File(s)','MultiSelect','On');
if isstr(files), files = {files}; end

for i=1:length(files)
	[hdr,data] = mcBinRead([ path files{1} ]);
	t = 0:1/hdr.sampleRate:length(data)/hdr.sampleRate-1/hdr.sampleRate;
    matrix = [t',data];
    ttl = logical(matrix(:,2));
    onsets = find( diff(ttl) == 1 );

end