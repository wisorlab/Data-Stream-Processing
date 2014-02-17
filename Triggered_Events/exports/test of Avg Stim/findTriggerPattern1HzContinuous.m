function [avgWave, randoms, triggerStarts] = findTriggerPattern(eeg, ttl, fs, msBefore, msAfter, sleepdata)
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

avgWave = zeros(4,samplesPerWave);
numOfWavesInState = zeros(4,2);
randoms = zeros(size(avgWave));
numOfRandomWavesInState = zeros(4,1);

    
sampleStarts = triggerStarts-sampleStart;
sampleEnds = triggerStarts+sampleEnd-1;
sampleEnds = sampleEnds(sampleStarts > 0);
sampleStarts = sampleStarts(sampleStarts > 0);
sampleStarts = sampleStarts(sampleEnds < length(eeg));
sampleEnds = sampleEnds(sampleEnds < length(eeg));

for i = 1:length(sampleEnds)
    state = sleepdata(ceil(triggerStarts(i)/4000));
    if state == 5
        continue;
    end
    avgWave(state,1:samplesPerWave) = avgWave(state,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';
    numOfWavesInState(state,1) = numOfWavesInState(state)+1;

    startIndex = floor(sampleStarts(i)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch

    randoms(state,1:samplesPerWave) = randoms(state,1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)';
    numOfRandomWavesInState(state,1) = numOfRandomWavesInState(state)+1;
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

