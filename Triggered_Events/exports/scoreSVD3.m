function [] = scoreSVD3()

[files,path] = uigetfile({'*.edf','EDF Files (*.edf)';'*.*','All Files'},... % Open the user interface for opening files
'Select EDF Files','MultiSelect','On');
if ~iscell(files)
    if isequal(files,0)
        return;
    end
    files = {files};
end

% Ask if the user wants to smooth the data.
response = questdlg('Smooth drift in signal?','User Input Required','Yes','No','No');
if strcmp(response,'Yes')
    smoothState = 1;
else
    smoothState = 0;
end

% Ask if the user wants high frequency noise reduction
% MAKE FILTER DESIGN WINDOW
response = questdlg('Filter high frequency noise?','User Input Required','Yes','No','No');
if strcmp(response,'Yes')
    filterState = 1;
else
    filterState = 0;
end


A = [];
avg = zeros(10*400*6,1);
processSameChannel = 0;
for i = 1:length(files)
    if ~isempty(strfind(files{i},'Baseline')) || ~isempty(strfind(files{i},'Cont')) || isempty(strfind(files{i},' with TTL Channel'))
        continue;
    end
    if ~isempty(strfind(files{i},' with TTL Channel'))
        commonFileName = files{i}(1:strfind(files{i},' with TTL Channel')-1);
    else
        commonFileName = files{i}(1:strfind(files{i},'.edf')-1);
    end
    fftfiles = dir(path);
    for j = 1:length(fftfiles)
       [~,name,ext] = fileparts(fftfiles(j).name);
       if strcmp(ext,'.txt') && ~isempty(strfind(name,commonFileName))
            disp(['Loading output data from ''', name,ext,'''...']);
            sleepdata = importFFTPowerFile([path,name,ext]);
            break;
       end
    end
    if ~exist('sleepdata','var')
        disp('No FFT file found. File not included.')
        break;
    end
    [matrix, format, fs] = retrieveData(files{i},path);
    
    [~,~,ext] = fileparts(files{i});
    if processSameChannel == 0 % If we need to know which channels to process
        channelSelectLabel = format.label;
        ttlIndex = find(ismember(channelSelectLabel,'TTL'))+1; % Find TTL column and add one for the time column offset
        channelSelectLabel(ttlIndex-1) = []; % Remove TTL from selectable channels
        [channelIndex,processSameChannel] = ChannelSelectDialog(channelSelectLabel); % Open Dialog to select channel
        type = channelSelectLabel(channelIndex);
        type = type{1};
        units = format.units(channelIndex);
        units = units{1};
        channelIndex = channelIndex + 1; % Offset the selected channel from the time column
    end
    if processSameChannel == -1
        disp('Processing aborted.')
        return;
    end
    matrix = matrix(1:length(sleepdata)*10*fs,:);
    for j = 2:length(matrix(1,:))-1
       matrix(:,j) = matrix(:,j)-mean(matrix(:,j)); 
    end
    data = matrix(:,channelIndex);    

    if smoothState == 1
        disp('Smoothing data...')
        data = movingSmoothing(data,150);
    end

    if filterState == 1
        disp('Filtering data...');
        data = filter60Hz(data);       
    end
    
    disp('Creating EEG snapshots...');

    totalCount = 0;
    for j = 1:length(sleepdata)
        R = reshape([matrix(10*fs*(j-1)+1:10*fs*(j-1)+10*fs,2:4),abs(fftshift(fft(matrix(10*fs*(j-1)+1:10*fs*(j-1)+10*fs,2:4))))],6*4000,1);
        A = [A,R];
        avg = avg+R;
        totalCount = totalCount + 1;
    end
    
end
    avg = avg/totalCount;

    
    %% Center the sample pictures at the "origin"
    for j = 1:totalCount
        A(:,j) = A(:,j) - avg;
    end

    %%  Computing the SVD
    disp('Computing single value decomposition...');
    [U,S,V] = svd(A,0);
    Phi = U(:,1:totalCount);
    Phi(:,1) = -1*Phi(:,1);
%     figure()
%     count = 1;
%     for i=1:3
%         for j=1:3
%             subplot(3,3,count)
%             imshow(uint8(25000*reshape(Phi(:,count),m,n)));
%             count = count + 1;
%         end
%     end


    %% project each image onto basis 
    disp('Projecting snapshots onto basis...');
    for j = 1:totalCount
        imvec = A(:,j);
        if sleepdata(j) == 1
            wakes(:,j) = imvec'*Phi(:,1:3);
        elseif sleepdata(j) == 2
            swss(:,j) = imvec'*Phi(:,1:3);
        elseif sleepdata(j) == 3
            rems(:,j) = imvec'*Phi(:,1:3);     
        end
    end
    
    wakeX = mean(wakes(1,:));
    wakeY = mean(wakes(2,:));
    wakeZ = mean(wakes(3,:));
    
    swssX = mean(swss(1,:));
    swssY = mean(swss(2,:));
    swssZ = mean(swss(3,:));
    
    remsX = mean(rems(1,:));
    remsY = mean(rems(2,:));
    remsZ = mean(rems(3,:));

    disp('Plotting results...');
    figure

    plot3(wakes(1,:),wakes(2,:),wakes(3,:),'r*')
    hold on
    plot3(swss(1,:),swss(2,:),swss(3,:),'b*')
    plot3(rems(1,:),rems(2,:),rems(3,:),'g*')
    plot3(wakeX,wakeY,wakeZ,'mo','LineWidth',5);
    plot3(swssX,swssY,swssZ,'co','LineWidth',5);
    plot3(remsX,remsY,remsZ,'yo','LineWidth',5);
    title(files{i});
    legend('Wake','SWS','REM','Wake Mean','SWS Mean','REM Mean');
    
    plotStimulationPattern3(['Human-Scored Output of ',files{i}],matrix(:,1),matrix(:,2),matrix(:,5),sleepdata)
    
end


