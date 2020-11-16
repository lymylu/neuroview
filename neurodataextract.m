classdef neurodataextract    
    properties
        parent
        mainWindow
    end
    methods
        function obj = CreateGUI(obj,parent)
           global objmatrixpath objmatrix
           if isempty(objmatrixpath)
               [f,p]=uigetfile;
               objmatrixpath=[p,f];
           end
           matrixinfo=matfile(objmatrixpath);
           objmatrix=matrixinfo.objmatrix;
           obj.parent=parent;
           obj.mainWindow=uix.Panel('Parent',obj.parent,'Title','DataExtract');
           maingrid=uix.VBox('Parent',obj.mainWindow)
           Subjectgrid=uix.HBox('Parent',maingrid);
           Tagchoosepanel=uix.VBox('Parent', Subjectgrid);
           SubjectTag=uicontrol(Tagchoosepanel,'Style','popupmenu');
           SubjectTagValue=uicontrol(Tagchoosepanel,'Style','popupmenu');
           Commandpanel=uix.VBox('Parent', Subjectgrid);
           SubjectTaginfo=uicontrol(Subjectgrid,'Style','Text');
           Subjectlist=uicontrol(Subjectgrid,'Style','listbox');    
           uicontrol(Commandpanel,'Style','pushbutton','String','Add the subject Tag/TagValue','Callback',@(~,~) obj.Addinfo(SubjectTag,SubjectTagValue,SubjectTaginfo,[]));
           uicontrol(Commandpanel,'Style','pushbutton','String','Delete the subject Tag/TagValue','Callback',@(~,~) obj.Deleteinfo(SubjectTaginfo));
           obj.Loadobjmatrix;
           obj.setTaginfo(objmatrix,SubjectTag,SubjectTagValue);  
           Filegrid=uix.HBox('Parent',maingrid);
           Tagchoosepanel=uix.VBox('Parent',Filegrid);
           Datatype=uicontrol(Tagchoosepanel,'Style','popupmenu','String',{'LFPdata','SPKdata','EVTdata',});
           FileTag=uicontrol(Tagchoosepanel,'Style','popupmenu');
           FileTagValue=uicontrol(Tagchoosepanel,'Style','popupmenu');
           addlistener(Datatype,'Value','PostSet', @(~,~) obj.Datatypechangefcn(Datatype,FileTag,FileTagValue))
           Commandpanel=uix.VBox('Parent',Filegrid);
           FileTaginfo=uicontrol(Filegrid,'Style','Text');
           Filelist=uicontrol(Filegrid,'Style','listbox');
           addlistener(FileTaginfo,'String','PostSet',@(~,~) obj.SelectFile(FileTaginfo,Filelist));
           uicontrol(Commandpanel,'Style','pushbutton','String','Add the File Tag/TagValue','Callback',@(~,~) obj.Addinfo(FileTag,FileTagValue,FileTaginfo,Datatype));
           uicontrol(Commandpanel,'Style','pushbutton','String','Delete the File Tag/TagValue','Callback',@(~,~) obj.Deleteinfo(FileTaginfo));
           uicontrol(Commandpanel,'Style','pushbutton','String','Select the Analaysis Method','Callback',@(~,~) obj.GenerateSelectmatrix(SubjectTaginfo,FileTaginfo));   
           addlistener(SubjectTaginfo,'String','PostSet',@(~,~) obj.SelectSubject(SubjectTaginfo,Subjectlist,Datatype,FileTag,FileTagValue));
        end
        function obj=LFPfilter(obj)
        end
        function obj=EventModify(obj)
        end
        function obj=DataOutput(obj)
        end
        function obj=ChectTagInfo(obj)
        end
    end
    methods(Static)
        function index=getSubject(Neurodata,Taginfo)
            index=[];
            for i=1:length(Neurodata)
                for j=1:length(Taginfo)
                    if length(Taginfo{j})<3
                        bool=Neurodata(i).Tagchoose('fileTag',Taginfo{j}{1},Taginfo{j}{2});
                    else
                         bool=Neurodata(i).Tagchoose('fileTag',Taginfo{j}{2},Taginfo{j}{3});
                    end
                    if bool==1
                        index=vertcat(index,i);
                        break;
                    end
                end
            end
        end
        function choosematrix=DataSelect(objmatrixpath,Subjectinfo,Fileinfo)
                originmatrix=matfile(objmatrixpath);
                originmatrix=originmatrix.objmatrix;
                Subjectinfo=regexpi(Subjectinfo,':','split');
                index=neurodataextract.getSubject(originmatrix,Subjectinfo);
                Filetype={'LFPdata','EVTdata','SPKdata','Videodata'};
                choosematrix=originmatrix(index);
                for i=1:length(choosematrix)
                    for j=1:length(Filetype)
                        index=contains(Fileinfo,Filetype{j});
                        tmpmatrix=eval(['choosematrix(i).',Filetype{j}]);
                        if sum(index)~=0
                            Fileinfotmp=regexpi(Fileinfo(index),':','split');
                            for k=1:length(tmpmatrix)
                                fileindx=neurodataextract.getSubject(tmpmatrix,Fileinfotmp);
                            end
                            eval(['choosematrix(i).',Filetype{j},'=tmpmatrix(fileindx);']);
                        else
                            eval(['choosematrix(i).',Filetype{j},'=[];']);
                        end                           
                    end
                end
        end             
    end
    methods(Access='private')
        function obj=Datatypechangefcn(obj,Datatype,FileTag,FileTagValue)   
            global Filematrix objindex objmatrix
                Filematrix=[];
                singleobj=objmatrix(objindex);
                subtype=Datatype.String{Datatype.Value};
                filename=[];
                for i=1:length(singleobj)
                   for j=1:length(eval(['singleobj(i).',subtype]))
                    Filematrix=[Filematrix,eval(['singleobj(i).',subtype,'(j)'])];
                   end
                end
                obj.setTaginfo(Filematrix,FileTag,FileTagValue);
        end
        function obj=SelectSubject(obj,SubjectTaginfo,Subjectlist,Datatype,FileTag,FileTagValue)
            global objindex objmatrix
            Taginfo=regexpi(SubjectTaginfo.String,':','split');
            objindex=obj.getSubject(objmatrix,Taginfo);
            tmpobjmatrix=objmatrix(objindex);
            listString=[];
            for i=1:length(tmpobjmatrix)
                 listString{i}=tmpobjmatrix(i).Datapath;
            end
            Subjectlist.String=listString;
            obj.Datatypechangefcn(Datatype,FileTag,FileTagValue)
        end
        function obj=SelectFile(obj,FileTaginfo,Filelist)
            global objmatrix objindex
                Taginfo=cellfun(@(x) regexpi(x,':','split'),FileTaginfo.String,'UniformOutput',0);
                Filetype=unique(cellfun(@(x) x{1},Taginfo,'UniformOutput',0));
                filematrix=objmatrix(objindex);
                Filelist.String=[];
                for i=1:length(filematrix)
                    for j=1:length(Filetype)
                        tmpmatrix=eval(['filematrix(i).',Filetype{j}]);
                        tmpindex=obj.getSubject(tmpmatrix,Taginfo);
                        for k=1:length(tmpindex)
                            try
                            Filelist.String=cat(1,Filelist.String,{tmpmatrix(tmpindex(k)).Filename});
                            catch
                                a=1;
                            end
                        end
                    end
                end
        end 
        function obj=Addinfo(obj,SubjectTag,SubjectTagValue,SubjectTaginfo,Datatype)
            if isempty(Datatype)
            SubjectTaginfo.String=unique(vertcat(SubjectTaginfo.String,{[SubjectTag.String{SubjectTag.Value},':',SubjectTagValue.String{SubjectTagValue.Value}]}));
            else 
            SubjectTaginfo.String=unique(vertcat(SubjectTaginfo.String,{[Datatype.String{Datatype.Value},':',SubjectTag.String{SubjectTag.Value},':',SubjectTagValue.String{SubjectTagValue.Value}]}));
            end
        end
        function obj=Deleteinfo(obj,SubjectTaginfo)
            index=listdlg('PromptString','Please Choose the Tag/TagValue(s) to Delete!','ListString',SubjectTaginfo.String,'Selectionmode','Multiple');
            SubjectTaginfo.String(index)=[];
        end
        function obj=Loadobjmatrix(obj)
            global objmatrix
            if isempty(objmatrix)
                 [f,p]=uigetfile();
                Taginfo=matfile([p,f]);
                objmatrix=Taginfo.objmatrix;
            end
        end
        function obj=setTaginfo(obj,neurodata,Tagmenu,Tagvaluemenu)
            TagInfo=neurodatatag.getTaginfo(neurodata,'Tagtype:Tagvalue');
            TagInfo=cellfun(@(x) regexpi(x,':','split'),TagInfo,'UniformOutput',0);
            for i=1:length(TagInfo)
                Tagname{i}=TagInfo{i}{1};
                Tagvalue{i}=TagInfo{i}{2};
            end
            Tagmenu.String=unique(Tagname);
            Tagmenu.Value=1;
            addlistener(Tagmenu,'Value','PostSet',@(~,~) obj.getTagValue(Tagmenu,Tagvaluemenu,Tagname,Tagvalue));
            obj.getTagValue(Tagmenu,Tagvaluemenu,Tagname,Tagvalue);
        end
        function obj=getTagValue(obj,Tagmenu,TagValuemenu,Tagname,Tagvalue)
            index=ismember(Tagname,Tagmenu.String(Tagmenu.Value));
            TagValuemenu.String=Tagvalue(index);
        end
        function obj=GenerateSelectmatrix(obj,SubjectTaginfo,FileTaginfo)
            global objmatrixpath choosematrix
            Subjectinfo=SubjectTaginfo.String;
            Fileinfo=FileTaginfo.String;
            choosematrix=obj.DataSelect(objmatrixpath,Subjectinfo,Fileinfo);
        end
    end
end

