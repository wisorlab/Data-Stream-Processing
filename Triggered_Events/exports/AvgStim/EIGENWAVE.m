% Check if the user is going to load the same file
if exist('file','var')
    oldfile = file;
end

[files,path] = uigetfile({'*.txt','Text Files (*.txt)';'*.edf','EDF Files (*.edf)';'*.*','All Files'},... % Open the user interface for opening files
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

processSameChannel = 0;
for i = 1:length(files)

            [matrix, format, fs] = retrieveData(files{i},path);

     [~,~,ext] = fileparts(files{i});
     if processSameChannel == 0 % If we need to know which channels to process
        if strcmp(ext,'.edf') 
            ttlIndex = find(ismember(format.label,'TTL'))+1; % Find TTL column
            format.label(ttlIndex-1) = []; % Remove TTL from selectable channels
            [channelIndex,processSameChannel] = ChannelSelectDialog(format.label); % Open Dialog to select channel
            channelIndex = channelIndex + 1; % Offset the selected channel from the time column
        elseif strcmp(ext,'.txt')
            % MAKE TTL AND EEG SELECTION MORE ROBUST/RELIABLE
            format.label(ismember(format.label,'t')) = []; % Remove the time label from selectable channels
            [channelIndex,processSameChannel] = ChannelSelectDialog(format.label);
            
            channelIndex = channelIndex + 2; % offset from ttl column
            ttlIndex = 3;
        end
     end
     if processSameChannel == -1
         disp('Processing aborted.')
         return;
     end
     
     % CIF Files have rows and columns reversed.
     
     time = matrix(:,1);
     data = matrix(:,channelIndex);
     ttl = matrix(:,ttlIndex);
     
     if smoothState == 1
         disp('Smoothing data...')
         % OPTIMIZE SMOOTHING?
         data = movingSmoothing(data,150);
     end
     
     if filterState == 1
        disp('Filtering data...');
        data = filter60Hz(data);
     end
     
     disp('Finding trigger patterns...');
     [waves,randoms,wavestates] = findTriggerPattern(data, ttl, fs);
     
     
    A = [];
    N = zeros(2,1);
    count = 0;


    disp('Mapping wave similarities...');
    N(1) = length(waves(:,1));
    N(2) = length(randoms(:,1));
    avg = zeros(length(waves(1,:)),1);  % what will become the average wave
    waves = waves';
    randoms = randoms';
    %testwaves(:,5*(i-1)+1:5*(i-1)+5) = waves(:,N+1:N+5);
    %% Load US Waves

    for j = 1:N(1)
        A = [A,waves(:,j)];
        avg = avg + waves(:,j);
        count = count + 1;
    end
    
    for j = 1:N(2)
        A = [A,randoms(:,j)];
        avg = avg + randoms(:,j);
        count = count + 1;
    end

    avg = avg/count;

    for j = 1:sum(N)
       A(:,j) = A(:,j) - avg; 
    end

    [U,S,V] = svd(A,0);
    Phi = U(:,1:sum(N));
    Phi(:,1) = -Phi(:,1);

    for j = 1:N(1)
        US(:,j) = A(:,j)'*Phi(:,1:3);
    end

    for j = 1:N(1)
        RANDOM(:,j) = A(:,N(1)+j)'*Phi(:,1:3);
    end

    figure
    plot3(US(1,:),US(2,:),US(3,:),'ro');
    hold on
    plot3(RANDOM(1,:),RANDOM(2,:),RANDOM(3,:),'bo');
    title(['Single Value Decomposition of ', files{i}])
    legend('US','RANDOM')

end


