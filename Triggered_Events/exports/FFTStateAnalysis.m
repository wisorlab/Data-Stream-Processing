clear

[filenames,pathname,filterIndex] = uigetfile('*.txt','Text Files (*.txt)','MultiSelect','on');
if ~iscell (filenames)filenames = {filenames}; end

Excel = actxserver('Excel.Application');
set(Excel, 'Visible', 1);
Workbooks = Excel.Workbooks;
Workbook.triggered = invoke(Workbooks, 'Add');
Sheets = Excel.ActiveWorkBook.Sheets;
invoke(Workbook.triggered,'Activate');
Sheets = Excel.ActiveWorkBook.Sheets;
sheetnames = {'1 Hz Wake','1 Hz REM','1 Hz SWS','10 Hz Wake','10 Hz REM','10 Hz SWS','20 Hz Wake','20 Hz REM','20 Hz SWS','40 Hz Wake','40 Hz REM','40 Hz SWS' };

for i = 1:9 invoke(Sheets,'Add'); end
for i = 1:12
    sheet = get(Sheets, 'Item', i);
    invoke(sheet, 'Activate');
    sheet.name = sheetnames{i};
end

columnLabels = cell(1,999);
columnLabels(1:7) = {'Gender','Filename','Strain','Animal ID','Group','Transgene','Intensity'};

for i = 1:length(sheetnames)
    invoke(Workbook.triggered,'Activate');
    Sheets = Excel.ActiveWorkBook.Sheets;
    sheet = get(Sheets, 'Item', i);
    invoke(sheet, 'Activate');
    sheetRange = get(sheet,'Range','A1:G1');
    set(sheetRange, 'Value', columnLabels);
end

for i = 1:length(filenames)  %this loop imports the data files one-by-one and processes the data in them into output files.
    try
        importDSILactateFftfile(strcat(pathname, char(filenames(i))));  % imports the file contents as 'data' to the global workspace
        name = char(filenames(i)); 
        numhertz = str2num(name((length(name)-5):(length(name)-4))) * 2;
        
        disp(filenames(i));
       
        FftOnly = data (:,1:numhertz); % fftonly is a matrix with as many rows as there are rows in the input file, and 40 columns corresponding to the EEG1 and EEG2 ffts in 1 Hz bins.
        TTLColumn=length(data(1,:));
        TTL = data (:,TTLColumn);
        State=char(textdata(3:length(textdata),2));  % makes a vector of the state data, the second column of the matrix known as textdata.
        TimeStamp=char(textdata(3:length(textdata),1));
        Tensec=str2num(TimeStamp(:,18:19));
        
        if mod(length(data(1,:)),10)==2
            FirstStim = min(find(TTL>0 & Tensec==00));
            if FirstStim < 181
                warning(sprintf('Spurious stimulus needs to be removed from file "%s" at line %d', char(filenames(i)), FirstStim));
            end
        else
            FirstStim=181;
        end
        BaselineEpoch=FirstStim-180;
        AllStims=find(TTL>0 & Tensec==0);
        StimPhase=(AllStims-FirstStim)/6;
        StimPhase(StimPhase<60)=1;
        StimPhase(StimPhase>=60 & StimPhase<150)=10;
        StimPhase(StimPhase>=150 & StimPhase<240)=20;
        StimPhase(StimPhase>=240 & StimPhase<330)=40;
        StimPhase(StimPhase>330)=-999;

        for j = 1:6  %this loop initializes the three vectors that will ultimately sum up the power spectra (0-20 Hz in 1 Hz bins) for each state within the file.
            BinStart=AllStims;
            BinStop=BinStart+179;
            FftThisBin = FftOnly(BinStart:BinStop,1:numhertz);
            clear SWSFft WakeFft REMSFft SWSEpochs WakeEpochs REMSEpochs;
            
            SWSEpochs=find(logical(State(BinStart:BinStop)=='S'));
            SWSMinutes(j)=numel(SWSEpochs)/6;
            if SWSMinutes(j)>0
                SWSFft=FftThisBin(SWSEpochs(:),1:numhertz);
                SWSFftAverage(j,1:numhertz)=mean(SWSFft);
            else SWSFftAverage(j,1:numhertz)=NaN;
            end
            
            WakeEpochs=find(logical(State(BinStart:BinStop)=='W'));
            WakeMinutes(j)=numel(WakeEpochs)/6;
            if WakeMinutes(j)>0
                WakeFft=FftThisBin(WakeEpochs(:),1:numhertz);
                WakeFftAverage(j,1:numhertz)=mean(WakeFft);
            else WakeFftAverage(j,1:numhertz)=NaN;
                
            end
            
            REMSEpochs=find(logical(State(BinStart:BinStop)=='R'));
            REMSMinutes(j)=numel(REMSEpochs)/6;
            if REMSMinutes(j)>0
                REMSFft=FftThisBin(REMSEpochs(:),1:numhertz);
                REMSFftAverage(j,1:numhertz)=mean(REMSFft);
            else REMSFftAverage(j,1:numhertz)=NaN;
            end
        end
        
        TextNote(1:8) = {'Nrem_Ffts','Wake_Ffts','Rems_Ffts','Nrem_Pcts','Wake_Pcts','Rems_Pcts','EEG Pwr Hz Bin','File ID'};
        
        %We have to make an output matrix for the FFT values from each state, which can then be outputted as an xlsx sheet.
        %The first two columns in the first row of each output matrix will be a set of labels derived from the text notes generated above.
        AllFftSWS(1,1) = TextNote(8);
        AllFftWake(1,1) = TextNote(8);
        AllFftREMS(1,1) = TextNote(8);
        AllPctSWS(1,1) = TextNote(8);
        AllPctWake(1,1) = TextNote(8);
        AllPctREMS(1,1) = TextNote(8);
        if numhertz == 40
            ColumnsEEG1 = MakeLabelFlox ('EEG1',20,12);
            ColumnsEEG2 = MakeLabelFlox ('EEG2',20,12);
            AllFftSWS(1,2:241) = ColumnsEEG1;
            AllFftSWS(1,242:481) = ColumnsEEG2;
            AllFftWake(1,2:241) = ColumnsEEG1; AllFftWake(1,242:481) = ColumnsEEG2;
            AllFftREMS(1,2:241) = ColumnsEEG1; AllFftREMS(1,242:481) = ColumnsEEG2;
        elseif numhertz == 80
            ColumnsEEG1 = MakeLabelFlox ('EEG1',40,12);
            ColumnsEEG2 = MakeLabelFlox ('EEG2',40,12);
            AllFftSWS(1,2:481) = ColumnsEEG1;
            AllFftSWS(1,482:482+length(ColumnsEEG2)-1) = ColumnsEEG2;
            AllFftWake(1,2:481) = ColumnsEEG1; AllFftWake(1,482:482+length(ColumnsEEG2)-1) = ColumnsEEG2;
            AllFftREMS(1,2:481) = ColumnsEEG1; AllFftREMS(1,482:482+length(ColumnsEEG2)-1) = ColumnsEEG2;
        end
        
        SWSColumns = MakeLabel ('SWS Minutes',12,1); AllPctSWS(1,2:13) = SWSColumns;
        WakeColumns = MakeLabel ('Wake Minutes',12,1); AllPctWake(1,2:13) = WakeColumns;
        REMSColumns = MakeLabel ('REMS Minutes',12,1); AllPctREMS(1,2:13) = REMSColumns;
        
        
        %The second column of the row for this mouse within each matrix will identify the mouse ID.
        AllFftSWS(i+1,1) = InputFileList(i,1);
        AllFftWake(i+1,1) = InputFileList(i,1);
        AllFftREMS(i+1,1) = InputFileList(i,1);
        AllPctSWS(i+1,1) = InputFileList(i,1);
        AllPctWake(i+1,1) = InputFileList(i,1);
        AllPctREMS(i+1,1) = InputFileList(i,1);
        
        for BinNumber = 1:12 %this 15-line loop outputs treatment data into a matrix.  See baseline data above.
            if numhertz == 40
                DummyCellArray =  mat2cell(SWSFftAverage(BinNumber,1:20), [1], [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                AllFftSWS(i+1,(BinNumber-1)*20+2:(BinNumber-1)*20+21) =  DummyCellArray;
                DummyCellArray =  mat2cell(SWSFftAverage(BinNumber,21:40), [1], [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                AllFftSWS(i+1,(BinNumber+11)*20+2:(BinNumber+11)*20+21) =  DummyCellArray;
                DummyCellArray =  mat2cell(WakeFftAverage(BinNumber,1:20), [1], [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                AllFftWake(i+1,(BinNumber-1)*20+2:(BinNumber-1)*20+21) =  DummyCellArray;
                DummyCellArray =  mat2cell(WakeFftAverage(BinNumber,21:40), [1], [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                AllFftWake(i+1,(BinNumber+11)*20+2:(BinNumber+11)*20+21) =  DummyCellArray;
                DummyCellArray =  mat2cell(REMSFftAverage(BinNumber,1:20), [1], [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                AllFftREMS(i+1,(BinNumber-1)*20+2:(BinNumber-1)*20+21) =  DummyCellArray;
                DummyCellArray =  mat2cell(REMSFftAverage(BinNumber,21:40), [1], [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                AllFftREMS(i+1,(BinNumber+11)*20+2:(BinNumber+11)*20+21) =  DummyCellArray;
                
            else
                DummyCellArray =  mat2cell(SWSFftAverage(BinNumber,1:40), [1], [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                AllFftSWS(i+1,(BinNumber-1)*40+2:(BinNumber-1)*40+41) =  DummyCellArray;
                DummyCellArray =  mat2cell(SWSFftAverage(BinNumber,41:80), [1], [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                AllFftSWS(i+1,(BinNumber+11)*40+2:(BinNumber+11)*40+41) =  DummyCellArray;
                DummyCellArray =  mat2cell(WakeFftAverage(BinNumber,1:40), [1], [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                AllFftWake(i+1,(BinNumber-1)*40+2:(BinNumber-1)*40+41) =  DummyCellArray;
                DummyCellArray =  mat2cell(WakeFftAverage(BinNumber,41:80), [1], [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                AllFftWake(i+1,(BinNumber+11)*40+2:(BinNumber+11)*40+41) =  DummyCellArray;
                DummyCellArray =  mat2cell(REMSFftAverage(BinNumber,1:40), [1], [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                AllFftREMS(i+1,(BinNumber-1)*40+2:(BinNumber-1)*40+41) =  DummyCellArray;
                DummyCellArray =  mat2cell(REMSFftAverage(BinNumber,41:80), [1], [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1]);
                AllFftREMS(i+1,(BinNumber+11)*40+2:(BinNumber+11)*40+41) =  DummyCellArray;
            end
        end
        
        clear DummyCellArray;
        DummyCellArray =  mat2cell(SWSMinutes, [1], [1 1 1 1 1 1 1 1 1 1 1 1]);
        AllPctSWS(i+1,2:13) =  DummyCellArray;
        DummyCellArray =  mat2cell(WakeMinutes, [1], [1 1 1 1 1 1 1 1 1 1 1 1]);
        AllPctWake(i+1,2:13) =  DummyCellArray;
        DummyCellArray =  mat2cell(REMSMinutes, [1], [1 1 1 1 1 1 1 1 1 1 1 1]);
        AllPctREMS(i+1,2:13) =  DummyCellArray;
        
        % Begin output to Excel
        strain = files(i).name(1:3);
        animalID = files(i).name(4:7);
        gender = files(i).name(9);
        if strcmpi(strain,'cef') || strcmpi(strain,'nef')
            if ~isempty(strfind(lower(files(i).name),'tamoxifen'))
                treatment = 'Tamoxifen';
                transgene = 'Yes';
            elseif ~isempty(strfind(lower(files(i).name),'vehicle'))
                treatment = 'Vehicle';
                transgene = 'No';
            else
                treatment = 'Unknown';
                transgene = 'Unknown';
            end
        elseif strcmpi(strain,'cif') || strcmpi(strain,'thy')
            treatment = files(i).name(11:12);
            if strcmpi(treatment,'++')
                transgene = 'Yes';
            else
                transgene = 'No';
            end
        end
        if ~isempty(strfind(lower(files(i).name),'cont'))
            intensity = 'Continuous';
        elseif ~isempty(strfind(lower(files(i).name),'1turn'))
            intensity = '1 Turn';
        elseif ~isempty(strfind(lower(files(i).name),'10turn'))
            intensity = '10 Turns';
        elseif ~isempty(strfind(lower(files(i).name),'baseline'))
            intensity = 'Baseline';
        else
            intensity = 'No Turns';
        end
        
        columnInfo = cell(1,7);
        columnInfo{1} = gender;
        columnInfo{2} = files(i).name;
        columnInfo{3} = strain;
        columnInfo{4} = animalID;
        columnInfo{5} = treatment;
        columnInfo{6} = transgene;
        columnInfo{7} = intensity;
        
        
        if numhertz == 40
            lineIndex = round((i+1)/2 + 1);

            sheet = get(Sheets, 'Item', find(strcmp(sheetnames,strcat('0.5-20hz SwsEegSpectra_', columnInfo{3})),1));
            invoke(sheet, 'Activate');
            sheetRange = get(sheet,'Range',['A',num2str(lineIndex) ,':G',num2str(lineIndex)]);
            set(sheetRange, 'Value',columnInfo);
            sheetRange2 = get(sheet,'Range',['H',num2str(lineIndex),':RT',num2str(lineIndex)]);
            set(sheetRange2, 'Value',AllFftSWS(i+1,:));
            sheetRange2 = get(sheet,'Range','H1:RT1');
            set(sheetRange2, 'Value',AllFftSWS(1,:));

            sheet = get(Sheets, 'Item', find(strcmp(sheetnames,strcat('0.5-20hz RemsEegSpectra_', columnInfo{3})),1));
            invoke(sheet, 'Activate');
            sheetRange = get(sheet,'Range',['A',num2str(lineIndex) ,':G',num2str(lineIndex)]);
            set(sheetRange, 'Value',columnInfo);
            sheetRange2 = get(sheet,'Range',['H',num2str(lineIndex),':RT',num2str(lineIndex)]);
            set(sheetRange2, 'Value',AllFftREMS(i+1,:));
            sheetRange2 = get(sheet,'Range','H1:RT1');
            set(sheetRange2, 'Value',AllFftREMS(1,:));

            sheet = get(Sheets, 'Item', find(strcmp(sheetnames,strcat('0.5-20hz WakeEegSpectra_', columnInfo{3})),1));
            invoke(sheet, 'Activate');
            sheetRange = get(sheet,'Range',['A',num2str(lineIndex) ,':G',num2str(lineIndex)]);
            set(sheetRange, 'Value',columnInfo);
            sheetRange2 = get(sheet,'Range',['H',num2str(lineIndex),':RT',num2str(lineIndex)]);
            set(sheetRange2, 'Value',AllFftWake(i+1,:));
            sheetRange2 = get(sheet,'Range','H1:RT1');
            set(sheetRange2, 'Value',AllFftWake(1,:));

            sheet = get(Sheets, 'Item', find(strcmp(sheetnames,strcat('0.5-20hz SWSMinutes_', columnInfo{3})),1));
            invoke(sheet, 'Activate');
            sheetRange = get(sheet,'Range',['A',num2str(lineIndex) ,':G',num2str(i+1)]);
            set(sheetRange, 'Value',columnInfo);
            sheetRange2 = get(sheet,'Range',['H',num2str(lineIndex),':T',num2str(i+1)]);
            set(sheetRange2, 'Value',AllPctSWS(i+1,:));
            sheetRange2 = get(sheet,'Range','H1:T1');
            set(sheetRange2, 'Value',AllPctSWS(1,:));

            sheet = get(Sheets, 'Item', find(strcmp(sheetnames,strcat('0.5-20hz RemsMinutes_', columnInfo{3})),1));
            invoke(sheet, 'Activate');
            sheetRange = get(sheet,'Range',['A',num2str(lineIndex) ,':G',num2str(i+1)]);
            set(sheetRange, 'Value',columnInfo);
            sheetRange2 = get(sheet,'Range',['H',num2str(lineIndex),':T',num2str(i+1)]);
            set(sheetRange2, 'Value',AllPctREMS(i+1,:));
            sheetRange2 = get(sheet,'Range','H1:T1');
            set(sheetRange2, 'Value',AllPctREMS(1,:));

            sheet = get(Sheets, 'Item', find(strcmp(sheetnames,strcat('0.5-20hz WakeMinutes_', columnInfo{3})),1));
            invoke(sheet, 'Activate');
            sheetRange = get(sheet,'Range',['A',num2str(lineIndex) ,':G',num2str(lineIndex)]);
            set(sheetRange, 'Value',columnInfo);
            sheetRange2 = get(sheet,'Range',['H',num2str(lineIndex),':T',num2str(lineIndex)]);
            set(sheetRange2, 'Value',AllPctWake(i+1,:));
            sheetRange2 = get(sheet,'Range','H1:T1');
            set(sheetRange2, 'Value',AllPctWake(1,:));
            
        elseif numhertz == 80
            lineIndex = round((i-1)/2) + 1;
            sheet = get(Sheets, 'Item', find(strcmp(sheetnames,strcat('0.5-40hz SwsEegSpectra_', columnInfo{3})),1));
            invoke(sheet, 'Activate');
            sheetRange = get(sheet,'Range',['A',num2str(lineIndex) ,':G',num2str(lineIndex)]);
            set(sheetRange, 'Value',columnInfo);
            sheetRange2 = get(sheet,'Range',['H',num2str(lineIndex),':AKG',num2str(lineIndex)]);
            set(sheetRange2, 'Value',AllFftSWS(i+1,:));
            sheetRange2 = get(sheet,'Range','H1:AKG1');
            set(sheetRange2, 'Value',AllFftSWS(1,:));

            sheet = get(Sheets, 'Item', find(strcmp(sheetnames,strcat('0.5-40hz RemsEegSpectra_', columnInfo{3})),1));
            invoke(sheet, 'Activate');
            sheetRange = get(sheet,'Range',['A',num2str(lineIndex) ,':G',num2str(lineIndex)]);
            set(sheetRange, 'Value',columnInfo);
            sheetRange2 = get(sheet,'Range',['H',num2str(lineIndex),':AKG',num2str(lineIndex)]);
            set(sheetRange2, 'Value',AllFftREMS(i+1,:));
            sheetRange2 = get(sheet,'Range','H1:AKG1');
            set(sheetRange2, 'Value',AllFftREMS(1,:));

            sheet = get(Sheets, 'Item', find(strcmp(sheetnames,strcat('0.5-40hz WakeEegSpectra_', columnInfo{3})),1));
            invoke(sheet, 'Activate');
            sheetRange = get(sheet,'Range',['A',num2str(lineIndex) ,':G',num2str(lineIndex)]);
            set(sheetRange, 'Value',columnInfo);
            sheetRange2 = get(sheet,'Range',['H',num2str(lineIndex),':AKG',num2str(lineIndex)]);
            set(sheetRange2, 'Value',AllFftWake(i+1,:));
            sheetRange2 = get(sheet,'Range','H1:AKG1');
            set(sheetRange2, 'Value',AllFftWake(1,:));      
        end  
    catch err
        msg = getReport(err);
        warning(msg);
    end
end

load chirp
sound  (y)