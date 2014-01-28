% Output routine for the Ultra Real Deal files
clearvars -EXCEPT stimMean1;

[files,path] = uigetfile({'*raw','Binary MCS Files (*.raw)';'*.*','All Files';'*.edf','EDF Files (*.edf)';'*.txt','Text Files (*.txt)';},... % Open the user interface for opening files
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

response = questdlg('Plot results?','User Input Required','Yes','No','Yes');
if strcmp(response,'Yes')
    plotState = 1;
else
    plotState = 0;
end

response = questdlg('Export to Excel?','User Input Required','Yes','No','No');
if strcmp(response,'Yes')
    exportState = 1;
    Excel = actxserver('Excel.Application');
    set(Excel, 'Visible', 1);
    Workbooks = Excel.Workbooks;
    Workbook = invoke(Workbooks, 'Add');
    Sheets = Excel.ActiveWorkBook.Sheets;
    invoke(Sheets,'Add');
    rowLabels = cell(7,1);
    rowLabels{1} = 'Time (s)';
    rowLabels{2} = '1Hz Opto';
    rowLabels{3} = '7Hz Opto';
    rowLabels{4} = '1Hz US';
    rowLabels{5} = '7Hz US';
    rowLabels{6} = '1Hz Control';
    rowLabels{7} = '7Hz Control';
    
    sheet = get(Sheets, 'Item', 2);
    invoke(sheet, 'Activate');
    sheet.name = 'Triggered Mean';
    Activesheet = Excel.Activesheet;
    ActivesheetRange = get(Activesheet,'Range','A1:A7');
    set(ActivesheetRange, 'Value', rowLabels);
    ActivesheetRange = get(Activesheet,'Range',['B1:',xlscol(length(wavetimevector)+1),num2str(1)]);
    set(ActivesheetRange, 'Value', wavetimevector);
        
    sheet = get(Sheets, 'Item', 4);
    invoke(sheet, 'Activate');
    sheet.name = 'Random Mean';
    Activesheet = Excel.Activesheet;
    ActivesheetRange = get(Activesheet,'Range','A1:A7');
    set(ActivesheetRange, 'Value', rowLabels);
    ActivesheetRange = get(Activesheet,'Range',['B1:',xlscol(length(wavetimevector)+1),num2str(1)]);
    set(ActivesheetRange, 'Value', wavetimevector);
    
    rowLabels{1} = 'Frequency (Hz)';
        
    sheet = get(Sheets, 'Item', 1);
    invoke(sheet, 'Activate');
    sheet.name = 'Triggered FFT';
    Activesheet = Excel.Activesheet;
    ActivesheetRange = get(Activesheet,'Range','A1:A7');
    set(ActivesheetRange, 'Value', rowLabels);
    ActivesheetRange = get(Activesheet,'Range',['B1:',xlscol(length(positiveFreqs)+1),num2str(1)]);
    set(ActivesheetRange, 'Value', positiveFreqs);
    
    sheet = get(Sheets, 'Item', 3);
    invoke(sheet, 'Activate');
    sheet.name = 'Random FFT';
    Activesheet = Excel.Activesheet;
    ActivesheetRange = get(Activesheet,'Range','A1:A7');
    set(ActivesheetRange, 'Value', rowLabels);
    ActivesheetRange = get(Activesheet,'Range',['B1:',xlscol(length(positiveFreqs)+1),num2str(1)]);
    set(ActivesheetRange, 'Value', positiveFreqs);
else
    exportState = 0;
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
     
     if fs ~= predictedSampleRate
        disp('Error: Please alter the variable predictedSampleRate in line 16 of AvgStim to the sampling frequency of the recordings'); 
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
     
     disp('Finding trigger patterns...');

     [waves,randoms,wavestates,samplestarts] = findTriggerPattern(data, matrix(:,ttlIndex), fs, msbefore, msafter, triggerPoint, 2);
     
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
     
     if plotState == 1
         type = [type,' in ',files{i}];
         plotStimulationPattern2(fs,matrix(:,1),data,matrix(:,ttlIndex),waves,stimMean,randMean,type,units,triggerPoint);
     end 
     
     if exportState == 1
        if ~isempty(strfind(lower(name),'1 hz'))
            if ~isempty(strfind(lower(name),'control'))
                row = '6';
            elseif ~isempty(strfind(lower(name),'us'))
                row = '4';
            elseif ~isempty(strfind(lower(name),'opto'))
                row = '2';
            else
                error('Stimulation type could not be identified.');
            end
        elseif ~isempty(strfind(lower(name),'7 hz'))
            if ~isempty(strfind(lower(name),'control'))
                row = '7';
            elseif ~isempty(strfind(lower(name),'us'))
                row = '5';
            elseif ~isempty(strfind(lower(name),'opto'))
                row = '3';
            else
                error('Stimulation type could not be identified.');
            end
        else
            error('Stimulation type could not be identified.');
        end
         

        trigffts = abs(fftshift(fft(stimMean)));
        randffts = abs(fftshift(fft(randMean)));
        
        sheet = get(Sheets, 'Item', 1);
        invoke(sheet, 'Activate');
        Activesheet = Excel.Activesheet;
        ActivesheetRange = get(Activesheet,'Range',['B',row,':',xlscol(length(trigffts(sign(freq) >= 0))+1),row]);
        set(ActivesheetRange, 'Value', trigffts(sign(freq) >= 0));
        
        sheet = get(Sheets, 'Item', 2);
        invoke(sheet, 'Activate');
        Activesheet = Excel.Activesheet;
        ActivesheetRange = get(Activesheet,'Range',['B',row,':',xlscol(length(stimMean)+1),row]);
        set(ActivesheetRange, 'Value', stimMean);
        
        sheet = get(Sheets, 'Item', 3);
        invoke(sheet, 'Activate');
        Activesheet = Excel.Activesheet;
        ActivesheetRange = get(Activesheet,'Range',['B',row,':',xlscol(length(randffts(sign(freq) >= 0))+1),row]);
        set(ActivesheetRange, 'Value', randffts(sign(freq) >= 0));
        
        sheet = get(Sheets, 'Item', 4);
        invoke(sheet, 'Activate');
        Activesheet = Excel.Activesheet;
        ActivesheetRange = get(Activesheet,'Range',['B',row,':',xlscol(length(randMean)+1),row]);
        set(ActivesheetRange, 'Value', randMean);
    end
end

if exportState == 1
    % Now save the workbook
    savename = ['1 Hz & 7 Hz US vs. Opto on ',name(1:8)];
    if smoothState == 1
        savename = [savename,' with Smoothing'];
    end
    if filterState == 1
        if smoothState == 1
            savename = [savename,' & 60Hz Filtering'];
        else
            savename = [savename,' with 60Hz Filtering'];
        end
    end
    if artifactState == 1
        if smoothState ==1 || filterState == 1
            savename = [savename,' & Artifact Removal'];
        else
            savename = [savename,' with Artifact Removal'];
        end
    end
           
    invoke(Workbook, 'SaveAs', [savename,'.xlsx']);

    % End process
    delete(Excel);
end
    
disp('Processing complete.');