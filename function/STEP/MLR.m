function varargout = MLRd(varargin)
% MLRD M-file for MLRd.fig
%      MLRD, by itself, creates a new MLRD or raises the existing
%      singleton*.
%
%      H = MLRD returns the handle to a new MLRD or the handle to
%      the existing singleton*.
%
%      MLRD('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MLRD.M with the given input arguments.
%
%      MLRD('Property','Value',...) creates a new MLRD or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MLRd_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MLRd_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MLRd

% Last Modified by GUIDE v2.5 13-Feb-2014 22:18:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MLRd_OpeningFcn, ...
                   'gui_OutputFcn',  @MLRd_OutputFcn, ...
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


% --- Executes just before MLRd is made visible.
function MLRd_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MLRd (see VARARGIN)

% Choose default command line output for MLRd
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MLRd wait for user response (see UIRESUME)
% uiwait(handles.figure1);
% plot average
EEG = evalin('base', 'EEG');
ST = evalin('base', 'ST');
ST.peak=[];

if ST.method_type==7
    plot(ST.f_T*1000,mean(ST.f_trials,2),'linewidth',2);grid on;hold on;
    signal=mean(ST.f_trials,2)';
    [tmax tmin vmax vmin]=extreme_point(signal);
    Vmax=max(vmax);
    Vmin=min(vmin);
    Tmax=ST.f_T(find(signal==Vmax))*1000;
    Tmin=ST.f_T(find(signal==Vmin))*1000;
else
    plot(EEG.times,mean(EEG.data(ST.channel_index,:,:),3),'linewidth',2);grid on;hold on;
    signal=mean(EEG.data(ST.channel_index,:,:),3);
    [tmax tmin vmax vmin]=extreme_point(signal);
    Vmax=max(vmax);
    Vmin=min(vmin);
    Tmax=EEG.times(find(signal==Vmax));
    Tmin=EEG.times(find(signal==Vmin));
end


plot(Tmax, Vmax,'rx','LineWidth',2,'MarkerSize',15);
plot(Tmin, Vmin,'rx','LineWidth',2,'MarkerSize',15);
hold off;
ST.peak(1,:)=[Tmin Vmin];
ST.peak(2,:)=[Tmax Vmax];
assignin('base','ST',ST);

% --- Outputs from this function are returned to the command line.
function varargout = MLRd_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function Peak_number_Callback(hObject, eventdata, handles)
% hObject    handle to Peak_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Peak_number as text
%        str2double(get(hObject,'String')) returns contents of Peak_number as a double


% --- Executes during object creation, after setting all properties.
function Peak_number_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Peak_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Update.
function Update_Callback(hObject, eventdata, handles)
% hObject    handle to Update (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
NumberofReg =str2num( get(handles.Peak_number,'string'));
EEG = evalin('base', 'EEG');
ST = evalin('base', 'ST');
if ST.method_type==7
    plot(ST.f_T*1000,mean(ST.f_trials,2),'linewidth',2);grid on;hold on;
    signal=mean(ST.f_trials,2)';
else
    plot(EEG.times,mean(EEG.data(ST.channel_index,:,:),3),'linewidth',2);grid on;hold on;
    signal=mean(EEG.data(ST.channel_index,:,:),3);
end
[tmax tmin vmax vmin]=extreme_point(signal);
ttemp=[tmax tmin];
vtemp=[vmax vmin];
Temp=sort(abs(vtemp),'descend');
ST.peak=[];
for i=1:NumberofReg
    Vvalue=Temp(i);
    Vmax=vtemp(find(abs(vtemp)==Vvalue));
    Tmax=EEG.times(find(signal==Vmax));
    plot(Tmax, Vmax,'rx','LineWidth',2,'MarkerSize',15);
    ST.peak(i,:)=[Tmax Vmax];
end
hold off;
assignin('base','ST',ST);

% --- Executes on button press in Confirm.
function Confirm_Callback(hObject, eventdata, handles)
% hObject    handle to Confirm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Pop_time_interval();


% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close;



% --- Executes on button press in Manual.
function Manual_Callback(hObject, eventdata, handles)
% hObject    handle to Manual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% select peaks automatically

NumberofReg =str2num( get(handles.Peak_number,'string'));
EEG = evalin('base', 'EEG');
ST = evalin('base', 'ST');
if ST.method_type==7
    plot(ST.f_T*1000,mean(ST.f_trials,2),'linewidth',2);grid on;hold on;
    signal=mean(ST.f_trials,2)';
    [tmax tmin vmax vmin]=extreme_point(signal);
    ttemp=[tmax tmin]+1;
    vtemp=[vmax vmin];
    axes(handles.axes1);
    ST.peak=[];
    t=ST.f_T*1000;
    for i=1:NumberofReg
        [x,y] = ginput(1);    
        for j=1:length(ttemp)
            distance(j)=abs(t(ttemp(j))-x);
        end
        Ttemp=ttemp(find(distance==min(distance)));
        Vvalue=vtemp(find(ttemp==Ttemp));
        Tvalue=t(Ttemp);
        plot(Tvalue, Vvalue,'rx','LineWidth',2,'MarkerSize',15);
        ST.peak(i,:)=[Tvalue Vvalue];
    end
    hold off;
    assignin('base','ST',ST);
    
else
    plot(EEG.times,mean(EEG.data(ST.channel_index,:,:),3),'linewidth',2);grid on;hold on;
    signal=mean(EEG.data(ST.channel_index,:,:),3);
    [tmax tmin vmax vmin]=extreme_point(signal);
    ttemp=[tmax tmin]+1;
    vtemp=[vmax vmin];
    axes(handles.axes1);
    ST.peak=[];
    for i=1:NumberofReg
        [x,y] = ginput(1);    
        for j=1:length(ttemp)
            distance(j)=abs(EEG.times(ttemp(j))-x);
        end
        Ttemp=ttemp(find(distance==min(distance)));
        Vvalue=vtemp(find(ttemp==Ttemp));
        Tvalue=EEG.times(Ttemp);
        plot(Tvalue, Vvalue,'rx','LineWidth',2,'MarkerSize',15);
        ST.peak(i,:)=[Tvalue Vvalue];
    end
    hold off;
    assignin('base','ST',ST);
end



% --- Executes on key press with focus on Manual and none of its controls.
function Manual_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to Manual (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
