function [fig] = plotStimulationPattern(t,wave,random,fs,units,label,triggerPoint,time,eeg,ttl,usedTriggers,sleepData)
    % Enlarge figure size
    set(0,'Units','pixels') 
    scnsize = get(0,'ScreenSize');
    scnsize(1) = 10;
    scnsize(2) = 40;
    scnsize(3) = scnsize(3)-20;
    scnsize(4) = scnsize(4)-50;
    fig = figure;
    set(fig,'OuterPosition',scnsize);
    
%     wakelines = zeros(2*length(find(sleepData == 1)));
%     remlines = zeros(2*length(find(sleepData == 2)));
%     sleeplines = zeros(2*length(find(sleepData == 3)));
%     unclassifiedlines = zeros(2*length(find(sleepData == 4)));
%     for i = 1:length(sleepData)
%         if sleepData(i) == 1
%             wakelines(2*(i-1)+1:2*(i-1)+2) = [10*(i-1) 10*(i-1)+10];
%             remlines(2*(i-1)+1:2*(i-1)+2) = NaN;
%             sleeplines(2*(i-1)+1:2*(i-1)+2) = NaN;
%             unclassifiedlines(2*(i-1)+1:2*(i-1)+2) = NaN;
%         elseif sleepData(i) == 2
%             wakelines(2*(i-1)+1:2*(i-1)+2) = NaN;
%             remlines(2*(i-1)+1:2*(i-1)+2) = [10*(i-1) 10*(i-1)+10];
%             sleeplines(2*(i-1)+1:2*(i-1)+2) = NaN;
%             unclassifiedlines(2*(i-1)+1:2*(i-1)+2) = NaN;
%         elseif sleepData(i) == 3
%             wakelines(2*(i-1)+1:2*(i-1)+2) = NaN;
%             remlines(2*(i-1)+1:2*(i-1)+2) = NaN;
%             sleeplines(2*(i-1)+1:2*(i-1)+2) = [10*(i-1) 10*(i-1)+10];
%             unclassifiedlines(2*(i-1)+1:2*(i-1)+2) = NaN;
%         elseif sleepData(i) == 4
%             wakelines(2*(i-1)+1:2*(i-1)+2) = NaN;
%             remlines(2*(i-1)+1:2*(i-1)+2) = NaN;
%             sleeplines(2*(i-1)+1:2*(i-1)+2) = NaN;
%             unclassifiedlines(2*(i-1)+1:2*(i-1)+2) = [10*(i-1) 10*(i-1)+10];
%         end
%     end     
%     subplot(2,3,1),plot(wakelines,zeros(length(wakelines),1),'c','LineWidth',6000);
%     hold on
%     set(gca,'Xlim',[min(time) max(time)]);
%     subplot(2,3,1),plot(remlines,zeros(length(remlines)),'m','LineWidth',6000);
%     subplot(2,3,1),plot(sleeplines,zeros(length(sleeplines)),'y','LineWidth',6000);
%     subplot(2,3,1),plot(unclassifiedlines,zeros(length(unclassifiedlines)),'k','LineWidth',6000); 
%     subplot(2,3,1),plot(time,eeg,'b');
%     subplot(2,3,1),plot(time,ttl.*300,'r');
%     subplot(2,3,1),plot(time(usedTriggers),ttl(usedTriggers).*300,'g.'); 
%     legend('Wake','Rem','Sleep','Unclassified','EEG','TTL','Triggers Used','Location','NorthWestOutside');    
%     title('Animal Recording');
%     ylabel('Voltage (uV)');
%     xlabel('Time (sec)');
    
    
    yscale = [-500 500];
    fftyscale = [0 15000];
    % Plot the mean of the triggered waveforms
    subplot(2,2,1),plot(t,wave)
    title('Mean Triggered Waveform');
    wavewidth = max(t);
    axis([0 wavewidth yscale(1) yscale(2)]);
    hold on
    subplot(2,2,1),plot([triggerPoint triggerPoint],[-10000 10000],'Color',[0.9 0 0]);
    text(triggerPoint + .004,480,'TTL Onset','Color',[0.9 0 0]);
    xlabel('Time (s)');
    ylabel(['Voltage (' units ')']);

    % Plot the mean of the randoms
    subplot(2,2,2),plot(t,random);
    title('Control Waveform');
    axis([0 wavewidth yscale(1) yscale(2)]);
    xlabel('Time (s)');
    ylabel(['Voltage (' units ')']);
    
    % Plot the fft of mean triggered waveform
    freq = linspace(-fs/2,fs/2,length(t));
    ffts = fftshift(fft(wave));
    subplot(2,2,3),plot(freq,abs(ffts));
    set(gca,'Xlim',[0 80]);
    set(gca,'Ylim',[fftyscale(1) fftyscale(2)]);
    title('FFT of Average of Stimulated Waveforms');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    
    % Plot the FFT of the random averaged wave
    ffts = fftshift(fft(random));
    subplot(2,2,4),plot(freq,abs(ffts));
    set(gca,'Xlim',[0 80]);
    set(gca,'Ylim',[fftyscale(1) fftyscale(2)]);
    title('FFT of Average of Randomly Timed Waveforms');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    
    suptitle(label);
end