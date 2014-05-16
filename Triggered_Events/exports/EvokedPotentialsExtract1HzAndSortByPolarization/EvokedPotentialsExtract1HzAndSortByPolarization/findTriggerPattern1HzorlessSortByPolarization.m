function [avgWave, randoms, ttlonsets] = findTriggerPattern1Hzorless(eeg, ttl, fs, msBefore, msAfter, sleepdata, Threshold)
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

WhileCount=0;

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
ttlison = find(ttl > 0) ;  %
ttlison = ttlison(ttlison < length(sleepdata)*fs*10); %remove from consideration the data from beyond the end of the data matrix.
% Find where the difference between the indeces of ons is not equal to one
% (i.e. the last ttl == 1 in each series of 1s). onEnds is a logical vector
% that returns true if the indeces of two points where the ttl == 1 are not adjacent.
ttloffsets = find(diff(ttlison) ~= 1); %find the positions in the ttl track that are offsets; those for which the next detected ttl on value is not the next position in the ttl track.
ttlfollowedbymoretthanahalfsecondoff = find(diff(ttlison) > fs*0.5); %find the positions in the ttl track that are followed by at least 0.5 seconds free of a ttl signal.
ttlonsets = ttlison(ttlfollowedbymoretthanahalfsecondoff+1); %above line means that each ttl point thereafter is a ttl start free of any ttl in the previous 500 msec

triggerEnds = [ttlison(ttloffsets);ttlison(end)]; %make a vector of all those ttl offsets and add to them the last detected ttl, which is by definition a ttl offset.

sampleStarts = ttlonsets-sampleStart; % find each ttlonset and go back in time to start snapshot.
sampleEnds = ttlonsets+sampleEnd-1; % find each ttlonset and move forward in time to start snapshot.
sampleEnds = sampleEnds(sampleStarts > 0);  %only include those samples that start after time zero in the matrix.
sampleStarts = sampleStarts(sampleStarts > 0);  %only include those samples that start after time zero in the matrix.
sampleStarts = sampleStarts(sampleEnds < length(eeg));  %only include those samples that end before the end of the matrix.
sampleEnds = sampleEnds(sampleEnds < length(eeg)); %only include those samples that end before the end of the matrix.

avgWave = zeros(12,samplesPerWave); % 12 averaged waves must be generated: WakePos,WakeNeut,WakeNeg,RemsPos,RemsNeut,RemsNeg,SwsPos,SwsNeut,SwsNeg
numOfWavesInState = zeros(12);      % number indiv waves contributing to each of 12 averaged waves must be counted.
randoms = zeros(size(avgWave));    % 12 averaged random curves must be generated: WakePos,WakeNeut,WakeNeg,RemsPos,RemsNeut,RemsNeg,SwsPos,SwsNeut,SwsNeg
numOfRandomWavesInState = zeros(12,1);   % four rows, two columns. This is an event counter for # randoms each state. Each row= a state; not clear what the second column is there for.

for i = 1:length(sampleEnds)   %go through all detected data snippets one by one.
    state = sleepdata(ceil(ttlonsets(i)/4000));  %ceil rounds up the ttl onset divided by the number of data points in an epoch.  This tells us which epoch in teh vector 'state' to get our state from.
    if state == 5
        continue;   %if there is an artifact, skip this loop for this particular stim onset.
    end
    Polarization = mean(eeg(sampleStarts(i)+sampleStart-11:sampleStarts(i)+sampleStart-1));
    
    if state==1 && Polarization < -Threshold
        avgWave(1,1:samplesPerWave) = avgWave(1,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';  %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfWavesInState(1) = numOfWavesInState(1)+1;   %count the number of waves in rows, each corresponding to a unique state.
        startIndex=sampleStarts(i);
        while max(ttl(startIndex:startIndex+samplesPerWave-1))>0 %this loop repeats until a segment of data devoid of any ttl signal is found.  Only then can the segment be included as a random fluctuation.
            startIndex = floor(sampleStarts(i)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch
            % '10*fs-samplesPerWave' calculates the # samples per 10-sec epoch minus the number samples per snippet.
            % 'round((10*fs-samplesPerWave)*rand())' multiplies this by a random
            % number btwn 0 and 1 to get a starting point somewhere between the start of an epoch and the latest possible start  that still contains data exclusively from that epoch.
            % 'floor(sampleStarts(i)/4000)' orients the random snippet relative to the start of the epoch.
        end
        randoms(1,1:samplesPerWave) = randoms(1,1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)'; %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfRandomWavesInState(1) = numOfRandomWavesInState(1)+1;
    
    elseif state==1 && Polarization < Threshold
        avgWave(2,1:samplesPerWave) = avgWave(2,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';  %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfWavesInState(2) = numOfWavesInState(2)+1;   %count the number of waves in rows, each corresponding to a unique state.
        startIndex=sampleStarts(i);
        while max(ttl(startIndex:startIndex+samplesPerWave-1))>0 %this loop repeats until a segment of data devoid of any ttl signal is found.  Only then can the segment be included as a random fluctuation.
            startIndex = floor(sampleStarts(i)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch
            % '10*fs-samplesPerWave' calculates the 1 samples per 10-sec epoch minus the number samples per snippet.
            % 'round((10*fs-samplesPerWave)*rand())' multiplies this by a random
            % number btwn 0 and 1 to get a starting point somewhere between the start of an epoch and the latest possible start  that still contains data exclusively from that epoch.
            % 'floor(sampleStarts(i)/4000)' orients the random snippet relative to the start of the epoch.
        end
        randoms(2,1:samplesPerWave) = randoms(2,1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)'; %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfRandomWavesInState(2) = numOfRandomWavesInState(2)+1;
    
    elseif state==1 && Polarization > Threshold
        avgWave(3,1:samplesPerWave) = avgWave(3,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';  %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfWavesInState(3) = numOfWavesInState(3)+1;   %count the number of waves in rows, each corresponding to a unique state.
        startIndex=sampleStarts(i);
        while max(ttl(startIndex:startIndex+samplesPerWave-1))>0 %this loop repeats until a segment of data devoid of any ttl signal is found.  Only then can the segment be included as a random fluctuation.
            startIndex = floor(sampleStarts(i)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch
            % '10*fs-samplesPerWave' calculates the # samples per 10-sec epoch minus the number samples per snippet.
            % 'round((10*fs-samplesPerWave)*rand())' multiplies this by a random
            % number btwn 0 and 1 to get a starting point somewhere between the start of an epoch and the latest possible start  that still contains data exclusively from that epoch.
            % 'floor(sampleStarts(i)/4000)' orients the random snippet relative to the start of the epoch.
        end
        randoms(3,1:samplesPerWave) = randoms(3,1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)'; %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfRandomWavesInState(3) = numOfRandomWavesInState(3)+1;
    
    elseif state==2 && Polarization < -Threshold
        avgWave(4,1:samplesPerWave) = avgWave(4,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';  %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfWavesInState(4) = numOfWavesInState(4)+1;   %count the number of waves in rows, each corresponding to a unique state.
        startIndex=sampleStarts(i);
        while max(ttl(startIndex:startIndex+samplesPerWave-1))>0 %this loop repeats until a segment of data devoid of any ttl signal is found.  Only then can the segment be included as a random fluctuation.
            startIndex = floor(sampleStarts(i)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch
            % '10*fs-samplesPerWave' calculates the # samples per 10-sec epoch minus the number samples per snippet.
            % 'round((10*fs-samplesPerWave)*rand())' multiplies this by a random
            % number btwn 0 and 1 to get a starting point somewhere between the start of an epoch and the latest possible start  that still contains data exclusively from that epoch.
            % 'floor(sampleStarts(i)/4000)' orients the random snippet relative to the start of the epoch.
        end
        randoms(4,1:samplesPerWave) = randoms(4,1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)'; %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfRandomWavesInState(4) = numOfRandomWavesInState(4)+1;
    
    elseif state==2 && Polarization < Threshold
        avgWave(5,1:samplesPerWave) = avgWave(5,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';  %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfWavesInState(5) = numOfWavesInState(5)+1;   %count the number of waves in rows, each corresponding to a unique state.
        startIndex=sampleStarts(i);
        while max(ttl(startIndex:startIndex+samplesPerWave-1))>0 %this loop repeats until a segment of data devoid of any ttl signal is found.  Only then can the segment be included as a random fluctuation.
            startIndex = floor(sampleStarts(i)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch
            % '10*fs-samplesPerWave' calculates the # samples per 10-sec epoch minus the number samples per snippet.
            % 'round((10*fs-samplesPerWave)*rand())' multiplies this by a random
            % number btwn 0 and 1 to get a starting point somewhere between the start of an epoch and the latest possible start  that still contains data exclusively from that epoch.
            % 'floor(sampleStarts(i)/4000)' orients the random snippet relative to the start of the epoch.
        end
        randoms(5,1:samplesPerWave) = randoms(5,1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)'; %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfRandomWavesInState(5) = numOfRandomWavesInState(5)+1;
    
    elseif state==2 && Polarization > Threshold
        avgWave(6,1:samplesPerWave) = avgWave(6,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';  %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfWavesInState(6) = numOfWavesInState(6)+1;   %count the number of waves in rows, each corresponding to a unique state.
        startIndex=sampleStarts(i);
        while max(ttl(startIndex:startIndex+samplesPerWave-1))>0 %this loop repeats until a segment of data devoid of any ttl signal is found.  Only then can the segment be included as a random fluctuation.
            startIndex = floor(sampleStarts(i)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch
            % '10*fs-samplesPerWave' calculates the # samples per 10-sec epoch minus the number samples per snippet.
            % 'round((10*fs-samplesPerWave)*rand())' multiplies this by a random
            % number btwn 0 and 1 to get a starting point somewhere between the start of an epoch and the latest possible start  that still contains data exclusively from that epoch.
            % 'floor(sampleStarts(i)/4000)' orients the random snippet relative to the start of the epoch.
        end
        randoms(6,1:samplesPerWave) = randoms(6,1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)'; %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfRandomWavesInState(6) = numOfRandomWavesInState(6)+1;
    
    elseif state==3 && Polarization < -Threshold
        avgWave(7,1:samplesPerWave) = avgWave(7,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';  %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfWavesInState(7) = numOfWavesInState(7)+1;   %count the number of waves in rows, each corresponding to a unique state.
        startIndex=sampleStarts(i);
        while max(ttl(startIndex:startIndex+samplesPerWave-1))>0 %this loop repeats until a segment of data devoid of any ttl signal is found.  Only then can the segment be included as a random fluctuation.
            startIndex = floor(sampleStarts(i)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch
            % '10*fs-samplesPerWave' calculates the # samples per 10-sec epoch minus the number samples per snippet.
            % 'round((10*fs-samplesPerWave)*rand())' multiplies this by a random
            % number btwn 0 and 1 to get a starting point somewhere between the start of an epoch and the latest possible start  that still contains data exclusively from that epoch.
            % 'floor(sampleStarts(i)/4000)' orients the random snippet relative to the start of the epoch.
        end
        randoms(7,1:samplesPerWave) = randoms(7,1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)'; %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfRandomWavesInState(7) = numOfRandomWavesInState(7)+1;
    
    elseif state==3 && Polarization < Threshold
        avgWave(8,1:samplesPerWave) = avgWave(8,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';  %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfWavesInState(8) = numOfWavesInState(8)+1;   %count the number of waves in rows, each corresponding to a unique state.
        startIndex=sampleStarts(i);
        while max(ttl(startIndex:startIndex+samplesPerWave-1))>0 %this loop repeats until a segment of data devoid of any ttl signal is found.  Only then can the segment be included as a random fluctuation.
            startIndex = floor(sampleStarts(i)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch
            % '10*fs-samplesPerWave' calculates the # samples per 10-sec epoch minus the number samples per snippet.
            % 'round((10*fs-samplesPerWave)*rand())' multiplies this by a random
            % number btwn 0 and 1 to get a starting point somewhere between the start of an epoch and the latest possible start  that still contains data exclusively from that epoch.
            % 'floor(sampleStarts(i)/4000)' orients the random snippet relative to the start of the epoch.
        end
        randoms(8,1:samplesPerWave) = randoms(8,1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)'; %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfRandomWavesInState(8) = numOfRandomWavesInState(8)+1;
    
    elseif state==3 && Polarization > Threshold
        avgWave(9,1:samplesPerWave) = avgWave(9,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';  %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfWavesInState(9) = numOfWavesInState(9)+1;   %count the number of waves in rows, each corresponding to a unique state.
        startIndex=sampleStarts(i);
        while max(ttl(startIndex:startIndex+samplesPerWave-1))>0 %this loop repeats until a segment of data devoid of any ttl signal is found.  Only then can the segment be included as a random fluctuation.
            startIndex = floor(sampleStarts(i)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch
            % '10*fs-samplesPerWave' calculates the # samples per 10-sec epoch minus the number samples per snippet.
            % 'round((10*fs-samplesPerWave)*rand())' multiplies this by a random
            % number btwn 0 and 1 to get a starting point somewhere between the start of an epoch and the latest possible start  that still contains data exclusively from that epoch.
            % 'floor(sampleStarts(i)/4000)' orients the random snippet relative to the start of the epoch.
        end
        randoms(9,1:samplesPerWave) = randoms(9,1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)'; %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfRandomWavesInState(9) = numOfRandomWavesInState(9)+1;
    
    elseif            Polarization < -Threshold
        avgWave(10,1:samplesPerWave) = avgWave(10,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';  %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfWavesInState(10) = numOfWavesInState(10)+1;   %count the number of waves in rows, each corresponding to a unique state.
        startIndex=sampleStarts(i);
        while max(ttl(startIndex:startIndex+samplesPerWave-1))>0 %this loop repeats until a segment of data devoid of any ttl signal is found.  Only then can the segment be included as a random fluctuation.
            startIndex = floor(sampleStarts(i)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch
            % '10*fs-samplesPerWave' calculates the # samples per 10-sec epoch minus the number samples per snippet.
            % 'round((10*fs-samplesPerWave)*rand())' multiplies this by a random
            % number btwn 0 and 1 to get a starting point somewhere between the start of an epoch and the latest possible start  that still contains data exclusively from that epoch.
            % 'floor(sampleStarts(i)/4000)' orients the random snippet relative to the start of the epoch.
        end
        randoms(10,1:samplesPerWave) = randoms(10,1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)'; %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfRandomWavesInState(10) = numOfRandomWavesInState(10)+1;
    
    elseif            Polarization < Threshold
        avgWave(11,1:samplesPerWave) = avgWave(11,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';  %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfWavesInState(11) = numOfWavesInState(11)+1;   %count the number of waves in rows, each corresponding to a unique state.
        startIndex=sampleStarts(i);
        while max(ttl(startIndex:startIndex+samplesPerWave-1))>0 %this loop repeats until a segment of data devoid of any ttl signal is found.  Only then can the segment be included as a random fluctuation.
            startIndex = floor(sampleStarts(i)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch
            % '10*fs-samplesPerWave' calculates the # samples per 10-sec epoch minus the number samples per snippet.
            % 'round((10*fs-samplesPerWave)*rand())' multiplies this by a random
            % number btwn 0 and 1 to get a starting point somewhere between the start of an epoch and the latest possible start  that still contains data exclusively from that epoch.
            % 'floor(sampleStarts(i)/4000)' orients the random snippet relative to the start of the epoch.
        end
        randoms(11,1:samplesPerWave) = randoms(11,1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)'; %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfRandomWavesInState(11) = numOfRandomWavesInState(11)+1;
    
    elseif            Polarization > Threshold
        avgWave(12,1:samplesPerWave) = avgWave(12,1:samplesPerWave)+eeg(sampleStarts(i):sampleEnds(i))';  %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfWavesInState(12) = numOfWavesInState(12)+1;   %count the number of waves in rows, each corresponding to a unique state.
        startIndex=sampleStarts(i);
        while max(ttl(startIndex:startIndex+samplesPerWave-1))>0 %this loop repeats until a segment of data devoid of any ttl signal is found.  Only then can the segment be included as a random fluctuation.
            startIndex = floor(sampleStarts(i)/4000)+round((10*fs-samplesPerWave)*rand()); % A random start point in the ten second window of an epoch
            % '10*fs-samplesPerWave' calculates the # samples per 10-sec epoch minus the number samples per snippet.
            % 'round((10*fs-samplesPerWave)*rand())' multiplies this by a random
            % number btwn 0 and 1 to get a starting point somewhere between the start of an epoch and the latest possible start  that still contains data exclusively from that epoch.
            % 'floor(sampleStarts(i)/4000)' orients the random snippet relative to the start of the epoch.
        end
        randoms(12,1:samplesPerWave) = randoms(12,1:samplesPerWave)+eeg(startIndex:startIndex+samplesPerWave-1)'; %adds the eeg values to the appropriate row of the average wave matrix, based on state.
        numOfRandomWavesInState(12) = numOfRandomWavesInState(12)+1;
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

for statecount=1:length(avgWave(:,1))
    if max(avgWave(statecount,:))==0 &&  min(avgWave(statecount,:))==0 
        avgWave(statecount,:)=nan;
        randoms(statecount,:)=nan;
    end
end        

end

