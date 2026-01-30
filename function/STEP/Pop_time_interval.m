function varargout = Pop_time_interval(varargin)
% POP_TIME_INTERVAL M-file for Pop_time_interval.fig
%      POP_TIME_INTERVAL, by itself, creates a new POP_TIME_INTERVAL or raises the existing
%      singleton*.
%
%      H = POP_TIME_INTERVAL returns the handle to a new POP_TIME_INTERVAL or the handle to
%      the existing singleton*.
%
%      POP_TIME_INTERVAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in POP_TIME_INTERVAL.M with the given input arguments.
%
%      POP_TIME_INTERVAL('Property','Value',...) creates a new POP_TIME_INTERVAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Pop_time_interval_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Pop_time_interval_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Pop_time_interval

% Last Modified by GUIDE v2.5 12-May-2011 05:32:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Pop_time_interval_OpeningFcn, ...
                   'gui_OutputFcn',  @Pop_time_interval_OutputFcn, ...
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


% --- Executes just before Pop_time_interval is made visible.
function Pop_time_interval_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Pop_time_interval (see VARARGIN)

% Choose default command line output for Pop_time_interval
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Pop_time_interval wait for user response (see UIRESUME)
% uiwait(handles.figure1);
ST = evalin('base', 'ST');
num_peak=size(ST.peak,1);
if num_peak<5
    for i=num_peak+1:5
        set(eval(strcat('handles.peak',num2str(i))),'Visible','off');
        set(eval(strcat('handles.text_Peak',num2str(i))),'Visible','off');
        set(eval(strcat('handles.ms',num2str(i))),'Visible','off');
    end
end

% --- Outputs from this function are returned to the command line.
function varargout = Pop_time_interval_OutputFcn(hObject, eventdata, handles) 
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
ST = evalin('base', 'ST');
EEG = evalin('base', 'EEG');
ST.interval=[];
Pre_time =str2num( get(handles.Pre_time,'string'));
Post_time =str2num( get(handles.Post_time,'string'));

for i=1:size(ST.peak,1)
    peak_interval(i)=str2num( get(eval(strcat('handles.peak',num2str(i))),'string'));
end

ST.interval=[Pre_time Post_time];
ST.peak_interval=peak_interval;
close;

if ST.method_type==5 || ST.method_type==1
    [ST] = Basis_regressors(EEG,ST);
elseif ST.method_type==6 || ST.method_type==7
    [ST] = MLR_regressors(EEG,ST); %% to be added
end

if ST.method_type==5
    T=find(ST.f_T*1000>=ST.interval(1)&ST.f_T*1000<=ST.interval(2));
    for i=1:length(ST.regressor)
        figure;hold on;grid on;
        plot(ST.f_T(T),ST.regressor{i}(:,1),'r','linewidth',2);
        plot(ST.f_T(T),ST.regressor{i}(:,2),'g','linewidth',2);
        plot(ST.f_T(T),ST.regressor{i}(:,3),'b','linewidth',2);
        hold off
    end
elseif ST.method_type==1
    T=find(EEG.times>=ST.interval(1)&EEG.times<=ST.interval(2));
    for i=1:length(ST.regressor)
        figure;hold on;grid on;
        plot(EEG.times(T),ST.regressor{i}(:,1),'r','linewidth',2);
        plot(EEG.times(T),ST.regressor{i}(:,2),'g','linewidth',2);
        plot(EEG.times(T),ST.regressor{i}(:,3),'b','linewidth',2);
        hold off
    end
elseif ST.method_type==6
    T=find(EEG.times>=ST.interval(1)&EEG.times<=ST.interval(2));
    for i=1:length(ST.regressor)
        figure;hold on;grid on;
        plot(EEG.times(T),ST.regressor{i}(:,1),'r','linewidth',2);
        plot(EEG.times(T),ST.regressor{i}(:,2),'g','linewidth',2);
        hold off
    end
elseif ST.method_type==7
    T=find(ST.f_T*1000>=ST.interval(1)&ST.f_T*1000<=ST.interval(2));
    for i=1:length(ST.regressor)
        figure;hold on;grid on;
        plot(ST.f_T(T),ST.regressor{i}(:,1),'r','linewidth',2);
        plot(ST.f_T(T),ST.regressor{i}(:,2),'g','linewidth',2);
        hold off
    end
end
[ST] = peak_measure(EEG,ST);
assignin('base','ST',ST);

% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close;


function Pre_time_Callback(hObject, eventdata, handles)
% hObject    handle to Pre_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Pre_time as text
%        str2double(get(hObject,'String')) returns contents of Pre_time as a double


% --- Executes during object creation, after setting all properties.
function Pre_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Pre_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Post_time_Callback(hObject, eventdata, handles)
% hObject    handle to Post_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Post_time as text
%        str2double(get(hObject,'String')) returns contents of Post_time as a double


% --- Executes during object creation, after setting all properties.
function Post_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Post_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function peak1_Callback(hObject, eventdata, handles)
% hObject    handle to peak1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of peak1 as text
%        str2double(get(hObject,'String')) returns contents of peak1 as a double


% --- Executes during object creation, after setting all properties.
function peak1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to peak1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function peak2_Callback(hObject, eventdata, handles)
% hObject    handle to peak2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of peak2 as text
%        str2double(get(hObject,'String')) returns contents of peak2 as a double


% --- Executes during object creation, after setting all properties.
function peak2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to peak2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function peak3_Callback(hObject, eventdata, handles)
% hObject    handle to peak3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of peak3 as text
%        str2double(get(hObject,'String')) returns contents of peak3 as a double


% --- Executes during object creation, after setting all properties.
function peak3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to peak3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function peak4_Callback(hObject, eventdata, handles)
% hObject    handle to peak4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of peak4 as text
%        str2double(get(hObject,'String')) returns contents of peak4 as a double


% --- Executes during object creation, after setting all properties.
function peak4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to peak4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function peak5_Callback(hObject, eventdata, handles)
% hObject    handle to peak5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of peak5 as text
%        str2double(get(hObject,'String')) returns contents of peak5 as a double


% --- Executes during object creation, after setting all properties.
function peak5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to peak5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


