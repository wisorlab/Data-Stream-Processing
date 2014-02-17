[files,path] = uigetfile({'*.txt','Text Files (*.txt)';'*.edf','EDF Files (*.edf)';'*.mat','MAT-files (*.mat)';'*.*','All Files'},... % Open the user interface for opening files
'Select Data File(s)','MultiSelect','On');
if ~iscell(files)
    if isequal(files,0)
        return;
    end
    % Turns the filename into a cell array
    % so the subsequent for loop works.
    file = files;
    files = cell(1,1);
    files{1} = file;
end

% Ask if the user wants high frequency noise reduction
% MAKE FILTER DESIGN WINDOW
response = questdlg('Filter high frequency noise?','User Input Required','Yes','No','Yes');
if strcmp(response,'Yes')
    filterState = 1;
else
    filterState = 0;
end

processSameChannel = 0;
for i = 1:length(files)
     [matrix, format, fs] = retrieveData(files{i},path);
     [~,~,ext] = fileparts(files{i});
     if processSameChannel == 0
        if strcmp(ext,'.edf') 
            % MAKE SURE TO REMOVE TTL FROM SELECTABLE CHANNELS
            [channelIndex,processSameChannel] = ChannelSelectDialog(format.label);
            channelIndex = channelIndex + 1; % offset from time column
            ttlIndex = find(ismember(format.label,'TTL'))+1;
        elseif strcmp(ext,'.txt')
            % MAKE TTL AND EEG SELECTION MORE ROBUST/RELIABLE
            [channelIndex,processSameChannel] = ChannelSelectDialog(format.label);
            channelIndex = channelIndex + 1; % offset from ttl column
            ttlIndex = 3;
        end
     end
     if processSameChannel == -1
         return;
     end
     
     time = matrix(:,1);
     channel = matrix(:,channelIndex);
     ttl = matrix(:,ttlIndex);
     
     disp('Smoothing data...')
     % OPTIMIZE SMOOTHING?
     driftCorrected = movingSmoothing(channel,150);
     
     if filterState == 1
        disp('Filtering data...');
        data = filter60Hz(driftCorrected);
     end
     
     disp('Finding trigger patterns...');
     [waves,randoms] = findTriggerPattern(time, data, ttl, fs);
     
     stimMean = mean(waves(:,1:end));
     randMean = mean(randoms(:,1:end));
     if nargin == 2 && export == 1
         disp('Exporting waves to Excel...');
         exportToExcel(filename,waves,randoms);
     end
     plotStimulationPattern(files{i},fs,time,channel,driftCorrected,ttl,waves,randoms,stimMean,randMean);
     %[stimMean,randMean] = UltrasoundVerification(files{i});
%             disp('Exporting waves to Excel...');
%             exportToExcel(files(i).name, stimMean, randMean, count)
%             count = count + 2;
end
    
% path = 'C:\Users\wisorlab\Documents\MATLAB\Matlab Scripts\Michele UltraSound Experiments\Batch Script\Real Time Trials';
% files = dir(path);
% count = 1;
% for i = 1:numel(files)
%     if files(i).isdir == 0
%         [~,name,ext] = fileparts(files(i).name);
%         disp(['Processing ', files(i).name]);
%         if strcmp(ext,'.txt')
%             [stimMean,randMean] = UltrasoundVerification(files(i).name);
% %             disp('Exporting waves to Excel...');
% %             exportToExcel(files(i).name, stimMean, randMean, count)
% %             count = count + 2;
%         end
%     end
% end
disp('Batch processing complete.');
    
