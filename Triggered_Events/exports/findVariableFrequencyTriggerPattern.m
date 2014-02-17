function [avgWave, randoms, stimulationFrequencies, usedTriggers] = findVariableFrequencyTriggerPattern(eeg, ttl, fs, msBefore, msAfter, sleepdata)
% [waves, randoms] = findTriggerPattern(eeg, ttl, fs, msBefore, msAfter)

% Function findTriggerPattern takes snapshots of each wave
% around a TTL triggered event, averages them, and takes random
% snapshots of the signal and averages those to create a control.

if nargin < 4
    msBefore = 100;
    msAfter = 200;
end

% Converts the sample window from milliseconds to sample indices
sampleStart = msBefore*fs/1000;
sampleEnd = msAfter*fs/1000;
samplesPerWave = sampleStart+sampleEnd; % The number of samples in each snapshot of triggered events

% figure
% time = 0:1/fs:length(eeg)/fs-1/fs;
% plot(time,eeg)
% hold on
% plot(time,ttl.*300,'k')

% Find all ttl on (i.e. ttl == 1).
ons = find(ttl > 0); 
ons = ons(ons < length(sleepdata)*fs*10);
% Find where the difference between the indeces of ons is not equal to one
% (i.e. the last ttl == 1 in each series of 1s). onEnds is a logical vector
% that returns true if the indeces of two points where the ttl == 1 are not adjacent.
onEnds = find(diff(ons) ~= 1); 

% Returns the indeces of the first on point in each trigger. 
% ons(1) is included because the function 'diff' in the previous
% line does not return the first trigger point
triggerStarts = [ons(1);ons(onEnds+1)]; 
% Returns the indeces of the last on point in each trigger.
% ons(end) is included because the function 'diff' in the 
% does not return the last trigger point
triggerEnds = [ons(onEnds);ons(end)]; 

numberOfSamplesBetweenTriggerStarts = triggerStarts(2:end)-triggerStarts(1:end-1);

 % Find the largest gaps between trigger pulses. Returns some small gaps which must be eliminated in the next line.
[largeGaps,gapLocations] = findpeaks(numberOfSamplesBetweenTriggerStarts);
lastPulseInTrain = largeGaps > 2*mean(largeGaps); % THIS WILL FAIL AT FINDING TRIGGER STARTS IF THE FREQUENCY OF TRIGGER IMPULSES IS PERFECT BECAUSE ALL NUMBERS OF SAMPLES BETWEEN TRIGGER IMPULSES WILL EQUAL THE MEAN
lastPulseInTrain = triggerStarts(gapLocations(lastPulseInTrain)); % Convert from a logical vector to a vector of indeces
lastPulseInTrain = [lastPulseInTrain;ons(onEnds(end)+1)]; % Add the last pulse in the recording

numberOfSamplesBetweenTriggerStarts = [ons(1);numberOfSamplesBetweenTriggerStarts]; % Include the number of samples between the beginning of the recording and the first triggerstart
[largeGaps,gapLocations] = findpeaks(numberOfSamplesBetweenTriggerStarts); % Find the largest gaps between trigger pulses. Returns some small gaps which must be eliminated in the next line.
% !!! Construct if statement using diff to see if the pulse trigger is
% perfectly timed.
firstPulseInTrain = largeGaps > 2*mean(largeGaps); % THIS WILL FAIL AT FINDING TRIGGER STARTS IF THE FREQUENCY OF TRIGGER IMPULSES IS PERFECT BECAUSE ALL NUMBERS OF SAMPLES BETWEEN TRIGGER IMPULSES WILL EQUAL THE MEAN
firstPulseInTrain = triggerStarts(gapLocations(firstPulseInTrain));
% Prevents adding faulty ttl triggers at the beginning of recordings.
firstPulseInTrain = [ons(1);firstPulseInTrain];

[~, numberOfSamplesBetweenTriggerStartsSortedIndeces] = sort(numberOfSamplesBetweenTriggerStarts);
firstPulseForStimFrequencyIndecesOfTriggerStarts = sort(numberOfSamplesBetweenTriggerStartsSortedIndeces(end-3:end));
firstPulseForStimFrequency = triggerStarts(firstPulseForStimFrequencyIndecesOfTriggerStarts);

% % Verify it worked with a plot.
% figure
% time = 0:1/fs:length(eeg)/fs-1/fs;
% plot(time,eeg)
% hold on
% plot(time,ttl.*300,'k')
% plot(time(firstPulseInTrain),ttl(firstPulseInTrain).*300,'g^')
% plot(time(lastPulseInTrain),ttl(lastPulseInTrain).*300,'ro')
% plot(time(firstPulseForStimFrequency),ttl(firstPulseForStimFrequency).*300,'md')
% 

% % Repeat the operation to find the beginning of each different stimulation
% % frequency
% [offTimeBetweenNewFrequencies,offIndexBetweenNewFrequencies] = findpeaks(firstPulseInTrain(2:end)-firstPulseInTrain(1:end-1));
% offTimeBetweenNewFrequencies = offTimeBetweenNewFrequencies > mean(offTimeBetweenNewFrequencies);
% firstPulseForStimFrequency = firstPulseInTrain(offIndexBetweenNewFrequencies(offTimeBetweenNewFrequencies)+1);
% firstPulseForStimFrequency = [ons(1);firstPulseForStimFrequency];

avgWave = zeros(length(firstPulseForStimFrequency)*4,samplesPerWave);
numOfWavesInState = zeros(length(firstPulseForStimFrequency)*4,2);
randoms = zeros(size(avgWave));
usedTriggers = cell(length(firstPulseForStimFrequency)*4,1);
numOfRandomWavesInState = zeros(length(firstPulseForStimFrequency)*4,2);
borders = [firstPulseForStimFrequency;length(ttl)];
stimulationFrequencies = zeros(length(firstPulseForStimFrequency),1);
for i = 2:length(borders)
    firstPulsesInFrequency = firstPulseInTrain(firstPulseInTrain >= borders(i-1));
    firstPulsesInFrequency = firstPulsesInFrequency(firstPulsesInFrequency < borders(i));
    lastPulsesInFrequency = lastPulseInTrain(lastPulseInTrain >= borders(i-1));
    lastPulsesInFrequency = lastPulsesInFrequency(lastPulsesInFrequency < borders(i));   
    samplesBetweenPulses = [];
    triggerStartsOfInterest = [];
    for j = 1:length(firstPulsesInFrequency)
        triggerStartsInStimFreq = triggerStarts(triggerStarts <= lastPulsesInFrequency(j)) > firstPulsesInFrequency(j);
        triggerStartsOfInterest = [triggerStartsOfInterest;triggerStarts(triggerStartsInStimFreq)];
        samplesBetweenPulses = [samplesBetweenPulses;numberOfSamplesBetweenTriggerStarts(triggerStartsInStimFreq)];
    end
%     stdSamplesBetweenPulses = std(samplesBetweenPulses);
%     meanSamplesBetweenPulses = mean(samplesBetweenPulses);
%     nonArtifacts = samplesBetweenPulses < meanSamplesBetweenPulses+stdSamplesBetweenPulses;
%     nonArtifacts = logical(nonArtifacts.*(samplesBetweenPulses > meanSamplesBetweenPulses-stdSamplesBetweenPulses));
%     samplesBetweenPulses = samplesBetweenPulses(nonArtifacts);
%     triggerStartsOfInterest = triggerStartsOfInterest(nonArtifacts);
    triggerStartsOfInterest = sort([firstPulsesInFrequency;triggerStartsOfInterest]);
    stimulationFrequencies(i-1) = round(1/(mean(samplesBetweenPulses)/fs));
    
    sampleStarts = triggerStartsOfInterest-sampleStart;
    sampleEnds = triggerStartsOfInterest+sampleEnd-1;
    sampleEnds = sampleEnds(sampleStarts > 0);
    sampleStarts = sampleStarts(sampleStarts > 0);
    sampleStarts = sampleStarts(sampleEnds < length(eeg));
    sampleEnds = sampleEnds(sampleEnds < length(eeg));

    for j = 1:length(sampleEnds)
        state = sleepdata(ceil(triggerStartsOfInterest(j)/4000));
        if state == 5
            continue;
        end
        avgWave(state+4*(i-2),1:samplesPerWave) = avgWave(state+4*(i-2),1:samplesPerWave)+eeg(sampleStarts(j):sampleEnds(j))';
        numOfWavesInState(state+4*(i-2),1) = numOfWavesInState(state+4*(i-2))+1;
        numOfWavesInState(state+4*(i-2),2) = find(sampleStarts(i) >= (firstPulseForStimFrequency-sampleStart),1,'last');
        usedTriggers{state+4*(i-2)} = [usedTriggers{state+4*(i-2)}, triggerStartsOfInterest(j)];
        
        startIndex = floor(sampleStarts(j)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch
        while any(ttl(startIndex:startIndex+samplesPerWave-1))
            startIndex = floor(sampleStarts(j)/4000)+round((10*fs-samplesPerWave)*rand());
        end
        randoms(state+4*(i-2),1:samplesPerWave) = randoms(state+4*(i-2),1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)';
        numOfRandomWavesInState(state+4*(i-2),1) = numOfRandomWavesInState(state+4*(i-2))+1;
        numOfRandomWavesInState(state+4*(i-2),2) = find(sampleStarts(i) >= (firstPulseForStimFrequency-sampleStart),1,'last');
    end
end

for i = 1:length(avgWave(:,1))
    if ~isempty(find(avgWave(i,:), 1))
        avgWave(i,:) = avgWave(i,:)./numOfWavesInState(i,1);
    end
    if ~isempty(find(randoms(i,:), 1))
        randoms(i,:) = randoms(i,:)./numOfRandomWavesInState(i,1);
    end
end

end

