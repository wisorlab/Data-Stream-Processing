% ==============================================================
% Inter-Stimulus Interval Analysis Script
% by @jonbrennecke
% ==============================================================
clear

% open the utils library
utils = getUtils;
utils.globalize('utils.xl');

[Excel,Workbooks,Sheets] = xl.new(); % get excel ActiveX
% sheets = xl.addSheets(Excel,{'x1','y1','x2','y2','dx','dy'});
% for i=1:length(sheets)
%     xl.set(sheets{i},[1,1],{'Filename','Date','Opto 1ms','Opto 2ms','Opto 4ms','Opto 16ms','Opto 64ms','US 1ms','US 2ms','US 4ms','US 16ms','US 64ms'});
% end

sheets = xl.addSheets(Excel,{'Triggered','Random'});
xl.set(sheets{1},[1,1],{'Filename','Data'})
xl.set(sheets{2},[1,1],{'Filename','Data'})

% open file dialog and create a cell array of the file(s)
[files,path] = uigetfile({'*raw','Binary MCS Files (*.raw)';'*.*','All Files';'*.edf','EDF Files (*.edf)';'*.txt','Text Files (*.txt)';},... % Open the user interface for opening files
'Select Data File(s)','MultiSelect','On');
if ~iscell(files), files = {files}; end

% ---------------------------------------------------------------

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


dates = [];
    
for i = 1:length(files)
    try
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
        data = data-mean(data); % mean subtract the data
        
        if smoothState == 1
            disp('Smoothing data...')
            data = movingSmoothing(data,150);
        end
        
        if filterState == 1
            disp('Filtering data...');
            data = filter60Hz(data);
        end
        
        disp('Finding trigger patterns...');
        
        [waves,randoms,wavestates,samplestarts,ttl] = findTriggerPattern_dualstims(data, matrix(:,ttlIndex), fs, msbefore, msafter, triggerPoint, 2);
        
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
%      plotStimulationPattern2(fs,matrix(:,1),data,matrix(:,ttlIndex),waves,stimMean,randMean,type,units,triggerPoint);
    
    % triggered
    xl.set(sheets{1},[1,i+1],{files{i}})
    xl.set(sheets{1},[2,i+1],stimMean)
    % random     
    xl.set(sheets{2},[1,i+1],{files{i}})
    xl.set(sheets{2},[2,i+1],randMean)
    
    throw(Exception);

    % =======================================================================
    % DETECT PEAKS AND INTER-STIMULUS INTERVALS
    % =======================================================================
    
    % split name into parts    
    r = regexp(name,'(\d+-\d+-\d+)\s+(\d+\s+\w+)\s+(\w+)\s+(\w+)\s?+(.*)?','tokens');
    nameparts = r{1,1};
    if(strcmp(nameparts{1,3},'US'))
        % Ultrasound stimulus yields a waveform that is inverted. 
        % Instead of trying to find minima, the most elegant solution 
        % is to simply invert the wave 
%         waves = -waves;
    end
    
%     stimMean = waves(k,:);
    stimMean = mean(waves);
    wavewidth = (length(waves(1,:))/fs-1/fs);
    wavetimevector = 0:1/fs:wavewidth;

    % find local maxima (and position of maxima) in 'waves' with 
    % amplitude greater than 1.5x the standard deviation
    clear pks upper lower longISI shortISI foundStims
    [pks(2,:),pks(1,:)] = findpeaks(stimMean);
    pks = pks';
    pks(:,1) = wavetimevector(pks(:,1));

    % set up figure for plotting
    figure; hold on;
    set(gca,'Color','black');
    axis([0 wavewidth -2 2]);
    suptitle(name);
    title('Mean Triggered Waveform (Local Maxima)');
    xlabel('Time (s)');
    ylabel(['Voltage (' units ')']);
    plot(wavetimevector,stimMean); % plot the waveform        
    
    % use ttl track to find 'expectedX'
    cero = max(ttl);
    uno = find(cero>0); % indexes of ttl track where stimulation points exist
    expectedX = wavetimevector(uno);
    
    % find peaks near expected point
    for j=1:length(expectedX)
        [foundStims(j,1),foundStims(j,2)] = utils.exp.closest(pks(:,1),expectedX(j));
    end
    [uniq,idxOriginal,idxUnique]=unique(foundStims(:,2)); % find unique values and their indexes
    stimpks = [foundStims(idxOriginal),pks(uniq,2)];
    
    stimpks = stimpks(setdiff(1:size(stimpks,1),find(stimpks(:,2)>mean(stimpks(:,2))-std(stimpks(:,2))==0)),:);
    
%     plot(stimpks(:,1),stimpks(:,2),'m.')
    
    interval = strsplit(nameparts{2},' '); 
    w = str2num(interval{1});
    % find the indexes of the first expected point in a train
    groups = 0;
    subd = expectedX(1:end)-expectedX(1);
    for k=1:21
        f = find(subd>k*(1/7.5)-(w*.005));
        subd = subd(f);
        groups(k,1) = groups(end) + f(1);
    end
    groups(1) = groups(1) + 1;
    groups(groups==0)=[];
    groups = [1; groups+[0:-1:-length(groups)+1]'];
    
    
    for j=1:length(groups)
        [expectFirst(j,1),expectFirst(j,2)]=utils.exp.closest(stimpks(:,1),expectedX(groups(j)));
    end
    
    expectSecond(:,2) = expectFirst(:,2)+1;
    expectSecond(:,1) = stimpks(expectSecond(:,2));
    expectSecond(:,2) = stimpks(expectSecond(:,2),2);
    expectFirst(:,2) = stimpks(expectFirst(:,2),2);
    
    expectSecond = expectSecond(setdiff(1:size(expectSecond,1),find(expectSecond(:,2)>mean(expectSecond(:,2))-3*std(expectSecond(:,2))==0)),:);
    expectFirst = expectFirst(setdiff(1:size(expectFirst,1),find(expectSecond(:,2)>mean(expectSecond(:,2))-3*std(expectSecond(:,2))==0)),:);
    plot(expectFirst(:,1),expectFirst(:,2),'m.');
    plot(expectSecond(:,1),expectSecond(:,2),'y.');
    
    ends = [floor((expectFirst(:,1)*5000)-w*50),floor((expectFirst(:,1)*5000)+w*50)];
%     if(ends(1)<=0) ends(1) = 1; ends(1,2) = w*100+1; end
%     if(ends(end)>length(stimMean)) ends(end) = length(stimMean); ends(end,1) = length(stimMean) - w*100; end

    for j=1:length(expectFirst)
%         try
            stimMeanCentered(j,:) = stimMean(ends(j,1):ends(j,2));
%         catch err
%         
%         end
    end
    
    centeredWave = mean(stimMeanCentered);
    
    figure; hold on;
    set(gca,'Color','black');
    axis([0 length(centeredWave) min(centeredWave)-0.1 max(centeredWave)+0.1]);
    suptitle(name);
    title('Average Peak (centered on 1st point)');
    xlabel('Time (s)');
    ylabel(['Voltage (' units ')']);
    
    first = mean(expectFirst);
    second = mean(expectSecond);
    
    plot(centeredWave,'g')
    
    % =====================================================================
    % excel output!
    % =====================================================================
 
    x1 = first(1);
    y1 = first(2); 
    x2 = second(1);
    y2 = second(2);
    dx = abs(first(1)-second(1));
    dy = abs(first(2)-second(2));
    
    % one way of doing this...    
    where = find(dates ==str2num(nameparts{1}));
    if isempty(where)
        dates(end+1) = str2num(nameparts{1});
        where = 1;
    end
    
    if strcmp(nameparts{3},'US'), isUS=5; else isUS=0; end
    
    interval = cell_location(str2num(interval{1})) + isUS;
    
    xl.set(sheets{1},[1,where+1], {files{i},nameparts{1}}); xl.set(sheets{1},[2+interval,where+1], {x1});  
    xl.set(sheets{2},[1,where+1], {files{i},nameparts{1}}); xl.set(sheets{2},[2+interval,where+1], {y1});  
    xl.set(sheets{3},[1,where+1], {files{i},nameparts{1}}); xl.set(sheets{3},[2+interval,where+1], {x2});  
    xl.set(sheets{4},[1,where+1], {files{i},nameparts{1}}); xl.set(sheets{4},[2+interval,where+1], {y2});  
    xl.set(sheets{5},[1,where+1], {files{i},nameparts{1}}); xl.set(sheets{5},[2+interval,where+1], {dx});  
    xl.set(sheets{6},[1,where+1], {files{i},nameparts{1}}); xl.set(sheets{6},[2+interval,where+1], {dy});  
    
    clearvars -except files dates path utils xl processSameChannel channelIndex smoothState filterState ttlIndex msbefore msafter triggerPoint artifactState units sheets

    catch err % demote the error to a warning and continue with the next file
        clearvars -except err files dates path utils xl processSameChannel channelIndex smoothState filterState ttlIndex msbefore msafter triggerPoint artifactState units sheets
        utils.debug.demote(err);
    end
end

disp('Processing complete.');
