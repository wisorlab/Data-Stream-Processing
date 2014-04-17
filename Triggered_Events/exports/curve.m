% =======================================================
% 
% Modification of 'EVOKEDPOTENTIALS_EDF_SORTBYSTARTPOTENTIAL.m' to find area under curve and peaks
% 
% by @jonbrennecke / https://github.com/jonbrennecke
% 
% =======================================================

addpath ./AvgStim/;


clear all; 
[files,path] = uigetfile({'*.edf','EDF Files (*.edf)';'*.*','All Files'},... % Open the user interface for opening files
'Select EDF File','MultiSelect','On');
if ~iscell(files), files = { files };  end


for i=1:length(files)

	[matrix, format, fs] = retrieveData(files{i},path);

	timeTrack = matrix(:,1);
	eeg1 = matrix(:,2);

	% approximation of the integral of the curve sampled at  x = [ startAt : 0.0002 : startAt + 0.0002 * 70 ], y = field(i,:)
	int = trapz( timeTrack, eeg1 );

	% find all the peaks
	[pks, idx] = findpeaks( eeg1 );

	%  find the greatest of the peaks ( which is distinct from max(field(i,:)) as endpoints may be the max, but aren't peaks )
	[maxPk,maxPkIdx] = max(pks);

end