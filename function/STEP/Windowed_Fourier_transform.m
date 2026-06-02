function varargout = Windowed_Fourier_transform(varargin)
% WINDOWED_FOURIER_TRANSFORM M-file for Windowed_Fourier_transform.fig
%      WINDOWED_FOURIER_TRANSFORM, by itself, creates a new WINDOWED_FOURIER_TRANSFORM or raises the existing
%      singleton*.
%
%      H = WINDOWED_FOURIER_TRANSFORM returns the handle to a new WINDOWED_FOURIER_TRANSFORM or the handle to
%      the existing singleton*.
%
%      WINDOWED_FOURIER_TRANSFORM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WINDOWED_FOURIER_TRANSFORM.M with the given input arguments.
%
%      WINDOWED_FOURIER_TRANSFORM('Property','Value',...) creates a new WINDOWED_FOURIER_TRANSFORM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Windowed_Fourier_transform_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Windowed_Fourier_transform_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Windowed_Fourier_transform

% Last Modified by GUIDE v2.5 05-May-2011 20:56:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Windowed_Fourier_transform_OpeningFcn, ...
                   'gui_OutputFcn',  @Windowed_Fourier_transform_OutputFcn, ...
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


% --- Executes just before Windowed_Fourier_transform is made visible.
function Windowed_Fourier_transform_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Windowed_Fourier_transform (see VARARGIN)

% Choose default command line output for Windowed_Fourier_transform
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Windowed_Fourier_transform wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Windowed_Fourier_transform_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function Baseline_pre_Callback(hObject, eventdata, handles)
% hObject    handle to Baseline_pre (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Baseline_pre as text
%        str2double(get(hObject,'String')) returns contents of Baseline_pre as a double


% --- Executes during object creation, after setting all properties.
function Baseline_pre_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Baseline_pre (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Baseline_post_Callback(hObject, eventdata, handles)
% hObject    handle to Baseline_post (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Baseline_post as text
%        str2double(get(hObject,'String')) returns contents of Baseline_post as a double


% --- Executes during object creation, after setting all properties.
function Baseline_post_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Baseline_post (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_ROI_num_Callback(hObject, eventdata, handles)
% hObject    handle to edit_ROI_num (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_ROI_num as text
%        str2double(get(hObject,'String')) returns contents of edit_ROI_num as a double


% --- Executes during object creation, after setting all properties.
function edit_ROI_num_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ROI_num (see GCBO)
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
ST = evalin('base', 'ST');
edit_ROI_num =str2num( get(handles.edit_ROI_num,'string'));
Xlim1 =str2num( get(handles.Xlim1,'string'));
Xlim2 =str2num( get(handles.Xlim2,'string'));
Ylim1 =str2num( get(handles.Ylim1,'string'));
Ylim2 =str2num( get(handles.Ylim2,'string'));
ST.ROI(edit_ROI_num,:)=[Xlim1 Xlim2 Ylim1 Ylim2];

% clf('reset');
imagesc(ST.TF.t,ST.TF.f,ST.TFA_avg);axis xy;%axis([Pre_limit Post_limit],[Low_limit High_limit]);
xlabel('Time (ms)','fontsize',8); 
ylabel('Frequency (Hz)','fontsize',8);
colorbar;
color_={'y','m','r','g','w','k','y','m','r','g','w','k','y','m','r','g','w','k'};
for i=1:edit_ROI_num
    Xlim1=ST.ROI(i,1);Xlim2=ST.ROI(i,2);Ylim1=ST.ROI(i,3);Ylim2=ST.ROI(i,4);
    rectangle('Position',[Xlim1,Ylim1,Xlim2-Xlim1,Ylim2-Ylim1],'EraseMode','background','Curvature',[0.2,0.2],'LineWidth',2,'EdgeColor',color_{i});
    text(Xlim2,Ylim1,strcat('ROI',num2str(i)),'FontSize',12);
end
assignin('base','ST',ST);

function Xlim1_Callback(hObject, eventdata, handles)
% hObject    handle to Xlim1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Xlim1 as text
%        str2double(get(hObject,'String')) returns contents of Xlim1 as a double


% --- Executes during object creation, after setting all properties.
function Xlim1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Xlim1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Xlim2_Callback(hObject, eventdata, handles)
% hObject    handle to Xlim2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Xlim2 as text
%        str2double(get(hObject,'String')) returns contents of Xlim2 as a double


% --- Executes during object creation, after setting all properties.
function Xlim2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Xlim2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Ylim1_Callback(hObject, eventdata, handles)
% hObject    handle to Ylim1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Ylim1 as text
%        str2double(get(hObject,'String')) returns contents of Ylim1 as a double


% --- Executes during object creation, after setting all properties.
function Ylim1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Ylim1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Ylim2_Callback(hObject, eventdata, handles)
% hObject    handle to Ylim2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Ylim2 as text
%        str2double(get(hObject,'String')) returns contents of Ylim2 as a double


% --- Executes during object creation, after setting all properties.
function Ylim2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Ylim2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ROI_selection.
function ROI_selection_Callback(hObject, eventdata, handles)
% hObject    handle to ROI_selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns ROI_selection contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ROI_selection


% --- Executes during object creation, after setting all properties.
function ROI_selection_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ROI_selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
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

% --- Executes on button press in Confirm.
function Confirm_Callback(hObject, eventdata, handles)
% hObject    handle to Confirm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
ST.TF_ST=[];
Top_percentage =str2num( get(handles.Top_percentage,'string'));
for i=1:size(ST.ROI,1)
    ROI{i}=ST.TFA(find(ST.TF.f>=ST.ROI(i,3)&ST.TF.f<=ST.ROI(i,4)),find(ST.TF.t>=ST.ROI(i,1)&ST.TF.t<=ST.ROI(i,2)),:);
    for j=1:size(ROI{i},3)
        temp=ROI{i}(:,:,j);
        temp1=reshape(temp,1,[]);
        temp2=sort(temp1,'descend');
        ST.TF_ST(j,i)=mean(temp2(1:round(length(temp2)*Top_percentage/100)));      
        clear temp temp1 temp2;
    end
end
assignin('base','ST',ST);
close;

function Top_percentage_Callback(hObject, eventdata, handles)
% hObject    handle to Top_percentage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Top_percentage as text
%        str2double(get(hObject,'String')) returns contents of Top_percentage as a double


% --- Executes during object creation, after setting all properties.
function Top_percentage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Top_percentage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Update_TFA.
function Update_TFA_Callback(hObject, eventdata, handles)
% hObject    handle to Update_TFA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EEG = evalin('base', 'EEG');
ST = evalin('base', 'ST');
ST.TFA=[];
ST.TF=[];
ST.TFA_avg=[];
ST.ROI=[];
ST.TF_ST=[];
Pre_limit =str2num( get(handles.Pre_limit,'string'));
Post_limit =str2num( get(handles.Post_limit,'string'));
Low_limit =str2num( get(handles.Low_limit,'string'));
High_limit =str2num( get(handles.High_limit,'string'));
Baseline_pre =str2num( get(handles.Baseline_pre,'string'));
Baseline_post =str2num( get(handles.Baseline_post,'string'));

t=EEG.times;
T=find((t>=Pre_limit)&(t<=Post_limit));
f=Low_limit:1:High_limit;
winsize = 250; % <========= window size (unit: ms) used for short-time Fourier transform
[S, P] = sub_tfa_stft(squeeze(EEG.data(ST.channel_index,T,:)),EEG.times(T) , EEG.times(T), f, EEG.srate, winsize); % S has phase information while P is the power spectral density
clear S;
t_pre_lim = [Baseline_pre,Baseline_post]; % <============= the pre-stimulus (baseline) time interval (unit: ms)
t_post_lim = [Pre_limit, Post_limit]; % <============= the post-stimulus time interval (unit: ms)
t_pre_idx = find((t>=t_pre_lim(1))&(t<=t_pre_lim(2)));
t_post_idx = find((t>=t_post_lim(1))&(t<=t_post_lim(2)));

P_Baseline_mean = mean(mean(P(:,t_pre_idx,:),3),2);
P_Baseline = repmat(P_Baseline_mean,[1,length(t_post_idx),size(EEG.data,3)]);
% FOUR methods for baseline correction (See: Roach and Mathalon, 2008)

% METHOD: substract and divide
P_BC = (P  - P_Baseline );%./P_Baseline;
P_BC_avg = mean(P_BC,3);
imagesc(EEG.times(T),f,P_BC_avg);axis xy;%axis([Pre_limit Post_limit],[Low_limit High_limit]);
xlabel('Time (ms)','fontsize',8); 
ylabel('Frequency (Hz)','fontsize',8);
colorbar;
ST.TFA=P_BC;
ST.TF.t=EEG.times(T);
ST.TF.f=f;
ST.TFA_avg=P_BC_avg;
assignin('base','ST',ST);

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




% --- Executes on button press in togglebutton3.
function togglebutton3_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton3


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in Left.
function Left_Callback(hObject, eventdata, handles)
% hObject    handle to Left (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
edit_ROI_num =str2num( get(handles.edit_ROI_num,'string'));
if edit_ROI_num==1
elseif edit_ROI_num>1
    edit_ROI_num=edit_ROI_num-1;
end
set(handles.edit_ROI_num, 'String', num2str(edit_ROI_num));

% --- Executes on button press in Right.
function Right_Callback(hObject, eventdata, handles)
% hObject    handle to Right (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
edit_ROI_num =str2num( get(handles.edit_ROI_num,'string'));
edit_ROI_num=edit_ROI_num+1;
set(handles.edit_ROI_num, 'String', num2str(edit_ROI_num));

