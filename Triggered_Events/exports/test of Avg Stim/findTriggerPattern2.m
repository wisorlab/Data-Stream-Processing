function [waves, wavestates, randoms] = findTriggerPattern2(eeg, ttl, fs, msbefore, msafter)
% [waves, randoms] = findTriggerPattern(eeg, ttl, fs, msbefore, msafter)

% Function findTriggerPattern takes snapshots of each wave
% around a TTL triggered event, averages them, and takes random
% snapshots of the signal to create a control average.

if nargin < 4
    msbefore = 100;
    msafter = 200;
end

samplestart = msbefore*fs/1000;
sampleend = msafter*fs/1000;
samplesperwave = samplestart+sampleend;

% Faster Solution
ons = find(ttl > 0);
onends = find(diff(ons) ~= 1);
triggerstarts = ons(onends+1);
samplestarts = triggerstarts-samplestart;
sampleends = ons(onends+1)+sampleend-1;
waves = zeros(length(sampleends),samplesperwave);
wavestates = length(sampleends);
for i = 1:length(sampleends)
    wavestates(i) = sign(eeg(triggerstarts(i)));
    waves(i,1:samplesperwave) = eeg(samplestarts(i):sampleends(i));
end
poswaves = waves(wavestates > 0,:);
meanposwave = mean(poswaves);

% % Slower Solution
% waves = zeros(1000000,samplesperwave); % preallocate 1,000,000 trigger events
% 
% j = 1;
% for i = 2:length(ttl)-sampleend % start at the second ttl index so we can make the following if statement
%     %tests = [i,ttl(i) > 0,ttl(i-1) == 0,i+msafter*fs/1000 <= length(eeg)]
%     if ttl(i) > 0 && ttl(i-1) == 0
%         waves(j,1:samplesperwave) = eeg(i-samplestart:i+sampleend);
%         j = j+1;
%     end
% end
% 
% waves( ~any(waves,2), : ) = [];  %rows
% waves( :, ~any(waves,1) ) = [];  %columns


randoms = zeros(size(waves));
% Create the randoms
for i = 1:length(waves(:,1))
    startIndex = round((length(eeg)-samplesperwave)*rand());
    randoms(i,1:samplesperwave) = eeg(startIndex:startIndex+samplesperwave-1);
end

end

