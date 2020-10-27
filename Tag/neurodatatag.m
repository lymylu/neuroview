function varargout = neurodatatag(varargin)
% NEURODATATAG MATLAB code for neurodatatag.fig
%      NEURODATATAG, by itself, creates a new NEURODATATAG or raises the existing
%      singleton*.
%
%      H = NEURODATATAG returns the handle to a new NEURODATATAG or the handle to
%      the existing singleton*.
%
%      NEURODATATAG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NEURODATATAG.M with the given input arguments.
%
%      NEURODATATAG('Property','Value',...) creates a new NEURODATATAG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before neurodatatag_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to neurodatatag_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help neurodatatag

% Last Modified by GUIDE v2.5 31-Aug-2020 20:05:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @neurodatatag_OpeningFcn, ...
                   'gui_OutputFcn',  @neurodatatag_OutputFcn, ...
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


% --- Executes just before neurodatatag is made visible.
function neurodatatag_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to neurodatatag (see VARARGIN)

% Choose default command line output for neurodatatag
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
global objmatrix DataTaglist Tagtmpmatrix
Tagtmpmatrix=[];
objmatrix=[];
DataTaglist={};


% UIWAIT makes neurodatatag wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = neurodatatag_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in SaveTag.
function SaveTag_Callback(hObject, eventdata, handles)
% hObject    handle to SaveTag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global objmatrix
uisave('objmatrix');




% --- Executes on button press in LoadTag.
function LoadTag_Callback(hObject, eventdata, handles)
% hObject    handle to LoadTag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global objmatrix DataTaglist
uiopen;
filelist=[];
informationtypeall=[];
informationall=[];
k=1;String=[];
for i=1:length(objmatrix)
filelist=vertcat(filelist,{objmatrix(i).Datapath});
[informationtype]=objmatrix(i).Tagcontent('fileTag');
try
    for j=1:length(informationtype)
        [informationtypeall{k},informationall{k}]=objmatrix(i).Tagcontent('fileTag',informationtype{j});
        k=k+1;
    end
end
[informationtype]=objmatrix(i).Tagcontent('ChannelTag');
try
    for j=1:length(informationtype)
        [informationtypeall{k},informationall{k}]=objmatrix(i).Tagcontent('ChannelTag',informationtype{j});
        k=k+1;
    end
end
end
for i=1:length(informationtypeall)
    String{i}=[informationtypeall{i},':',informationall{i}{:}];
end
DataTaglist=unique(String)';
set(handles.PathList,'String',filelist,'Value',1);



% --- Executes on button press in loadpath.
function loadpath_Callback(hObject, eventdata, handles)
% hObject    handle to loadpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global objmatrix 
path=uigetdir();
filelist=get(handles.PathList,'String');
index=[];
if ~isempty(objmatrix) 
for i=1:length(objmatrix)
    if strcmp(objmatrix(i).Datapath,path)
        index=i;
    end
end
end
if ~isempty(index)
    objmatrix(index)=objmatrix(index).fileappend(path);
else
     singleobj=NeuroData();
     singleobj=singleobj.fileappend(path);
     objmatrix=vertcat(objmatrix, singleobj);
     set(handles.PathList,'String',vertcat(filelist,{path}));
end





% --- Executes on button press in tagappend.
function tagappend_Callback(hObject, eventdata, handles)
% hObject    handle to tagappend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global objmatrix DataTaglist
objindex=get(handles.PathList,'Value');
singleobj=objmatrix(objindex);
[informationtype, information, DataTaglist]=Taginfoappend(DataTaglist)
for i=1:length(singleobj)
    singleobj(i)=singleobj(i).Taginfo('fileTag',informationtype,information);
end
objmatrix(objindex)=singleobj;
PathList_Callback(hObject, eventdata, handles)


% --- Executes on button press in tagdelete.
function tagdelete_Callback(hObject, eventdata, handles)
% hObject    handle to tagdelete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global objmatrix 
objindex=get(handles.PathList,'Value');
singleobj=objmatrix(objindex);
informationtypepool=[];
for i=1:length(singleobj);
informationtype=singleobj(i).Tagcontent('fileTag');
informationtypepool=vertcat(informationtypepool,informationtype);
end
informationtypepool=unique(informationtypepool);
chooseindex=listdlg('PromptString','选取要删除的标签名','SelectionMode','single','ListString', informationtypepool);
informationtype=informationtypepool{chooseindex};
for i=1:length(singleobj)
    singleobj(i)=singleobj(i).Taginfo('fileTag',informationtype,[]);
end
objmatrix(objindex)=singleobj;
PathList_Callback(hObject, eventdata, handles)



% --- Executes on selection change in PathList.
function PathList_Callback(hObject, eventdata, handles)
% hObject    handle to PathList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns PathList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PathList
global objmatrix
objindex=get(handles.PathList,'Value');
singleobj=objmatrix(objindex);
    String=[];String2=[];
for i=1:length(singleobj)
    [informationtype, information]=singleobj(i).Tagcontent('fileTag');
    try
    Stringtmp=cellfun(@(x,y) [x,':',y],informationtype,information,'UniformOutput',0);
    String=vertcat(String,Stringtmp);
    end
    [informationtype2, information2]=singleobj(i).Tagcontent('ChannelTag');
    try
         Stringtmp2=cellfun(@(x,y) [x,':',y],informationtype2,information2,'UniformOutput',0);
         String2=vertcat(String2,Stringtmp2);
    end
end
set(handles.taginfo,'String',unique(String));
set(handles.channelinfo,'String',unique(String2));
SubClassList_Callback(hObject, eventdata, handles)



% --- Executes during object creation, after setting all properties.
function PathList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PathList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in SubClassList.
function SubClassList_Callback(hObject, eventdata, handles)
% hObject    handle to SubClassList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SubClassList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SubClassList
global objmatrix Tagtmpmatrix  objtmpindex
Tagtmpmatrix=[];
objindex=get(handles.PathList,'Value');
singleobj=objmatrix(objindex);
subtypeindex=get(handles.SubClassList,'Value');
subtypelist=get(handles.SubClassList,'String');
subtype=subtypelist{subtypeindex};
filename=[];
objtmpindex=[];
for i=1:length(singleobj)
   for j=1:length(eval(['singleobj(i).',subtype]))
    Tagtmpmatrix=[Tagtmpmatrix,eval(['singleobj(i).',subtype,'(j)'])];
    objtmpindex=[objtmpindex,i];
   end
end
for i=1:length(Tagtmpmatrix)
    filename=[filename,{Tagtmpmatrix(i).Filename}];
end
set(handles.FileList,'String',filename,'Value',1);



% --- Executes during object creation, after setting all properties.
function SubClassList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SubClassList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in FileList.
function FileList_Callback(hObject, eventdata, handles)
% hObject    handle to FileList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns FileList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from FileList
global Tagtmpmatrix
fileindex=get(handles.FileList,'Value');
singleobj=Tagtmpmatrix(fileindex);
    String=[];String2=[];
for i=1:length(singleobj)
    [informationtype, information]=singleobj(i).Tagcontent('fileTag');
    try
    Stringtmp=cellfun(@(x,y) [x,':',y],informationtype,information,'UniformOutput',0);
    String=vertcat(String,Stringtmp);
    end
end
set(handles.subtaginfo,'String',unique(String));


% --- Executes during object creation, after setting all properties.
function FileList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FileList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in subtagappend.
function subtagappend_Callback(hObject, eventdata, handles)
% hObject    handle to subtagappend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global  Tagtmpmatrix DataTaglist
fileindex=get(handles.FileList,'Value');
singleobj=Tagtmpmatrix(fileindex);
[informationtype, information, DataTaglist]=Taginfoappend(DataTaglist)
for i=1:length(singleobj)
    singleobj(i)=singleobj(i).Taginfo('fileTag',informationtype,information);
end
Tagtmpmatrix(fileindex)=singleobj;
FileList_Callback(hObject, eventdata, handles);
SaveSubTag_Callback(hObject, eventdata, handles)




% --- Executes on button press in subtagdelete.
function subtagdelete_Callback(hObject, eventdata, handles)
% hObject    handle to subtagdelete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global  Tagtmpmatrix 
fileindex=get(handles.FileList,'Value');
singleobj=Tagtmpmatrix(fileindex);
informationtypepool=[];
for i=1:length(singleobj)
informationtype=singleobj(i).Tagcontent('fileTag');
informationtypepool=vertcat(informationtypepool,informationtype);
end
informationtypepool=unique(informationtypepool);
chooseindex=listdlg('PromptString','选取要删除的标签名','SelectionMode','single','ListString', informationtypepool);
informationtype=informationtypepool{chooseindex};
for i=1:length(singleobj)
    singleobj(i)=singleobj(i).Taginfo('fileTag',informationtype,[]);
end
Tagtmpmatrix(fileindex)=singleobj;
FileList_Callback(hObject, eventdata, handles);
SaveSubTag_Callback(hObject, eventdata, handles);

% --- Executes on button press in channeltagappend.
function channeltagappend_Callback(hObject, eventdata, handles)
% hObject    handle to channeltagappend (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global  objmatrix DataTaglist
fileindex=get(handles.PathList,'Value');
singleobj=objmatrix(fileindex);
[informationtype, information, DataTaglist]=Taginfoappend(DataTaglist)
for i=1:length(singleobj)
    singleobj(i)=singleobj(i).Taginfo('ChannelTag',informationtype,information);
end
objmatrix(fileindex)=singleobj;






% --- Executes on button press in channeltagdelete.
function channeltagdelete_Callback(hObject, eventdata, handles)
% hObject    handle to channeltagdelete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global  objmatrix
fileindex=get(handles.PathList,'Value');
singleobj=objmatrix(fileindex);
informationtypepool=[];
for i=1:length(singleobj)
informationtype=singleobj(i).Tagcontent('ChannelTag');
informationtypepool=vertcat(informationtypepool,informationtype);
end
informationtypepool=unique(informationtypepool);
chooseindex=listdlg('PromptString','选取要删除的标签名','SelectionMode','single','ListString', informationtypepool);
informationtype=informationtypepool{chooseindex};
for i=1:length(singleobj)
    singleobj(i)=singleobj(i).Taginfo('ChannelTag',informationtype,[]);
end
objmatrix(fileindex)=singleobj;

% --- Executes on button press in initialized.
function initialized_Callback(hObject, eventdata, handles)
% hObject    handle to initialized (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Tagtmpmatrix
fileindex=get(handles.FileList,'Value');
singleobj=Tagtmpmatrix(fileindex);
subclassindex=get(handles.SubClassList,'Value');
subclass=get(handles.SubClassList,'String');
subclasstype=subclass{subclassindex};
switch subclasstype
    case 'LFPdata'
        output=inputdlg({'请输入文件的通道总数','请输入文件的采样率','请输入转换为μV的系数'});
        Channelnum=output{1};
        Samplerate=output{2};
        ADconvert=output{3};
        for i=1:length(singleobj)
            singleobj(i)=singleobj(i).initialize(Channelnum, Samplerate,ADconvert);
        end
    case 'SPKdata'
        output=inputdlg('请输入文件的采样率');
        Samplerate=output{1};
        for i=1:length(singleobj)
            singleobj(i)=singleobj(i).initialize(Samplerate)
        end
    case 'EVTdata'
        for i=1:length(singleobj)
            singleobj(i)=singleobj(i).initialize();
        end
end
Tagtmpmatrix(fileindex)=singleobj;
SaveSubTag_Callback(hObject, eventdata, handles);


% --- Executes on button press in SaveSubTag.
function SaveSubTag_Callback(hObject, eventdata, handles)
% hObject    handle to SaveSubTag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global objmatrix Tagtmpmatrix objtmpindex
objindex=get(handles.PathList,'Value');
singleobj=objmatrix(objindex);
subclassindex=get(handles.SubClassList,'Value');
subclass=get(handles.SubClassList,'String');
subclasstype=subclass{subclassindex};
for i=1:length(singleobj)
    eval(['singleobj(i).',subclasstype,'=Tagtmpmatrix(find(objtmpindex==i))']);
end
objmatrix(objindex)=singleobj;


% --- Executes on button press in deletepath.
function deletepath_Callback(hObject, eventdata, handles)
% hObject    handle to deletepath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global objmatrix objtmpindex
objindex=get(handles.PathList,'Value');
objmatrix(objindex)=[];
String=get(handles.PathList,'String');
String(objindex,:)=[];
set(handles.PathList,'String',String,'Value',1);
if ~isempty(objtmpindex)
    objtmpindex(find(objtmpindex==objindex))=[];
end
SubClassList_Callback(hObject, eventdata, handles)


% --- Executes on button press in changedirectory.
function changedirectory_Callback(hObject, eventdata, handles)
% hObject    handle to changedirectory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global objmatrix
objindex=get(handles.PathList,'Value');
objmatrixtmp=objmatrix(objindex);
change=inputdlg({'原始路径','更改路径'});
objmatrixtmp=replace(objmatrixtmp,change);
if ispc
    objmatrixtmp=replace(objmatrixtmp,{'/','\'});
else
    objmatrixtmp=replace(objmatrixtmp,{'\','/'});
end
objmatrix(objindex)=objmatrixtmp;

for i=1:length(objmatrix)
    pathlist{i}=objmatrix(i).Datapath
end
    set(handles.PathList,'String',pathlist,'Value',1);

    function objmatrixtmp=replace(objmatrixtmp,change)
 for i=1:length(objmatrixtmp)
    try
        objmatrixtmp(i).Datapath=strrep(objmatrixtmp(i).Datapath,change{1},change{2});
    end
    try
        for c=1:length(objmatrixtmp(i).LFPdata)
            objmatrixtmp(i).LFPdata(c).Filename=strrep(objmatrixtmp(i).LFPdata(c).Filename,change{1},change{2});
        end
    end
    try
        for c=1:length(objmatrixtmp(i).SPKdata)
            objmatrixtmp(i).SPKdata(c).Filename=strrep(objmatrixtmp(i).SPKdata(c).Filename,change{1},change{2});
        end
    end
        try
        for c=1:length(objmatrixtmp(i).EVTdata)
            objmatrixtmp(i).EVTdata(c).Filename=strrep(objmatrixtmp(i).EVTdata(c).Filename,change{1},change{2});
        end
    end
end