classdef neurodatatag
    % GUI panel of neurodatatag
    % Load the tag information of the metadata from the .mat files contains NEURODATA obj.
    % The neurodata objects could be managed by adding or deleting tags
    % 
    
    properties
        parent
        mainWindow
    end
    methods     
        function obj=CreateGUI(obj,parent)
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
           Datatype=uicontrol('Parent',buttonpanel,'Style','popupmenu','String',{'LFPdata','SPKdata','CALdata','EVTdata','Videodata','Neuroresult'},'Tag','Filetype');
           uicontrol('Parent',buttonpanel,'Style','pushbutton','String','Load the File','Callback',@(~,~) obj.AddFile(Datatype,Subjectlist));
           uicontrol('Parent',buttonpanel,'Style','pushbutton','String','Add File Tag','Callback',@(~,~) obj.AddFileTag);
           uicontrol('Parent',buttonpanel,'Style','pushbutton','String','Delete File Tag','Callback',@(~,~) obj.DeleteFileTag);
           uicontrol('Parent',buttonpanel,'Style','pushbutton','String','Initialize Files','Callback',@(~,~) obj.initialized);
           Filelist=uicontrol('Parent',subFilePanel,'Style','listbox','String',[],'Tag','Filelist','min',0,'max',3);
           addlistener(Datatype,'Value','PostSet',@(~,~) obj.Datatypechangefcn(Datatype,Subjectlist,Filelist));
           contextmenu=uicontextmenu(obj.parent);
           uimenu(contextmenu,'Text','Remove choosed file','MenuSelectedFcn',@(~,~) obj.RemoveFile(Filelist));
           Filelist.UIContextMenu=contextmenu;
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
           try
             %obj.LoadTagInfo();
           end
        end 
        function CheckTagInfo(obj)
            % check the whether the taginfo file integration
            global NV
            obj.SaveTagInfo;
            err=0;
            err_subjecttag=[];
            err_nopath=[];
            for i=1:length(NV.objmatrix)
                if isempty(NV.objmatrix(i).fileTag)
                    err_subjecttag=vertcat(err_subjecttag,{NV.objmatrix(i).Datapath});
                end
                if ~exist(NV.objmatrix(i).Datapath,'dir')
                    err_nopath=vertcat(err_nopath,{NV.objmatrix(i).Datapath});
                end
            end
            figure;
            if ~isempty(err_subjecttag)
                tmpbox=uix.VBox('Parent',gcf);
                tmppanel=uix.Panel('Parent',tmpbox,'Title','the following dir/file(s) with no tags, they cannot be choosed for following analysis.');
                uicontrol('parent',tmppanel,'Style','listbox','String',err_subjecttag);
                err=1;
            end
            Datatype=findobj(obj.parent,'Tag','Filetype');
            for i=1:length(Datatype.String)
                err_filetag=[];
                for j=1:length(NV.objmatrix)
                    tmp=NV.objmatrix.struct();
                    if isfield(tmp,Datatype.String{i})
                    tmpfile=eval(['NV.objmatrix(j).',Datatype.String{i}]);
                    if ~isempty(tmpfile)
                    for k=1:length(tmpfile)
                        if ~tmpfile(k).check
                            err_filetag=vertcat(err_filetag,{tmpfile(k).Filename});
                        end
                        if ~exist(tmpfile(k).Filename,'file')&&~exist(tmpfile(k).Filename,'dir')
                            err_nopath=vertcat(err_nopath,{tmpfile(k).Filename});
                        end
                    end
                    end
                    end
                end
                if ~isempty(err_filetag)
                    tmpbox=uix.VBox('Parent',gcf);
                    tmppanel=uix.Panel('Parent',tmpbox,'Title',['the following dir/file(s) with no tags in ',Datatype.String{i}]);
                    uicontrol('parent',tmppanel,'Style','listbox','String',err_filetag);
                    err=1;
                end
                if ~isempty(err_nopath)
                    tmpbox=uix.VBox('Parent',gcf);
                    tmppanel=uix.Panel('Parent',tmpbox,'Title',['the following dir/file(s) are not exist.']);
                    uicontrol('parent',tmppanel,'Style','listbox','String',err_nopath);
                    err=1;
                end
            end
            if ~err
                msgbox('no dir/file(s) with no tags');
            end
        end
        function LoadTagInfo(obj)
            global NV
            Subjecttagpool=findobj(obj.parent,'Tag','SubjectTaglist');
            Channeltagpool=findobj(obj.parent,'Tag','ChannelTaglist');
            Filetagpool=findobj(obj.parent,'Tag','FileTaglist');
            Subjecttaglist=findobj(obj.parent,'Tag','SubjectTagShow');
            Channeltaglist=findobj(obj.parent,'Tag','ChannelTagShow');
            Filetaglist=findobj(obj.parent,'Tag','FileTagShow');
            Filelist=findobj(obj.parent,'Tag','Filelist');
            Subjectlist=findobj(obj.parent,'Tag','Subjectlist');
            if isempty(NV.objmatrix)
            [f,p]=uigetfile('*.mat;*.yaml','Select the metadata information file');
            [~,~,ext]=fileparts([p,f]);
                NV.objmatrixpath=[p,f];
                if strcmp(ext,'.yaml')
                    Taginfo=yaml.loadFile([p,f],'ConvertToArray',true);
                    NV.objmatrix=NeuroData(Taginfo);
                elseif strcmp(ext,'.mat')
                    Taginfo=matfile(NV.objmatrixpath);           
                    NV.objmatrix=Taginfo.objmatrix; 
                    assert(strcmp(class(NV.objmatrix),'NeuroData'),'no metadata information in the .mat file!');
                else
                    error('not support other format of information');
                end
            end          
                Datapathlist=NV.objmatrix.getDatapath;
                set(Subjectlist,'String',Datapathlist);
                set(Subjectlist,'Value',1:length(Subjectlist.String));
                Subjecttagpool.String=NV.objmatrix.getTaginfo('Tagname:Tagvalue','fileTag');
                Channeltagpool.String=NV.objmatrix.getTaginfo('Tagname:Tagvalue','ChannelTag');
                filetype=findobj(obj.parent,'Tag','Filetype');
                output=[];
                for j=1:length(NV.objmatrix)
                for i=1:length(filetype.String)
                    try
                        filetaglist=eval(['NV.objmatrix(j).',filetype.String{i},'.getTaginfo(''Tagname:Tagvalue'',''fileTag'');']);
                    end
                    output=vertcat(output,filetaglist);
                end
                end
                Filetagpool.String=unique(output);
                set(Subjectlist,'Value',1);
        end
        function ChangeRoot(obj)
            global NV
            Subjectlist=findobj(obj.parent,'Tag','Subjectlist');
            NV.objmatrixtmp=NV.objmatrix(Subjectlist.Value);
            change=inputdlg({'original path','modified path'});
            NV.objmatrixtmp=obj.replace(NV.objmatrixtmp,change);
            if ispc
                NV.objmatrixtmp=obj.replace(NV.objmatrixtmp,{'/','\'});
            else
                NV.objmatrixtmp=obj.replace(NV.objmatrixtmp,{'\','/'});
            end
            NV.objmatrix(Subjectlist.Value)=NV.objmatrixtmp;
            for i=1:length(NV.objmatrix)
                pathlist{i}=NV.objmatrix(i).Datapath;
            end
            set(Subjectlist,'String',pathlist,'Value',1);
        end     
    end
    methods(Static)
        function SaveTagInfo
            global NV
            if ~isempty(NV.objmatrix)
                objmatrix=NV.objmatrix;
                if ~isempty(NV.objmatrixpath)
                     answer=questdlg('overwrite the current Tag information file?');
                    if strcmp(answer,'Yes')
                        yaml.dumpFile(NV.objmatrixpath,objmatrix.struct());
                        %save(NV.objmatrixpath,'objmatrix');
                    elseif strcmp(answer,'No')
                        [f,p]=uiputfile('*.yaml');
                        yaml.dumpFile([p,f],objmatrix.struct());
                        NV.objmatrixpath=[p,f];
                        %uisave('objmatrix');
                    end
                else
                     [f,p]=uiputfile('*.yaml');
                     yaml.dumpFile([p,f],objmatrix.struct());
                     NV.objmatrixpath=[p,f];
                end
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
                                if ~isempty(tagvalue)
                                    output=vertcat(output,{char(strcat(tagtype{j},':',tagvalue{:}))});
                                end
                            end
                        end
                    end
                case 'LFPData' % % sample rate, channel, ADconvert
                    reservevar={'Samplerate','Channelnum','ADconvert','Precision'};
                    for i=1:length(Neurodata)
                        for j=1:length(reservevar)
                            if ~isempty(eval(['Neurodata(i).',reservevar{j}]))
                                tmp=eval(['Neurodata(i).',reservevar{j}]);
                                output=cat(1,output,{char(strcat(reservevar{j},':',tmp))});
                            end
                        end
                    end
                case 'SPKData' % % cluster relative to channel number
                     reservevar={'SortingType','Channelnum','Samplerate'};
                    for i=1:length(Neurodata)
                        for j=1:length(reservevar)
                            if ~isempty(eval(['Neurodata(i).',reservevar{j}]))
                                tmp=eval(['Neurodata(i).',reservevar{j}]);
                                output=cat(1,output,{char(strcat(reservevar{j},':',tmp))});
                            end
                        end
                    end
                case 'EVTData' % % EVTtype
                        reservevar=fieldnames(Neurodata.EVTinfo);
                    for i=1:length(Neurodata)
                        for j=1:length(reservevar)
                            if ~isempty(eval(['Neurodata(i).EVTinfo.',reservevar{j}]))
                                tmp=eval(['Neurodata(i).EVTinfo.',reservevar{j}]);
                                for c=1:length(tmp)
                                    output=cat(1,output,{char(strcat(reservevar{j},':',tmp{c}))});
                                end
                            end
                        end
                    end
%                     for i=1:length(Neurodata)
%                         Eventtype=Neurodata(i).EVTtype;
%                         for j=1:length(Eventtype)
%                             output=vertcat(output,{['EVTtype:',Eventtype{j}]});
%                         end
%                     end
                case 'VideoData' % %  correct time
                    reservevar={'correcttime'};
                    for i=1:length(Neurodata)
                        for j=1:length(reservevar)
                            if ~isempty(eval(['Neurodata(i).',reservevar{j}]))
                                tmp=eval(['Neurodata(i).',reservevar{j}]);
                                output=cat(1,output,{char(strcat(reservevar{j},':',tmp))});
                            end
                        end
                    end
%                     for i=1:length(Neurodata)
%                         correcttime=Neurodata(i).correcttime;
%                         if ~isempty(correcttime)
%                             output=vertcat(output,{['Videobegintime:',num2str(correcttime)]});
%                         end
%                     end
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
                filetype={'LFPdata','SPKdata','CALdata','EVTdata','Videodata','NeuroResult'};
                for j=1:length(filetype)
                    try
                        for c=1:length(eval(['objmatrixtmp(i).',filetype{j}]))
                            eval(['objmatrixtmp(i).',filetype{j},'(c).Filename=strrep(objmatrixtmp(i).',filetype{j},'(c).Filename,change{1},change{2});']);
                            if strcmp(filetype{j},'NeuroResult')
                                NeuroResult.adjustNewPath(eval(['objmatrixtmp(i).',filetype{j},'(c).Filename;']));
                            end
                        end
                    end
                end
            end
        end
    end
    methods(Access='private')
        function LoadSubjectDir(obj)
               global NV
               path=uigetdir();
               Subjectlist=findobj(obj.parent,'Tag','Subjectlist');
               filelist=Subjectlist.String;
               index=[];
                if isfield(NV,'objmatrix') 
                for i=1:length(NV.objmatrix)
                    if strcmp(NV.objmatrix(i).Datapath,path)
                        index=i;
                    end
                end
                else
                    NV.objmatrix=[];
                end
                if ~isempty(index)
                    NV.objmatrix(index)=NV.objmatrix(index).fileappend(path);
                     set(Subjectlist,'Value',index);
                else
                     singleobj=NeuroData();
                     singleobj=singleobj.fileappend(path);
                     try
                        NV.objmatrix=vertcat(NV.objmatrix, singleobj);
                     catch
                        NV.objmatrix=horzcat(NV.objmatrix, singleobj);
                     end
                     set(Subjectlist,'String',vertcat(filelist,{path}));
                     set(Subjectlist,'Value',length(filelist)+1);
                end
                 Datatype=findobj(obj.parent,'Tag','Filetype');
                 Filelist=findobj(obj.parent,'Tag','Filelist');
                 Datatypechangefcn(obj,Datatype,Subjectlist,Filelist)
        end
        function DeleteSubjectDir(obj)
            global NV
                Subjectlist=findobj(obj.parent,'Tag','Subjectlist');
                NV.objmatrix(Subjectlist.Value)=[];
                Subjectlist.String(Subjectlist.Value)=[];         
                if ~isempty(Subjectlist.String)
                    Subjectlist.Value=1;
                end
        end
        function AddSubjectTag(obj,option)
            global NV
            Subjectlist=findobj(gcf,'Tag','Subjectlist');
            singleobj=NV.objmatrix(Subjectlist.Value);
            switch option
                case 'fileTag'
                    DataTaglist=findobj(gcf,'Tag','SubjectTaglist');
                case 'ChannelTag'
                    DataTaglist=findobj(gcf,'Tag','ChannelTaglist');
            end
            [informationtype, information, Tagstring]=Taginfoappend(DataTaglist.String);
            DataTaglist.String=Tagstring;       
            for i=1:length(singleobj)
                singleobj(i)=singleobj(i).Taginfo(option,informationtype,information);
            end
            NV.objmatrix(Subjectlist.Value)=singleobj;
            obj.SubjectValueChangedFcn;
        end
        function DeleteSubjectTag(obj,option)
            global NV
            Subjectlist=findobj(gcf,'Tag','Subjectlist');
            singleobj=NV.objmatrix(Subjectlist.Value);
            switch option
                case 'fileTag'
                    Tagname=singleobj.getTaginfo('Tagname','fileTag');
                case 'ChannelTag'
                    Tagname=singleobj.getTaginfo('Tagname','ChannelTag');
            end
            chooseindex=listdlg('PromptString','delet a tag','SelectionMode','single','ListString', Tagname);
            Tagname=Tagname{chooseindex};
            for i=1:length(singleobj)
                singleobj(i)=singleobj(i).Taginfo(option,Tagname,[]);
            end
            NV.objmatrix(Subjectlist.Value)=singleobj;
            obj.SubjectValueChangedFcn;
        end
        function FileValueChangedFcn(obj)
            global NV
            Fileobj=findobj(obj.parent,'Tag','Filelist');
            Filetag=findobj(obj.parent,'Tag','FileTagShow');
            Filetag.String=NV.Filematrix(Fileobj.Value).getTaginfo('Tagname:Tagvalue','fileTag');
            Fileprop=findobj(obj.parent,'Tag','InitializedShow');
            Fileprop.String=obj.getPropertiesinfo(NV.Filematrix(Fileobj.Value));
        end
        function SubjectValueChangedFcn(obj)
            global NV
            Subjectobj=findobj(obj.parent,'Tag','Subjectlist');
            Datatype=findobj(obj.parent,'Tag','Filetype');
            Filelist=findobj(obj.parent,'Tag','Filelist');
            Subjecttag=findobj(obj.parent,'Tag','SubjectTagShow');
            Subjecttag.String=NV.objmatrix(Subjectobj.Value).getTaginfo('Tagname:Tagvalue','fileTag');
            Subjectchannel=findobj(obj.parent,'Tag','ChannelTagShow');
            Subjectchannel.String=obj.getPropertiesinfo(NV.objmatrix(Subjectobj.Value));
            obj.Datatypechangefcn(Datatype,Subjectobj,Filelist);
        end
        function Datatypechangefcn(obj,Datatype,Subjectlist,Filelist)
            global NV
            NV.Filematrix=[];
            singleobj=NV.objmatrix(Subjectlist.Value);
            subtype=Datatype.String{Datatype.Value};
            filename=[];
            NV.objtmpindex=[];
            for i=1:length(singleobj)
                try
                NV.Filematrix=[NV.Filematrix,eval(['singleobj(i).',subtype])];
                NV.objtmpindex=[NV.objtmpindex,i*ones(1,length(eval(['singleobj(i).',subtype])))];
                catch
                    NV.Filematrix=[NV.Filematrix,[]];
                    NV.objtmpindex=[NV.objtmpindex,[]];
                end  
            end
            for i=1:length(NV.Filematrix)
                filename=[filename,{NV.Filematrix(i).Filename}];
            end
            set(Filelist,'String',filename,'Value',1);
            Filetaglist=findobj(obj.parent,'Tag','FileTagShow'); 
            Fileproplist=findobj(obj.parent,'Tag','InitializedShow');
            if ~isempty(NV.Filematrix)
                Filetaglist.String= NV.Filematrix(Filelist.Value).getTaginfo('Tagname:Tagvalue','fileTag');
                Fileproplist.String=obj.getPropertiesinfo(NV.Filematrix(Filelist.Value));
            else
                Filetaglist.String=[];
                Fileproplist.String=[];
            end
        end
        function AddFileTag(obj)
            global NV
            Filelist=findobj(gcf,'Tag','Filelist');
            singleobj=NV.Filematrix(Filelist.Value);
            DataTaglist=findobj(gcf,'Tag','FileTaglist');
            [informationtype, information, Tagstring]=Taginfoappend(DataTaglist.String);
            DataTaglist.String=Tagstring;
            for i=1:length(singleobj)
                singleobj(i)=singleobj(i).Taginfo('fileTag',informationtype,information);
            end
            NV.Filematrix(Filelist.Value)=singleobj;
            obj.SaveFileToSubject;
            obj.FileValueChangedFcn;
        end
        function DeleteFileTag(obj)
            global NV
            Filelist=findobj(gcf,'Tag','Filelist');
            singleobj=NV.Filematrix(Filelist.Value);
            Tagname=singleobj.getTaginfo('Tagname','fileTag');
            chooseindex=listdlg('PromptString','choose the tags to delete!','SelectionMode','single','ListString', Tagname);
            Tagname=Tagname{chooseindex};
            for i=1:length(singleobj)
                singleobj(i)=singleobj(i).Taginfo('fileTag',Tagname,[]);
            end
            NV.Filematrix(Filelist.Value)=singleobj;
            obj.SaveFileToSubject;
            obj.FileValueChangedFcn;
        end
        function SaveFileToSubject(obj)
            global NV
            Subjectlist=findobj(obj.parent,'Tag','Subjectlist');
            singleobj=NV.objmatrix(Subjectlist.Value);
            Filetype=findobj(obj.parent,'Tag','Filetype');
            subclasstype=Filetype.String{Filetype.Value};
            for i=1:length(singleobj)
                try
                    addprop(singleobj(i),subclasstype);
                end
                eval(['singleobj(i).',subclasstype,'=NV.Filematrix(find(NV.objtmpindex==i));']);
            end
            NV.objmatrix(Subjectlist.Value)=singleobj;
        end
        function TagModify(obj,TagList,option)
            global NV
            if length(TagList.Value)>1
                warndlg('Please choose One Tag:TagValue to modify!');
                return;
            else
                origin=regexpi(TagList.String{TagList.Value},':','split');
                modified=inputdlg('Please input the modified Tag:TagValue');
                modified2=regexpi(modified{:},':','split');
                switch option
                    case 'Subject'
                        for i=1:length(NV.objmatrix)
                            bool = Tagchoose(NV.objmatrix(i),'fileTag', origin{1}, origin{2});
                            if bool==1
                                NV.objmatrix(i).Taginfo('fileTag',origin{1},[]);
                                NV.objmatrix(i).Taginfo('fileTag',modified2{1},modified2{2});
                            end
                        end
                    case 'File'
                        for i=1:length(NV.Filematrix)
                            bool = Tagchoose(NV.Filematrix(i),'fileTag',origin{1}, origin{2});
                            if bool==1
                                NV.Filematrix(i).Taginfo('fileTag',origin{1},[]);
                                NV.Filematrix(i).Taginfo('fileTag',modified2{1},modified2{2});
                            end
                        end
                        obj.SaveFileToSubject;
                end
                TagList.String(TagList.Value)=modified;
            end
        end              
        function TagSelect(obj,TagList,option)
            global NV
            origin=cellfun(@(x) regexpi(x,':','split'), TagList.String(TagList.Value),'UniformOutput',0);
            switch option
                case 'Subject'
                    value=[];
                    Subjectlist=findobj(obj.parent,'Tag','Subjectlist');
                    for i=1:length(NV.objmatrix)
                        for j=1:size(origin,1)
                            bool=Tagchoose(NV.objmatrix(i),'fileTag',origin{j}{1},origin{j}{2});
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
                    for i=1:length(NV.Filematrix)
                        for j=1:size(origin{:},1)
                            bool(i)=Tagchoose(NV.Filematrix(i),'fileTag',origin{j}{1},origin{j}{2});
                            if bool(i)==1
                                value=vertcat(value,i);
                                break;
                            end
                        end
                    end
                    Filelist.Value=value;
            end
        end
        function RemoveFile(obj,Filelist)
            global NV
            index=Filelist.Value;
            NV.Filematrix(index)=[];
            NV.objtmpindex(index)=[];
            obj.SaveFileToSubject;
            obj.SubjectValueChangedFcn;
        end
        function AddFile(obj,Datatype,Subjectlist)
            global NV
            if length(unique(Subjectlist.Value))>1
                error('only Support Loading files from the single directory');
            else
                cd(Subjectlist.String{Subjectlist.Value});
                datatype=Datatype.String{Datatype.Value};
                if ~strcmp(Datatype.String{Datatype.Value},'Neuroresult')
                    tmpobj=eval([datatype(1:end-4),'Data();']);
                else
                    tmpobj=NeuroResult();
                end
                tmpmatrix=tmpobj.fileappend;
                NV.Filematrix=cat(2,NV.Filematrix,tmpmatrix);
                NV.objtmpindex=ones(length(NV.Filematrix),1);
                obj.SaveFileToSubject;
                obj.SubjectValueChangedFcn;
            end
        end  
        function initialized(obj)
            global NV
            Filelist=findobj(obj.parent,'Tag','Filelist');
            singleobj=NV.Filematrix(Filelist.Value);
            Filetype=findobj(obj.parent,'Tag','Filetype');
            subclasstype=Filetype.String{Filetype.Value};
            switch subclasstype
                case 'LFPdata'
                    output=inputdlg({'Total Channel Number','SampleRate','ADconvert','Precision'},'LFP Details',1,{'','','','int16'});
                    Channelnum=output{1};
                    Samplerate=output{2};
                    ADconvert=output{3};
                    Precision=output{4};
                    for i=1:length(singleobj)
                        singleobj(i)=singleobj(i).initialize(Channelnum, Samplerate,ADconvert,Precision);
                    end
            case {'SPKdata','CALdata'}
                    output=inputdlg({'SampleRate','Channelnum'});
                    Samplerate=output{1};
                    Channelnum=output{2};
                    multiWaitbar('initialized',0)
                    for i=1:length(singleobj)
                        singleobj(i)=singleobj(i).initialize(Channelnum,Samplerate);
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
                        correcttime=inputdlg('please input the correcttime value!');
                        for i=1:length(singleobj)
                            singleobj(i).initialize(correcttime{:});
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
                                 singleobj(i).initialize(num2str(events.time(i)));
                            end
                        end
                end
                end
           NV.Filematrix(Filelist.Value)=singleobj;
           obj.SaveFileToSubject;
           obj.FileValueChangedFcn;
        end   
    end
end