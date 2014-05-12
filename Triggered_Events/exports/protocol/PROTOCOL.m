clear

% add path to mcBinRead.m
addpath ../../../../Matlab/etc/;

% add path to the XL class 
addpath ../../../../Matlab/etc/matlab-utils/;

% ask the user for files
[files,path] = uigetfile({'*edf','EDF Files (*.edf)';'*.*','All Files'; },'Select Data File(s)','MultiSelect','On');
if isstr(files), files = {files}; end

xl = XL();

for i=1:length(files)

	[ header data ] = edfread([path files{i}]);

	hz = header.samples(i) / header.duration; % should be 400hz

	eeg1 = data(:,1);
	eeg2 = data(:,2);
	emg = data(:,3);
	ttl = data(:,4);  

	% [pow, freq] = Utils.periodogram( eeg1, 4000, hz, 2000);


	% tens = Utils.slice(eeg1,4000); % seperate into 10 min bins
	% twentyHz = Utils.slice(tens(1,:),200);
	% mean((real(fft(twentyHz(1,:))').^2)/200
		% mean(real(fft(twentyHz)).^2)'
		% mean(real(fft(twentyHz))).^2'



	% n-many samples in 10 min bins and 1 min bins
	tenMin = 600 * hz;
	oneMin = 60 * hz;

	% number of samples in one ms
	ms = hz / 1000; 

	firstOnset = find(ttl>0,1);

	% start = first TTL onset minus 10 min
	begin = firstOnset - tenMin;

	% eeg1
	eeg1 = eeg1(begin:end);
	eeg2 = eeg2(begin:end);
	emg = emg(begin:end);
	ttl = ttl(begin:end);

	% slice into 10min intervals
	tenMinEEG1 = Utils.slice(eeg1,tenMin);
	tenMinEEG2 = Utils.slice(eeg2,tenMin);
	tenMinEMG = Utils.slice(emg,tenMin);
	tenMinTTL = Utils.slice(ttl,tenMin);

	% slice into 1min intervals
	oneMinEEG1 = Utils.slice(eeg1,oneMin);
	oneMinEEG2 = Utils.slice(eeg2,oneMin);
	oneMinEMG = Utils.slice(emg,oneMin);
	oneMinTTL = Utils.slice(ttl,oneMin);


	% fft in 10 min bins
	eeg1_10min_FFT = fft(tenMinEEG1);
	eeg2_10min_FFT = fft(tenMinEEG2);
	emg_10min_FFT = fft(tenMinEMG);

	% fft in 1 min bins
	eeg1_1min_FFT = fft(oneMinEEG1);
	eeg2_1min_FFT = fft(oneMinEEG2);
	emg_1min_FFT = fft(oneMinEMG);


	% downsample to 1hz bins
	eeg1_10min_1hz = [];
	eeg1_1min_1hz = [];

	for j=1:size(eeg1_10min_FFT,1)
		eeg1_10min_1hz(end+1,:) = Utils.downsample( real(emg_10min_FFT(j,:)), 400 );
		eeg1_1min_1hz(end+1,:) = Utils.downsample( real(emg_1min_FFT(j,:)), 400 );
	end

	% output FFT data to EXCEL

	sheet = xl.addSheet('10min Bins');
	xl.rmDefaultSheets();

	binTitles = arrayfun(@(i) [ 'mins ' num2str((i-1)*10) '-' num2str(i*10) ], 1:size(eeg1_10min_1hz,1),'UniformOutput',false);

	xl.setCells( sheet, [1,1], {'EEG1 -- FFT in 10 Minute Bins'} );
	xl.setCells( sheet, [1,2], binTitles', 'FFFF00', 'true' );
	xl.setCells( sheet, [2, 2], eeg1_10min_1hz );

	sheet = xl.addSheet('1min Bins');
	xl.setCells( sheet, [1,1], {'EEG1 -- FFT in 1 Minute Bins'} );
	xl.setCells( sheet, [1,2], binTitles', 'FFFF00', 'true' );
	xl.setCells( sheet, [2, 2], eeg1_1min_1hz );



end