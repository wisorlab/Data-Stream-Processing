function [waves] = detectSlowWaves(eeg,fs,epochl)
	
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	% detect slow wave patterns in an electrophysiological wave
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	% :param eeg - wave vector
	% :param fs - frequency in hertz
	% :param epochl - length of an epochs

	zermat=zeros(1,length(eeg));

	B = [1 0 -1];
	convolved_signal = conv(eeg,B);

	signs = sign(convolved_signal);

	troughs = (diff(signs) > 0);
	uppeaks = (diff(signs) < 0);

	% uppeaks=find(imregionalmax(eeg)>0); % Find the indices of max voltages
	% troughs=find(imregionalmin(eeg)>0); % Find the indices of min voltages
	uppeaks(eeg(uppeaks)<0)=[]; % Eliminate any negative local maxima
	troughs(eeg(troughs)>0)=[]; % Eliminate any positive local minima
	zermat(uppeaks)=1;zermat(troughs)=2; % Mark points in the zero matrix as (1) a peak and (2) a trough
	peaktroughs=find(zermat>0); % Return indices of these points in zermat
	peaktroughss=zermat(peaktroughs); % Return whether they are a peak(1) or trough(2)
	tro=find(peaktroughss==2); % Return the indices of all troughs in peaktroughss
	waves=zeros(20000,20);
	for i=1:length(tro)-1
		sn=peaktroughss(tro(i)+1); % Grab the index of ith peak after the ith trough
		sp=peaktroughss(tro(i+1)-1); % Grab the index of the peak immediately before the ith+1 trough
		if sn==1 && sp==1 % If they are both peaks
			wavest=peaktroughs(tro(i)); % Grab the index of the ith trough in zermat
			epst=ceil(wavest/(fs*epochl)); % I think show what epoch the wave lies in 
			waveend=peaktroughs(tro(i+1)); % Grab the index of the ith+1 trough in zermat
			wave=eeg(wavest:waveend); % Define the wave
			[b,c]=max(wave); % Find the maximum voltage of the wave
			s=length(wave);  % Find the number of samples in the wave
			m=wavest+ceil(s/2); % Find the midpoint of the wave
			%upswing=max(abs(diff(wave(1:c)))); % Find the maximum difference between two consecutive samples on the upswing.
			%downswing=max(abs(diff(wave(c:end)))); % Find the maximum difference between two consecutive samples on the downswing.
			AmpUp1=b-wave(1); % Find the voltage difference between the maximum and the first point in the wave.
			AmpDown1=b-wave(end); % Find the voltage difference between the maximum and the last point in the wave.
			SlopeUp1=AmpUp1/(c/fs); % Divide the rise, by the run. Note that c is the index from the beginning of the wave.
			SlopeDown1=AmpDown1/((c-s)/fs); % Find the negative slope.
			c=wavest+c; % Make c the index of the wave's max from the beginning of the file.
			nump=uppeaks; % Find the local maxima within the wave.
			[ad,nump]=find(nump>0); % Return the rows and columns for positive local maxima.
			nump=length(nump); % Determine the number of peaks.
			numppsec = nump/(s/fs);
			FirstP=wave(ad(1)); % Assign the voltage of the first peak.
			LastP=wave(ad(end)); % Assign the voltage of the last peak.
			AmpUp2=FirstP-wave(1); % Find the amplitude of the first peak relative to the beginning of the wave.
			AmpDown2=LastP-wave(end); % Find the amplitude of the last peak relative to the end of the wave.
			SlopeUp2=AmpUp2/(ad(1)/fs); % Find the slope from the beginning to the the first peak.
			SlopeDown2=AmpDown2/((ad(end)-s)/fs); % Find the slope from the last peak to the end of the wave.
			meanAmp=mean(wave(ad)); % Calculate the mean amplitude of the peaks.
			waves(i,:) = [epst wavest m waveend s/fs AmpUp1 AmpDown1 wave(1) b wave(end) nump c numppsec meanAmp   SlopeUp1 SlopeDown1 AmpUp2 AmpDown2 SlopeUp2 SlopeDown2];
		end
	end
end