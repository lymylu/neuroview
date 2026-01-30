function varargout = Pop_spectral_analysis(varargin)
% POP_SPECTRAL_ANALYSIS M-file for Pop_spectral_analysis.fig
%      POP_SPECTRAL_ANALYSIS, by itself, creates a new POP_SPECTRAL_ANALYSIS or raises the existing
%      singleton*.
%
%      H = POP_SPECTRAL_ANALYSIS returns the handle to a new POP_SPECTRAL_ANALYSIS or the handle to
%      the existing singleton*.
%
%      POP_SPECTRAL_ANALYSIS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in POP_SPECTRAL_ANALYSIS.M with the given input arguments.
%
%      POP_SPECTRAL_ANALYSIS('Property','Value',...) creates a new POP_SPECTRAL_ANALYSIS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Pop_spectral_analysis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Pop_spectral_analysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Pop_spectral_analysis

% Last Modified by GUIDE v2.5 03-Apr-2012 22:18:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Pop_spectral_analysis_OpeningFcn, ...
                   'gui_OutputFcn',  @Pop_spectral_analysis_OutputFcn, ...
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


% --- Executes just before Pop_spectral_analysis is made visible.
function Pop_spectral_analysis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Pop_spectral_analysis (see VARARGIN)

% Choose default command line output for Pop_spectral_analysis
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Pop_spectral_analysis wait for user response (see UIRESUME)
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
set(handles.Channel_list,'String',labels);
TF.loadfilename=loadfilename;
TF.loadpathname=loadpathname;
assignin('base','TF',TF);


% --- Outputs from this function are returned to the command line.
function varargout = Pop_spectral_analysis_OutputFcn(hObject, eventdata, handles) 
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
TF = evalin('base', 'TF');
loadfilename=TF.loadfilename;
loadpathname=TF.loadpathname;
time_low_limit =str2num( get(handles.time_low_limit,'string'));
time_high_limit =str2num( get(handles.time_high_limit,'string'));
freq_low_limit =str2num( get(handles.freq_low_limit,'string'));
freq_high_limit =str2num( get(handles.freq_high_limit,'string'));
% select channels
index_selected = get(handles.Channel_list,'Value');
close;

NumFiles = length(loadfilename);
for nfile=1:NumFiles
    EEG = pop_loadset([loadpathname,loadfilename{nfile}]);
    Fs = EEG.srate;                    % Sampling frequency
    T = 1/Fs;                     % Sample time
    L = size(EEG.data,2);                     % Length of signal
    NFFT = 2^nextpow2(L); % Next power of 2 from length of y
    f = Fs/2*linspace(0,1,NFFT/2+1);
    if ndims(EEG.data)==2    
        for nbchan=1:EEG.nbchan
            y = EEG.data(nbchan,:);        
            Y(nbchan,:,nfile) = fft(y,NFFT)/L;
        end
    elseif ndims(EEG.data)==3
        t_idx=find(EEG.times>=time_low_limit & EEG.times<=time_high_limit);
        for nbchan=1:EEG.nbchan
            for ntrial=1:EEG.trials
                y = squeeze(EEG.data(nbchan,t_idx,ntrial));
                Y_temp(nbchan,:,ntrial) = fft(y,NFFT)/L;
            end
        end
        Y(:,:,nfile)=squeeze(mean(Y_temp,3));
    end
end

f_idx=find(f>=freq_low_limit & f<=freq_high_limit);
f_out=f(f_idx);
Y_out=abs(Y(:,f_idx,:));

delta=[0 4];delta_idx=find(f_out>=delta(1) & f_out<=delta(2));
theta=[4 8];theta_idx=find(f_out>=theta(1) & f_out<=theta(2));
alpha=[8 13];alpha_idx=find(f_out>=alpha(1) & f_out<=alpha(2));
beta=[13 30];beta_idx=find(f_out>=beta(1) & f_out<=beta(2));
gamma=[30 100];gamma_idx=find(f_out>=gamma(1) & f_out<=gamma(2));

if ~isempty(delta_idx)
    temp=squeeze(mean(Y_out(:,delta_idx,:),2));value.delta=temp(index_selected,:);
    figure; topoplot(mean(temp,2), EEG.chanlocs);title('scalp topography at delta band (<4 Hz)'); 
    my_handle=colorbar;
    set(get(my_handle,'Title'),'string','amplitude (uV^2)');
end
if ~isempty(theta_idx)
    temp=squeeze(mean(Y_out(:,theta_idx,:),2));value.theta=temp(index_selected,:);
    figure; topoplot(mean(temp,2), EEG.chanlocs);  title('scalp topography at theta band (4-8 Hz)');  
    my_handle=colorbar;
    set(get(my_handle,'Title'),'string','amplitude (uV^2)'); 
end
if ~isempty(alpha_idx)
    temp=squeeze(mean(Y_out(:,alpha_idx,:),2));value.alpha=temp(index_selected,:);
    figure; topoplot(mean(temp,2), EEG.chanlocs); title('scalp topography at alpha band (8-13 Hz)'); 
    my_handle=colorbar;
    set(get(my_handle,'Title'),'string','amplitude (uV^2)');
end
if ~isempty(beta_idx)
    temp=squeeze(mean(Y_out(:,beta_idx,:),2));value.beta=temp(index_selected,:);
    figure; topoplot(mean(temp,2), EEG.chanlocs); title('scalp topography at beta band (13-30 Hz)'); 
    my_handle=colorbar;
    set(get(my_handle,'Title'),'string','amplitude (uV^2)');
end
if ~isempty(gamma_idx)
    temp=squeeze(mean(Y_out(:,gamma_idx,:),2));value.gamma=temp(index_selected,:);
    figure; topoplot(mean(temp,2), EEG.chanlocs); title('scalp topography at gamma band (30-100 Hz)');
    my_handle=colorbar;
    set(get(my_handle,'Title'),'string','amplitude (uV^2)');
end

figure; hold on;
plot(f_out,2*squeeze(mean(Y_out(index_selected,:,:),3)));
title('Amplitude Spectrum')
xlabel('Frequency (Hz)')
ylabel('uV^2')
xlim([freq_low_limit freq_high_limit]);

 
TF.channel=EEG.chanlocs(index_selected);
TF.spectrum=Y_out(index_selected,:,:);
TF.f=f_out;
TF.value=value;
assignin('base','TF',TF);

% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close;


% --- Executes on selection change in Channel_list.
function Channel_list_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Channel_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Channel_list


% --- Executes during object creation, after setting all properties.
function Channel_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Channel_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
