function varargout = Matching_pursuit(varargin)
% MATCHING_PURSUIT M-file for Matching_pursuit.fig
%      MATCHING_PURSUIT, by itself, creates a new MATCHING_PURSUIT or raises the existing
%      singleton*.
%
%      H = MATCHING_PURSUIT returns the handle to a new MATCHING_PURSUIT or the handle to
%      the existing singleton*.
%
%      MATCHING_PURSUIT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MATCHING_PURSUIT.M with the given input arguments.
%
%      MATCHING_PURSUIT('Property','Value',...) creates a new MATCHING_PURSUIT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Matching_pursuit_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Matching_pursuit_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Matching_pursuit

% Last Modified by GUIDE v2.5 06-May-2011 01:09:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Matching_pursuit_OpeningFcn, ...
                   'gui_OutputFcn',  @Matching_pursuit_OutputFcn, ...
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


% --- Executes just before Matching_pursuit is made visible.
function Matching_pursuit_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Matching_pursuit (see VARARGIN)

% Choose default command line output for Matching_pursuit
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Matching_pursuit wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = Matching_pursuit_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit13_Callback(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit13 as text
%        str2double(get(hObject,'String')) returns contents of edit13 as a double


% --- Executes during object creation, after setting all properties.
function edit13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton10.
function pushbutton10_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function ROI_number_manu_Callback(hObject, eventdata, handles)
% hObject    handle to ROI_number_manu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ROI_number_manu as text
%        str2double(get(hObject,'String')) returns contents of ROI_number_manu as a double


% --- Executes during object creation, after setting all properties.
function ROI_number_manu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ROI_number_manu (see GCBO)
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
ROI_number_manu =str2num( get(handles.ROI_number_manu,'string'));
if ROI_number_manu==1
elseif ROI_number_manu>1
    ROI_number_manu=ROI_number_manu-1;
end
set(handles.ROI_number_manu, 'String', num2str(ROI_number_manu));

% --- Executes on button press in Right.
function Right_Callback(hObject, eventdata, handles)
% hObject    handle to Right (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ROI_number_manu =str2num( get(handles.ROI_number_manu,'string'));
ROI_number_manu=ROI_number_manu+1;
set(handles.ROI_number_manu, 'String', num2str(ROI_number_manu));

% --- Executes on button press in Density.
function Density_Callback(hObject, eventdata, handles)
% hObject    handle to Density (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
for i=1:length(ST.MPA)
    for j=1:size(ST.MPA{i}.MP_PARAM,1)
        Den_axis(i,j,1:2)=ST.MPA{i}.MP_PARAM(j,1:2);
    end
end
T=ST.MP.t;
f=ST.MP.f;
Den=reshape(Den_axis,[],2);
[bandwidth,density,X,Y]=kde2d(Den,2^8,[min(T)/1000,min(f)],[max(T)/1000, max(f)]);
imagesc(T/1000,f,density);axis xy;
xlabel('Time (ms)','fontsize',8); 
ylabel('Frequency (Hz)','fontsize',8);
colorbar;
ST.type=0;
ST.density=density;
ST.MPROI=[];
assignin('base','ST',ST);
set(handles.ROI_number_manu, 'String', num2str(1));

% --- Executes on button press in Energy.
function Energy_Callback(hObject, eventdata, handles)
% hObject    handle to Energy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
P_avg=ST.MPA_avg;
T=ST.MP.t;
f=ST.MP.f;
imagesc(T,f,P_avg);axis xy;%axis([Pre_limit Post_limit],[Low_limit High_limit]);
xlabel('Time (ms)','fontsize',8); 
ylabel('Frequency (Hz)','fontsize',8);
colorbar;
ST.type=1;
ST.MPROI=[];
assignin('base','ST',ST);
set(handles.ROI_number_manu, 'String', num2str(1));

function ROI_number_auto_Callback(hObject, eventdata, handles)
% hObject    handle to ROI_number_auto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ROI_number_auto as text
%        str2double(get(hObject,'String')) returns contents of ROI_number_auto as a double


% --- Executes during object creation, after setting all properties.
function ROI_number_auto_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ROI_number_auto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Update_auto.
function Update_auto_Callback(hObject, eventdata, handles)
% hObject    handle to Update_auto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
ST.automanu=0;
ROI_number_auto =str2num( get(handles.ROI_number_auto,'string'));
for i=1:length(ST.MPA)
    for j=1:size(ST.MPA{i}.MP_PARAM,1)
        Den_axis(i,j,1:5)=ST.MPA{i}.MP_PARAM(j,:);
    end
end
Den=reshape(Den_axis,[],5);
%% two dimension way
Den1(:,1)=(Den(:,1)-min(Den(:,1)))/(max(Den(:,1))-min(Den(:,1)));
Den1(:,2)=(Den(:,2)-min(Den(:,2)))/(max(Den(:,2))-min(Den(:,2)));
[IDX,C] = kmeans(Den1(:,1:2),ROI_number_auto);
color_={'r','g','b','m','k','y','r','g','b','m','k','y','r','g','b','m','k','y'};
index=zeros(1,ROI_number_auto);
figure;hold on; axis([min(Den(:,1)) max(Den(:,1)) min(Den(:,2)) max(Den(:,2))]);
for i=1:size(Den,1)
    for j=1:ROI_number_auto
        if IDX(i)==j && index(j)==0
            lengend_points(j,:)=Den(i,:);
            index(j)=1;
        end
    end
end
for i=1:ROI_number_auto
    plot(lengend_points(i,1),lengend_points(i,2),'.','markersize',15,'color',color_{i});hold on;
    legend_label{i}=strcat('Cluster',num2str(i));
end
legend(legend_label,ROI_number_auto);

for i=1:size(Den,1)
    plot(Den(i,1),Den(i,2),'.','markersize',15,'color',color_{IDX(i)});hold on;
    for j=1:ROI_number_auto
        if IDX(i)==j && index(j)==0
            lengend_points(j,:)=Den(i,:);
            index(j)=1;
        end
    end
end
            
% for i=1:size(C,1)
%     plot(C(i,1),C(i,2),'X','linewidth',3,'markersize',20,'color',color_{i});hold on;
% end
grid on;
ST.auto.Den_axis=Den_axis;
ST.auto.Den=Den;
ST.auto.IDX=IDX;
% ST.auto.C=C;
assignin('base','ST',ST);

%% three dimension way
% % [IDX,C] = kmeans(Den(:,1:3),ROI_number_auto);
% % color_={'r','g','b','m','k','y','r','g','b','m','k','y','r','g','b','m','k','y'};
% % figure;
% % for i=1:size(Den,1)
% %     plot3(Den(i,1),Den(i,2),Den(i,3),'.','markersize',15,'color',color_{IDX(i)});hold on;
% % end
% % for i=1:size(C,1)
% %     plot3(C(i,1),C(i,2),C(i,3),'X','linewidth',3,'markersize',20,'color',color_{i});hold on;
% % end
% % grid on;view(-60,20);
% % ST.auto.Den_axis=Den_axis;
% % ST.auto.Den=Den;
% % ST.auto.IDX=IDX;
% % ST.auto.C=C;
% % assignin('base','ST',ST);

% --- Executes on button press in Update_manu.
function Update_manu_Callback(hObject, eventdata, handles)
% hObject    handle to Update_manu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ST = evalin('base', 'ST');
ROI_number_manu =str2num( get(handles.ROI_number_manu,'string'));
Xlim1 =str2num( get(handles.Xlim1,'string'));
Xlim2 =str2num( get(handles.Xlim2,'string'));
Ylim1 =str2num( get(handles.Ylim1,'string'));
Ylim2 =str2num( get(handles.Ylim2,'string'));
ST.MPROI(ROI_number_manu,:)=[Xlim1 Xlim2 Ylim1 Ylim2];

% clf('reset');

if ST.type==1
    imagesc(ST.MP.t,ST.MP.f,ST.MPA_avg);axis xy;%axis([Pre_limit Post_limit],[Low_limit High_limit]);
elseif ST.type==0
    imagesc(ST.MP.t,ST.MP.f,ST.density);axis xy;
end
xlabel('Time (ms)','fontsize',8); 
ylabel('Frequency (Hz)','fontsize',8);
colorbar;
color_={'y','m','r','g','w','k','y','m','r','g','w','k','y','m','r','g','w','k'};
for i=1:ROI_number_manu
    Xlim1=ST.MPROI(i,1);Xlim2=ST.MPROI(i,2);Ylim1=ST.MPROI(i,3);Ylim2=ST.MPROI(i,4);
    rectangle('Position',[Xlim1,Ylim1,Xlim2-Xlim1,Ylim2-Ylim1],'EraseMode','background','Curvature',[0.2,0.2],'LineWidth',2,'EdgeColor',color_{i});
    text(Xlim2,Ylim1,strcat('ROI',num2str(i)),'FontSize',12);
end
ST.automanu=1;
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


% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close;

% --- Executes on button press in Update_TFA.
function Update_TFA_Callback(hObject, eventdata, handles)
% hObject    handle to Update_TFA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EEG = evalin('base', 'EEG');
ST = evalin('base', 'ST');
Pre_limit =str2num( get(handles.Pre_limit,'string'));
Post_limit =str2num( get(handles.Post_limit,'string'));
Low_limit =str2num( get(handles.Low_limit,'string'));
High_limit =str2num( get(handles.High_limit,'string'));

t=EEG.times;
T=EEG.times(find((t>=Pre_limit)&(t<=Post_limit)));
f=Low_limit:2:High_limit;
Fs=EEG.srate;
data=squeeze(EEG.data(ST.channel_index,find((t>=Pre_limit)&(t<=Post_limit)),:));
h = waitbar(0,'Please wait...');
for i=1:size(data,2)
    x=double(data(:,i));
    %% Matching Pursuit
    % Parameters for Matching Pursuit
    PARAM_MP.Num_Iter = 20; % number of iterations
    PARAM_MP.MinTotalPower = 99.9; %  minimum extracted power 
    PARAM_MP.optim_options = optimset('Display','off','MaxIter',20,'TolFun',1e-6,'TolX',1e-6); % for covex optimization
    [ P_WVD, P, MP_PARAM ] = SubFunc_MP(x, T/1000, f, Fs, PARAM_MP);
 %     [P_WVD, P, PARAM_est, PARAM_est_0, R_x, Rec_x, Rec_x_0, P_R_x, P_Rec_x, P_Rec_x_0, P_Res, P_Res_0] = SubFunc_MP(x, T/1000, f, Fs, PARAM_MP);
    ST.MPA{i}.P_WVD=P_WVD;
    ST.MPA{i}.P=P;
    ST.MPA{i}.MP_PARAM=MP_PARAM;
    P_avg(i,:,:)=P_WVD;
    waitbar(i/size(data,2));
end
close(h); 
imagesc(T,f,squeeze(mean(P_avg,1)));axis xy;%axis([Pre_limit Post_limit],[Low_limit High_limit]);
xlabel('Time (ms)','fontsize',8); 
ylabel('Frequency (Hz)','fontsize',8);
colorbar;
ST.MP.t=T;
ST.MP.f=f;
ST.MPA_avg=squeeze(mean(P_avg,1));
ST.automanu=1;ST.type=1;
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


% --- Executes on button press in Confirm.
function Confirm_Callback(hObject, eventdata, handles)
% hObject    handle to Confirm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ST = evalin('base', 'ST');
if ST.automanu==1
    ST.MP_ST=[];
    for i=1:length(ST.MPA)
        for j=1:size(ST.MPA{i}.MP_PARAM,1)
            Den_axis(i,j,1:3)=ST.MPA{i}.MP_PARAM(j,[1 2 5]);
        end
    end
    for i=1:size(ST.MPROI,1)        
        for j=1:size(Den_axis,1)
            ST.MP_ST(j,i)=0;
            for k=1:size(Den_axis,2)
                temp=Den_axis(j,k,:);
                if (temp(1)>=ST.MPROI(i,1)/1000)&&(temp(1)<=ST.MPROI(i,2)/1000)
                    if (temp(2)>=ST.MPROI(i,3))&&(temp(2)<=ST.MPROI(i,4))
                        ST.MP_ST(j,i)=abs(temp(3))+ST.MP_ST(j,i); 
                    end
                end
            end
            clear temp;
        end
    end
elseif ST.automanu==0
    ST.MP_ST=[];
    Den_axis=ST.auto.Den_axis;
    Den=ST.auto.Den;
    IDX=ST.auto.IDX;
%     C=ST.auto.C;
    MP_STV=zeros(size(Den_axis,1),max(IDX));
    IDX1=reshape(IDX,size(Den_axis,1),size(Den_axis,2));
    for ii=1:size(Den_axis,1)
        for jj=1:size(Den_axis,2)
            MP_STV(ii,IDX1(ii,jj))=MP_STV(ii,IDX1(ii,jj))+abs(Den_axis(ii,jj,5));
        end
    end
    ST.MP_ST=MP_STV;
end
assignin('base','ST',ST);




