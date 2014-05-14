function [avgWave, randoms, ttlonsets] = findTriggerPattern(eeg, ttl, fs, msBefore, msAfter, sleepdata)
% [waves, randoms] = findTriggerPattern(eeg, ttl, fs, msBefore, msAfter)

% Function findTriggerPattern takes snapshots of each wave in the eeg
% channel based on the ttl event detected in ttl.  
% around a TTL triggered event, averages them, and takes random
% snapshots of the signal and averages those to create a control.
%IMPORTANT: THIS ALGORITHM DOES NOT DETECT THE FREQUENCY OF STIMULATION!!!
%IT JUST OUTPUTS RESPONSES TO ALL STIMULI

if nargin < 4    %should never be the case, but assumes a 300 msec window if there are less than 6 inputs.      
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
ttlison = find(ttl > 0);  %
ttlison = ttlison(ttlison < length(sleepdata)*fs*10); %remove from consideration the data from beyond the end of the data matrix.
% Find where the difference between the indeces of ons is not equal to one
% (i.e. the last ttl == 1 in each series of 1s). onEnds is a logical vector
% that returns true if the indeces of two points where the ttl == 1 are not adjacent.
ttloffsets = find(diff(ttlison) ~= 1); %find the positions in the ttl track that are offsets; those for which the next detected ttl on value is not the next position in the ttl track.

% Returns the indeces of the first on point in each trigger. 
% ons(1) is included because the function 'diff' in the previous
% line does not return the first trigger point
ttlonsets = [ttlison(1);ttlison(ttloffsets+1)];  %generate a vector that concatenates  the first detected ttl with all ttl positions subsequent to those that are offsets. Those instances of ttl on that are the next ttl on after a ttl offset are by definition onsets.   
% Returns the indeces of the last on point in each trigger.
% ons(end) is included because the function 'diff' in the 
% does not return the last trigger point
triggerEnds = [ttlison(ttloffsets);ttlison(end)]; %make a vector of all those ttl offsets and add to them the last detected ttl, which is by definition a ttl offset. 

avgWave = zeros(4,samplesPerWave); %make a vector of zeros in preparation for generating an avg wave
numOfWavesInState = zeros(4,2);  % four rows, two columns
randoms = zeros(size(avgWave)); %make a vector of zeros in preparation for generating an avg random curve
numOfRandomWavesInState = zeros(4,1);  % four rows, one column

sampleStarts = ttlonsets-sampleStart; % find each ttlonset and go back in time to start snapshot.  
sampleEnds = ttlonsets+sampleEnd-1; % find each ttlonset and move forward in time to start snapshot.
sampleEnds = sampleEnds(sampleStarts > 0);  %only include those samples that start after time zero in the matrix.
sampleStarts = sampleStarts(sampleStarts > 0);  %only include those samples that start after time zero in the matrix.
sampleStarts = sampleStarts(sampleEnds < length(eeg));  %only include those samples that end before the end of the matrix.
sampleEnds = sampleEnds(sampleEnds < length(eeg)); %only include those samples that end before the end of the matrix.

for i = 1:length(sampleEnds)   %go through all detected data snippets one by one.
    state = sleepdata(ceil(ttlonsets(i)/4000));  %ceil rounds up the ttl onset divided by the number of data points in an epoch.  This tells us which epoch in teh vector 'state' to get our state from.  
    if state == 5
        continue;   %if there is an artifact, skip this loop for this particular stim onset.
    end
    avgWave(state,1:samplesPerWave) = avgWave(state,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';  %adds the eeg values to the appropriate row of the average wave matrix, based on state.
    numOfWavesInState(state,1) = numOfWavesInState(state)+1;   % 

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

