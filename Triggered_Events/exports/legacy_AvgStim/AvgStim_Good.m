% The standard floxed output routine for 400 data points.
if findobj('type','figure')
    response = questdlg('Close all plots?','User Input Required','Yes','No','Yes');
    if strcmp(response,'Yes')
        close all;
    end
end

[files,path] = uigetfile({'*.edf','EDF Files (*.edf)';'*.*','All Files'},... % Open the user interface for opening files
'Select EDF File','MultiSelect','On');
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

response = questdlg('Export to Excel?','User Input Required','Yes','No','Yes');
if strcmp(response,'Yes')
    exportState = 1;
    Excel = actxserver('Excel.Application');
    set(Excel, 'Visible', 1);
    Workbooks = Excel.Workbooks;
%     Workbook.triggered = Excel.Workbooks.Open('C:\Users\wisorlab\Documents\Flox Testing Triggered Waveforms With Thy1 Animals.xlsx');
    Workbook.triggered = invoke(Workbooks, 'Add');
    sheetnames = {'1 Hz Wake','1 Hz REM','1 Hz SWS','1 Hz Unscored','10 Hz Wake','10 Hz REM','10 Hz SWS','10 Hz Unscored','20 Hz Wake','20 Hz REM','20 Hz SWS','20 Hz Unscored','40 Hz Wake','40 Hz REM','40 Hz SWS','40 Hz Unscored'};
    Sheets = Excel.ActiveWorkBook.Sheets;
    for i = 1:13
        invoke(Sheets,'Add');
    end
    for i = 1:16
        sheet = get(Sheets, 'Item', i);
        invoke(sheet, 'Activate');
        sheet.name = sheetnames{i};
    end
else
    exportState = 0;
end

response = questdlg('Plot results?','User Input Required','Yes','No','No');
if strcmp(response,'Yes')
    plotState = 1;
else
    plotState = 0;
end

rowCount = ones(16,1);
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
     
     if ~isempty(strfind(files{i},'NEF'))
         if str2double(files{i}(4:7)) > 1600
            if length(matrix(:,1)) > 23000*400
                matrix = matrix(1:23000*400,:);
            end
         end
     end
     % CIF Files have rows and columns reversed.
     
%      time = matrix(:,1);
     data = matrix(:,channelIndex);
%      ttl = matrix(:,ttlIndex);
    

%      if smoothState == 1
%          disp('Smoothing data...')
%          data = movingSmoothing(data,150);
%      end
%      
%      if filterState == 1
%         disp('Filtering data...');
%         data = filter60Hz(data);       
%      end
     
     disp('Finding trigger patterns...');
     msbefore = 500;
     msafter = 500;
     triggerPoint = msbefore/1000;
     [waves,randoms,stimFreqs,usedTriggers] = findVariableFrequencyTriggerPattern(data, matrix(:,ttlIndex), fs, msbefore, msafter, sleepdata);
     
     if isempty(waves)
         error('No TTL events found.');
     end
     
%      if artifactState == 1
%         waves = throwArtifacts(waves);
%         randoms = randoms(length(waves(:,1)));
%      end
     
     
     t = 0:1/fs:(msbefore+msafter)/1000-1/fs;
     strain = files{i}(1:3);
     animalID = files{i}(4:7);
     gender = files{i}(9);
     if strcmpi(strain,'cef') || strcmpi(strain,'nef')
         if ~isempty(strfind(lower(files{i}),'tamoxifen'))
             treatment = 'Tamoxifen';
             transgene = 'Yes';
         elseif ~isempty(strfind(lower(files{i}),'vehicle'))
             treatment = 'Vehicle';
             transgene = 'No';
         else
             treatment = 'Unknown';
             transgene = 'Unknown';
         end
     elseif strcmpi(strain,'cif') || strcmpi(strain,'thy')
         treatment = files{i}(11:12);
         if strcmpi(treatment,'++')
             transgene = 'Yes';
         else
             transgene = 'No';
         end
     end
     if strcmpi(strain,'thy')
        tenHzWaves = waves(13:16,:);
        waves(9:16,:) = waves(5:12,:);
        waves(5:8,:) = tenHzWaves;
     end

     if ~isempty(strfind(lower(files{i}),'cont'))
         intensity = 'Continuous';
     elseif ~isempty(strfind(lower(files{i}),'1turn'))
         intensity = '1 Turn';  
     elseif ~isempty(strfind(lower(files{i}),'10turn'))
         intensity = '10 Turns';
     elseif ~isempty(strfind(lower(files{i}),'baseline'))
         intensity = 'Baseline';
     else  
         intensity = 'No Turns';
     end
     sleepstateCount = 1;
     for j = 1:length(waves(:,1))
        if sleepstateCount == 1
            sleepstate = 'wake';
        elseif sleepstateCount == 2
            sleepstate = 'REM';
        elseif sleepstateCount == 3
            sleepstate = 'SWS';
        else
            sleepstate = 'unscored';
            sleepstateCount = 0;
        end
        if exportState == 1
            rowCount(j) = rowCount(j)+1;
            
            columnLabels = cell(1,7);
            columnLabels{1} = 'Gender';
            columnLabels{2} = 'Filename';
            columnLabels{3} = 'Strain';           
            columnLabels{4} = 'Animal ID';
            columnLabels{5} = 'Group';
            columnLabels{6} = 'Transgene?';
            columnLabels{7} = 'Intensity'; 
            
            columnInfo = cell(1,7);
            columnInfo{1} = gender;
            columnInfo{2} = files{i};
            columnInfo{3} = strain;
            columnInfo{4} = animalID;
            columnInfo{5} = treatment;
            columnInfo{6} = transgene;
            columnInfo{7} = intensity;           

            invoke(Workbook.triggered,'Activate');
            Sheets = Excel.ActiveWorkBook.Sheets;
            sheet = get(Sheets, 'Item', j);
            invoke(sheet, 'Activate');

            sheetRange = get(sheet,'Range','A1:G1');
            set(sheetRange, 'Value', columnLabels);

            sheetRange = get(sheet,'Range',['A',num2str(rowCount(j)),':G',num2str(rowCount(j))]);
            set(sheetRange, 'Value',columnInfo);
            
            timeRow = -msbefore/1000:1/fs:msafter/1000-1/fs;
            timeRowLabel = cell(1,2*length(timeRow)+1);
            for k = 1:length(timeRow)
                timeRowLabel{k} = ['Trig ', num2str(timeRow(k))];
            end
            
            
%             waves100 = avg4(waves);
%             randoms100 = avg4(randoms);
            
            timeRowLabel{k+1} = '';
            offset = k+1;
            
            for k = 1:length(timeRow)
                timeRowLabel{offset+k} = ['Rand ', num2str(timeRow(k))];
            end
            
            sheetRange = get(sheet,'Range',['H1:',xlscol(length(timeRowLabel)+7),'1']);
            set(sheetRange, 'Value', timeRowLabel);

            sheetRange = get(sheet,'Range',['H',num2str(rowCount(j)),':',xlscol(length(waves(j,:))+7),num2str(rowCount(j))]);
            set(sheetRange, 'Value', waves(j,:));
            
            sheetRange = get(sheet,'Range',[xlscol(length(waves(j,:))+9),num2str(rowCount(j)),':',xlscol(length(waves(j,:))+length(randoms(j,:))+8),num2str(rowCount(j))]);
            set(sheetRange, 'Value', randoms(j,:));
                
            sleepstateCount = sleepstateCount + 1;
        end
        if plotState == 1
            label = [type,' at ', num2str(stimFreqs(ceil(j/4))),' Hz during ', sleepstate,' in ',files{i}];
            fig = plotStimulationPattern3(t,waves(j,:),randoms(j,:),fs,units,label,triggerPoint,matrix(:,1),data,matrix(:,ttlIndex),usedTriggers{j},sleepdata);
        end
     end

end
if exportState == 1
    delete(Excel);
end
disp('Processing complete.');
    