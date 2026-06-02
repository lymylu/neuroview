function varargout = STTF_plot(varargin)
% STTF_PLOT M-file for STTF_plot.fig
%      STTF_PLOT, by itself, creates a new STTF_PLOT or raises the existing
%      singleton*.
%
%      H = STTF_PLOT returns the handle to a new STTF_PLOT or the handle to
%      the existing singleton*.
%
%      STTF_PLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STTF_PLOT.M with the given input arguments.
%
%      STTF_PLOT('Property','Value',...) creates a new STTF_PLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before STTF_plot_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to STTF_plot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help STTF_plot

% Last Modified by GUIDE v2.5 07-May-2011 20:07:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @STTF_plot_OpeningFcn, ...
                   'gui_OutputFcn',  @STTF_plot_OutputFcn, ...
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


% --- Executes just before STTF_plot is made visible.
function STTF_plot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to STTF_plot (see VARARGIN)

% Choose default command line output for STTF_plot
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes STTF_plot wait for user response (see UIRESUME)
% uiwait(handles.figure1);
ST = evalin('base', 'ST');
if ST.plot_type==1
    imagesc(ST.TF.t,ST.TF.f,squeeze(ST.TFA(:,:,1)));axis xy;
elseif ST.plot_type==0
    imagesc(ST.TF.t,ST.TF.f,squeeze(ST.MPA{1}.P(:,:,1)));axis xy;
end
xlabel('Time (ms)','fontsize',8); 
ylabel('Frequency (Hz)','fontsize',8);
colorbar;

% --- Outputs from this function are returned to the command line.
function varargout = STTF_plot_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function Channel_number_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Channel_number as text
%        str2double(get(hObject,'String')) returns contents of Channel_number as a double


% --- Executes during object creation, after setting all properties.
function Channel_number_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Channel_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Left.
function Left_Callback(hObject, eventdata, handles)
% hObject    handle to Left (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
Channel_number =str2num( get(handles.Channel_number,'string'));
if Channel_number==1
elseif Channel_number>1
    Channel_number=Channel_number-1;
end
set(handles.Channel_number, 'String', num2str(Channel_number));

if ST.plot_type==1
    imagesc(ST.TF.t,ST.TF.f,squeeze(ST.TFA(:,:,Channel_number)));axis xy;
elseif ST.plot_type==0
    imagesc(ST.TF.t,ST.TF.f,squeeze(ST.MPA{1}.P(:,:,Channel_number)));axis xy;
end
xlabel('Time (ms)','fontsize',8); 
ylabel('Frequency (Hz)','fontsize',8);
colorbar;

% --- Executes on button press in Right.
function Right_Callback(hObject, eventdata, handles)
% hObject    handle to Right (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
index=size(ST.TFA,3);
Channel_number =str2num( get(handles.Channel_number,'string'));
if Channel_number>=index
elseif Channel_number<index
    Channel_number=Channel_number+1;
end
set(handles.Channel_number, 'String', num2str(Channel_number));
if ST.plot_type==1
    imagesc(ST.TF.t,ST.TF.f,squeeze(ST.TFA(:,:,Channel_number)));axis xy;
elseif ST.plot_type==0
    imagesc(ST.TF.t,ST.TF.f,squeeze(ST.MPA{1}.P(:,:,Channel_number)));axis xy;
end
xlabel('Time (ms)','fontsize',8); 
ylabel('Frequency (Hz)','fontsize',8);
colorbar;
