function [filteredData] = filter60Hz(data)
    fs = 5000;
    % A bandstop filter that takes out 60Hz noise
    Fpass1 = 58;      % First Passband Frequency
    Fstop1 = 59;      % First Stopband Frequency
    Fstop2 = 300;      % Second Stopband Frequency
    Fpass2 = 301;      % Second Passband Frequency
    Apass1 = 0.5;     % First Passband Ripple (dB)
    Astop  = 60;      % Stopband Attenuation (dB)
    Apass2 = 1;       % Second Passband Ripple (dB)
    match  = 'both';  % Band to match exactly
    
    % Construct an FDESIGN object and call its ELLIP method.
    h  = fdesign.bandstop(Fpass1, Fstop1, Fstop2, Fpass2, Apass1, Astop, ...
                          Apass2, fs);
    Hd = design(h, 'ellip', 'MatchExactly', match);
    filteredData = filter(Hd, data);
end