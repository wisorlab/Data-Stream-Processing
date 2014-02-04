% An output routine for dose response data that outputs 
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
msbefore = 800;
msafter = 800;
triggerPoint = msbefore/1000;
timeRow = -msbefore/1000:1/predictedSampleRate:msafter/1000-1/predictedSampleRate;
freq = linspace(-predictedSampleRate/2,predictedSampleRate/2,length(timeRow));
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
    TraceWorkbook = invoke(Workbooks, 'Add');
    Sheets = Excel.ActiveWorkBook.Sheets;
    invoke(Sheets,'Add');
    columnLabels = cell(1,2*length(timeRow)+4);
    columnLabels{1} = 'Filename';
    columnLabels{2} = 'Stimulus';
    columnLabels{3} = 'Duration';

    for k = 4:length(timeRow)+3
        columnLabels{k} = ['Trig ', num2str(timeRow(k-3))];
    end

    columnLabels{k+1} = '';
    offset = k+1;

    for k = 1:length(timeRow)
        columnLabels{offset+k} = ['Rand ', num2str(timeRow(k))];
    end
    
    freqRow = cell(1,2*length(positiveFreqs)+4);
    freqRow(1:3) = columnLabels(1:3);
    
    for k = 4:length(positiveFreqs)+3
        freqRow{k} = ['Trig ', num2str(positiveFreqs(k-3))];
    end

    freqRow{k+1} = '';
    offset = k+1;

    for k = 1:length(positiveFreqs)
        freqRow{offset+k} = ['Rand ', num2str(positiveFreqs(k))];
    end
    
    smallTimeVector = -msbefore/1000:10/predictedSampleRate:msafter/1000-10/predictedSampleRate;
    
    smallColumnLabels = cell(1,2*length(smallTimeVector)+4);
    smallColumnLabels{1} = 'Filename';
    smallColumnLabels{2} = 'Stimulus';
    smallColumnLabels{3} = 'Duration';

    for k = 4:length(smallTimeVector)+3
        smallColumnLabels{k} = ['Trig ', num2str(smallTimeVector(k-3))];
    end

    smallColumnLabels{k+1} = '';
    offset = k+1;

    for k = 1:length(smallTimeVector)
        smallColumnLabels{offset+k} = ['Rand ', num2str(smallTimeVector(k))];
    end
    
    sheet = get(Sheets, 'Item', 1);
    invoke(sheet, 'Activate');
    sheet.name = '5000 Hz';
    Activesheet = Excel.Activesheet;
    ActivesheetRange = get(Activesheet,'Range',['A1:',xlscol(length(columnLabels)),'1']);
    set(ActivesheetRange, 'Value', columnLabels);
    
    sheet = get(Sheets, 'Item', 3);
    invoke(sheet, 'Activate');
    sheet.name = '5000 Hz Filtered';
    Activesheet = Excel.Activesheet;
    ActivesheetRange = get(Activesheet,'Range',['A1:',xlscol(length(columnLabels)),'1']);
    set(ActivesheetRange, 'Value', columnLabels);
        
    sheet = get(Sheets, 'Item', 2);
    invoke(sheet, 'Activate');
    sheet.name = '500 Hz';
    Activesheet = Excel.Activesheet;
    ActivesheetRange = get(Activesheet,'Range',['A1:',xlscol(length(smallColumnLabels)),'1']);
    set(ActivesheetRange, 'Value', smallColumnLabels);
    
    sheet = get(Sheets, 'Item', 4);
    invoke(sheet, 'Activate');
    sheet.name = '500 Hz Filtered';
    Activesheet = Excel.Activesheet;
    ActivesheetRange = get(Activesheet,'Range',['A1:',xlscol(length(smallColumnLabels)),'1']);
    set(ActivesheetRange, 'Value', smallColumnLabels);
    
    FFTWorkbook = invoke(Workbooks, 'Add');
    Sheets = Excel.ActiveWorkBook.Sheets;
    sheet = get(Sheets, 'Item', 3);
    invoke(sheet, 'Delete');
    
    sheet = get(Sheets, 'Item', 1);
    invoke(sheet, 'Activate');
    sheet.name = '5000 Hz';
    Activesheet = Excel.Activesheet;
    ActivesheetRange = get(Activesheet,'Range',['A1:',xlscol(length(freqRow)),'1']);
    set(ActivesheetRange, 'Value', freqRow);
    
    sheet = get(Sheets, 'Item', 2);
    invoke(sheet, 'Activate');
    sheet.name = '5000 Hz Filtered';
    Activesheet = Excel.Activesheet;
    ActivesheetRange = get(Activesheet,'Range',['A1:',xlscol(length(freqRow)),'1']);
    set(ActivesheetRange, 'Value', freqRow);
    
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
     
     
     disp('Finding trigger patterns...');

     [waves,randoms,wavestates,samplestarts] = findTriggerPattern(data, matrix(:,ttlIndex), fs, msbefore, msafter, triggerPoint, 2);
     
     filtData = filter60Hz(data); 
     [filtWaves,filtRandoms] = findTriggerPattern(filtData, matrix(:,ttlIndex), fs, msbefore, msafter, triggerPoint, 2);
     
     if isempty(waves)
         error('No TTL events found.');
     end
     
     if artifactState == 1
         disp('Removing artifacts...')
         [waves, artifactIndeces] = throwArtifacts(waves);
         randoms = randoms(1:length(waves(:,1)),:);
         filtWaves = throwArtifacts(filtWaves);
         filtRandoms = filtRandoms(1:length(filtWaves(:,1)),:);
     end
     stimMean = mean(waves);
     randMean = mean(randoms);
     
     filtStimMean = mean(filtWaves);
     filtRandMean = mean(filtRandoms);
     
     if plotState == 1
         type = [type,' in ',files{i}];
         plotStimulationPattern2(fs,matrix(:,1),data,matrix(:,ttlIndex),waves,stimMean,randMean,type,units,triggerPoint);
     end 
     
     if exportState == 1
        if ~isempty(strfind(lower(name),'led'))
            stimType = 'LED';
        elseif ~isempty(strfind(lower(name),'us'))
            stimType = 'US';
        else
            stimType = 'Unknown';
        end
         
        if ~isempty(strfind(lower(name),'10ms')) || ~isempty(strfind(lower(name),'10 ms'))
            intensity = '10ms';
        elseif ~isempty(strfind(lower(name),'5ms')) || ~isempty(strfind(lower(name),'5 ms'))
            intensity = '5ms';
        elseif ~isempty(strfind(lower(name),'2.5ms')) || ~isempty(strfind(lower(name),'2.5 ms'))
            intensity = '2.5ms';
        elseif ~isempty(strfind(lower(name),'1ms')) || ~isempty(strfind(lower(name),'1 ms'))
            intensity = '1ms';
        elseif ~isempty(strfind(lower(name),'0.5ms')) || ~isempty(strfind(lower(name),'0.5 ms'))
            intensity = '0.5ms';
        end 
         

        trigffts = abs(fftshift(fft(stimMean)));
        trigffts = trigffts(sign(freq) >= 0);
        randffts = abs(fftshift(fft(randMean)));
        randffts = randffts(sign(freq) >= 0);

        fftOutput = cell(1,length(trigffts)+length(randffts)+4);
        fftOutput{1} = files{i};
        fftOutput{2} = stimType;
        fftOutput{3} = intensity;
        fftOutput(4:length(trigffts)+3) = num2cell(trigffts);
        fftOutput{length(trigffts)+4} = '';
        fftOutput(length(trigffts)+5:length(trigffts)+length(randffts)+4) = num2cell(randffts);
        
        filtTrigffts = abs(fftshift(fft(filtStimMean)));
        filtTrigffts = filtTrigffts(sign(freq) >= 0);
        filtRandffts = abs(fftshift(fft(filtRandMean)));
        filtRandffts = filtRandffts(sign(freq) >= 0);
        
        filtFftOutput = cell(1,length(filtTrigffts)+length(filtRandffts)+4);
        filtFftOutput{1} = files{i};
        filtFftOutput{2} = stimType;
        filtFftOutput{3} = intensity;
        filtFftOutput(4:length(filtTrigffts)+3) = num2cell(filtTrigffts);
        filtFftOutput{length(filtTrigffts)+4} = '';
        filtFftOutput(length(filtTrigffts)+5:length(filtTrigffts)+length(filtRandffts)+4) = num2cell(filtRandffts);        
        
        invoke(FFTWorkbook,'Activate')
        Sheets = Excel.ActiveWorkBook.Sheets;
        
        sheet = get(Sheets, 'Item', 1);
        invoke(sheet, 'Activate');
        Activesheet = Excel.Activesheet;
        ActivesheetRange = get(Activesheet,'Range',['A',num2str(i+1),':',xlscol(length(fftOutput)),num2str(i+1)]);
        set(ActivesheetRange, 'Value', fftOutput);
        
        sheet = get(Sheets, 'Item', 2);
        invoke(sheet, 'Activate');
        Activesheet = Excel.Activesheet;
        ActivesheetRange = get(Activesheet,'Range',['A',num2str(i+1),':',xlscol(length(filtFftOutput)),num2str(i+1)]);
        set(ActivesheetRange, 'Value', filtFftOutput);
        
        invoke(TraceWorkbook,'Activate')
        Sheets = Excel.ActiveWorkBook.Sheets;
        
        traceOutput = cell(1,length(stimMean)+length(randMean)+4);
        traceOutput{1} = files{i};
        traceOutput{2} = stimType;
        traceOutput{3} = intensity;
        traceOutput(4:length(stimMean)+3) = num2cell(stimMean);
        traceOutput{length(stimMean)+4} = '';
        traceOutput(length(stimMean)+5:length(stimMean)+length(randMean)+4) = num2cell(randMean);
        
        filtTraceOutput = cell(1,length(filtStimMean)+length(filtRandMean)+4);
        filtTraceOutput{1} = files{i};
        filtTraceOutput{2} = stimType;
        filtTraceOutput{3} = intensity;
        filtTraceOutput(4:length(filtStimMean)+3) = num2cell(filtStimMean);
        filtTraceOutput{length(filtStimMean)+4} = '';
        filtTraceOutput(length(filtStimMean)+5:length(filtStimMean)+length(filtRandMean)+4) = num2cell(filtRandMean);
            
        sheet = get(Sheets, 'Item', 1);
        invoke(sheet, 'Activate');
        Activesheet = Excel.Activesheet;
        ActivesheetRange = get(Activesheet,'Range',['A',num2str(i+1),':',xlscol(length(traceOutput)),num2str(i+1)]);
        set(ActivesheetRange, 'Value', traceOutput);
        
        sheet = get(Sheets, 'Item', 3);
        invoke(sheet, 'Activate');
        Activesheet = Excel.Activesheet;
        ActivesheetRange = get(Activesheet,'Range',['A',num2str(i+1),':',xlscol(length(filtTraceOutput)),num2str(i+1)]);
        set(ActivesheetRange, 'Value', filtTraceOutput);
        
        stimMean = avg10(stimMean);
        randMean = avg10(randMean);
        
        filtStimMean = avg10(filtStimMean);
        filtRandMean = avg10(filtRandMean);
        
        traceOutput = cell(1,length(stimMean)+length(randMean)+4);
        traceOutput{1} = files{i};
        traceOutput{2} = stimType;
        traceOutput{3} = intensity;
        traceOutput(4:length(stimMean)+3) = num2cell(stimMean);
        traceOutput{length(stimMean)+4} = '';
        traceOutput(length(stimMean)+5:length(stimMean)+length(randMean)+4) = num2cell(randMean);
        
        filtTraceOutput = cell(1,length(filtStimMean)+length(filtRandMean)+4);
        filtTraceOutput{1} = files{i};
        filtTraceOutput{2} = stimType;
        filtTraceOutput{3} = intensity;
        filtTraceOutput(4:length(filtStimMean)+3) = num2cell(filtStimMean);
        filtTraceOutput{length(filtStimMean)+4} = '';
        filtTraceOutput(length(filtStimMean)+5:length(filtStimMean)+length(filtRandMean)+4) = num2cell(filtRandMean);
            
        sheet = get(Sheets, 'Item', 2);
        invoke(sheet, 'Activate');
        Activesheet = Excel.Activesheet;
        ActivesheetRange = get(Activesheet,'Range',['A',num2str(i+1),':',xlscol(length(traceOutput)),num2str(i+1)]);
        set(ActivesheetRange, 'Value', traceOutput);
        
        sheet = get(Sheets, 'Item', 4);
        invoke(sheet, 'Activate');
        Activesheet = Excel.Activesheet;
        ActivesheetRange = get(Activesheet,'Range',['A',num2str(i+1),':',xlscol(length(filtTraceOutput)),num2str(i+1)]);
        set(ActivesheetRange, 'Value', filtTraceOutput);
        
    end
end

if exportState == 1
    % Now save the workbook
    savename = 'US Dose Response';
    if smoothState == 1
        savename = [savename,' with Smoothing'];
    end
    if artifactState == 1
        if smoothState == 1 || filterState == 1
            savename = [savename,' & Artifact Removal'];
        else
            savename = [savename,' with Artifact Removal'];
        end
    end
           
    invoke(TraceWorkbook, 'SaveAs', [savename,'.xlsx']);

    % End process
    delete(Excel);
end
    
disp('Processing complete.');