function [] = showContinuousRecords()
clear all; 
path = 'C:/Users/wisorlab/Documents/MATLAB/Matlab Scripts/Flox Testing/Data Files/';
files = dir(path);

processSameChannel = 0;
for i = 1:length(files)
    files(i)
     if ~isempty(strfind(files(i).name,'Cont')) && ~isempty(strfind(files(i).name,'with TTL Channel'))
         [matrix, format] = retrieveData(files(i).name,path);

         if processSameChannel == 0 % If we need to know which channels to process
                channelSelectLabel = format.label;
                ttlIndex = find(ismember(channelSelectLabel,'TTL'))+1; % Find TTL column and add one for the time column offset
                channelSelectLabel(ttlIndex-1) = []; % Remove TTL from selectable channels
                [channelIndex,processSameChannel] = ChannelSelectDialog(channelSelectLabel); % Open Dialog to select channel
                channelIndex = channelIndex + 1; % Offset the selected channel from the time column
         end

          if processSameChannel == -1
             disp('Processing aborted.')
             return;
          end

          time = matrix(:,1);
          data = matrix(:,channelIndex);
          ttl = matrix(:,ttlIndex);

          figure
          plot(time,data);
          hold on
          plot(time,ttl.*300,'r');
          title(files(i).name)
     end
end

end

