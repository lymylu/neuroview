function varargout = Overlapping_testing(varargin)
% OVERLAPPING_TESTING M-file for Overlapping_testing.fig
%      OVERLAPPING_TESTING, by itself, creates a new OVERLAPPING_TESTING or raises the existing
%      singleton*.
%
%      H = OVERLAPPING_TESTING returns the handle to a new OVERLAPPING_TESTING or the handle to
%      the existing singleton*.
%
%      OVERLAPPING_TESTING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OVERLAPPING_TESTING.M with the given input arguments.
%
%      OVERLAPPING_TESTING('Property','Value',...) creates a new OVERLAPPING_TESTING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Overlapping_testing_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Overlapping_testing_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Overlapping_testing

% Last Modified by GUIDE v2.5 12-May-2011 05:44:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Overlapping_testing_OpeningFcn, ...
                   'gui_OutputFcn',  @Overlapping_testing_OutputFcn, ...
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


% --- Executes just before Overlapping_testing is made visible.
function Overlapping_testing_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Overlapping_testing (see VARARGIN)

% Choose default command line output for Overlapping_testing
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Overlapping_testing wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Overlapping_testing_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function Pre_limit_Callback(hObject, eventdata, handles)
% hObject    handle to Pre_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Pre_limit as text
%        str2double(get(hObject,'String')) returns contents of Pre_limit as a double


% --- Executes during object creation, after setting all properties.
function Pre_limit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Pre_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Post_limit_Callback(hObject, eventdata, handles)
% hObject    handle to Post_limit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Post_limit as text
%        str2double(get(hObject,'String')) returns contents of Post_limit as a double


% --- Executes during object creation, after setting all properties.
function Post_limit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Post_limit (see GCBO)
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
Pre_limit =str2num( get(handles.Pre_limit,'string'));
Post_limit =str2num( get(handles.Post_limit,'string'));
EEG = evalin('base', 'EEG');
index=0;
overlap_trials=0;
for i=1:length(EEG.epoch)
    if length(EEG.epoch(1,i).event)==1
        index=0;
    else
        for j=1:length(EEG.epoch(1,i).event)
            if EEG.epoch(1,i).eventlatency{j}>=Pre_limit && EEG.epoch(1,i).eventlatency{j}<0
                index=1;
            end
            if EEG.epoch(1,i).eventlatency{j}>0 && EEG.epoch(1,i).eventlatency{j}<Post_limit
                index=1;
            end
        end
    end
    overlap_trials=overlap_trials+index;
end
total_trials=length(EEG.epoch);
percentage=overlap_trials/total_trials*100;

set(handles.Overlapped_trials,'String',num2str(overlap_trials));
set(handles.Total_trials,'String',num2str(total_trials));
set(handles.Percentage,'String',strcat(num2str(percentage),'%'));

% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close;

