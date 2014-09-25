function varargout = deltaDetect(varargin)
% DELTADETECT M-file for deltaDetect.fig
%      DELTADETECT, by itself, creates a new DELTADETECT or raises the existing
%      singleton*.
%
%      H = DELTADETECT returns the handle to a new DELTADETECT or the handle to
%      the existing singleton*.
%
%      DELTADETECT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DELTADETECT.M with the given input arguments.
%
%      DELTADETECT('Property','Value',...) creates a new DELTADETECT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before deltaDetect_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to deltaDetect_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help deltaDetect

% Last Modified by GUIDE v2.5 06-Sep-2012 09:02:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @deltaDetect_OpeningFcn, ...
                   'gui_OutputFcn',  @deltaDetect_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT



% --- Executes just before deltaDetect is made visible.
function deltaDetect_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to deltaDetect (see VARARGIN)


% Choose default command line output for deltaDetect
%t = tic;
warning('off','MATLAB:xlswrite:AddSheet');
handles.output = hObject;
guidata(hObject,handles);
uipushtool1_ClickedCallback(hObject, eventdata, handles);
%disp(['Opening Function: ', num2str(toc(t))]);


% UIWAIT makes deltaDetect wait for user response (see UIRESUME)
% uiwait(handles.highPassEdge);

% --------------------------------------------------------------------
function uipushtool1_ClickedCallback(hObject, eventdata, handles)
% Callback for opening a new file.
% hObject    handle to uipushtool1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%t = tic;
[filename,filepath]=uigetfile({'*.sev','SevenuP Graphic/Sprite Files (*.sev)';'*.edf','European Data Format Files (*.edf)';'*.txt','Text Files (*.txt)';'*.*','All Files'},... %Open the user interface for opening files
    'Select Data File');
if filename ~= 0 %uigetfile returns 0 if it could not locate the file or filepath
    if filepath ~= 0
        cd(filepath); %change directory
    end
%     prompt = {'Start:','Stop:'};
%     title = 'How many seconds of the sample would you like to import?';
%     def = {'0','600'};
%     inputdlg(prompt,title,2,def);
    initializeSettings(hObject, handles, filename);
    handles = guidata(hObject); %update the handles structure
    updatePlots(hObject, eventdata, handles);
    uipushtool2_ClickedCallback(hObject, eventdata, handles);
    close(handles.bar); % close the load bar
end
%disp(['Open file: ', num2str(toc(t))]);

function initializeSettings(hObject, handles, filename)
% Sets GUI parameters for loading a new file
    %t = tic;
    if isfield(handles,'matrix') % checks if matrix already exists in the handles structure
        handles = rmfield(handles,'matrix'); % removes the matrix field
    end
    if isfield(handles,'original_matrix')
        handles = rmfield(handles,'original_matrix');
    end
    if isfield(handles,'filtered_matrix')
        handles = rmfield(handles,'filtered_matrix');
    end
    % Refactor this so we aren't double checking the extension
    % Consider adding it to the handles structure
    [~,~,ext] = fileparts(filename); %Returns the filename extension
    if isfield(handles,'edfheader') && ~strcmp(ext,'.txt')
        handles = rmfield(handles,'edfheader');
    end
    guidata(hObject,handles);
    
    determineFileType(hObject,handles,filename);
    handles = guidata(hObject);
    handles.hertz = handles.original_hertz; % hertz is the compressed frequency. original_hertz is the frequency of the original file
    if handles.hertz > 2000 && (isempty(get(handles.compression,'String')) || str2double(get(handles.compression,'String')) > 2000); % If the sampling frequency is greater than 2000Hz and compression is not set or set above 2000Hz
        handles.matrix = compress(handles.original_matrix,handles.original_hertz,256); % compressed matrix = the original matrix at 256 Hz
        handles.hertz = 256; 
        set(handles.compression,'String',256); % Display the compression that occurred
    elseif ~isempty(get(handles.compression,'String')) && (str2double(get(handles.compression,'String')) < handles.original_hertz) % If the compression is set below 2000 Hz
        handles.hertz = str2double(get(handles.compression,'String'));
        handles.matrix = compress(handles.original_matrix,handles.original_hertz,str2double(get(handles.compression,'String'))); %compressed matrix = the original matrix at the compression frequency        
    else
        handles.matrix = handles.original_matrix;
    end

    waitbar(1/2,handles.bar,'Initializing GUI Handles');
    set(handles.filename,'String',filename); % Show the filename in the top left corner of the GUI
    set(handles.window,'String',round(handles.matrix(end,1))) % Make the plot window the full sample
    set(handles.windowUnits,'Value',2); % Display the units of the window in seconds
    sampleRateString = ['Original Sample Rate: ',num2str(handles.original_hertz),' Hz']; % Construct the original sample rate info
    set(handles.originalSampleRate,'String',sampleRateString); % Display the original sample rate info
    if isfield(handles,'edfheader')
       set(handles.channel,'string',handles.edfheader.label);
    else
        channel_options = ''; % Construct the options for channel selection
        for i = 1:handles.channels-1
            channel_options = [channel_options,'EEG ', num2str(i),'|'];
        end
        channel_options = [channel_options,'EEG ', num2str(i+1)]; 
        set(handles.channel,'string',channel_options); % Display the options for channel selection
    end
    handles.eeg = 2; % Set EEG to the first EEG channel (1+time column);
    set(handles.channel,'value',1); % Set the channel drop down menu to the first EEG
   
    set(handles.numSlowWaves,'String','Number of Slow Waves:'); % Clears the number of slow waves display
    set(handles.slowWaveTable,'Data',[]); % Clears the slow wave table
           
    set(handles.rawData,'value',1); % Make the display features checkboxes checked
    set(handles.filteredData,'value',1);
    set(handles.slowWaves,'value',1);
    set(handles.negativePeakOne,'value',1);
    set(handles.maximumVoltage,'value',1);
    set(handles.negativePeakTwo,'value',1);
    
    handles.rawPlot = 1;
    handles.filteredPlot = 1;
    handles.slowWavesPlot = 1;
    handles.negativePeakOnePlot = 1;
    handles.maxVoltagePlot = 1;
    handles.negativePeakTwoPlot = 1;
    
    handles.manual_amplitude = 0; % Tells the GUI to calculate minimum peak to peak amplitudes
    set(handles.amplitude,'String',100); % Default wave detection parameters
    set(handles.maxAmplitude,'String',600);
    set(handles.p2ptime,'String',.25);
    set(handles.maxp2ptime,'String',2);
    set(handles.epochLength,'String',4);
    set(handles.slider1,'Max',(handles.matrix(end,1)-str2double(get(handles.epochLength,'String')))); % Sets the range of the slider
    
    set(handles.lowPassEdge,'String',.5); % Default Chevbyshev Type II Parameters
    set(handles.highPassEdge,'String',4); % pass band
    set(handles.lowStopEdge,'String',.01);
    set(handles.highStopEdge,'String',10); % stop band
    set(handles.passBandRipple,'String',3); 
    set(handles.stopBandAttenuation,'String',20);
    
    guidata(hObject, handles);
   % disp(['Initialize Settings: ', num2str(toc(t))]);

    
function determineFileType(hObject,handles,filename)
%t = tic;
[~,~,ext] = fileparts(filename); %Returns the filename extension
if strcmp(ext,'.txt') % if it is a text file
    try
        fid = fopen(filename);
    catch err  
        error(['The file could not be loaded. '...
            'Be sure your file name is correct '...
            'and make sure you are in the correct directory.']);
    end
    title = textscan(fid,'%c%c%c%c%c%c%c%c',1); %Grab the first 8 characters of the document.
    title = horzcat(title{1:8}); % Concatenate the cell array
    if strcmp(title,'MC_DataT') % True if the file is an MCD text document
        handles.filetype = 'mcd';
        handles.bar = waitbar(1/10,'Importing MC Rack Data');
        [handles.original_matrix,handles.original_hertz,handles.channels] = mcscan(filename);
        handles.original_matrix(:,1) = handles.original_matrix(:,1)/1000; %convert the timestamp from ms to seconds
    else
        error('The file does not appear to have Multi Channel System''s text formatting.')
    end
elseif strcmp(ext,'.edf') % if the file is an EDF
    handles.filetype = 'edf';
    handles.bar = waitbar(1/10,'Importing EDF Data');
    [handles.edfheader,data] = edfread(filename);
    collectedChannels = handles.edfheader.samples == max(handles.edfheader.samples);
    num_channels = length(collectedChannels(collectedChannels == 1));
    for i = 2:num_channels
        if handles.edfheader.samples(i) ~= handles.edfheader.samples(i-1)
            beep;
            warning('Number of samples in each channel varies. May cause false results.');
        end
    end
    if handles.edfheader.records == -1
        handles.original_hertz = handles.edfheader.samples(1)/handles.edfheader.duration;
        time = handles.edfheader.duration;
        num_samples = handles.edfheader.samples(1);
    else
        handles.original_hertz = handles.edfheader.samples(1)/handles.edfheader.duration;
        time = handles.edfheader.duration*handles.edfheader.records;
        num_samples = handles.edfheader.samples(1)*handles.edfheader.records;
    end
    handles.original_matrix = zeros(num_samples,num_channels+1);
    handles.original_matrix(:,1) = 0:1/handles.original_hertz:time-(1/handles.original_hertz);
    handles.original_matrix(:,2:num_channels+1) = data(:,collectedChannels == 1);
    handles.channels = num_channels;
elseif strcmp(ext,'.sev') % if the file is a .sev file (Tucker Davis Technologies)
    handles.filetype = 'sev';
    handles.bar = waitbar(1/10,'Importing SEV Data');
    streamOutput = sev_read_RS2(filename);
    handles.original_matrix = zeros(length(streamOutput.Data),2); 
    handles.original_matrix(:,1) = 0:1/498.6:(length(streamOutput.Data)-1)/498.6; %construct the time column 
    handles.original_matrix(:,2) = streamOutput.Data.*1000000; %convert volts to microvolts
    handles.original_hertz = 498.6;
    handles.channels = 1;
end
guidata(hObject,handles);
%disp(['Determine File Type: ', num2str(toc(t))]);


function compression_Callback(hObject, eventdata, handles)
% hObject    handle to compression (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of compression as text
%        str2double(get(hObject,'String')) returns contents of compression as a double
%t = tic;
if str2double(get(handles.compression,'String')) > handles.original_hertz
    msgbox('The compression cannot be greater than the sampling rate of the original file.','Error');
elseif isempty(get(handles.compression,'String')) || strcmp(get(handles.compression,'String'),'0') || str2double(get(handles.compression,'String')) == 0
    handles.matrix = handles.original_matrix;
    handles.hertz = handles.original_hertz;
    updatePlots(hObject, eventdata, handles);
else
    handles.hertz = str2double(get(handles.compression,'String'));
    handles.matrix = compress(handles.original_matrix,handles.original_hertz,handles.hertz);
    updatePlots(hObject, eventdata, handles);
end
handles = guidata(hObject);
guidata(hObject,handles);
%disp(['Compression Callback: ',num2str(toc(t))]);


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% Set appropriate axis limits and settings

offset = get(handles.slider1,'Value');
xlimits = get(handles.plot1,'XLim');
zoomfactor = (xlimits(2)-xlimits(1));
set(handles.plot1,'XLim',[offset offset+zoomfactor]);
setappdata(get(handles.plot1, 'ZLabel'), 'ZOOMAxesData', [handles.matrix(1,1) handles.matrix(end,1)]); % Fixes a bug in the zoom out button.


function window_Callback(hObject, eventdata, handles)
% hObject    handle to window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of window as text
%        str2double(get(hObject,'String')) returns contents of window as a double
xlimits = get(handles.plot1,'Xlim');
units = get(handles.windowUnits,'Value');
if units == 1 % milliseconds
    unit = 1/1000;
elseif units == 2 % seconds
    unit = 1;
elseif units == 3 % minutes
    unit = 60;
end
if isnan(str2double(get(handles.window,'String'))) || str2double(get(handles.window,'String')) == 0
    uipushtool2_ClickedCallback(hObject, eventdata, handles);
else
    set(handles.plot1,'Xlim',[xlimits(1) xlimits(1)+str2double(get(handles.window,'String'))*unit]);
end

function determineWindow(handles)
xlimits = get(handles.plot1,'Xlim');
units = get(handles.windowUnits,'Value');
if units == 1 % milliseconds
    unit = 1/1000;
elseif units == 2 % seconds
    unit = 1;
elseif units == 3 % minutes
    unit = 60;
end
set(handles.window,'String',(xlimits(2)-xlimits(1))/unit);


% --- Executes on selection change in windowUnits.
function windowUnits_Callback(hObject, eventdata, handles)
% hObject    handle to windowUnits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns windowUnits contents as cell array
%        contents{get(hObject,'Value')} returns selected item from windowUnits
window_Callback(hObject, eventdata, handles)


% --- Outputs from this function are returned to the command line.
function varargout = deltaDetect_OutputFcn(hObject,eventdata,handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes on selection change in channel.
function channel_Callback(hObject, eventdata, handles)
% hObject    handle to channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns channel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel
if handles.eeg ~= get(handles.channel,'value')+1;
    handles.eeg = get(handles.channel,'value')+1; % Shifts handles.eeg one because of the time column
    set(handles.rawData,'Value',1);
    set(handles.slowWaveTable,'Data',[]);
    handles.manual_amplitude = 0;
    updatePlots(hObject, eventdata, handles);
    handles = guidata(hObject);
    guidata(hObject,handles);
end

% --- Executes on button press in rawData.
function rawData_Callback(hObject, eventdata, handles)
% hObject    handle to rawData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rawData
if ~ishandle(handles.rawPlot)
    updatePlots(hObject, eventdata, handles);
end
if get(handles.rawData,'Value') == 0
    set(handles.rawPlot,'Visible','off');
else
    set(handles.rawPlot,'Visible','on');
end

% BUG: Ylimits undefined with compression
function plotRawData(hObject,handles,xlimits,ylimits)   
    handles.rawPlot = plot(handles.plot1,handles.matrix(:,1),handles.matrix(:,handles.eeg));
    set(handles.plot1,'XLim',xlimits);
    set(handles.plot1,'YLim',ylimits); % ylimits fixes a minor bug that temporarily shifts 
    guidata(hObject,handles);          % the plot when initializing the
                                       % filtered plot.
    
% --- Executes on button press in filteredData.
function filteredData_Callback(hObject, eventdata, handles)
% hObject    handle to filteredData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of filteredData

% The below code seems whacky or perhaps inefficient, but it is the only
% way it works. The ineffieciency is not perceptable. DO NOT CHANGE.

if ~ishandle(handles.filteredPlot)
    updatePlots(hObject, eventdata, handles);
end
if get(handles.filteredData,'Value') == 0
    set(handles.filteredPlot,'Visible','off');
else
    set(handles.filteredPlot,'Visible','on');
end

% BUG: gcf may grab plots other that deltaDetect
function plotFilteredData(hObject,handles)
    handles.filtered_matrix = constructFilter(handles);
    handles.filteredPlot = plot(handles.plot1,handles.filtered_matrix(:,1),handles.filtered_matrix(:,handles.eeg),'Color',[0 0 0]);
    guidata(hObject,handles);

    
function filtered_matrix = constructFilter(handles)
%t = tic;
fs = handles.hertz; % sampling rate
p1=str2double(get(handles.lowPassEdge,'String')); 
p2=str2double(get(handles.highPassEdge,'String')); % pass band
s1=str2double(get(handles.lowStopEdge,'String'));
s2=str2double(get(handles.highStopEdge,'String')); % stop band
Rp=str2double(get(handles.passBandRipple,'String')); 
Rs=str2double(get(handles.stopBandAttenuation,'String'));
Wp=[p1 p2]/(fs/2); Ws=[s1 s2]/(fs/2);  
[n, Wn]=cheb2ord(Wp,Ws,Rp,Rs);
[bb,aa]=cheby2(n,Rs,Wn);
filtered_matrix = handles.matrix;
s = warning('error','MATLAB:nearlySingularMatrix');
try
    filtered_matrix(:,2:end) = filtfilt(bb,aa,handles.matrix(:,2:end));
catch err
    msgbox('The current parameters create a non-invertible matrix that would create improper scaling. Vary the Chebyshev parameters or compression.');
end
warning(s);
%disp(['Construct Filter: ', num2str(toc(t))]);


% --- Executes on button press in slowWaves.
function slowWaves_Callback(hObject, eventdata, handles)
% hObject    handle to slowWaves (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of slowWaves

if ~ishandle(handles.slowWavesPlot)
    updatePlots(hObject, eventdata, handles);
end
for i=1:length(handles.slowWavesPlot(:,1))
    if get(handles.slowWaves,'Value') == 0
        set(handles.slowWavesPlot(i),'Visible','off');
    else
        set(handles.slowWavesPlot(i),'Visible','on');
    end
end

function plotSlowWaves(hObject, handles)
%t = tic;
    table_waves = getSlowWaves(hObject,handles,handles.eeg);
    handles = guidata(hObject);
    set(handles.slowWaveTable,'Data',table_waves);
    handles.slowWavesPlot = ones(20000,1); % if it were zeros, we might get a root object error when we delete the plots
    for i=1:length(handles.slow_waves(:,1))
    	handles.slowWavesPlot(i) = plot(handles.plot1,handles.filtered_matrix(handles.slow_waves(i,2):handles.slow_waves(i,4),1),handles.filtered_matrix(handles.slow_waves(i,2):handles.slow_waves(i,4),handles.eeg),'LineWidth',2,'Color',[1 0 0]); % Plot the slow wave
    end
    handles.slowWavesPlot = handles.slowWavesPlot(handles.slowWavesPlot~=1);   
    num_slow_waves = length(handles.slow_waves(:,1));
    num_slow_waves_string = ['Number of Slow Waves: ',num2str(num_slow_waves)];
    set(handles.numSlowWaves,'String',num_slow_waves_string);
    guidata(hObject,handles);
   % disp(['Plot Slow Waves: ', num2str(toc(t))]);
    
function table_waves = getSlowWaves(hObject,handles,eeg)
   % t = tic;
    if ~isfield(handles,'filtered_matrix')
        handles.filtered_matrix = constructFilter(handles);
    end
    if handles.manual_amplitude == 0
        setMinAmplitude(handles);
    end 
    minTime = str2double(get(handles.p2ptime,'String')); % time (in seconds) specifies the length a positive deflection must be to be deemed a slow wave.
    maxTime = str2double(get(handles.maxp2ptime,'String'));
    minAmplitude = str2double(get(handles.amplitude,'String'));
    maxAmplitude = str2double(get(handles.maxAmplitude,'String'));
    %time = tic;
    handles.slow_waves = SlowWaveDetect(handles,eeg);
    %disp(['Slow Wave Detect: ', num2str(toc(time))]);
    handles.slow_waves = handles.slow_waves(handles.slow_waves(:,5)>=minTime,:);
    handles.slow_waves = handles.slow_waves(handles.slow_waves(:,5)<=maxTime,:);
    handles.slow_waves = handles.slow_waves(handles.slow_waves(:,6)>=minAmplitude,:);
    handles.slow_waves = handles.slow_waves(handles.slow_waves(:,6)<=maxAmplitude,:);
    table_waves = handles.slow_waves;
    table_waves(:,2:4) = table_waves(:,2:4)/handles.hertz;
    guidata(hObject,handles);
   % disp(['Get Slow Waves: ', num2str(toc(t))]);
    
function setMinAmplitude(handles)
    if length(handles.filtered_matrix(:,handles.eeg))/handles.hertz > 600
        summary = quantile(handles.filtered_matrix(1:handles.hertz*600,handles.eeg),[.05 .95]);
    else
        summary = quantile(handles.filtered_matrix(:,handles.eeg),[.05 .95]);
    end
    set(handles.amplitude,'String',abs(summary(1))+abs(summary(2)));
        
function updatePlots(hObject, eventdata, handles)
   % t = tic;
    xlimits = get(handles.plot1,'XLim');
    ylimits = get(handles.plot1,'YLim');
    hold(handles.plot1,'off');
    
    plotRawData(hObject,handles,xlimits,ylimits);
    handles = guidata(hObject);
    hold(handles.plot1,'on');
    
    if isfield(handles,'edfheader')
        label = handles.edfheader.label(get(handles.channel,'Value'));
    else
        label = cell(1,1);
        label{1} = get(handles.channel,'String');
    end
    if ~strcmp(label{1}(1,1:3),'EEG')
        return;
    else
        plotFilteredData(hObject, handles);
        handles = guidata(hObject);

        plotSlowWaves(hObject, handles);
        handles = guidata(hObject);

        plotFirstNegativePeaks(hObject, handles);
        handles = guidata(hObject);
        plotMaxVoltage(hObject, handles);
        handles = guidata(hObject);
        plotSecondNegativePeaks(hObject, handles);
        handles = guidata(hObject);
    end
    
    set(handles.plot1,'XLim',xlimits);
    set(handles.plot1,'YLim',ylimits);
    ylabel(handles.plot1,'Amplitude (µV)');
    xlabel(handles.plot1,'Time (sec)');
    determineVisibility(handles);
    handles.manual_amplitude = 0;
    guidata(hObject,handles);
   % disp(['Update Plots: ', num2str(toc(t))]);

    
function determineVisibility(handles)
    if get(handles.rawData,'Value') == 0
        set(handles.rawPlot,'Visible','off')
    else
        set(handles.rawPlot,'Visible','on')
    end
    if get(handles.filteredData,'Value') == 0
        set(handles.filteredPlot,'Visible','off')
    else
        set(handles.filteredPlot,'Visible','on')
    end
    if get(handles.slowWaves,'Value') == 0
        set(handles.slowWavesPlot,'Visible','off')
    else
        set(handles.slowWavesPlot,'Visible','on')
    end
    if get(handles.negativePeakOne,'Value') == 0
        set(handles.negativePeakOnePlot,'Visible','off')
    else
        set(handles.negativePeakOnePlot,'Visible','on')
    end
    if get(handles.maximumVoltage,'Value') == 0
        set(handles.maxVoltagePlot,'Visible','off')
    else
        set(handles.maxVoltagePlot,'Visible','on')
    end
    if get(handles.negativePeakTwo,'Value') == 0
        set(handles.negativePeakTwoPlot,'Visible','off')
    else
        set(handles.negativePeakTwoPlot,'Visible','on')
    end

% --- Executes on button press in negativePeakOne.
function negativePeakOne_Callback(hObject, eventdata, handles)
% hObject    handle to negativePeakOne (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of negativePeakOne
if ~ishandle(handles.negativePeakOnePlot)
    updatePlots(hObject, eventdata, handles);
end
if get(handles.negativePeakOne,'Value') == 0
    set(handles.negativePeakOnePlot,'Visible','off');
else
    set(handles.negativePeakOnePlot,'Visible','on');
end


function plotFirstNegativePeaks(hObject,handles)     
    handles.negativePeakOnePlot = scatter(handles.plot1,handles.filtered_matrix(handles.slow_waves(:,2)),handles.filtered_matrix(handles.slow_waves(:,2),handles.eeg),'v','MarkerFaceColor',[0 1 0],'MarkerEdgeColor',[0 .4 0]); % Plot the start point
    guidata(hObject,handles);

% --- Executes on button press in maximumVoltage.
function maximumVoltage_Callback(hObject, eventdata, handles)
% hObject    handle to maximumVoltage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of maximumVoltage
if ~ishandle(handles.maxVoltagePlot)
    updatePlots(hObject, eventdata, handles);
end
if get(handles.maximumVoltage,'Value') == 0
    set(handles.maxVoltagePlot,'Visible','off');
else
    set(handles.maxVoltagePlot,'Visible','on');
end



function plotMaxVoltage(hObject,handles)  
    handles.maxVoltagePlot = scatter(handles.plot1,handles.filtered_matrix(handles.slow_waves(:,12)),handles.filtered_matrix(handles.slow_waves(:,12),handles.eeg),'^','MarkerFaceColor',[1 1 0],'MarkerEdgeColor',[.4 .4 0]); 
    guidata(hObject,handles);
    
% --- Executes on button press in zeroCrossingTwo.
function zeroCrossingTwo_Callback(hObject, eventdata, handles)
% hObject    handle to zeroCrossingTwo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of zeroCrossingTwo


% --- Executes on button press in negativePeakTwo.
function negativePeakTwo_Callback(hObject, eventdata, handles)
% hObject    handle to negativePeakTwo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of negativePeakTwo
if ~ishandle(handles.negativePeakTwoPlot)
    updatePlots(hObject, eventdata, handles);
end
if get(handles.negativePeakTwo,'Value') == 0
    set(handles.negativePeakTwoPlot,'Visible','off');
else
    set(handles.negativePeakTwoPlot,'Visible','on');
end


function plotSecondNegativePeaks(hObject,handles) 
    handles.negativePeakTwoPlot = scatter(handles.plot1,handles.filtered_matrix(handles.slow_waves(:,4)),handles.filtered_matrix(handles.slow_waves(:,4),handles.eeg),'v','MarkerFaceColor',[.8 0 0],'MarkerEdgeColor',[.2 0 0]); % Plot the start point
    guidata(hObject,handles);

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider4_Callback(hObject, eventdata, handles)
% hObject    handle to slider4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function lowPassEdge_Callback(hObject, eventdata, handles)
% hObject    handle to lowPassEdge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lowPassEdge as text
%        str2double(get(hObject,'String')) returns contents of lowPassEdge as a double
updatePlots(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function lowPassEdge_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lowPassEdge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function highPassEdge_Callback(hObject, eventdata, handles)
% hObject    handle to highPassEdge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of highPassEdge as text
%        str2double(get(hObject,'String')) returns contents of highPassEdge as a double
updatePlots(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function highPassEdge_CreateFcn(hObject, eventdata, handles)
% hObject    handle to highPassEdge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function lowStopEdge_Callback(hObject, eventdata, handles)
% hObject    handle to lowStopEdge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lowStopEdge as text
%        str2double(get(hObject,'String')) returns contents of lowStopEdge as a double
updatePlots(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function lowStopEdge_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lowStopEdge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function highStopEdge_Callback(hObject, eventdata, handles)
% hObject    handle to highStopEdge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of highStopEdge as text
%        str2double(get(hObject,'String')) returns contents of highStopEdge as a double
updatePlots(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function highStopEdge_CreateFcn(hObject, eventdata, handles)
% hObject    handle to highStopEdge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function passBandRipple_Callback(hObject, eventdata, handles)
% hObject    handle to passBandRipple (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of passBandRipple as text
%        str2double(get(hObject,'String')) returns contents of passBandRipple as a double
updatePlots(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function passBandRipple_CreateFcn(hObject, eventdata, handles)
% hObject    handle to passBandRipple (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function stopBandAttenuation_Callback(hObject, eventdata, handles)
% hObject    handle to stopBandAttenuation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stopBandAttenuation as text
%        str2double(get(hObject,'String')) returns contents of stopBandAttenuation as a double
updatePlots(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function stopBandAttenuation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stopBandAttenuation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function originalSampleRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to originalSampleRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes during object creation, after setting all properties.
function filename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% BUG Epoch's at the end of the table of slow waves


% --- Executes when selected cell(s) is changed in slowWaveTable.
function slowWaveTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to slowWaveTable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
% handles = guidata(gcf);
handles = guidata(hObject);
epochLength = str2double(get(handles.epochLength,'String'));
selected_cells = eventdata.Indices;
if numel(selected_cells) ~= 0
    if length(selected_cells(:,1)) > 1
        if selected_cells(1,2) == 1
            fftlimits = [(epochLength*(handles.slow_waves(selected_cells(1,1),1)-1)) (epochLength*(handles.slow_waves(selected_cells(end,1),1)-1))+epochLength];
            xlimits = fftlimits;
        else
            fftlimits = [handles.filtered_matrix(floor(handles.slow_waves(selected_cells(1,1),2)),1) handles.filtered_matrix(ceil(handles.slow_waves(selected_cells(end,1),4)),1)];
            xlimits = [fftlimits(1)-.25 fftlimits(2)+.25];
        end
    else
        if selected_cells(1,2) == 1
            fftlimits = [(epochLength*(handles.slow_waves(selected_cells(1,1),1)-1)) (epochLength*(handles.slow_waves(selected_cells(1,1),1)-1))+epochLength];
            xlimits = fftlimits;
        else
            fftlimits = [handles.filtered_matrix(floor(handles.slow_waves(selected_cells(1,1),2)),1) handles.filtered_matrix(ceil(handles.slow_waves(selected_cells(1,1),4)),1)];
            xlimits = [fftlimits(1)-.25 fftlimits(2)+.25];
        end
    end
    set(handles.plot1,'XLim',xlimits);
    set(handles.slider1,'Value',xlimits(1));
    determineWindow(handles);
    if handles.hertz*fftlimits(2) > length(handles.filtered_matrix)
        fftlimits(2) = length(handles.filtered_matrix)/handles.hertz;
    end
    plotlimits = round(handles.hertz*fftlimits(1))+1:round(handles.hertz*fftlimits(2));
    [f,a] = freqspec(handles.filtered_matrix(plotlimits,handles.eeg),handles.hertz);
    plot(handles.fftplot,f,a);
    title(handles.fftplot,'Fast Fourier Transform');
    xlabel(handles.fftplot,'Frequency (Hz)');
    ylabel(handles.fftplot,'Amplitude (µV)');
    set(handles.fftplot,'Xlim',[0 30]);
end
setappdata(get(handles.plot1, 'ZLabel'), 'ZOOMAxesData', [handles.matrix(1,1) handles.matrix(end,1)]); % Fixes a bug in the zoom out button.

%% Flashes the selection
% for i = 1:3
% flash = plot(handles.plot1,handles.filtered_matrix(plotlimits,1),handles.filtered_matrix(plotlimits,handles.eeg),'Color',[1 .6 0],'LineWidth',2);
% pause(.1);
% delete(flash);
% pause(.1);
% end
% --------------------------------------------------------------------


function uipushtool2_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtool2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


set(handles.plot1,'XLim',[handles.matrix(1,1) handles.matrix(end,1)]);
set(handles.plot1,'YLim',[-480 480]);
dataSeconds = length(handles.matrix(:,1))/handles.hertz; 
units = get(handles.windowUnits,'Value');
if units == 1
    set(handles.window,'String',dataSeconds*1000);
elseif units == 2
    set(handles.window,'String',dataSeconds);
elseif units == 3
    set(handles.window,'String',dataSeconds/60);
end

function zoomPostCallback(hObject, eventdata, handles)

xlimits = get(handles.plot1,'Xlim');
time = xlimits(2)-xlimits(1);
set(handles.window,'String',time);

% --- Executes on button press in export.
function export_Callback(hObject, eventdata, handles)
% hObject    handle to export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of export
filename = get(handles.filename,'String');

[~,savename,~] = fileparts(filename);
savename = [savename,' Slow Waves'];
[savename, pathname, filter] = uiputfile( ...
    {'*.xlsx','Excel File (*.xlsx)';'*.mat','Matlab File';'*.*', 'All Files'},'Save As',savename);
if savename == 0 
    return;
else
    if pathname == 0
        fullname = savename;
    else
        fullname = fullfile(pathname,savename);
    end
    if filter == 1
        excelExport(hObject, handles, fullname);
    else
        save(fullname,handles.slow_waves);
    end
end

function num_slow_waves = excelExport(hObject, handles, fullname)
    numSheets = length(get(handles.channel,'String'));
    % Suppress spreadsheet creation warning
    warning('off','MATLAB:xlswrite:AddSheet');
    num_slow_waves = cell(3,numSheets+1);
    num_slow_waves{2,1} = 'Number of Slow Waves';
    num_slow_waves{3,1} = 'Minimum Amplitude';
    for i=1:numSheets
        handles.eeg = i+1;
        table_waves = num2cell(getSlowWaves(hObject,handles,handles.eeg));
        handles = guidata(hObject);
        sheetname = ['EEG ',num2str(i)];
        num_slow_waves{1,i+1} = sheetname;
        num_slow_waves{2,i+1} = length(table_waves);
        summary = quantile(handles.filtered_matrix(:,handles.eeg),[.05 .95]);
        num_slow_waves{3,i+1} = abs(summary(1))+abs(summary(2));
        col_header = get(handles.slowWaveTable,'ColumnName')';
        output_matrix = [col_header; table_waves]; % Join cell arrays
        
        % Solve memory
        % Smooth loadbar for batch export       
        % WRITE FUNCTION WITHIN UPDATE PLOTS THAT SWITCHES EDF MATRICES!!!
        
        write = 0;
        while write == 0
            try
                xlswrite(fullname, output_matrix , sheetname);
                write = 1;
            catch err
                response = questdlg(err.message,'Other application(s) using file','Resume','Cancel','Resume');  % Tell user to close file.
                if strcmp(response,'Cancel')
                    return;
                end
            end
        end
    end
    write = 0;
    while write == 0
        try
            xlswrite(fullname, num_slow_waves, 'Total Slow Waves Per Channel');
            write = 1;
        catch err
            response = questdlg(err.message,'Other application(s) using file','Resume','Cancel','Resume');  % Tell user to close file.
            if strcmp(response,'Cancel')
                return;
            end
        end
    end
    deleteEmptyExcelSheets(fullname);
 

function deleteEmptyExcelSheets(fileName)
% Check whether the file exists
if ~exist(fileName,'file')
    error([fileName ' does not exist !']);
    else
    % Check whether it is an Excel file
    typ = xlsfinfo(fileName);
    if ~strcmp(typ,'Microsoft Excel Spreadsheet')
        error([fileName ' not an Excel sheet !']);
    end
end

% If fileName does not contain a "\" the name of the current path is added
% to fileName. The reason for this is that the full path is required for
% the command "excelObj.workbooks.Open(fileName)" to work properly.
if isempty(strfind(fileName,'\'))
    fileName = [cd '\' fileName];
end

excelObj = actxserver('Excel.Application');
excelWorkbook = excelObj.workbooks.Open(fileName);
worksheets = excelObj.sheets;
sheetIdx = 1;
sheetIdx2 = 1;
numSheets = worksheets.Count;
% Prevent beeps from sounding if we try to delete a non-empty worksheet.
excelObj.EnableSound = false;

% Loop over all sheets
while sheetIdx2 <= numSheets
% Saves the current number of sheets in the workbook
temp = worksheets.count;
% Check whether the current worksheet is the last one. As there always
% need to be at least one worksheet in an xls-file the last sheet must
% not be deleted.
    if or(sheetIdx>1,numSheets-sheetIdx2>0)
    % worksheets.Item(sheetIdx).UsedRange.Count is the number of used cells.
    % This will be 1 for an empty sheet. It may also be one for certain other
    % cases but in those cases, it will beep and not actually delete the sheet.
        if worksheets.Item(sheetIdx).UsedRange.Count == 1
            worksheets.Item(sheetIdx).Delete;
        end
    end
    % Check whether the number of sheets has changed. If this is not the
    % case the counter "sheetIdx" is increased by one.
    if temp == worksheets.count;
        sheetIdx = sheetIdx + 1;
    end
    sheetIdx2 = sheetIdx2 + 1; % prevent endless loop...
end
excelObj.EnableSound = true;
excelWorkbook.Save;
excelWorkbook.Close(false);
excelObj.Quit;
delete(excelObj);
return; 
 


function epochLength_Callback(hObject, eventdata, handles)
% hObject    handle to epochLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of epochLength as text
%        str2double(get(hObject,'String')) returns contents of epochLength as a double
updatePlots(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function epochLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to epochLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function p2ptime_Callback(hObject, eventdata, handles)
% hObject    handle to p2ptime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of p2ptime as text
%        str2double(get(hObject,'String')) returns contents of p2ptime as a double
updatePlots(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function p2ptime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to p2ptime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function amplitude_Callback(hObject, eventdata, handles)
% hObject    handle to amplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of amplitude as text
%        str2double(get(hObject,'String')) returns contents of amplitude as
%        a double
if isempty(str2double(get(hObject,'String')))
    set(handles.amplitude,'String',0);
end
handles.manual_amplitude = 1;
updatePlots(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function amplitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to amplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function plot1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plot1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate plot1



function maxp2ptime_Callback(hObject, eventdata, handles)
% hObject    handle to maxp2ptime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxp2ptime as text
%        str2double(get(hObject,'String')) returns contents of maxp2ptime as a double
updatePlots(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function maxp2ptime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxp2ptime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function maxAmplitude_Callback(hObject, eventdata, handles)
% hObject    handle to maxAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxAmplitude as text
%        str2double(get(hObject,'String')) returns contents of maxAmplitude as a double
if isempty(str2double(get(hObject,'String')))
    set(handles.maxAmplitude,'String',0);
end
updatePlots(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function maxAmplitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxAmplitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function windowUnits_CreateFcn(hObject, eventdata, handles)
% hObject    handle to windowUnits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function compression_CreateFcn(hObject, eventdata, handles)
% hObject    handle to compression (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function window_CreateFcn(hObject, eventdata, handles)
% hObject    handle to window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function channel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function exportloop_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to exportloop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename]=uigetfile({'*.edf','EDF Files (*.edf)';'*.txt','Text Files (*.txt)';'*.*','All Files'},...
    'Select Files for Batch Processing','MultiSelect','on');
if ~iscell(filename) && length(filename)<=1 && filename == 0
    return;
end

if ~iscell(filename)
    file = filename;
    filename = cell(1,1);
    filename{1} = file;
end

[summaryname,filepath]=uiputfile({'*.xlsx','Excel Files (*.xlsx)'},'Name the Experiment Summary and Select a Destination');
if ~iscell(summaryname) && length(summaryname)<=1 && summaryname == 0
    return;
else
    for i = 1:length(filename)
        if filename{i} == 0
            disp([filename{i},' could not be opened.']);
        else
            if filepath == 0
                null;
            else
                filename{i} = fullfile(filepath,filename{i});
            end
            [dir,file,~] = fileparts(filename{i});
            if exist([dir,'\',file,' Slow Waves.xlsx'],'file')
                prompt = [[file,' Slow Waves.xlsx'],' already exists. Do you want to overwrite the file?']; % Create a prompt string
                response = questdlg(prompt,'File exists','Yes to All','Yes','No','Yes to All');  % Ask to overwrite
%                 handles.questprmpt = 0;
                if strcmp(response,'Yes to All')
                    break;
                elseif strcmp(response,'Yes')
                    continue;
                elseif strcmp(response,'No')
                    filename{i} = [];
                elseif strcmp(response,'Cancel Export')
                    return;
                end
            end
        end
    end
    filename = filename(~cellfun('isempty',filename));
    summary = cell(2+(length(filename)),length(get(handles.channel,'String'))+1);
    summary{2,1} = 'Minimum Amplitude';
    for i = 1:length(get(handles.channel,'String'))
        summary{1,i+1} = ['EEG ', num2str(i)];
    end
    handles.num_of_files = length(filename);
    for i = 1:length(filename)
        handles.current_file = i;
        [~,handlename,ext] = fileparts(filename{i});
        initializeSettings(hObject, handles, [handlename,ext]);
        handles = guidata(hObject);
        num_slow_waves = excelExport(hObject,handles,[[filepath,'\', handlename,' Slow Waves'],'.xlsx']);
        summary{2*i,1} = handlename;
        summary(2*i,2:length(get(handles.channel,'String'))+1) = num_slow_waves(2,2:length(get(handles.channel,'String'))+1);
        summary(2*i+1,2:length(get(handles.channel,'String'))+1) = num_slow_waves(3,2:length(get(handles.channel,'String'))+1);
        close(handles.bar);
    end   
    write = 0;
    while write == 0
        try
            xlswrite([filepath,summaryname], summary, 'Experiment Summary');
            write = 1;
        catch err
            response = questdlg(err.message,'Other application(s) using file','Resume','Cancel','Resume');  % Tell user to close file.
            if strcmp(response,'Cancel')
                return;
            end
        end
    end
    deleteEmptyExcelSheets([filepath,summaryname]);
    guidata(hObject,handles);
end
