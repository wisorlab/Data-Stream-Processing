% A simple routine for verifying the average response of real time data.
% Does not support Excel output.
[files,path] = uigetfile({'*raw','Binary MCS Files (*.raw)';'*.*','All Files';'*.edf','EDF Files (*.edf)';'*.txt','Text Files (*.txt)';},... % Open the user interface for opening files
'Select Data File(s)','MultiSelect','On');
if ~iscell(files)
    if isequal(files,0)
        return;
    end
    % Turns the filename into a cell array
    % so the subsequent for loop works.
    files = {files};
end

predictedSampleRate = 5000;
msbefore = 1500;
msafter = 1500;
triggerPoint = msbefore/1000;
wavetimevector = -msbefore/1000:1/predictedSampleRate:msafter/1000-1/predictedSampleRate;
freq = linspace(-predictedSampleRate/2,predictedSampleRate/2,length(wavetimevector));
positiveFreqs = freq(sign(freq) >= 0);

% Ask if the user wants to smooth the data.
response = questdlg('Smooth drift in signal?','User Input Required','Yes','No','Yes');
if strcmp(response,'Yes')
    smoothState = 1;
else
    smoothState = 0;
end

% Ask if the user wants high frequency noise reduction
% MAKE FILTER DESIGN WINDOW
response = questdlg('Filter high frequency noise?','User Input Required','Yes','No','Yes');
if strcmp(response,'Yes')
    filterState = 1;
else
    filterState = 0;
end

% Ask if the user wants to remove artifacts
response = questdlg('Remove artifacts?','User Input Required','Yes','No','Yes');
if strcmp(response,'Yes')
    artifactState = 1;
else
    artifactState = 0;
end

processSameChannel = 0;
for i = 1:length(files)
     [matrix, format, fs] = retrieveData(files{i},path);
     [~,name,ext] = fileparts(files{i});
     if processSameChannel == 0 % If we need to know which channels to process
        if strcmp(ext,'.edf') 
            ttlIndex = find(ismember(format.label,'TTL'))+1; % Find TTL column
            format.label(ttlIndex-1) = []; % Remove TTL from selectable channels
            [channelIndex,processSameChannel] = ChannelSelectDialog(format.label); % Open Dialog to select channel
            units = format.units(channelIndex);
            units = units{1};
            channelIndex = channelIndex + 1; % Offset the selected channel from the time column
        elseif strcmp(ext,'.txt')
            % MAKE TTL AND EEG SELECTION MORE ROBUST/RELIABLE
            offset = 0;
            channelSelectLabel = format.label;
            if ~isempty(ismember(format.label,'t'))
                offset = 1;
                channelSelectLabel(ismember(channelSelectLabel,'t')) = []; % Remove the time label from selectable channels           
                channelSelectLabel(ismember(channelSelectLabel,'%t')) = [];
            end
            if ~isempty(strfind(channelSelectLabel,'Di'))
                ttlIndex = find(not(cellfun('isempty', strfind(channelSelectLabel,'Di D1 00'))))+offset;
                offset = offset + length(cell2mat(strfind(channelSelectLabel,'Di')));
                channelSelectLabel(not(cellfun('isempty', strfind(channelSelectLabel,'Di')))) = [];
            end
            [channelIndex,processSameChannel] = ChannelSelectDialog(channelSelectLabel);
            channelIndex = channelIndex + offset; % offset from ttl column
            units = 'mV';
        elseif strcmp(ext,'.raw')
            offset = 0;
            channelSelectLabel = format.label;
            if ~isempty(ismember(format.label,'t'))
                offset = 1;
                channelSelectLabel(ismember(channelSelectLabel,'t')) = []; % Remove the time label from selectable channels           
                channelSelectLabel(ismember(channelSelectLabel,'%t')) = [];
            end
            if ~isempty(strfind(channelSelectLabel,'Di'))
                ttlIndex = find(not(cellfun('isempty', strfind(channelSelectLabel,'Di_D1_00'))))+offset;
                if isempty(ttlIndex)
                    ttlIndex = find(not(cellfun('isempty', strfind(channelSelectLabel,'Di_D1'))))+offset;
                end
                offset = offset + length(cell2mat(strfind(channelSelectLabel,'Di')));
                channelSelectLabel(not(cellfun('isempty', strfind(channelSelectLabel,'Di')))) = [];
            end
            [channelIndex,processSameChannel] = ChannelSelectDialog(channelSelectLabel);
            channelIndex = channelIndex + offset; % offset from ttl column
            units = 'mV';
        end
     end
     type = format.label(channelIndex);
     type = type{1};
     if processSameChannel == -1
         disp('Processing aborted.')
         return;
     end
     
     data = matrix(:,channelIndex);
     data = data-mean(data);
     
     if smoothState == 1
         disp('Smoothing data...')
         data = movingSmoothing(data,150);
     end
     
     if filterState == 1
        disp('Filtering data...');
        data = filter60Hz(data);       
     end
     
     disp('Finding trigger patterns...');

     [waves,randoms,wavestates,samplestarts] = findTriggerPatternAllPulses(data, matrix(:,ttlIndex), fs, msbefore, msafter, triggerPoint, 2);
     
     if isempty(waves)
         error('No TTL events found.');
     end
     
     if artifactState == 1
         disp('Removing artifacts...')
         [waves, artifactIndeces] = throwArtifacts(waves);
         randoms = randoms(1:length(waves(:,1)),:);
     end
     stimMean = mean(waves);
     randMean = mean(randoms);
     [AbsolutePower,NormalizedPower] = CalculateFftPower(stimMean,fs,6,8,10)
     [RAbsolutePower,RNormalizedPower] = CalculateFftPower(randMean,fs,6,8,10)

    
    if smoothState == 1
        type = [type,' with Smoothing'];
    end
    if filterState == 1
        if smoothState == 1
            type = [type,' & Filtering'];
        else
            type = [type,' with Filtering'];
        end
    end
    if artifactState == 1
        if smoothState == 1 || filterState == 1
            type = [type,' & Artifact Removal'];
        else
            type = [type,' with Artifact Removal'];
        end
    end
    
     type = [type,' in ',files{i}];
     plotStimulationPattern2(fs,matrix(:,1),data,matrix(:,ttlIndex),waves,stimMean,randMean,type,units,triggerPoint);

     
end

disp('Processing complete.');