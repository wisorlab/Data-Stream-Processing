function [] = plotStimulationPattern(fs,t,channel,ttl,waves,stimMean,randMean,label,units,triggerpoint,triggerstarts)
    % Enlarge figure size
    set(0,'Units','pixels') 
    scnsize = get(0,'ScreenSize');
    scnsize(1) = 10;
    scnsize(2) = 40;
    scnsize(3) = scnsize(3)-20;
    scnsize(4) = scnsize(4)-50;
    fig = figure;
    set(fig,'OuterPosition',scnsize);

    wavewidth = length(waves(1,:))/fs-1/fs;
    wavetimevector = 0:1/fs:wavewidth;
    
    % Plot the drift-corrected signal
    hold off
    subplot(2,3,1),plot(t,channel);
    hold on
    subplot(2,3,1),plot(t,ttl.*300,'r');
    subplot(2,3,1),plot(t(triggerstarts),ttl(triggerstarts).*300,'g^');
    xlim([0 t(end)]);
    title('Drift-Corrected Signal');
    xlabel('Time (s)');
    ylabel(['Voltage (' units ')']);

    % Plot the FFT of the averaged stimulation
    %shape = reshape(waves,numel(waves),1);
    freq = linspace(-fs/2,fs/2,length(wavetimevector));
    ffts = fftshift(fft(stimMean));
    if exist('ffthandle','var')
        subplot(2,3,4),plot(freq,abs(ffts));
        set(gca,'Ylim',get(ffthandle,'Ylim'));
    else
        ffthandle = subplot(2,3,4);
        subplot(2,3,4),plot(freq,abs(ffts));
    end
    set(gca,'Xlim',[0 80]);
    limits = get(gca,'Ylim');
    title('FFT of Averaged Stimulation');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    
    % Plot the mean of the triggered waveforms
    subplot(2,3,5),plot(wavetimevector,stimMean)
    hold on
    subplot(2,3,5),plot([triggerpoint triggerpoint],[min(stimMean)-2 max(stimMean)+2],'r');
    title('Mean Triggered Waveform');
    axis([0 wavewidth min(stimMean)-2 max(stimMean)+2]);
    text(triggerpoint + .004,max(stimMean)+1,'TTL Onset','Color',[0.9 0 0]);
    xlabel('Time (s)');
    ylabel(['Voltage (' units ')']);

%     % Plot all the triggered waveforms
%     subplot(2,3,2),plot(wavetimevector,waves);
%     xlim([0 wavewidth]);
%     title('All Triggered Waveforms');
%     xlabel('Time (s)');
%     ylabel(['Voltage (' units ')']);
    
    % Plot the FFT of the random averaged wave
    freq = linspace(-fs/2,fs/2,length(wavetimevector));
    ffts = fftshift(fft(randMean));
    subplot(2,3,3),plot(freq,abs(ffts));
    set(gca,'Xlim',[0 80]);
    set(gca,'Ylim',limits);
    title('FFT of Randomly Timed Waveform');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    % Plot all the random waveforms
%     subplot(2,3,3),plot(wavetvec,randoms);
%     xlim([0 wavewidth]);
%     title(['All Random Waveforms of ', filename])

    % Plot the mean of the randoms
    subplot(2,3,6),plot(wavetimevector,randMean);
    title('Randomly Timed Waveform')
    xlabel('Time (s)');
    ylabel(['Voltage (' units ')']);
    axis([0 wavewidth min(stimMean)-2 max(stimMean)+2]);
    suptitle(label);
    hold off;

end