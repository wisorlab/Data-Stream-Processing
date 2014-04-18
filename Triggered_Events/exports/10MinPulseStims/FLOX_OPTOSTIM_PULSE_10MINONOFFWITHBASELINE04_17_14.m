%This script produces sleep state percentages and sleep state (i.e., REMS, SWS and wake)-specific FFT values
%in each of 5 contiguous 10-min intervals. Input file is a neuroscore txt
%output file (10-sec epochs including TTL track as last column of data.
%The timing of the 10-min intervals is triggered by the first TTL signal onset in the txt file.  
%Interval 1 is the 10 min interval immediately preceding first TTL signal
%onset. The laser is on for 10ms
%Interval 2 is the 10 min interval immediately after first TTL onset; The
%laser is on for 100ms
%Interval 3 is the next 10 min interval; The laser is on for 1s
%Interval 4 is the next 10 min interval; The laser is on for 10s
%Interval 5 is the next 10 min interval; The laser is on for 100s
%Interval 6 is the next 10 min interval; The laser is on for 1000s

clear  %clears all pre-existing variables from the workspace so they do not impact processing in this run.
delete '10MinPulseStim.xlsx'

[files,path] = uigetfile({'*txt','TXT Files (*.txt)';'*.*','All Files'; },'Select Data File(s)','MultiSelect','On');
if isstr(files), files = {files}; end


HowManyFiles = length(files); % Need to know the number of files to process.  This number is encoded as the variable "HowManyFiles".

for FileCounter = 1:length(files)   %Runs the following set of commands for each file meeting criterion within the current directory.
    InputFileList {FileCounter,1} = files{FileCounter};  %InputFileList is a Cell Array of Strings, meaning an array of strings that are not necessarily uniform in number of characters.
    InputFileList {FileCounter,2} = FileCounter; %Each row in InputFileList contains the name of one *.txt file followed by the row number associated with that file in InputFileList.
end  % the use of '{}' to signify array positions identifies this array as a cell array of strings.

%label independent variable columns (1-7)in output file.

columnLabels = cell(1,999);
columnLabels{1} = 'Filename';
columnLabels{2} = 'Gender';
columnLabels{3} = 'Strain';
columnLabels{4} = 'Animal ID';
columnLabels{5} = 'Group';
columnLabels{6} = 'Transgene?';
columnLabels{7} = 'Intensity';

for ColumnLabeler=1:7
    AllPctREMS{1,ColumnLabeler} =  char(columnLabels(ColumnLabeler));
    AllPctSWS{1,ColumnLabeler} = char(columnLabels(ColumnLabeler));
    AllPctWake{1,ColumnLabeler} = char(columnLabels(ColumnLabeler));
    AllFftREMS{1,ColumnLabeler} =  char(columnLabels(ColumnLabeler));
    AllFftSWS{1,ColumnLabeler} = char(columnLabels(ColumnLabeler));
    AllFftWake{1,ColumnLabeler} = char(columnLabels(ColumnLabeler));
end;

%label dependent variable columns (8-12)in state output sheets.


AllPctREMS{1,8} = ['Baseline'];
AllPctSWS{1,8} = ['Baseline'];
AllPctWake{1,8} = ['Baseline'];

AllPctREMS{1,9} = ['1st Stim - 10ms'];
AllPctSWS{1,9} = ['1st Stim - 10ms'];
AllPctWake{1,9} = ['1st Stim - 10ms'];

AllPctREMS{1,10} = ['2nd Stim - 100ms'];
AllPctSWS{1,10} = ['2nd Stim - 100ms'];
AllPctWake{1,10} = ['2nd Stim - 100ms'];

AllPctREMS{1,11} = ['3rd Stim - 1s'];
AllPctSWS{1,11} = ['3rd Stim - 1s'];
AllPctWake{1,11} = ['3rd Stim - 1s'];

AllPctREMS{1,12} = ['4th Stim - 10s'];
AllPctSWS{1,12} = ['4th Stim - 10s'];
AllPctWake{1,12} = ['4th Stim - 10s'];

AllPctREMS{1,13} = ['5th Stim - 100s'];
AllPctSWS{1,13} = ['5th Stim - 100s'];
AllPctWake{1,13} = ['5th Stim - 100s'];



for FileCounter=1:length(files)  %this loop imports the data files one-by-one and processes the data in them into output files.
    
    clear SWSFft REMSFft WakeFft SWSFftAverage REMSFftAverage WakeFftAverage SWSFftRearrange REMSFftRearrange WakeFftRearrange LinearFftSWS LinearFftREMS LinearFftWake;
    
    try
        importDSILactateFftfile([path files{FileCounter}]);  %importfile is a function (stored as the file'importfile.m' that imports a DSI output text file to produce two matrices.
        % One matrix (textdata) holds the date/time stamp.  The other (data) holds the lactate and EEG data.
        %It is a major caveat that the headers from the txt file are retained in textdata but not in data, which means that data and textdata are not aligned with respect to epoch number
        
        numhertz = str2num(files{FileCounter}((length(files{FileCounter})-5):(length(files{FileCounter})-4))) * 2;
        
        disp(files{FileCounter});
        
        FftOnly = data (:,1:numhertz); % fftonly is a matrix with as many rows as there are rows in the input file, and 40 columns corresponding to the EEG1 and EEG2 ffts in 1 Hz bins.
        TTLColumn=length(data(1,:));
        TTL = data (:,TTLColumn);
        
        State=char(textdata(3:length(textdata),2));  % makes a vector of the state data, the second column of the matrix known as textdata.
        TimeStamp=char(textdata(3:length(textdata),1));
        Tensec=str2num(TimeStamp(:,18:19));
        
        % if the number in the units place of the width of 'data' is 2,
        % proceed, otherwise 'FirstStim' is 300 
        % Determines whether there is TTL column (when mod == 2)
        if mod(length(data(1,:)),10)==2
            FirstStim=min(find(TTL>0));
            if FirstStim < 60
                string = strcat('Spurious stimulus needs to be removed from file ',InputFileList(FileCounter,1),' at line ', num2str(FirstStim));
                warning(string{:});
            end
        else
            % there is no TTL signal, so we will albitrarily start the
            % analysis 300 epochs into the record
            FirstStim=300;
        end
        BaselineEpoch=FirstStim-60;
        AllStims=find(TTL>0);
% %         StimPhase=(AllStims-FirstStim)/6;
% %         StimPhase (StimPhase<=1)=1;
% %         StimPhase (StimPhase>1)=10;
       
        % find the time of the first stim onset
        tstamp = regexp(textdata(FirstStim+2),'(\d+\/\d+\/\d+)\s*,(\d+:\d+:\d+\s+\w+)','tokens');
        time0 = tstamp{1,1}{1}{2};    
        
        for BinReader = 1:6  % this loop initializes the three vectors that will ultimately sum up the power spectra (0-20 Hz in 1 Hz bins) for each state within the file.
            BinStart=BaselineEpoch+(BinReader-1)*60;
            BinStop=BinStart+59;
            if BinStop>length(data)
                BinStop=length(data);
            end
            FftThisBin = FftOnly(BinStart:BinStop,1:numhertz);
            clear SWSFft WakeFft REMSFft SWSEpochs WakeEpochs REMSEpochs;
            
            SWSEpochs=find(logical(State(BinStart:BinStop)=='S'));
            SWSMinutes(BinReader)=numel(SWSEpochs)/6;        %State(State(BinStart:BinStop)=='S')))/6;
            if SWSMinutes(BinReader)>0
                SWSFft=FftThisBin(SWSEpochs(:),1:numhertz);
                SWSFftAverage(BinReader,1:numhertz)=mean(SWSFft);
            else SWSFftAverage(BinReader,1:numhertz)=NaN;
            end
            
            WakeEpochs=find(logical(State(BinStart:BinStop)=='W'));
            WakeMinutes(BinReader)=numel(WakeEpochs)/6;        %State(State(BinStart:BinStop)=='W')))/6;
            if WakeMinutes(BinReader)>0
                WakeFft=FftThisBin(WakeEpochs(:),1:numhertz);
                WakeFftAverage(BinReader,1:numhertz)=mean(WakeFft);
            else WakeFftAverage(BinReader,1:numhertz)=NaN;
                
            end
            
            
            REMSEpochs=find(logical(State(BinStart:BinStop)=='R'));
            REMSMinutes(BinReader)=numel(REMSEpochs)/6;        %State(State(BinStart:BinStop)=='R')))/6;
            if REMSMinutes(BinReader)>0
                REMSFft=FftThisBin(REMSEpochs(:),1:numhertz);
                REMSFftAverage(BinReader,1:numhertz)=mean(REMSFft);
            else REMSFftAverage(BinReader,1:numhertz)=NaN;
            end
        end
        
        %The vector array of strings TextNote must be created so as to identify the data that will be outputted in subsequent columns on each line of the output spreadhseet.
        TextNote{1} = 'Nrem_Ffts';
        TextNote{2} = 'Wake_Ffts';
        TextNote{3} = 'Rems_Ffts';
        TextNote{4} = 'Nrem_Pcts';
        TextNote{5} = 'Wake_Pcts';
        TextNote{6} = 'Rems_Pcts';
        TextNote{7} = 'EEG Pwr Hz Bin';
        TextNote{8} = 'File ID';
        
        %We have to make an output matrix for the FFT values from each state, which can then be outputted as an xlsx sheet.
        %The first two columns in the first row of each output matrix will be a set of labels derived from the text notes generated above.
        AllFftSWS(1,1) = TextNote(8);
        AllFftWake(1,1) = TextNote(8);
        AllFftREMS(1,1) = TextNote(8);
        AllPctSWS(1,1) = TextNote(8);
        AllPctWake(1,1) = TextNote(8);
        AllPctREMS(1,1) = TextNote(8);
        if numhertz == 40
            ColumnsEEG1 = MakeLabelFloxPulsewithBaseline('EEG1',numhertz/2,6);
            ColumnsEEG2 = MakeLabelFloxPulsewithBaseline('EEG2',numhertz/2,6);
            
            % AllFftSWS(1,8:numhertz/2*5+7) = ColumnsEEG1; AllFftSWS(1,numhertz/2*5+8:numhertz/2*10+7) = ColumnsEEG2;
            AllFftWake(1,8:numhertz/2*6+7) = ColumnsEEG1; AllFftWake(1,numhertz/2*6+8:numhertz/2*12+7) = ColumnsEEG2;
            % AllFftREMS(1,8:numhertz/2*5+7) = ColumnsEEG1; AllFftREMS(1,numhertz/2*5+8:numhertz/2*10+7) = ColumnsEEG2;
        
        elseif numhertz == 80
            ColumnsEEG1 = MakeLabelFloxPulsewithBaseline('EEG1',numhertz/2,6);
            ColumnsEEG2 = MakeLabelFloxPulsewithBaseline('EEG2',numhertz/2,6);
            
            AllFftSWS(1,8:numhertz/2*6+7) = ColumnsEEG1; AllFftSWS(1,numhertz/2*6+8:numhertz/2*12+7) = ColumnsEEG2;
            AllFftWake(1,8:numhertz/2*6+7) = ColumnsEEG1; AllFftWake(1,numhertz/2*6+8:numhertz/2*12+7) = ColumnsEEG2;
            AllFftREMS(1,8:numhertz/2*6+7) = ColumnsEEG1; AllFftREMS(1,numhertz/2*6+8:numhertz/2*12+7) = ColumnsEEG2;
        end
        
        SWSPctColumns = MakeLabel ('SWS Minutes',5,1); AllPctSWS(1,2:6) = SWSPctColumns;
        WakePctColumns = MakeLabel ('Wake Minutes',5,1); AllPctWake(1,2:6) = WakePctColumns;
        REMSPctColumns = MakeLabel ('REMS Minutes',5,1); AllPctREMS(1,2:6) = REMSPctColumns;
        
        
        %The second column of the row for this mouse within each matrix will identify the mouse ID.
        AllFftSWS(FileCounter+1,1) = InputFileList(FileCounter,1);
        AllFftWake(FileCounter+1,1) = InputFileList(FileCounter,1);
        AllFftREMS(FileCounter+1,1) = InputFileList(FileCounter,1);
        AllPctSWS(FileCounter+1,1) = InputFileList(FileCounter,1);
        AllPctWake(FileCounter+1,1) = InputFileList(FileCounter,1);
        AllPctREMS(FileCounter+1,1) = InputFileList(FileCounter,1);
        

        % rearrange fft matrix such that EEG2 is below EEG1 rather than on
        % same row.
        SWSFftRearrange(1:6,1:numhertz/2) = SWSFftAverage(1:6,1:numhertz/2);
        SWSFftRearrange(7:12,1:numhertz/2) = SWSFftAverage(1:6,numhertz/2+1:numhertz);
        WakeFftRearrange(1:6,1:numhertz/2) = WakeFftAverage(1:6,1:numhertz/2);
        WakeFftRearrange(7:12,1:numhertz/2) = WakeFftAverage(1:6,numhertz/2+1:numhertz);
        REMSFftRearrange(1:6,1:numhertz/2) = REMSFftAverage(1:6,1:numhertz/2);
        REMSFftRearrange(7:12,1:numhertz/2) = REMSFftAverage(1:6,numhertz/2+1:numhertz);
        
       %PLACE DOUBLE ARRAY CONTENT INTO SINGLE ROW OF CELL ARRAY
       %EEG1 across 5 intervals followed by EEG across 5 intervals
        LinearFftSWS=reshape(SWSFftRearrange',1,numhertz*6);
        LinearFftWake = reshape(WakeFftRearrange',1,numhertz*6);
        LinearFftREMS = reshape(REMSFftRearrange',1,numhertz*6);
        for ColumnLabeler=1:numhertz*6
            AllFftSWS{FileCounter+1,ColumnLabeler+7} = LinearFftSWS(ColumnLabeler);
            AllFftWake{FileCounter+1,ColumnLabeler+7} = LinearFftWake(ColumnLabeler);
            AllFftREMS{FileCounter+1,ColumnLabeler+7} = LinearFftREMS(ColumnLabeler);
        end;
        
        for ColumnLabeler=1:6
            AllPctREMS{FileCounter+1,ColumnLabeler+7} = REMSMinutes(ColumnLabeler);
            AllPctSWS{FileCounter+1,ColumnLabeler+7} = SWSMinutes(ColumnLabeler);
            AllPctWake{FileCounter+1,ColumnLabeler+7} = WakeMinutes(ColumnLabeler);
        end;
        
        % Assign text values to columns 1 through 7 so as to identify independent variables associated with each file. 
        strain = files{FileCounter}(1:3);
        animalID = files{FileCounter}(4:7);
        gender = files{FileCounter}(9);
        if strcmpi(strain,'cef') || strcmpi(strain,'nef')
            if ~isempty(strfind(lower(files{FileCounter}),'tamoxifen'))
                treatment = 'Tamoxifen';
                transgene = 'Yes';
            elseif ~isempty(strfind(lower(files{FileCounter}),'vehicle'))
                treatment = 'Vehicle';
                transgene = 'No';
            else
                treatment = 'Unknown';
                transgene = 'Unknown';
            end
        elseif strcmpi(strain,'cif') || strcmpi(strain,'thy')
            treatment = files{FileCounter}(11:12);
            if strcmpi(treatment,'++')
                transgene = 'Yes';
            else
                transgene = 'No';
            end
        end
        if ~isempty(strfind(lower(files{FileCounter}),'cont'))
            intensity = 'Continuous';
        elseif ~isempty(strfind(lower(files{FileCounter}),'1turn'))
            intensity = '1 Turn';
        elseif ~isempty(strfind(lower(files{FileCounter}),'10turn'))
            intensity = '10 Turns';
        elseif ~isempty(strfind(lower(files{FileCounter}),'baseline'))
            intensity = 'Baseline';
        else
            intensity = 'No Turns';
        end
        
        columnInfo = cell(1,7);
        columnInfo{1} = files{FileCounter};
        columnInfo{2} = gender;
        columnInfo{3} = strain;
        columnInfo{4} = animalID;
        columnInfo{5} = treatment;
        columnInfo{6} = transgene;
        columnInfo{7} = intensity;
        
        for ColumnLabeler=1:7
            AllPctREMS{FileCounter+1,ColumnLabeler} =  char(columnInfo(ColumnLabeler));
            AllPctSWS{FileCounter+1,ColumnLabeler} = char(columnInfo(ColumnLabeler));
            AllPctWake{FileCounter+1,ColumnLabeler} = char(columnInfo(ColumnLabeler));
            AllFftREMS{FileCounter+1,ColumnLabeler} =  char(columnInfo(ColumnLabeler));
            AllFftSWS{FileCounter+1,ColumnLabeler} = char(columnInfo(ColumnLabeler));
            AllFftWake{FileCounter+1,ColumnLabeler} = char(columnInfo(ColumnLabeler));
        end;
        
        
    catch err
        msg = getReport(err);
        warning(msg);
    end
end

% ======================= OUTPUT TO EXCEL

addpath ../../../../Matlab/etc/matlab-utils/

xl = XL();

sheets = xl.addSheets({ 'WakePct', 'SWSPct', 'REMSPct', 'WakeFft', 'SWSFft', 'REMSFft' });

xl.rmDefaultSheets();

xl.setCells( xl.Sheets.Item('WakePct'), [1,1], AllPctWake );
xl.setCells( xl.Sheets.Item('SWSPct'), [1,1], AllPctSWS );
xl.setCells( xl.Sheets.Item('REMSPct'), [1,1], AllPctREMS );
xl.setCells( xl.Sheets.Item('WakeFft'), [1,1], AllFftWake );
xl.setCells( xl.Sheets.Item('SWSFft'), [1,1], AllFftSWS );
xl.setCells( xl.Sheets.Item('REMSFft'), [1,1], AllFftREMS );

xl.sourceInfo( mfilename('fullpath') );

load chirp
sound  (y)