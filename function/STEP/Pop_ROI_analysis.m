function varargout = Pop_ROI_analysis(varargin)
% Pop_ROI_analysis M-file for Pop_ROI_analysis.fig
%      Pop_ROI_analysis, by itself, creates a new Pop_ROI_analysis or raises the existing
%      singleton*.
%
%      H = Pop_ROI_analysis returns the handle to a new Pop_ROI_analysis or the handle to
%      the existing singleton*.
%
%      Pop_ROI_analysis('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in Pop_ROI_analysis.M with the given input arguments.
%
%      Pop_ROI_analysis('Property','Value',...) creates a new Pop_ROI_analysis or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Pop_ROI_analysis_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Pop_ROI_analysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Pop_ROI_analysis

% Last Modified by GUIDE v2.5 05-May-2011 20:56:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Pop_ROI_analysis_OpeningFcn, ...
                   'gui_OutputFcn',  @Pop_ROI_analysis_OutputFcn, ...
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


% --- Executes just before Pop_ROI_analysis is made visible.
function Pop_ROI_analysis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Pop_ROI_analysis (see VARARGIN)

% Choose default command line output for Pop_ROI_analysis
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Pop_ROI_analysis wait for user response (see UIRESUME)
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
TFA = evalin('base', 'TFA');
TFA.loadfilename=loadfilename;
TFA.loadpathname=loadpathname;
assignin('base','TFA',TFA);

% --- Outputs from this function are returned to the command line.
function varargout = Pop_ROI_analysis_OutputFcn(hObject, eventdata, handles) 
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
TFA = evalin('base', 'TFA');
edit_ROI_num =str2num( get(handles.edit_ROI_num,'string'));
Xlim1 =str2num( get(handles.Xlim1,'string'));
Xlim2 =str2num( get(handles.Xlim2,'string'));
Ylim1 =str2num( get(handles.Ylim1,'string'));
Ylim2 =str2num( get(handles.Ylim2,'string'));
TFA.ROI(edit_ROI_num,:)=[Xlim1 Xlim2 Ylim1 Ylim2];

% clf('reset');
imagesc(TFA.t,TFA.f,squeeze(mean(TFA.P_BC(TFA.chan_idx,:,:,:),4)));axis xy;%axis([Pre_limit Post_limit],[Low_limit High_limit]);
xlabel('Time (ms)','fontsize',8); 
ylabel('Frequency (Hz)','fontsize',8);
colorbar;
color_={'y','m','r','g','w','k','y','m','r','g','w','k','y','m','r','g','w','k'};
for i=1:edit_ROI_num
    Xlim1=TFA.ROI(i,1);Xlim2=TFA.ROI(i,2);Ylim1=TFA.ROI(i,3);Ylim2=TFA.ROI(i,4);
    rectangle('Position',[Xlim1,Ylim1,Xlim2-Xlim1,Ylim2-Ylim1],'EraseMode','background','Curvature',[0.2,0.2],'LineWidth',2,'EdgeColor',color_{i});
    text(Xlim2,Ylim1,strcat('ROI',num2str(i)),'FontSize',12);
end
assignin('base','TFA',TFA);


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
TFA = evalin('base', 'TFA');
TFA.ROI_value=[];
Top_percentage =str2num( get(handles.Top_percentage,'string'));
for i=1:size(TFA.ROI,1)
    ROI{i}=TFA.P_BC(:,find(TFA.f>=TFA.ROI(i,3)&TFA.f<=TFA.ROI(i,4)),find(TFA.t>=TFA.ROI(i,1)&TFA.t<=TFA.ROI(i,2)),:);
    for j=1:size(ROI{i},4)
        for k=1:size(ROI{i},1)
            temp=ROI{i}(k,:,:,j);
            temp1=reshape(temp,1,[]);
            temp2=sort(temp1,'descend');
            TFA.ROI_value(k,j,i)=mean(temp2(1:round(length(temp2)*Top_percentage/100)));      
            clear temp temp1 temp2;
        end
    end
    temp=squeeze(mean(TFA.ROI_value(:,:,i),2));
    figure; topoplot(temp, TFA.channel);title(strcat('scalp topography at ROI',num2str(i))); 
    my_handle=colorbar;
    set(get(my_handle,'Title'),'string','amplitude (ER 100%)');
end
assignin('base','TFA',TFA);
% close;

figure;imagesc(TFA.t,TFA.f,squeeze(mean(TFA.P_BC(TFA.chan_idx,:,:,:),4)));axis xy;%axis([Pre_limit Post_limit],[Low_limit High_limit]);
xlabel('Time (ms)','fontsize',8); 
ylabel('Frequency (Hz)','fontsize',8);
colorbar;
color_={'y','m','r','g','w','k','y','m','r','g','w','k','y','m','r','g','w','k'};
for i=1:size(TFA.ROI,1)
    Xlim1=TFA.ROI(i,1);Xlim2=TFA.ROI(i,2);Ylim1=TFA.ROI(i,3);Ylim2=TFA.ROI(i,4);
    rectangle('Position',[Xlim1,Ylim1,Xlim2-Xlim1,Ylim2-Ylim1],'EraseMode','background','Curvature',[0.2,0.2],'LineWidth',2,'EdgeColor',color_{i});
    text(Xlim2,Ylim1,strcat('ROI',num2str(i)),'FontSize',12);
end



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
TFA = evalin('base', 'TFA');
TFA.P_BC=[];
loadfilename=TFA.loadfilename;
loadpathname=TFA.loadpathname;

time_low_limit =str2num( get(handles.Pre_limit,'string'));
time_high_limit =str2num( get(handles.Post_limit,'string'));
freq_low_limit =str2num( get(handles.Low_limit,'string'));
freq_high_limit =str2num( get(handles.High_limit,'string'));
Baseline_low =str2num( get(handles.Baseline_pre,'string'));
Baseline_high =str2num( get(handles.Baseline_post,'string'));

index_selected = TFA.chan_idx;

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
    for nchan=1:size(EEG.data,1)
        x = squeeze(EEG.data(nchan,:,:)); % data to be analyzed (points x trials)

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
        P_BC = (P - P_Baseline_Mean )./P_Baseline_Mean;
        TFA.P_BC(nchan,:,:,nfile)=squeeze(mean(P_BC,3));
    end
end

TFA.channel=EEG.chanlocs;
TFA.chan_idx=index_selected;
TFA.t=t*1000;
TFA.f=f;
TFA.Fs=Fs;
assignin('base','TFA',TFA);
imagesc(TFA.t,TFA.f,squeeze(mean(TFA.P_BC(TFA.chan_idx,:,:,:),4)));axis xy;
axis([time_low_limit time_high_limit freq_low_limit freq_high_limit]);
xlabel('time (s)');
ylabel('frequency (Hz)');
my_handle=colorbar;
set(get(my_handle,'Title'),'string','ER 100%');




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

