function [waves,randoms] = FloxVerification(filename, export)
    if nargin < 1
        [filename] = uigetfile({'EDF Files (*.edf)';'*.*','All Files'},... % Open the user interface for opening files
        'Select EDF Data File');
        if ~iscell(filename)
            if length(filename) <= 1 && filename == 0
                return;
            end
        end
    end
    disp('Reading in file data...');
    [hdr,data] = edfread(filename);
    eeg_index = 0;
    for i = 1:size(hdr.label,2)
        eeg_index = eeg_index + 1;
        if (strfind(hdr.label{i},'EEG1'))
            break;
        end
    end
    eeg = data(:,eeg_index);
    ttl = data(:,4);
    fs = hdr.samples(eeg_index)/hdr.duration;
    t = 0:1/fs:hdr.duration-1/fs; % time is in seconds
    disp('Smoothing data...');
    driftCorrected = movingSmoothing(eeg,50);

%     % A bandstop filter that takes out 60Hz noise
%     Fpass1 = 58;      % First Passband Frequency
%     Fstop1 = 59;      % First Stopband Frequency
%     Fstop2 = 61;      % Second Stopband Frequency
%     Fpass2 = 62;      % Second Passband Frequency
%     Apass1 = 0.5;     % First Passband Ripple (dB)
%     Astop  = 60;      % Stopband Attenuation (dB)
%     Apass2 = 1;       % Second Passband Ripple (dB)
%     match  = 'both';  % Band to match exactly
%     
%     % Construct an FDESIGN object and call its ELLIP method.
%     h  = fdesign.bandstop(Fpass1, Fstop1, Fstop2, Fpass2, Apass1, Astop, ...
%                           Apass2, fs);
%     Hd = design(h, 'ellip', 'MatchExactly', match);
%     driftCorrected = filter(Hd, driftCorrected);
%     
    disp('Finding trigger patterns...');
    [waves,randoms] = findTriggerPattern(t, driftCorrected, ttl, fs);
    stimMean = mean(waves(:,1:end));
    randMean = mean(randoms(:,1:end));
    if nargin == 2 && export == 1
        disp('Exporting waves to Excel...');
        exportToExcel(filename,waves,randoms);
    end
    
    % Plot the original signal
    hold off
    figure
    subplot(2,3,1),plot(t,eeg);
    hold on
    subplot(2,3,1),plot(t,ttl.*100,'r');
    title(['Original Signal of ', filename]);

    
    % Plot the drift-corrected signal
    hold off
    subplot(2,3,4),plot(t,driftCorrected);
    hold on
    subplot(2,3,4),plot(t,ttl.*100,'r');
    title(['Drift-Corrected Signal of ', filename]);

    % Plot all the triggered waveforms
    wavetvec = 0:1/fs:length(waves(1,:))/fs-1/fs; % ***THIS MUST BE MODIFIED IF THE WINDOW OF THE SNAPSHOT CHANGES
    subplot(2,3,2),plot(wavetvec,waves);
    title(['All Triggered Waveforms of ', filename]);

    % Plot the mean of the triggered waveforms
    subplot(2,3,5),plot(wavetvec,stimMean)
    title(['Mean Triggered Waveform of ', filename]);
  
    % Plot all the random waveforms
    subplot(2,3,3),plot(wavetvec,randoms);
    title(['All Random Waveforms of ', filename])

    % Plot the mean of the randoms
    subplot(2,3,6),plot(wavetvec,randMean);
    title(['Control Waveform of ', filename])
    
%     figure
%     freq = linspace(-fs/2,fs/2,length(wavetvec));
%     ffts = fftshift(fft(stimMean));
%     plot(freq,abs(ffts));
%     set(gca,'Xlim',[0 80]);
%     title('FFT of Averaged Stimulation');
%     xlabel('Frequency (Hz)');
%     ylabel('Magnitude');
end