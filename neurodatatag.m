classdef neurodatatag
    % Create the GUI panel of neurodatatag
    properties
        parent
        mainWindow
    end
    methods     
        function obj=CreateGUI(obj,parent)
            global objmatrixpath
           obj.parent=parent;
           obj.mainWindow=uix.Panel('Parent',obj.parent,'Title','Neurodatatag');
           maingrid=uix.VBox('Parent',obj.mainWindow);
           % %
           SubjectPanel=uix.Panel('Parent',maingrid,'Title','SubjectInfomation');
           subSubjectPanel=uix.HBox('Parent',SubjectPanel);
           buttonpanel=uix.VBox('Parent',subSubjectPanel);
           uicontrol('Parent',buttonpanel,'Style','pushbutton','String','Load Subject Dir','Callback',@(~,~) obj.LoadSubjectDir);
           uicontrol('Parent',buttonpanel,'Style','pushbutton','String','Delete Selected Subject Dir','Callback',@(~,~) obj.DeleteSubjectDir);
           uicontrol('Parent',buttonpanel,'Style','pushbutton','String','Add Subject Tag','Callback', @(~,~) obj. AddSubjectTag('fileTag'));
           uicontrol('Parent',buttonpanel,'Style','pushbutton','String','Delete Subject Tag','Callback', @(~,~) obj. DeleteSubjectTag('fileTag'));
           uicontrol('Parent',buttonpanel,'Style','pushbutton','String','Add Channel Tag','Callback',@(~,~) obj.AddSubjectTag('ChannelTag'));
           uicontrol('Parent',buttonpanel,'Style','pushbutton','String','Delete Channel Tag','Callback',@(~,~) obj.DeleteSubjectTag('ChannelTag'));
           Subjectlist=uicontrol('Parent',subSubjectPanel,'Style','listbox','String',[],'Tag','Subjectlist','min',0,'max',3);
           tmppanel=uix.VBox('Parent',subSubjectPanel);
           tmppanel2=uix.Panel('Parent',tmppanel,'Title','Subject Tag Info');
           uicontrol('Parent',tmppanel2,'Style','Text','String',[],'Tag','SubjectTagShow');
           tmppanel2=uix.Panel('Parent',tmppanel,'Title','Subject Channel Info');
           uicontrol('Parent',tmppanel2,'Style','Text','String',[],'Tag','ChannelTagShow');
           addlistener(Subjectlist,'Value','PostSet',@(~,~) obj.SubjectValueChangedFcn);
           tmppanel=uix.VBox('Parent',subSubjectPanel);
           tmppanel2=uix.Panel('Parent',tmppanel,'Title','Subject Tag pool');
           SubjectTaglist=uicontrol('Parent',tmppanel2,'Style','listbox','String',[],'Tag','SubjectTaglist','min',0,'max',3);
           tmppanel2=uix.Panel('Parent',tmppanel,'Title','Channel Tag pool');
           uicontrol('Parent',tmppanel2,'Style','listbox','String',[],'Tag','ChannelTaglist','min',0,'max',3);
           contextmenu=uicontextmenu(obj.parent);
           uimenu(contextmenu,'Text','Modifiy the Selected Tag/TagValue','MenuSelectedFcn', @(~,~) obj.TagModify(SubjectTaglist,'Subject'));
           uimenu(contextmenu,'Text','Choose the Subject with Selected Tag/TagValue','MenuSelectedFcn', @(~,~) obj.TagSelect(SubjectTaglist,'Subject'));
           SubjectTaglist.UIContextMenu=contextmenu;
           % % % % % % %
           FilePanel=uix.Panel('Parent',maingrid,'Title','FileInformation');
           subFilePanel=uix.HBox('Parent',FilePanel);
           buttonpanel=uix.VBox('Parent',subFilePanel);
           Datatype=uicontrol('Parent',buttonpanel,'Style','popupmenu','String',{'LFPdata','SPKdata','EVTdata','Videodata'},'Tag','Filetype');
           uicontrol('Parent',buttonpanel,'Style','pushbutton','String','Add File Tag','Callback',@(~,~) obj.AddFileTag);
           uicontrol('Parent',buttonpanel,'Style','pushbutton','String','Delete File Tag','Callback',@(~,~) obj.DeleteFileTag);
           uicontrol('Parent',buttonpanel,'Style','pushbutton','String','Initialize Files','Callback',@(~,~) obj.initialized);
           Filelist=uicontrol('Parent',subFilePanel,'Style','listbox','String',[],'Tag','Filelist','min',0,'max',3);
           addlistener(Datatype,'Value','PostSet',@(~,~) obj.Datatypechangefcn(Datatype,Subjectlist,Filelist));
           tmppanel=uix.VBox('Parent',subFilePanel);
           tmppanel2=uix.Panel('Parent',tmppanel,'Title','File Tag Info');
           uicontrol('Parent',tmppanel2,'Style','Text','String',[],'Tag','FileTagShow');
           tmppanel2=uix.Panel('Parent',tmppanel,'Title','File Properties');
           uicontrol('Parent',tmppanel2,'Style','Text','String',[],'Tag','InitializedShow');
           addlistener(Filelist,'Value','PostSet',@(~,~) obj.FileValueChangedFcn);
           tmppanel=uix.VBox('Parent',subFilePanel);
           tmppanel2=uix.Panel('Parent',tmppanel,'Title','File Tag Pool');
           FileTaglist=uicontrol('Parent',tmppanel2,'Style','listbox','String',[],'Tag','FileTaglist','min',0,'max',3);
           contextmenu=uicontextmenu(obj.parent);
           uimenu(contextmenu,'Text','Modifiy the Selected Tag/TagValue','MenuSelectedFcn', @(~,~) obj.TagModify(FileTaglist,'File'));
           uimenu(contextmenu,'Text','Choose the File with Selected Tag/TagValue','MenuSelectedFcn', @(~,~) obj.TagSelect(FileTaglist,'File'));
           FileTaglist.UIContextMenu=contextmenu;
           obj.LoadTagInfo();
        end 
        function CheckTagInfo(obj)
            err=[];
            Subjectobj=findobj(obj.parent,'Tag','Subjectlist');
            SubjectTagShow=findobj(obj.parent,'Tag','SubjectTagShow');
            SubjectChannel=findobj(obj.parent,'Tag','ChannelTagShow');
            for i=1:length(Subjectobj.String)
                Subjectobj.Value=i;
                if isempty(SubjectTagShow.String) || isempty(SubjectChannel.String)
                    err=vertcat(err,Subjectobj.String(i));
                end
            end
            Subjectobj.Value=1:length(Subjectobj.String);
            Datatype=findobj(obj.parent,'Tag','Filetype');
            Filelist=findobj(obj.parent,'Tag','Filelist');
            FileTagShow=findobj(obj.parent,'Tag','FileTagShow');
            FilePropShow=findobj(obj.parent,'Tag','InitializedShow');
            for i=1:length(Datatype.String)
                Datatype.Value=i;
                for j=1:length(Filelist.String)
                    Filelist.Value=j;
                    if isempty(FileTagShow.String) || isempty(FilePropShow.String)
                        err=vertcat(err,Filelist.String(j));
                    end
                end
            end
            if ~isempty(err)
                figure;
                tmppanel=uix.Panel('Parent',gcf,'Title','the following dir/file(s) with no tags, they will be excluded with following analysis.');
                uicontrol('parent',tmppanel,'Style','listbox','String',err);
            else
                msgbox('no dir/file(s) with no tags');
            end
        end
        function SaveTagInfo(obj)
            global objmatrix
            if ~isempty(objmatrix)
                uisave('objmatrix');
            end
        end
        function LoadTagInfo(obj)
            global objmatrix objmatrixpath
            Subjecttagpool=findobj(obj.parent,'Tag','SubjectTaglist');
            Channeltagpool=findobj(obj.parent,'Tag','ChannelTaglist');
            Filetagpool=findobj(obj.parent,'Tag','FileTaglist');
            Subjecttaglist=findobj(obj.parent,'Tag','SubjectTagShow');
            Channeltaglist=findobj(obj.parent,'Tag','ChannelTagShow');
            Filetaglist=findobj(obj.parent,'Tag','FileTagShow');
            Filelist=findobj(obj.parent,'Tag','Filelist');
            Subjectlist=findobj(obj.parent,'Tag','Subjectlist');
            if isempty(objmatrixpath)
                [f,p]=uigetfile();
                objmatrixpath=[p,f];
            end
            Taginfo=matfile(objmatrixpath);
            objmatrix=Taginfo.objmatrix;
            for i=1:length(objmatrix)
                Datapathlist{i}=objmatrix(i).Datapath;
            end
            Subjectlist.String=Datapathlist;
            Subjectlist.Value=1:length(Subjectlist.String);
            Subjecttagpool.String=Subjecttaglist.String;
            Channeltagpool.String=Channeltaglist.String;
            filetype=findobj(obj.parent,'Tag','Filetype');
            output=[];
            for i=1:length(filetype.String)
                filetype.Value=i;
                Filelist.Value=1:length(Filelist.String);
                output=vertcat(output,Filetaglist.String);
            end
            Filetagpool.String=unique(output);
            Subjectlist.Value=1;
        end
        function ChangeRoot(obj)
            global objmatrix
            Subjectlist=findobj(obj.parent,'Tag','Subjectlist');
            objmatrixtmp=objmatrix(Subjectlist.Value);
            change=inputdlg({'original path','modified path'});
            objmatrixtmp=obj.replace(objmatrixtmp,change);
            if ispc
                objmatrixtmp=obj.replace(objmatrixtmp,{'/','\'});
            else
                objmatrixtmp=obj.replace(objmatrixtmp,{'\','/'});
            end
            objmatrix(Subjectlist.Value)=objmatrixtmp;
            for i=1:length(objmatrix)
                pathlist{i}=objmatrix(i).Datapath
            end
            set(Subjectlist,'String',pathlist,'Value',1);
        end
        function initialized(obj)
            global Filematrix
            Filelist=findobj(obj.parent,'Tag','Filelist');
            singleobj=Filematrix(Filelist.Value);
            Filetype=findobj(obj.parent,'Tag','Filetype');
            subclasstype=Filetype.String{Filetype.Value};
            switch subclasstype
                case 'LFPdata'
                    output=inputdlg({'Total Channel Number','SampleRate','ADconvert'});
                    Channelnum=output{1};
                    Samplerate=output{2};
                    ADconvert=output{3};
                    for i=1:length(singleobj)
                        singleobj(i)=singleobj(i).initialize(Channelnum, Samplerate,ADconvert);
                    end
            case 'SPKdata'
                    output=inputdlg('SampleRate');
                    Samplerate=output{1};
                    multiWaitbar('initialized',0)
                    for i=1:length(singleobj)
                        singleobj(i)=singleobj(i).initialize(Samplerate);
                        multiWaitbar('initialized',i/length(singleobj));
                    end
                    multiWaitbar('initialized','close');
            case 'EVTdata'
                    for i=1:length(singleobj)
                        singleobj(i)=singleobj(i).initialize();
                    end
            case 'Videodata'
                answer = questdlg('define the correcttime of the Video(s)', ...
            'Video Correct', 'Input the Value','Correct by the event file','Cancel','Cancel');
                switch answer
                    case 'Input the Value'
                        inputdlg('please input the correcttime value!');
                        for i=1:length(singleobj)
                            singleobj(i).singleobj(i).initialize();
                        end
                    case 'Correct by the event file'
                        msgbox('the video will be corrected by a specific eventtype in a event file, the multiple video(s) will be sorted by time according to their creation time');
                        [f,p]=uigetfile('.evt','choose a event file!');
                        events=LoadEvents_neurodata([p,f]);
                        [~,index]=sort(events.time);
                        events.time=events.time(index);
                        events.description=events.description(index);
                        eventtype=unique(events.description);
                        SaveEvents_neurodata([p,f],events,1);
                        type=listdlg('ListString',eventtype,'Promptstring','choose a eventtype');
                        index=ismember(events.description,eventtype(type));
                        correcttime=events.time(index);
                        if length(correcttime)~=length(singleobj)
                            fprintf('the number of the events %1.0f is different from the number of video files %1.0f, they are not relative!', [length(correcttime),length(singleobj)]);
                            return;
                        else
                            for i=1:length(singleobj)
                                time=dir(singleobj(i).Filename);
                                timecreate(i)=time.datenum;
                            end
                            [timecreate,index]=sort(timecreate);
                            singleobj=singleobj(index);
                            for i=1:length(singleobj)
                                 singleobj(i).initialize(events.time(i));
                            end
                        end
                end
                end
           Filematrix(Filelist.Value)=singleobj;
           obj.SaveFileToSubject;
        end        
    end
    methods(Static)
        function output=getTaginfo(Neurodata,option)
            output=[];
            switch option
                case 'Tagtype'    
                    for i=1:length(Neurodata)
                    tagtype=Neurodata(i).Tagcontent('fileTag');
                        for j=1:length(tagtype)
                            output=vertcat(output,tagtype(j));
                        end
                    end
                case 'Tagtype:Tagvalue'
                    for i=1:length(Neurodata)
                        tagtype=Neurodata(i).Tagcontent('fileTag');
                        if ~isempty(tagtype)
                            for j=1:length(tagtype)
                                 [tagtype{j},tagvalue]=Neurodata(i).Tagcontent('fileTag',tagtype{j});
                                 output=vertcat(output,{[tagtype{j},':',tagvalue{:}]});
                            end
                        end
                    end
                case 'ChannelTag'
                       for i=1:length(Neurodata)
                    tagtype=Neurodata(i).Tagcontent('ChannelTag');
                        for j=1:length(tagtype)
                            output=vertcat(output,tagtype(j));
                        end
                       end
            end
               if ~isempty(output)
                        output=unique(output);
               end
        end
        function output=getPropertiesinfo(Neurodata)
            output=[];
            switch class(Neurodata)    
                case 'NeuroData' % %  Channel Info
                    for i=1:length(Neurodata)
                        tagtype=Neurodata(i).Tagcontent('ChannelTag');
                        if ~isempty(tagtype)
                            for j=1:length(tagtype)
                                [tagtype{j},tagvalue]=Neurodata(i).Tagcontent('ChannelTag',tagtype{j});
                                if ~isempty(tagvalue);
                                    output=vertcat(output,{[tagtype{j},':',tagvalue{:}]});
                                end
                            end
                        end
                    end
                case 'LFPData' % % sample rate, channel, ADconvert
                    for i=1:length(Neurodata)
                        samplerate=Neurodata(i).Samplerate;
                        channelnum=Neurodata(i).Channelnum;
                        ADconvert=Neurodata(i).ADconvert;
                        if ~isempty(samplerate);
                            output=cat(1,output,{['Samplerate:',samplerate]},{['Channelnumber:',channelnum]},{['ADconvert:',ADconvert]});
                        end
                    end
                case 'SPKData' % % cluster relative to channel number
                    for i=1:length(Neurodata)
                        Spkchannel=Neurodata(i).SPKchannel;
                        if ~isempty(Spkchannel)
                            output=vertcat(output,{['Clusterchannel:',num2str(Spkchannel)]});
                        end
                    end
                case 'EVTData' % % EVTtype
                    for i=1:length(Neurodata)
                        Eventtype=Neurodata(i).EVTtype;
                        for j=1:length(Eventtype)
                            output=vertcat(output,{['EVTtype:',Eventtype{j}]});
                        end
                    end
                case 'VideoData' % %  correct time
                    for i=1:length(Neurodata)
                        correcttime=Neurodata(i).correcttime;
                        if isempty(correcttime)
                            output=vertcat(output,{['Videobegintime:',num2str(correcttime)]});
                        end
                    end
            end
            if ~isempty(output)
                        output=unique(output);
            end
        end
        function objmatrixtmp=replace(objmatrixtmp,change)
            for i=1:length(objmatrixtmp)
                try
                    objmatrixtmp(i).Datapath=strrep(objmatrixtmp(i).Datapath,change{1},change{2});
                end
                filetype={'LFPdata','SPKdata','EVTdata','Videodata'};
                for j=1:length(filetype)
                    try
                        for c=1:length(eval(['objmatrixtmp(i).',filetype{j}]))
                            eval(['objmatrixtmp(i).',filetype{j},'(c).Filename=strrep(objmatrixtmp(i).',filetype{j},'(c).Filename,change{1},change{2});']);
                        end
                    end
                end
            end
        end
    end
    methods(Access='private')
        function LoadSubjectDir(obj)
               global objmatrix
               path=uigetdir();
               Subjectlist=findobj(obj.parent,'Tag','Subjectlist');
               filelist=Subjectlist.String;
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
                     set(Subjectlist,'Value',index);
                else
                     singleobj=NeuroData();
                     singleobj=singleobj.fileappend(path);
                     objmatrix=vertcat(objmatrix, singleobj);
                     set(Subjectlist,'String',vertcat(filelist,{path}));
                     set(Subjectlist,'Value',length(filelist)+1);
                end
        end
        function DeleteSubjectDir(obj)
            global objmatrix
                Subjectlist=findobj(obj.parent,'Tag','Subjectlist');
                objmatrix(Subjectlist.Value)=[];
                Subjectlist.String(Subjectlist.Value)=[];         
                if ~isempty(Subjectlist.String)
                    Subjectlist.Value=1;
                end
        end
        function AddSubjectTag(obj,option)
            global objmatrix
            Subjectlist=findobj(gcf,'Tag','Subjectlist');
            singleobj=objmatrix(Subjectlist.Value);
            switch option
                case 'fileTag'
                    DataTaglist=findobj(gcf,'Tag','SubjectTaglist');
                case 'ChannelTag'
                    DataTaglist=findobj(gcf,'Tag','ChannelTaglist');
            end
            [informationtype, information, Tagstring]=Taginfoappend(DataTaglist.String)
            DataTaglist.String=Tagstring;       
            for i=1:length(singleobj)
                singleobj(i)=singleobj(i).Taginfo(option,informationtype,information);
            end
            objmatrix(Subjectlist.Value)=singleobj;
            obj.SubjectValueChangedFcn;
        end
        function DeleteSubjectTag(obj,option)
            global objmatrix
            Subjectlist=findobj(gcf,'Tag','Subjectlist');
            singleobj=objmatrix(Subjectlist.Value);
            switch option
                case 'fileTag'
                    Tagname=obj.getTaginfo(singleobj,'Tagtype');
                case 'ChannelTag'
                    Tagname=obj.getTaginfo(singleobj,'ChannelTag');
            end
            chooseindex=listdlg('PromptString','选取要删除的标签名','SelectionMode','single','ListString', Tagname);
            Tagname=Tagname{chooseindex};
            for i=1:length(singleobj)
                singleobj(i)=singleobj(i).Taginfo(option,Tagname,[]);
            end
            objmatrix(Subjectlist.Value)=singleobj;
            obj.SubjectValueChangedFcn;
        end
        function FileValueChangedFcn(obj)
            global Filematrix
            Fileobj=findobj(obj.parent,'Tag','Filelist');
            Filetag=findobj(obj.parent,'Tag','FileTagShow');
            Filetag.String=obj.getTaginfo(Filematrix(Fileobj.Value),'Tagtype:Tagvalue');
            Fileprop=findobj(obj.parent,'Tag','InitializedShow');
            Fileprop.String=obj.getPropertiesinfo(Filematrix(Fileobj.Value));
        end
        function SubjectValueChangedFcn(obj)
            global objmatrix
            Subjectobj=findobj(obj.parent,'Tag','Subjectlist');
            Datatype=findobj(obj.parent,'Tag','Filetype');
            Filelist=findobj(obj.parent,'Tag','Filelist');
            Subjecttag=findobj(obj.parent,'Tag','SubjectTagShow');
            Subjecttag.String=obj.getTaginfo(objmatrix(Subjectobj.Value),'Tagtype:Tagvalue');
            Subjectchannel=findobj(obj.parent,'Tag','ChannelTagShow');
            Subjectchannel.String=obj.getPropertiesinfo(objmatrix(Subjectobj.Value));
            obj.Datatypechangefcn(Datatype,Subjectobj,Filelist);
        end
        function Datatypechangefcn(obj,Datatype,Subjectlist,Filelist)
            global objmatrix Filematrix objtmpindex
            Filematrix=[];
            singleobj=objmatrix(Subjectlist.Value);
            subtype=Datatype.String{Datatype.Value};
            filename=[];
            objtmpindex=[];
            for i=1:length(singleobj)
               for j=1:length(eval(['singleobj(i).',subtype]))
                Filematrix=[Filematrix,eval(['singleobj(i).',subtype,'(j)'])];
                objtmpindex=[objtmpindex,i];
               end
            end
            for i=1:length(Filematrix)
                filename=[filename,{Filematrix(i).Filename}];
            end
            set(Filelist,'String',filename,'Value',1);
            Filetaglist=findobj(obj.parent,'Tag','FileTagShow');
            Filetaglist.String=obj.getTaginfo(Filematrix(Filelist.Value),'Tagtype:Tagvalue');
            Fileproplist=findobj(obj.parent,'Tag','InitializedShow');
            Fileproplist.String=obj.getPropertiesinfo(Filematrix(Filelist.Value));
        end
        function AddFileTag(obj)
            global Filematrix
            Filelist=findobj(gcf,'Tag','Filelist');
            singleobj=Filematrix(Filelist.Value);
            DataTaglist=findobj(gcf,'Tag','FileTaglist');
            [informationtype, information, Tagstring]=Taginfoappend(DataTaglist.String)
            DataTaglist.String=Tagstring;
            for i=1:length(singleobj)
                singleobj(i)=singleobj(i).Taginfo('fileTag',informationtype,information);
            end
            Filematrix(Filelist.Value)=singleobj;
            obj.SaveFileToSubject;
        end
        function DeleteFileTag(obj)
            global Filematrix
            Filelist=findobj(gcf,'Tag','Filelist');
            singleobj=Filematrix(Filelist.Value);
            Tagname=obj.getTaginfo(singleobj,'Tagtype');
            chooseindex=listdlg('PromptString','选取要删除的标签名','SelectionMode','single','ListString', Tagname);
            Tagname=Tagname{chooseindex};
            for i=1:length(singleobj)
                singleobj(i)=singleobj(i).Taginfo('fileTag',Tagname,[]);
            end
            Filematrix(Filelist.Value)=singleobj;
            obj.SaveFileToSubject;
        end
        function SaveFileToSubject(obj)
            global Filematrix objmatrix objtmpindex
            Subjectlist=findobj(obj.parent,'Tag','Subjectlist');
            singleobj=objmatrix(Subjectlist.Value);
            Filetype=findobj(obj.parent,'Tag','Filetype');
            subclasstype=Filetype.String{Filetype.Value};
            for i=1:length(singleobj)
                eval(['singleobj(i).',subclasstype,'=Filematrix(find(objtmpindex==i))']);
            end
            objmatrix(Subjectlist.Value)=singleobj;
        end
        function TagModify(obj,TagList,option)
            global Filematrix objmatrix
            if length(TagList.Value)>1
                warndlg('Please choose One Tag:TagValue to modify!');
                return;
            else
                origin=regexpi(TagList.String{TagList.Value},':','split');
                modified=inputdlg('Please input the modified Tag:TagValue');
                modified2=regexpi(modified{:},':','split');
                switch option
                    case 'Subject'
                        for i=1:length(objmatrix)
                            bool = Tagchoose(objmatrix(i),'fileTag', origin{1}, origin{2});
                            if bool==1
                                objmatrix(i).Taginfo('fileTag',origin{1},[]);
                                objmatrix(i).Taginfo('fileTag',modified2{1},modified2{2});
                            end
                        end
                    case 'File'
                        for i=1:length(Filematrix)
                            bool = Tagchoose(Filematrix(i),'fileTag', origin{1}, origin{2});
                            if bool==1
                                Filematrix(i).Taginfo('fileTag',origin{1},[]);
                                Filematrix(i).Taginfo('fileTag',modified2{1},modified2{2});
                            end
                        end
                        obj.SaveFileToSubject;
                end
                TagList.String(TagList.Value)=modified;
            end
        end              
        function TagSelect(obj,TagList,option)
            global Filematrix objmatrix 
            origin=cellfun(@(x) regexpi(x,':','split'), TagList.String(TagList.Value),'UniformOutput',0);
            switch option
                case 'Subject'
                    value=[];
                    Subjectlist=findobj(obj.parent,'Tag','Subjectlist');
                    for i=1:length(objmatrix)
                        for j=1:size(origin,1)
                            bool=Tagchoose(objmatrix(i),'fileTag',origin{j}{1},origin{j}{2})
                            if bool==1
                                value=vertcat(value,i);
                                break;
                            end
                        end
                    end
                    Subjectlist.Value=value;
                case 'File'
                    value=[];
                    Filelist=findobj(obj.parent,'Tag','Filelist');
                    for i=1:length(Filematrix)
                        for j=1:size(origin,1)
                            bool=Tagchoose(Filematrix(i),'fileTag',origin{j,1},origin{j,2})
                            if bool==1
                                value=vertcat(value,i);
                                break;
                            end
                        end
                    end
                    Filelist.Value=value;
            end
        end
    end
end