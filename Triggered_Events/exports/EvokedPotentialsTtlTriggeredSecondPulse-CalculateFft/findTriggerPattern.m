function [waves, randoms, wavestates, samplestarts] = findTriggerPattern(eeg, ttl, fs, msbefore, msafter, triggerPoint, state)
% [waves, randoms] = findTriggerPattern(eeg, ttl, fs, msbefore, msafter)

% Function findTriggerPattern takes snapshots of each wave
% around a TTL triggered event, averages them, and takes random
% snapshots of the signal to create a control average.

if nargin < 4
    msbefore = 100;
    msafter = 200;
end

% Converts the sample window from milliseconds to sample indices
samplestart = msbefore*fs/1000;
sampleend = msafter*fs/1000;
samplesperwave = samplestart+sampleend;

% Faster Solution
% ttl = ttl(1:length(eeg));
ons = find(ttl > 0); % Find all ttl on
onends = find(diff(ons) ~= 1);
triggerstarts = ons(onends+1);

TtlIsOn = find(ttl > 0);
TtlOffsetIndex = find(diff(TtlIsOn) ~= 1);
TtlOnsetIndex = TtlIsOn(logical(ttl(TtlIsOn-1)==0));
SecondOnsetInPair=TtlOnsetIndex(find(diff(TtlOnsetIndex)<fs*0.07)+1);
triggerstarts = SecondOnsetInPair;
% triggerwindow = zeros(length(triggerstarts),1);
% for i = 1:70:length(triggerstarts)
%     triggerwindow(1:35) = 1;
% end
% triggerstarts = triggerstarts(triggerwindow == 1);
samplestarts = triggerstarts-samplestart;
sampleends = triggerstarts+sampleend-1;
sampleends = sampleends(samplestarts > 0);
samplestarts = samplestarts(samplestarts > 0);
samplestarts = samplestarts(sampleends < length(eeg));
sampleends = sampleends(sampleends < length(eeg));
waves = zeros(length(sampleends),samplesperwave);
wavestates = zeros(length(sampleends),1);
for i = 1:length(sampleends)
%     if eeg(triggerstarts(i)) > posthresh
%         wavestates(i) = 1;
%     elseif eeg(triggerstarts(i)) < negthresh
%         wavestates(i) = -1;
%     else 
%         wavestates(i) = 0;
%     end
    waves(i,1:samplesperwave) = eeg(samplestarts(i):sampleends(i));
end

% figure
% time = 0:1/fs:length(eeg)/fs-1/fs;
% plot(time,eeg)
% hold on
% plot(time,ttl.*5,'k')
% plot(time(triggerstarts),ttl(triggerstarts).*5,'g^')

%[waves] = throwArtifacts(waves);

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

offIndeces = find(eeg == 0);
offLengths = diff(offIndeces);


for i = 1:length(waves(:,1))
    startIndex = round((length(eeg)-samplesperwave)*rand());
%     while any(ttl(startIndex:startIndex+samplesperwave-1))
%         startIndex = round((length(eeg)-samplesperwave)*rand());
%     end
    randoms(i,1:samplesperwave) = eeg(startIndex:startIndex+samplesperwave-1);
end


% Set the voltage threshold for sorting the polarization state at the
% trigger onset
posthresh = 2;
negthresh = -2;
if nargin > 6
    if state == 1
        for i = 1:length(waves(:,1))
            startIndex = round((length(eeg)-samplesperwave)*rand());
            while (eeg(startIndex+fs*triggerPoint) < posthresh) || any(ttl(startIndex:startIndex+samplesperwave-1))
                startIndex = round((length(eeg)-samplesperwave)*rand());
            end
            randoms(i,1:samplesperwave) = eeg(startIndex:startIndex+samplesperwave-1);
        end
    elseif state == 0
        for i = 1:length(waves(:,1))
            startIndex = round((length(eeg)-samplesperwave)*rand());
            while (eeg(startIndex+fs*triggerPoint) > posthresh) || (eeg(startIndex+fs*triggerPoint) < negthresh) || any(ttl(startIndex:startIndex+samplesperwave-1))
                startIndex = round((length(eeg)-samplesperwave)*rand());
            end
            randoms(i,1:samplesperwave) = eeg(startIndex:startIndex+samplesperwave-1);
        end
    elseif state == -1
        for i = 1:length(waves(:,1))
            startIndex = round((length(eeg)-samplesperwave)*rand());
            while (eeg(startIndex+fs*triggerPoint) > negthresh) || any(ttl(startIndex:startIndex+samplesperwave-1))
                startIndex = round((length(eeg)-samplesperwave)*rand());
            end
            randoms(i,1:samplesperwave) = eeg(startIndex:startIndex+samplesperwave-1);
        end
    end
end


end

