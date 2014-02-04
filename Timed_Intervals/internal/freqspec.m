function [ f, a, freqs, max_amps ] = freqspec( matrix, Fs )
% [f, a, freqs, max_amps] = freqspec(matrix, sample_frequency)
% Outputs a plot of frequency vs. amplitude for signal analysis.
% Comment out line 36 if window is not fitting.

L = length(matrix);

NFFT = 2^(nextpow2(L));
Y = fft(matrix,NFFT)/L;
f = Fs/2*linspace(0,1,NFFT/2+1);
a = 2*abs(Y(1:NFFT/2+1));

% Finds the frequency with the maximum amplitude.
maxes = a(imregionalmax(a));
maxes = sort(maxes);
max_amps = maxes(end-4:end-1)';
freqs = zeros(1,4);
for i=4:-1:1
    x = a == max_amps(i);
    freqs(1,i) = f(x);
end


% Plot single-sided amplitude spectrum.

% 
% title(sprintf('%iHz Single-Sided Amplitude Spectrum of y(t) Max:(%.3f,%.3f)',Fs,freq,amp))
% xlabel('Frequency (Hz)')
% ylabel('|y(f)|')
% axis([0 20 0 max(max_amps)+20])






