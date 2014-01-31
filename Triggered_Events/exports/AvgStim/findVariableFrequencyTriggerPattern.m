function [waves, randoms, triggerBin, stimulationFrequencies, triggerstarts] = findVariableFrequencyTriggerPattern(eeg, ttl, fs, msbefore, msafter)
% [waves, randoms] = findTriggerPattern(eeg, ttl, fs, msbefore, msafter)

% Function findVariableFrequencyTriggerPattern takes snapshots of each wave
% around a TTL triggered event, averages them, and takes random
% snapshots of the signal and averages those to create a control.
% Different frequencies within the recording are detected and snapshots are
% separated based on stimulus frequency. Frequencies are assumed to be
% integers.

if nargin < 4
    msbefore = 100;
    msafter = 200;
end

% Converts the sample window from milliseconds to sample indices
samplestart = msbefore*fs/1000;
sampleend = msafter*fs/1000;
samplesperwave = samplestart+sampleend; % The number of samples in each snapshot of triggered events


% Find all ttl on (i.e. ttl == 1).
ons = find(ttl > 0); 

% Find where the difference between the indeces of ons is not equal to one
% (i.e. the last ttl == 1 in each series of 1s). onends is a logical vector
% that returns true if the indeces of two points where the ttl == 1 are not adjacent.
onends = find(diff(ons) ~= 1); 

% Returns the indeces of the first on point in each trigger. 
% ons(1) is included because the function 'diff' in the previous
% line does not return the first trigger point
triggerstarts = [ons(1);ons(onends+1)]; 

% Returns the indeces of the last on point in each trigger.
% ons(end) is included because the function 'diff' in the 
% does not return the last trigger point
triggerends = [ons(onends);ons(end)]; 

numberOfSamplesBetweenTriggerStarts = triggerstarts(2:end)-triggerstarts(1:end-1);

try
     % Find the largest gaps between trigger pulses. Returns some small gaps which must be eliminated in the next line.
    [largeGaps,gapLocations] = findpeaks(numberOfSamplesBetweenTriggerStarts);
    lastPulseInTrain = largeGaps > 2*mean(largeGaps); % THIS WILL FAIL AT FINDING TRIGGER STARTS IF THE FREQUENCY OF TRIGGER IMPULSES IS PERFECT BECAUSE ALL NUMBERS OF SAMPLES BETWEEN TRIGGER IMPULSES WILL EQUAL THE MEAN
    lastPulseInTrain = triggerstarts(gapLocations(lastPulseInTrain)); % Convert from a logical vector to a vector of indeces
    lastPulseInTrain = [lastPulseInTrain;ons(onends(end)+1)]; % Add the last pulse in the recording

    numberOfSamplesBetweenTriggerStarts = [ons(1);numberOfSamplesBetweenTriggerStarts]; % Include the number of samples between the beginning of the recording and the first triggerstart
    [largeGaps,gapLocations] = findpeaks(numberOfSamplesBetweenTriggerStarts); % Find the largest gaps between trigger pulses. Returns some small gaps which must be eliminated in the next line.
    % !!! Construct if statement using diff to see if the pulse trigger is
    % perfectly timed.
    firstPulseInTrain = largeGaps > 2*mean(largeGaps); % THIS WILL FAIL AT FINDING TRIGGER STARTS IF THE FREQUENCY OF TRIGGER IMPULSES IS PERFECT BECAUSE ALL NUMBERS OF SAMPLES BETWEEN TRIGGER IMPULSES WILL EQUAL THE MEAN
    firstPulseInTrain = triggerstarts(gapLocations(firstPulseInTrain));
    firstPulseInTrain = [ons(1);firstPulseInTrain];

    [offTimeBetweenNewFrequencies,offIndexBetweenNewFrequencies] = findpeaks(firstPulseInTrain(2:end)-firstPulseInTrain(1:end-1));
    offTimeBetweenNewFrequencies = offTimeBetweenNewFrequencies > mean(offTimeBetweenNewFrequencies);
    firstPulseForParticularStimFrequency = firstPulseInTrain(offIndexBetweenNewFrequencies(offTimeBetweenNewFrequencies)+1);
    firstPulseForParticularStimFrequency = [ons(1);firstPulseForParticularStimFrequency];
catch
    disp('Trigger detection failed. Please examine regularity of TTL channel.')
    time = 0:1/fs:length(eeg)/fs-1/fs;
    plot(time,eeg)
    hold on
    plot(time,ttl.*300,'k')
end
time = 0:1/fs:length(eeg)/fs-1/fs;
plot(time,eeg)
hold on
plot(time,ttl.*300,'k')
plot(time(firstPulseInTrain),ttl(firstPulseInTrain).*300,'g^')
plot(time(lastPulseInTrain),ttl(lastPulseInTrain).*300,'ro')
% plot(time(firstPulseForParticularStimFrequency),ttl(firstPulseForParticularStimFrequency).*300,'md')

borders = [firstPulseForParticularStimFrequency;length(ttl)];
stimulationFrequencies = zeros(length(firstPulseForParticularStimFrequency),1);
for i = 2:length(borders)
    avgTimeBetweenPulses = 0;
    firstPulsesInFrequency = firstPulseInTrain(firstPulseInTrain >= borders(i-1));
    firstPulsesInFrequency = firstPulsesInFrequency(firstPulsesInFrequency < borders(i));
    lastPulsesInFrequency = lastPulseInTrain(lastPulseInTrain >= borders(i-1));
    lastPulsesInFrequency = lastPulsesInFrequency(lastPulsesInFrequency < borders(i));   
    for j = 1:length(firstPulsesInFrequency)
        %FLAW FOUND
        avgTimeBetweenPulses = avgTimeBetweenPulses + mean(numberOfSamplesBetweenTriggerStarts(triggerstarts(triggerstarts <= lastPulsesInFrequency(j)) > firstPulsesInFrequency(j)));
    end
    stimulationFrequencies(i-1) = round(1/(avgTimeBetweenPulses/(j*fs)));
end

samplestarts = triggerstarts-samplestart;
sampleends = triggerstarts+sampleend-1;
sampleends = sampleends(samplestarts > 0);
samplestarts = samplestarts(samplestarts > 0);
samplestarts = samplestarts(sampleends < length(eeg));
sampleends = sampleends(sampleends < length(eeg));
waves = zeros(length(sampleends),samplesperwave);
triggerBin = zeros(length(waves),1);
for i = 1:length(sampleends)
    waves(i,1:samplesperwave) = eeg(samplestarts(i):sampleends(i));
    triggerBin(i) = find(samplestarts(i) >= (firstPulseForParticularStimFrequency-samplestart),1,'last');
end


% Create the randoms
randoms = zeros(size(waves));
for i = 1:length(waves(:,1))
    startIndex = round((length(eeg)-samplesperwave)*rand());
    while any(ttl(startIndex:startIndex+samplesperwave-1))
        startIndex = round((length(eeg)-samplesperwave)*rand());
    end
    randoms(i,1:samplesperwave) = eeg(startIndex:startIndex+samplesperwave-1);
end

end

