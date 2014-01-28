clear
utils = getUtils;
[files,path] = uigetfile({'*.edf','EDF Files (*.edf)';'*.*','All Files'},'Select EDF File','MultiSelect','On');
if ~iscell(files) files = {files}; end

utils.globalize('utils.xl');
[Excel,Workbooks,Sheets] = xl.new();
stim_types = [1, 10, 20, 40];
sheets = xl.addSheets(Excel,{'1Hz W', '10Hz W', '20Hz W', '40Hz W','1Hz S', '10Hz S', '20Hz S', '40Hz S','1Hz R', '10Hz R', '20Hz R', '40Hz R'});
for i=1:length(sheets)
    xl.set(sheets{i},[1,1],{'Filename','Strain','ID#','Sex','+/-','Treatment','Intensity','Date','Extra'});
end

for i=1:length(files)
    try
        % load the data from the *.edf
        [matrix, format, fs] = retrieveData(files{i},path);
        basename = utils.std.split(files{i},'with TTL Channel.edf');
        fft_files = utils.os.path.like(basename{1},path);
        text = utils.os.open([path,utils.std.strip(fft_files(1).name,'.txt'),'.txt']);
        edf = read_edf([ path files{i}]);
        clear sleepdata full_sleepdata
        for j=3:length(text)
            line = utils.std.split(text{j},'\t');
            sleepdata(j-2,1) = line(2);
        end
        for j=1:length(sleepdata)
            full_sleepdata((4000*(j-1))+1:j*4000) = sleepdata{j};
        end

        % compare timestamps
        % if necessary, add blank characters onto 'full_sleepdata', so that the 
        % onset times match perfectly.
        firstline = utils.std.split(text{3},'\t');
        starttime = regexp(firstline(1),',(\d+:\d+:\d+)','tokens');
        starttime = starttime{1,1}{1,1}{1,1}; % wtf?
        strdiff = starttime - edf.h1.starttime;
        diff = str2num(char(48+strdiff(4:5)))*60 - str2num(char(48+abs(strdiff(7:8)))); % ascii trickery
        
        % at this point, we can correct the variable 'full_sleepdata' so that its length matches
        % the length of the matrix. This is just a matter of adding the right number of zeros
        % on the beginning and end.
        full_sleepdata = [zeros(1,diff*400) full_sleepdata ]; % prepend zeros
        full_sleepdata = [ full_sleepdata zeros(1,length(matrix)-length(full_sleepdata)) ]; % append zeros

        % find indices of stim onsets
        stim_onsets = []; matched_sleepdata = [];
        for j=2:length(matrix)
            if matrix(j,5)>matrix(j-1,5)
                stim_onsets(end+1)=j; 
                matched_sleepdata(1,end+1) = full_sleepdata(j);
            end
        end

        matched_sleepdata = matched_sleepdata';

        stim_onsets_diff = stim_onsets(2:end) - stim_onsets(1:end-1);
        sleep_data = matrix(stim_onsets,[1,2,3,4]);
        data = struct('chunks',[],'freq',[],'state',[],'time',[],'mean',struct());
        for j=1:length(sleep_data)
            % check if first stim comes before 500, if so, skip it
            if round(sleep_data(j)*400+1) >= 500
                data.chunks{j,1} = matrix(round(sleep_data(j)*400+1)-500:round(sleep_data(j)*400+1)+500,[1,2,3,4]); 
            end
        end

        freq = utils.exp.logical_eval(stim_onsets_diff,{'x>300 & x<500','x>30 & x<50','x>15 & x<25','x>5 & x<15','x>500'},{1,10,20,40,0});

        % 'stim_changes' is determined by when 'stim_onsets_diff' is greater
        % than 3.5x its standard deviation
        all_stim_changes = find((stim_onsets_diff>std(stim_onsets_diff)*3.5));
        stim_changes = [ 1 all_stim_changes(all_stim_changes<length(stim_onsets_diff)) length(freq)];
        data.freq(1,1) = 0; data.time(1,1) = 0;
        % create frequency array
        for j=1:length(stim_changes)-1
            stim_avg(j) = mode(freq(stim_changes(j):stim_changes(j+1)));
            if stim_avg(j)<10, stim_avg(j) = 1; end
            data.freq(1+stim_changes(j):1+stim_changes(j+1),1) = stim_avg(j);
            % data.time(1+stim_changes(j):1+stim_changes(j+1),1) = 1:numel(stim_changes(j):stim_changes(j+1));
        end 
        data.freq(1,1) = data.freq(2,1);

        % create position array
        for j=1:length(stim_onsets)
            for k=abs(-j:-1) % loop backwards
                tdelta = matrix(stim_onsets(j)) - matrix(stim_onsets(k)); % time difference in seconds
                if tdelta > 10, break; end
                data.time(j,1) = tdelta;
            end
        end    


        % parse filename and extract relevant info
        result = regexp(files{i},'^([a-zA-Z]+)(\d+)\s+(\w+)\s+(((\+*)?(\-*)?)?)\s*([a-zA-Z]+)?\s*(\d+\w+)\s+(\d+_\d+_\d+)\s+(.*)','tokens');
        header_info = result{1};

        % construct the mean data, and send to Excel
        sleepstates = 'WSR';
        for k = 1:length(sleepstates)
            % NOTE: uncomment the following 2 lines to plot
            % f = figure;
            % title(files{i});
            for j=1:length(stim_types)

                try
                    % set the file name first, so that if averaging fails, we know which files didn't process correctly.
                    xl.set(sheets{(k-1)*length(stim_types)+j},[1,i+1], {files{i},header_info{:}});

                    % average
                    rows = cell2mat(data.chunks(logical(data.freq==stim_types(j) & data.time==0 & matched_sleepdata==sleepstates(k))));
                    presliced = mean(rows(:,[2:4:end]),2);
                    sliced = utils.std.slice(presliced',1001);
                    eval(['data.mean.mean_' sleepstates(k) '_' num2str(stim_types(j)) 'Hz=mean(sliced);']);

                catch err
                    warning(['Data for ''' files{i} ''', in sleepstate ''' sleepstates(k) ''' at frequency ''' num2str(stim_types(j)) ''' could not be processed: insufficient stimuli detected.' ]);
                    continue
                end

                try

                    % plot in subplots
                    % NOTE: uncomment the following 3 lines if you want to plot
                    % h = subplot(2,2,j,'Color','black');
                    % eval(['plot(data.mean.mean_' sleepstates(k) '_' num2str(stim_types(j)) 'Hz,''r'');']);
                    % title(h, [ num2str(stim_types(j)) 'Hz ' sleepstates(k)]);

                    % Excel
                    xl.set(sheets{(k-1)*length(stim_types)+j},[length(header_info)+2,i+1],eval(['data.mean.mean_' sleepstates(k) '_' num2str(stim_types(j)) 'Hz']));
                    
                % exception handling
                catch err
                    msg = getReport(err);
                    warning(msg);
                end
            end
        end

    % exception handling
    catch err
        % rethrow(err)
        msg = getReport(err);
        warning(msg);
    end
end
