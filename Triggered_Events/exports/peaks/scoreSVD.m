function [] = scoreSVD()

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
    data = matrix(:,channelIndex);    

    if smoothState == 1
        disp('Smoothing data...')
        data = movingSmoothing(data,150);
    end

    if filterState == 1
        disp('Filtering data...');
        data = filter60Hz(data);       
    end
    
    A = [];
    avg = zeros(10*fs*(length(matrix(1,:))-1),1);
    
    wakeSnapShots = zeros(10*fs,length(matrix(1,:))-1,sum(sleepdata == 1));
    SWSSnapShots = zeros(10*fs,length(matrix(1,:))-1,sum(sleepdata == 2));
    REMSnapShots = zeros(10*fs,length(matrix(1,:))-1,sum(sleepdata == 3));
    wakeCount = 1;
    SWSCount = 1;
    REMCount = 1;
    totalCount = 0;
    for j = 1:length(sleepdata)
        if sleepdata(j) == 1
            wakeSnapShots(:,:,wakeCount) = matrix(10*fs*(j-1)+1:10*fs*(j-1)+10*fs,2:end);
            wakeCount = wakeCount + 1;
        elseif sleepdata(j) == 2
            SWSSnapShots(:,:,SWSCount) = matrix(10*fs*(j-1)+1:10*fs*(j-1)+10*fs,2:end);
            SWSCount = SWSCount + 1;
        elseif sleepdata(j) == 3
            REMSnapShots(:,:,REMCount) = matrix(10*fs*(j-1)+1:10*fs*(j-1)+10*fs,2:end);
            REMCount = REMCount + 1;
        end
        R = reshape(matrix(10*fs*(j-1)+1:10*fs*(j-1)+10*fs,2:end),10*fs*(length(matrix(1,:))-1),1);
        A = [A,R];
        avg = avg+R;
        totalCount = totalCount + 1;
    end
    avg = avg/totalCount;
    wakeAvg = sum(wakeSnapShots,3)./wakeCount;
    SWSSnapShots = sum(SWSSnapShots,3)./SWSCount;
    REMSnapShots = sum(REMSnapShots,3)./REMCount;
    
    %% Center the sample pictures at the "origin"
    for j = 1:totalCount
        A(:,j) = A(:,j) - avg;
%         R = reshape(A(:,j),10*fs,length(matrix(1,:))-1);
%         plot(R);
    end

    %%  Computing the SVD
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
    
    figure

    plot3(wakes(1,:),wakes(2,:),wakes(3,:),'ro')
    hold on
    plot3(swss(1,:),swss(2,:),swss(3,:),'bo')
    plot3(rems(1,:),rems(2,:),rems(3,:),'go')
    legend('Wake','SWS','REM');
end

end


