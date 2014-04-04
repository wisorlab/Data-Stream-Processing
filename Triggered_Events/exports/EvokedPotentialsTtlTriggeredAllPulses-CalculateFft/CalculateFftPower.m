function [AbsolutePower,NormalizedPower] = CalculateFftPower(InputTrace,SampleRate,LowCut,HighCut,TopOfScale)
%Input Trace is any signal collected at known sampling rate.  
%Fft power is calculated in frequency bands of 0.333 Hz.
% AbsolutePower  = power summed across all frequency values where LowCut < freq < High Cut.
%NormalizedPower = Absolute Power / (Fft power across all frequency values where freq < TopOfScale).

FftPower = abs(fftshift(fft(InputTrace))); %InputVector is an electrophysiological trace of known sampling frequency, fs
        %here, we do a discrete Fourier transform of InputTrace with a fast
        %Fourier transform algorithm: "fft(InputTrace)"
        % This transform yields a complex double, in which each value has a real and an imagined component.
        %fftshift moves the zero component of this fft to the center of the array.
        %abs removes the complex component of the complex double, yielding
        %a curve that is symmetrical about the FFT power @ zero Hz.

msbefore = 1500; %length(InputTrace)/SampleRate/2;            %we routinely collect a 3-sec window of data, so 1500 msec before ttl onset and 1500 msec after
msafter = 1500; %length(InputTrace)/SampleRate/2;
wavetimevector = -msbefore/1000:1/SampleRate:msafter/1000-1/SampleRate; %go from -1.5 to 1.5 sec in 1/fs intervals. 3 sec of data)
freq = linspace(-SampleRate/2,SampleRate/2,length(wavetimevector)); %generate a vector equivalent in length to wavetimevector that starts at -2500 and goes to 2500.
%These are the frequencies associated with the FftPower values.  
%We can throw out those less than 0 and the FftPower Values associated with them.
FftPower=FftPower(freq>0);  %Retain in FftPower only those power values that are in bins greater than zero.
freq=freq(freq>0); %Retain in freq only those bins greater than zero.
AbsolutePower = sum(FftPower(freq>LowCut&freq<HighCut));  %sum power for values between low cut and high cut.
NormalizedPower = sum(FftPower(freq>LowCut&freq<HighCut))/sum(FftPower(freq<TopOfScale));  %sum power for values between low cut and high cut, divide by total power up to top of scale.


end

