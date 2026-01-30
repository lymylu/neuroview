function varargout = Pop_time_frequency_analysis(varargin)
% POP_TIME_FREQUENCY_ANALYSIS M-file for Pop_time_frequency_analysis.fig
%      POP_TIME_FREQUENCY_ANALYSIS, by itself, creates a new POP_TIME_FREQUENCY_ANALYSIS or raises the existing
%      singleton*.
%
%      H = POP_TIME_FREQUENCY_ANALYSIS returns the handle to a new POP_TIME_FREQUENCY_ANALYSIS or the handle to
%      the existing singleton*.
%
%      POP_TIME_FREQUENCY_ANALYSIS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in POP_TIME_FREQUENCY_ANALYSIS.M with the given input arguments.
%
%      POP_TIME_FREQUENCY_ANALYSIS('Property','Value',...) creates a new POP_TIME_FREQUENCY_ANALYSIS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Pop_time_frequency_analysis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Pop_time_frequency_analysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Pop_time_frequency_analysis

% Last Modified by GUIDE v2.5 04-Apr-2012 12:40:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Pop_time_frequency_analysis_OpeningFcn, ...
                   'gui_OutputFcn',  @Pop_time_frequency_analysis_OutputFcn, ...
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


% --- Executes just before Pop_time_frequency_analysis is made visible.
function Pop_time_frequency_analysis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Pop_time_frequency_analysis (see VARARGIN)

% Choose default command line output for Pop_time_frequency_analysis
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Pop_time_frequency_analysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);
[loadfilename, loadpathname] = uigetfile('*.set','Pick EEG files','MultiSelect', 'on');
if ~iscell(loadfilename); tmp{1} = loadfilename; loadfilename=tmp; end
EEG = pop_loadset([loadpathname,loadfilename{1}]);
for i=1:length(EEG.chanlocs)
    labels{i}=EEG.chanlocs(i).labels;
end
if length(EEG.chanlocs)==0
    labels{i}='1';
end
set(handles.channel_list,'String',labels);
TFA.loadfilename=loadfilename;
TFA.loadpathname=loadpathname;
assignin('base','TFA',TFA);

% --- Outputs from this function are returned to the command line.
function varargout = Pop_time_frequency_analysis_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function time_low_limit_Callback(hObject, eventdata, handles)
% hObject    handle to time_low_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of time_low_limit as text
%        str2double(get(hObject,'String')) returns contents of time_low_limit as a double


% --- Executes during object creation, after setting all properties.
function time_low_limit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time_low_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function time_high_limit_Callback(hObject, eventdata, handles)
% hObject    handle to time_high_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of time_high_limit as text
%        str2double(get(hObject,'String')) returns contents of time_high_limit as a double


% --- Executes during object creation, after setting all properties.
function time_high_limit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time_high_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_low_limit_Callback(hObject, eventdata, handles)
% hObject    handle to freq_low_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_low_limit as text
%        str2double(get(hObject,'String')) returns contents of freq_low_limit as a double


% --- Executes during object creation, after setting all properties.
function freq_low_limit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_low_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function freq_high_limit_Callback(hObject, eventdata, handles)
% hObject    handle to freq_high_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of freq_high_limit as text
%        str2double(get(hObject,'String')) returns contents of freq_high_limit as a double


% --- Executes during object creation, after setting all properties.
function freq_high_limit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to freq_high_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in confirm.
function confirm_Callback(hObject, eventdata, handles)
% hObject    handle to confirm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
TFA = evalin('base', 'TFA');
loadfilename=TFA.loadfilename;
loadpathname=TFA.loadpathname;

time_low_limit =str2num( get(handles.time_low_limit,'string'));
time_high_limit =str2num( get(handles.time_high_limit,'string'));
freq_low_limit =str2num( get(handles.freq_low_limit,'string'));
freq_high_limit =str2num( get(handles.freq_high_limit,'string'));
% select channels
index_selected = get(handles.channel_list,'Value');
close;

NumFiles = length(loadfilename);
for nfile=1:NumFiles
    EEG = pop_loadset([loadpathname,loadfilename{nfile}]);
    xtimes = EEG.times.'/1000; % time axis of data x (unit: sec)
    Fs = EEG.srate; % sampling rate
    N_Trials = EEG.trials; % number of trials
    % time-freqeuncy parameters used in time-frequency analysis (TFA)
    df = 1; % the frequency step between two frequency bins evaluated in TFA
    t = xtimes(find(xtimes>=time_low_limit/1000 & xtimes<=time_high_limit/1000));
    f = [freq_low_limit:df:min(Fs/2,freq_high_limit)]'; % frequency bins evaluated in TFA (it is better to use a frequency step of 1/(2^k), athough others are OK)

    N_Time = length(t);
    N_Freq = length(f);

    %% PART III: Time-frequency analysis
    S = single(zeros(N_Freq,N_Time,N_Trials));
    x = squeeze(EEG.data(index_selected,:,:)); % data to be analyzed (points x trials)

      %% MWT (morlet wavelet transform)
    TFA_opt = 'MWT';                % STFT or MWT
    TFA_PARAM.detrend_opt = 1;      % detrend the data when performing MWT (if reconstruct is needed, then it is 0)
    TFA_PARAM.algm_opt = 'fast';    % how to calculate MWT
    TFA_PARAM.omega = 5;            % to define the central frequency of Morlet wavelet
    TFA_PARAM.sigma = 0.15;          % to define the spread of Morlet wavelet in time domain
    for n_trial=1:size(x,2)
        [S(:,:,n_trial)] = sub_mwt(x(:,n_trial), xtimes, t, f, Fs, TFA_PARAM.omega, TFA_PARAM.sigma, TFA_PARAM.detrend_opt, TFA_PARAM.algm_opt);
    end
    P = (abs(S).^2);
    zero_index=find(abs(t)==min(abs(t)));
    t_baseln_idx = round(zero_index*0.2):round(zero_index*0.8);
    % baseline value is obtained from each trial, NOT all trials
    P_Baseline_Mean_Vec = mean(mean(P(:,t_baseln_idx,:),3),2);
    P_Baseline_Mean = repmat(P_Baseline_Mean_Vec,[1,size(P,2),size(P,3)]);
    TFA.unit = 'ER';
    P_BC = (P - P_Baseline_Mean );%./P_Baseline_Mean;
    TFA.P_BC(:,:,nfile)=squeeze(mean(P_BC,3));
end
zero_index=find(abs(t)==min(abs(t)));
t_baseln_idx = round(zero_index*0.2):round(zero_index*0.8);

TFA.channel=EEG.chanlocs;
TFA.chan_idx=index_selected;
TFA.t=t;
TFA.f=f;
TFA.Fs=Fs;
assignin('base','TFA',TFA);
figure;hold on;
imagesc(t,f,squeeze(mean(TFA.P_BC,3)));axis xy;
axis([time_low_limit/1000 time_high_limit/1000 freq_low_limit freq_high_limit]);
xlabel('time (s)');
ylabel('frequency (Hz)');
my_handle=colorbar;
set(get(my_handle,'Title'),'string','uV^2');

% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close;

% --- Executes on selection change in channel_list.
function channel_list_Callback(hObject, eventdata, handles)
% hObject    handle to channel_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns channel_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_list


% --- Executes during object creation, after setting all properties.
function channel_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
