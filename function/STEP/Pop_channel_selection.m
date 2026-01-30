function varargout = Pop_channel_selection(varargin)
% POP_CHANNEL_SELECTION M-file for Pop_channel_selection.fig
%      POP_CHANNEL_SELECTION, by itself, creates a new POP_CHANNEL_SELECTION or raises the existing
%      singleton*.
%
%      H = POP_CHANNEL_SELECTION returns the handle to a new POP_CHANNEL_SELECTION or the handle to
%      the existing singleton*.
%
%      POP_CHANNEL_SELECTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in POP_CHANNEL_SELECTION.M with the given input arguments.
%
%      POP_CHANNEL_SELECTION('Property','Value',...) creates a new POP_CHANNEL_SELECTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Pop_channel_selection_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Pop_channel_selection_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Pop_channel_selection

% Last Modified by GUIDE v2.5 09-May-2011 04:42:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Pop_channel_selection_OpeningFcn, ...
                   'gui_OutputFcn',  @Pop_channel_selection_OutputFcn, ...
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


% --- Executes just before Pop_channel_selection is made visible.
function Pop_channel_selection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Pop_channel_selection (see VARARGIN)

% Choose default command line output for Pop_channel_selection
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Pop_channel_selection wait for user response (see UIRESUME)
% uiwait(handles.figure1);
EEG = evalin('base', 'EEG');
for i=1:length(EEG.chanlocs)
    labels{i}=EEG.chanlocs(i).labels;
end
if length(EEG.chanlocs)==0
    labels{i}='1';
end
set(handles.Channel_list,'String',labels);

% --- Outputs from this function are returned to the command line.
function varargout = Pop_channel_selection_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in Channel_list.
function Channel_list_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns Channel_list contents as cell array
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


% --- Executes on button press in Confirm.
function Confirm_Callback(hObject, eventdata, handles)
% hObject    handle to Confirm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
index_selected = get(handles.Channel_list,'Value');
ST = evalin('base', 'ST');
ST.channel_index=index_selected;
assignin('base','ST',ST);
close;
if ST.method_type==1
    MLRd();
elseif ST.method_type==2
    Windowed_Fourier_transform();
elseif ST.method_type==3
    Matching_pursuit();
elseif ST.method_type==4
    Wavelet_filtering();
elseif ST.method_type==5
    Wavelet_filtering();
elseif ST.method_type==6
    MLR();
elseif ST.method_type==7
    Wavelet_filtering();
end


% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
ST.channel_index=1;
assignin('base','ST',ST);
close;

