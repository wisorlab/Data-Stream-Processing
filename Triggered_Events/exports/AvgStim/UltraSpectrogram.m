% NOTE: This is the same as calling spectrogram with no outputs.
close all;
% for i = 2:length(eeg)
%     if ttl(i) > 0 && ttl(i-1) == 0
%         break;
%     end
% end
range = 1:length(eeg);
fs = 5000;
window = fs*2.5;
overlap = fs*0;
F = 4:.1:12;
hold off;
subplot(2,1,1),plot(time(range)./1000,eeg(range));
set(fig,'OuterPosition',scnsize);
hold on
subplot(2,1,1),plot(time(range)./1000,ttl(range).*55.5,'k');
xlabel('Time (s)');
ylabel('Amplitude (mV)');

[y,f,t,p] = spectrogram(eeg(range),window,overlap,F,fs,'yaxis'); 
subplot(2,1,2),surf(t,f,10*log10(abs(p)),'EdgeColor','none');
xlabel('Time (s)');
ylabel('Frequency (Hz)');
zlabel('Magnitude');
view(0,90);
view([0,-90,75]);
view([-90,0,75]);
view([-45,-45,75]);

%subplot(2,1,2),spectrogram(eeg(range),window,overlap,F,fs,'yaxis'); 
% xlabel('Time (s)');
% ylabel('Frequency (Hz)');

