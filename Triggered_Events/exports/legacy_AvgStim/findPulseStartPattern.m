function [waves, randoms, wavestates] = findTriggerPatternFronts(t,eeg, ttl, fs, msbefore, msafter)
% [waves, randoms] = findTriggerPattern(eeg, ttl, fs, msbefore, msafter)

% Function findTriggerPattern takes snapshots of each wave
% around a TTL triggered event, averages them, and takes random
% snapshots of the signal to create a control average.

if nargin <= 4
    msbefore = 100;
    msafter = 200;
end

% Converts the sample window from milliseconds to sample indices
samplestart = msbefore*fs/1000;
sampleend = msafter*fs/1000;
samplesperwave = samplestart+sampleend;

% Set the voltage threshold for sorting the polarization state at the
% trigger onset
posthresh = 2;
negthresh = -2;

ons = find(ttl > 0); % Find all ttl on
onends = find(diff(ons) ~= 1);
triggerstarts = [ons(1);ons(onends+1)];
pulsestarts = [triggerstarts(1);triggerstarts([0;diff(triggerstarts) > mean(diff(triggerstarts))] == 1)];
samplestarts = pulsestarts-samplestart;
sampleends = pulsestarts+sampleend-1;
sampleends = sampleends(samplestarts > 0);
samplestarts = samplestarts(samplestarts > 0);
samplestarts = samplestarts(sampleends < length(eeg));
sampleends = sampleends(sampleends < length(eeg));
waves = zeros(length(sampleends),samplesperwave);
wavestates = zeros(length(sampleends),1);
for i = 1:length(sampleends)
    if eeg(pulsestarts(i)) > posthresh
        wavestates(i) = 1;
    elseif eeg(pulsestarts(i)) < negthresh
        wavestates(i) = -1;
    else 
        wavestates(i) = 0;
    end
    waves(i,1:samplesperwave) = eeg(samplestarts(i):sampleends(i));
end

randoms = zeros(size(waves));
% Create the randoms
for i = 1:length(waves(:,1))
    startIndex = round((length(eeg)-samplesperwave)*rand());
%     while any(ttl(startIndex:startIndex+samplesperwave-1))
%         startIndex = round((length(eeg)-samplesperwave)*rand());
%     end
    randoms(i,1:samplesperwave) = eeg(startIndex:startIndex+samplesperwave-1);
end

end

