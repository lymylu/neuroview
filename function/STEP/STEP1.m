function varargout = STEP1(varargin)
% STEP M-file for STEP.fig
%      STEP1, by itself, creates a new STEP1 or raises the existing
%      singleton*.
%
%      H = STEP1 returns the handle to a new STEP1 or the handle to
%      the existing singleton*.
%
%      STEP1('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STEP1.M with the given input arguments.
%
%      STEP1('Property','Value',...) creates a new STEP1 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before STEP1_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to STEP1_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help STEP1

% Last Modified by GUIDE v2.5 02-May-2012 23:50:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @STEP1_OpeningFcn, ...
                   'gui_OutputFcn',  @STEP1_OutputFcn, ...
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


% --- Executes just before STEP1 is made visible.
function STEP1_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to STEP1 (see VARARGIN)

% Choose default command line output for STEP1
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes STEP1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% display start image 
h = axes('Position',[0.05 -0.07 0.9 1]); % [0.2 0.2 0.3 0.3]����λ�úʹ�С
xx = imread('start.tif'); %% need to change!!!
imshow(xx);
EEG=[];

ST.peak=[];
ST.interval=[];
ST.regressor=[];
ST.Coeffs=[];
ST.parameter=[];

ST.ROI=[];
ST.TF_ST=[];
ST.TFA=[];
ST.TF=[];
ST.TFA_avg=[];

ST.MPA=[];
ST.MP=[];
ST.MPROI=[];
ST.density=[];
ST.type=[];
ST.automanu=[];
ST.auto=[];
ST.MPA_avg=[];
ST.MP_ST=[];
ST.channel_index=1;
assignin('base', 'EEG',EEG);
assignin('base', 'ST',ST);

% --- Outputs from this function are returned to the command line.
function varargout = STEP1_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function save_EEGLAB_data_Callback(hObject, eventdata, handles)
% hObject    handle to save_EEGLAB_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% save file with EEGLAB format
EEG = evalin('base', 'EEG');
pop_saveset( EEG );

% --------------------------------------------------------------------
function Save_single_trial_values_Callback(hObject, eventdata, handles)
% hObject    handle to Save_single_trial_wft_values (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
MLRd=ST.parameter;
WFT=ST.TF_ST;
MP=ST.MP_ST;
[filename, pathname, filterindex] = uiputfile({'*.mat','MAT-files (*.mat)'},'Save as');
fn=[pathname, filename];

save(fn,'MLRd', 'WFT', 'MP');

% --------------------------------------------------------------------
function MLRd_Callback(hObject, eventdata, handles)
% hObject    handle to MLRd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
ST.method_type=1;
assignin('base', 'ST',ST);
Pop_channel_selection();


% --------------------------------------------------------------------
function Windowed_Fourier_transform_Callback(hObject, eventdata, handles)
% hObject    handle to Windowed_Fourier_transform (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
ST.method_type=2;
assignin('base', 'ST',ST);
Pop_channel_selection();


% --------------------------------------------------------------------
function Matching_pursuit_Callback(hObject, eventdata, handles)
% hObject    handle to Matching_pursuit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
ST.method_type=3;
assignin('base', 'ST',ST);
Pop_channel_selection();


% --------------------------------------------------------------------
function Average_WFT_Callback(hObject, eventdata, handles)
% hObject    handle to Average_WFT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
figure;imagesc(ST.TF.t,ST.TF.f,ST.TFA_avg);axis xy;%axis([Pre_limit Post_limit],[Low_limit High_limit]);
xlabel('Time (ms)','fontsize',8); 
ylabel('Frequency (Hz)','fontsize',8);
colorbar;

% --------------------------------------------------------------------
function Single_trial_WFT_Callback(hObject, eventdata, handles)
% hObject    handle to Single_trial_WFT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
ST.plot_type=1;
assignin('base', 'ST',ST);
STTF_plot();
% --------------------------------------------------------------------
function Import_EEG_data_Callback(hObject, eventdata, handles)
% hObject    handle to Import_EEG_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Import EEG data
EEG = pop_importdata();
EEG = eeg_checkset( EEG );
assignin('base', 'EEG',EEG);

% --------------------------------------------------------------------
function Import_Markers_Callback(hObject, eventdata, handles)
% hObject    handle to Import_Markers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Import markers
EEG = evalin('base', 'EEG');
EEG = pop_importevent( EEG );
EEG = eeg_checkset( EEG );
assignin('base', 'EEG',EEG);

% --------------------------------------------------------------------
function Save_Callback(hObject, eventdata, handles)
% hObject    handle to Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function Exit_Callback(hObject, eventdata, handles)
% hObject    handle to Exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close;

% --------------------------------------------------------------------
function Filter_Callback(hObject, eventdata, handles)
% hObject    handle to Filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EEG = evalin('base', 'EEG');
EEG = pop_eegfilt(EEG);
EEG = eeg_checkset( EEG );
assignin('base', 'EEG',EEG);

% --------------------------------------------------------------------
function Epoch_Callback(hObject, eventdata, handles)
% hObject    handle to Epoch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EEG = evalin('base', 'EEG');
EEG = pop_epoch( EEG);
EEG = eeg_checkset( EEG );
assignin('base', 'EEG',EEG);

% --------------------------------------------------------------------
function Baseline_correction_Callback(hObject, eventdata, handles)
% hObject    handle to Baseline_correction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EEG = evalin('base', 'EEG');
EEG = pop_rmbase(EEG);
EEG = eeg_checkset( EEG );
assignin('base', 'EEG',EEG);

% --------------------------------------------------------------------
function Time_domain_Callback(hObject, eventdata, handles)
% hObject    handle to Time_domain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Time_frequency_domain_Callback(hObject, eventdata, handles)
% hObject    handle to Time_frequency_domain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Continous_EEG_Callback(hObject, eventdata, handles)
% hObject    handle to Continous_EEG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EEG = evalin('base', 'EEG');
pop_eegplot( EEG, 1, 1, 0);
EEG = eeg_checkset( EEG );
assignin('base', 'EEG',EEG);

% --------------------------------------------------------------------
function Epoched_EEG_Callback(hObject, eventdata, handles)
% hObject    handle to Epoched_EEG (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EEG = evalin('base', 'EEG');
pop_erpimage(EEG,1);
EEG = eeg_checkset( EEG );
assignin('base', 'EEG',EEG);

% --------------------------------------------------------------------
function Regressors_Callback(hObject, eventdata, handles)
% hObject    handle to Regressors (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EEG = evalin('base', 'EEG');
ST = evalin('base', 'ST');
T=find(EEG.times>=ST.interval(1)&EEG.times<=ST.interval(2));
for i=1:length(ST.regressor)
    figure;hold on;grid on;
    plot(EEG.times(T),ST.regressor{i}(:,1),'r','linewidth',2);
    plot(EEG.times(T),ST.regressor{i}(:,2),'g','linewidth',2);
    plot(EEG.times(T),ST.regressor{i}(:,3),'b','linewidth',2);
    hold off
end

% --------------------------------------------------------------------
function Time_frequency_plot_Callback(hObject, eventdata, handles)
% hObject    handle to Time_frequency_plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function File_Callback(hObject, eventdata, handles)
% hObject    handle to File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Single_trial_WFT_analysis_Callback(hObject, eventdata, handles)
% hObject    handle to Single_trial_WFT_analysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function View_Callback(hObject, eventdata, handles)
% hObject    handle to View (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --------------------------------------------------------------------
function Load__EEGLAB_data_Callback(hObject, eventdata, handles)
% hObject    handle to Load__EEGLAB_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Load existing dataset with EEGLAB format
EEG = pop_loadset();
EEG = eeg_checkset( EEG );
assignin('base', 'EEG',EEG);


% --------------------------------------------------------------------
function Close_Callback(hObject, eventdata, handles)
% hObject    handle to Close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EEG = evalin('base', 'EEG');
ST = evalin('base', 'ST');
EEG=[];
ST.peak=[];
ST.interval=[];
ST.regressor=[];
ST.Coeffs=[];
ST.parameter=[];

ST.ROI=[];
ST.TF_ST=[];
ST.TFA=[];
ST.TF=[];
ST.TFA_avg=[];

ST.MPA=[];
ST.MP=[];
ST.MPROI=[];
ST.density=[];
ST.type=[];
ST.automanu=[];
ST.auto=[];
ST.MPA_avg=[];
ST.MP_ST=[];
ST.channel_index=1;
assignin('base', 'EEG',EEG);
assignin('base', 'ST',ST);



% --------------------------------------------------------------------
function Average_MP_Callback(hObject, eventdata, handles)
% hObject    handle to Average_MP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
P_avg=ST.MPA_avg;
T=ST.MP.t;
f=ST.MP.f;
figure;imagesc(T,f,P_avg);axis xy;%axis([Pre_limit Post_limit],[Low_limit High_limit]);
xlabel('Time (ms)','fontsize',8); 
ylabel('Frequency (Hz)','fontsize',8);
colorbar;

% --------------------------------------------------------------------
function Single_trial_MP_Callback(hObject, eventdata, handles)
% hObject    handle to Single_trial_MP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
ST.plot_type=0;
assignin('base', 'ST',ST);
STTF_plot();

% --------------------------------------------------------------------
function Single_trial_analysis_Callback(hObject, eventdata, handles)
% hObject    handle to Single_trial_analysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --------------------------------------------------------------------
function WF_MLRd_Callback(hObject, eventdata, handles)
% hObject    handle to WF_MLRd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
ST.method_type=5;
assignin('base', 'ST',ST);
Pop_channel_selection();

% --------------------------------------------------------------------
function WF_Callback(hObject, eventdata, handles)
% hObject    handle to WF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ST = evalin('base', 'ST');
ST.method_type=4;
assignin('base', 'ST',ST);
Pop_channel_selection();

 



% --------------------------------------------------------------------
function MLR_Callback(hObject, eventdata, handles)
% hObject    handle to MLR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
ST.method_type=6;
assignin('base', 'ST',ST);
Pop_channel_selection();

% --------------------------------------------------------------------
function WF_MLR_Callback(hObject, eventdata, handles)
% hObject    handle to WF_MLR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
ST.method_type=7;
assignin('base', 'ST',ST);
Pop_channel_selection();

% --------------------------------------------------------------------
function Overlap_testing_Callback(hObject, eventdata, handles)
% hObject    handle to Overlap_testing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Overlapping_testing();


% --------------------------------------------------------------------
function Import_Brain_Vision_Callback(hObject, eventdata, handles)
% hObject    handle to Import_Brain_Vision (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[EEG] = pop_loadbv;
EEG = eeg_checkset( EEG );
assignin('base', 'EEG',EEG);


% --------------------------------------------------------------------
function TFA_Callback(hObject, eventdata, handles)
% hObject    handle to TFA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function frequency_analysis_Callback(hObject, eventdata, handles)
% hObject    handle to frequency_analysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

Pop_spectral_analysis();



% --------------------------------------------------------------------
function ROI_analysis_Callback(hObject, eventdata, handles)
% hObject    handle to ROI_analysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Pop_ROI_analysis();


% --------------------------------------------------------------------
function time_frequency_analysis_Callback(hObject, eventdata, handles)
% hObject    handle to time_frequency_analysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Pop_time_frequency_analysis();
% set('ROI_analysis','Enable','on');
set(handles.ROI_analysis,'Enable','on');
