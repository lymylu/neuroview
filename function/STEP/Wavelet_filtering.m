function varargout = Wavelet_filtering(varargin)
% WAVELET_FILTERING M-file for Wavelet_filtering.fig
%      WAVELET_FILTERING, by itself, creates a new WAVELET_FILTERING or raises the existing
%      singleton*.
%
%      H = WAVELET_FILTERING returns the handle to a new WAVELET_FILTERING or the handle to
%      the existing singleton*.
%
%      WAVELET_FILTERING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WAVELET_FILTERING.M with the given input arguments.
%
%      WAVELET_FILTERING('Property','Value',...) creates a new WAVELET_FILTERING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Wavelet_filtering_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Wavelet_filtering_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Wavelet_filtering

% Last Modified by GUIDE v2.5 09-May-2011 19:28:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Wavelet_filtering_OpeningFcn, ...
                   'gui_OutputFcn',  @Wavelet_filtering_OutputFcn, ...
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


% --- Executes just before Wavelet_filtering is made visible.
function Wavelet_filtering_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Wavelet_filtering (see VARARGIN)

% Choose default command line output for Wavelet_filtering
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Wavelet_filtering wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Wavelet_filtering_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in Confirm.
function Confirm_Callback(hObject, eventdata, handles)
% hObject    handle to Confirm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = evalin('base', 'EEG');
ST = evalin('base', 'ST');
Left_limit =str2num( get(handles.Left_limit,'string'));
Right_limit =str2num( get(handles.Right_limit,'string'));
Low_limit =str2num( get(handles.Low_limit,'string'));
High_limit =str2num( get(handles.High_limit,'string'));
Threshold =str2num( get(handles.Threshold,'string'));
x_trials=squeeze(EEG.data(ST.channel_index,find(EEG.times>=Left_limit & EEG.times<=Right_limit),:));
Fs =EEG.srate; % sampling frequency
epoch=EEG.times(find(EEG.times>=Left_limit & EEG.times<=Right_limit))/1000;  % time points
f=Low_limit:1:High_limit;  %%% frequency resolution
threshold=Threshold/100; %%% Please specify the threshold here. 
[P_mask] = model_generation(x_trials,f,Fs,epoch,threshold);
[f_trials] = tf_filtering(x_trials,f,Fs,P_mask);  %% f_trials is the filtered results
ST.f_T=epoch;
ST.f_trials=f_trials;
assignin('base','ST',ST);
if ST.method_type==4   
    close;close;
elseif ST.method_type==5
    close;close;
    MLRd();
elseif ST.method_type==7
    close;close;
    MLR();
end



function Left_limit_Callback(hObject, eventdata, handles)
% hObject    handle to Left_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Left_limit as text
%        str2double(get(hObject,'String')) returns contents of Left_limit as a double


% --- Executes during object creation, after setting all properties.
function Left_limit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Left_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Right_limit_Callback(hObject, eventdata, handles)
% hObject    handle to Right_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Right_limit as text
%        str2double(get(hObject,'String')) returns contents of Right_limit as a double


% --- Executes during object creation, after setting all properties.
function Right_limit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Right_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Low_limit_Callback(hObject, eventdata, handles)
% hObject    handle to Low_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Low_limit as text
%        str2double(get(hObject,'String')) returns contents of Low_limit as a double


% --- Executes during object creation, after setting all properties.
function Low_limit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Low_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function High_limit_Callback(hObject, eventdata, handles)
% hObject    handle to High_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of High_limit as text
%        str2double(get(hObject,'String')) returns contents of High_limit as a double


% --- Executes during object creation, after setting all properties.
function High_limit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to High_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Threshold_Callback(hObject, eventdata, handles)
% hObject    handle to Threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Threshold as text
%        str2double(get(hObject,'String')) returns contents of Threshold as a double


% --- Executes during object creation, after setting all properties.
function Threshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close;

