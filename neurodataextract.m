classdef neurodataextract    
    properties
        parent
        mainWindow
    end
    methods
        function obj=CreateGUI(obj,parent)
           global objmatrixpath objmatrix
           if isempty(objmatrixpath)
               [f,p]=uigetfile;
               objmatrixpath=[p,f];
           end
           matrixinfo=matfile(objmatrixpath);
           objmatrix=matrixinfo.objmatrix;
           obj.parent=parent;
           obj.mainWindow=uix.Panel('Parent',obj.parent,'Title','DataExtract');
           maingrid=uix.VBox('Parent',obj.mainWindow);
           Subjectgrid=uix.HBox('Parent',maingrid);
           Tagchoosepanel=uix.VBox('Parent', Subjectgrid);
           SubjectTag=uicontrol(Tagchoosepanel,'Style','popupmenu','Tag','FileTag');
           SubjectTagValue=uicontrol(Tagchoosepanel,'Style','popupmenu','Tag','FileTagValue');
           Commandpanel=uix.VBox('Parent', Subjectgrid);
           SubjectTaginfopanel=uix.VBox('Parent',Subjectgrid);
           SubjectTaginfo=uicontrol(SubjectTaginfopanel,'Style','Text');
           Subjectunion=uicontrol(SubjectTaginfopanel,'Style','checkbox','Tag','union','String','select the union')
           Subjectlist=uicontrol(Subjectgrid,'Style','listbox');    
           uicontrol(Commandpanel,'Style','pushbutton','String','Add the subject Tag/TagValue','Callback',@(~,~) obj.Addinfo(Tagchoosepanel,SubjectTaginfo,[]));
           uicontrol(Commandpanel,'Style','pushbutton','String','Delete the subject Tag/TagValue','Callback',@(~,~) obj.Deleteinfo(SubjectTaginfo));
           obj.Loadobjmatrix;
           obj.setTaginfo(objmatrix,SubjectTag,SubjectTagValue);  
           Filegrid=uix.HBox('Parent',maingrid);
           Tagchoosepanel=uix.VBox('Parent',Filegrid);
           Datatype=uicontrol(Tagchoosepanel,'Style','popupmenu','String',{'LFPdata','SPKdata','CALdata','EVTdata','Videodata','Neuroresult'});
           FileTag=uicontrol(Tagchoosepanel,'Style','popupmenu','Tag','FileTag');
           FileTagValue=uicontrol(Tagchoosepanel,'Style','popupmenu','Tag','FileTagValue');
           addlistener(Datatype,'Value','PostSet', @(~,~) obj.Datatypechangefcn(Datatype,Tagchoosepanel));
           Commandpanel=uix.VBox('Parent',Filegrid);
           FileTaginfopanel=uix.VBox('Parent',Filegrid);
           FileTaginfo=uicontrol(FileTaginfopanel,'Style','Text');
           Fileunion=uicontrol(FileTaginfopanel,'Style','checkbox','Tag','union','String','select the union');
           Filelist=uicontrol(Filegrid,'Style','listbox');
           addlistener(FileTaginfo,'String','PostSet',@(~,~) obj.SelectFile(SubjectTaginfo,Subjectunion,FileTaginfo,Filelist,Fileunion));
           uicontrol(Commandpanel,'Style','pushbutton','String','Add the File Tag/TagValue','Callback',@(~,~) obj.Addinfo(Tagchoosepanel,FileTaginfo,Datatype));
           uicontrol(Commandpanel,'Style','pushbutton','String','Delete the File Tag/TagValue','Callback',@(~,~) obj.Deleteinfo(FileTaginfo));
           %uicontrol(Commandpanel,'Style','pushbutton','String','Select the NeuroData','Callback',@(~,~) obj.GenerateSelectmatrix(SubjectTaginfo,FileTaginfo,Subjectunion,Fileunion));   
           addlistener(SubjectTaginfo,'String','PostSet',@(~,~) obj.SelectSubject(SubjectTaginfo,Subjectlist,Datatype,Tagchoosepanel,Subjectunion));
           obj.Datatypechangefcn(Datatype,Tagchoosepanel);
        end
        function obj=LFPFilter(obj)
            % filt the LFPdata using eegfilt
            global objmatrixpath objindex choosematrix
            obj.CheckValid('LFPdata');
            originmatrix=matfile(objmatrixpath,'Writable',true);
            neuromatrix=originmatrix.objmatrix;
%             NeuroMethod.Checkpath('eeglab');
            prompt={'filtfilename','lowcutfreq ','highcutfreq','filtorder','notchfilter'};
            title='input Params';
            lines=2;
            def={'_filt.lfp','0','100','0','0'};
            x=inputdlg(prompt,title,lines,def,'on');
            [informationtype,information]=Taginfoappend([]);
            multiWaitbar('Processing',0);
            for i=1:length(choosematrix)
                for j=1:length(choosematrix(i).LFPdata)
                    Data=NeuroResult();
                    Data=Data.ReadLFP(choosematrix(i).LFPdata(j),[],[],[]);
                    for k=1:length(Data.LFPdata)
                        FiltData=[];     
                            if str2num(x{5})==1
                                FiltData{k}=notchfilter(Data.LFPdata{k}',str2num(choosematrix(i).LFPdata(j).Samplerate),[str2num(x{2}),str2num(x{3})]);
                            else
                                 FiltData{k}=eegfilt(Data.LFPdata{k}',str2num(choosematrix(i).LFPdata(j).Samplerate),str2num(x{2}),str2num(x{3}),0,str2num(x{4}),str2num(x{5}));
                            end
                    Filtfilename=strrep(choosematrix(i).LFPdata(j).Filename,'.lfp',x{1});
                    NewLFP=LFPData.Clone(choosematrix(i).LFPdata(j));
                    NewLFP.Filename=Filtfilename;
                    NewLFP.Taginfo('fileTag',informationtype,information);
                    neuromatrix(objindex(i)).LFPdata=horzcat(neuromatrix(objindex(i)).LFPdata,NewLFP);
                    fid=fopen(Filtfilename,'w');
                    FiltData=cell2mat(FiltData')';
                    fwrite(fid,FiltData','int16');
                    fclose(fid);
                    clear FiltData;
                    end
                end
                multiWaitbar('Processing',i/length(choosematrix));
            end
            originmatrix.objmatrix=neuromatrix;
            multiWaitbar('Processing','close');
        end
        function obj=EventModify(obj)
            global choosematrix
            eventmodify=EventModified();
            option=[];
            try
                obj.CheckValid('EVTdata');
                option='Event';
            catch
                option='noEvent';
            end
            try 
                obj.CheckValid('Videodata');
                option=[option,'_Video'];
            end
            eventmodify.cal(choosematrix,obj.mainWindow,option);
        end
        function obj=DataOutput(obj)
        global choosematrix
            if ~isempty(choosematrix)
                NeuroMethod.getParams(choosematrix);
                savepath=uigetdir('Save Path of the extract data');
                format='matfile'; % could support hdf5 in the future;
                for i=1:length(choosematrix)
                    [totalpath,filename]=fileparts(choosematrix(i).Datapath);
%                     [~,filename]=fileparts(totalpath);
                    try
                    NeuroResult=choosematrix(i).LoadData;
                    NeuroResult.SaveData(savepath,filename,format,[]);
                    catch ME
                        disp(ME);
                    end
                    multiWaitbar('loading data',i/length(choosematrix));
                end
            end
        end
        function obj=FiringProperties(obj)
            global choosematrix
               obj.CheckValid('SPKdata');
               NeuroMethod.Checkpath('Cellexplorer');
               for i=1:length(choosematrix)
                   FiringProperties.cal(choosematrix(i)); 
                   multiWaitbar('Processing...', i/length(choosematrix));
               end
               multiWaitbar('Processsing...','close');
        end         
    end
    methods(Access='private')
        function obj=Datatypechangefcn(obj,Datatype,Tagchoosepanel)   
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
                FileTag=findobj(Tagchoosepanel,'Tag','FileTag');
                FileTagValue=findobj(Tagchoosepanel,'Tag','FileTagValue');
                delete(FileTag);
                delete(FileTagValue);
                FileTag=uicontrol(Tagchoosepanel,'Style','popupmenu','Tag','FileTag');
                FileTagValue=uicontrol(Tagchoosepanel,'Style','popupmenu','Tag','FileTagValue','Value',1);
                try
                    obj.setTaginfo(Filematrix,FileTag,FileTagValue);
                end
        end
        function obj=SelectSubject(obj,SubjectTaginfo,Subjectlist,Datatype,Tagchoosepanel,Subjectunion)
            global objindex objmatrix choosematrix
            Taginfo=regexpi(SubjectTaginfo.String,':','split');
            intersect=Subjectunion.Value;
            objindex=obj.getSubject(objmatrix,Taginfo,intersect);
            objindex=find(objindex==1);
            tmpobjmatrix=objmatrix(objindex);
            listString=[];
            for i=1:length(tmpobjmatrix)
                 listString{i}=tmpobjmatrix(i).Datapath;
            end
            Subjectlist.String=listString;
            obj.Datatypechangefcn(Datatype,Tagchoosepanel);
            Subjectlist.Value=1;
            choosematrix=[];
        end
        function obj=SelectFile(obj,SubjectTaginfo,Subjectunion,FileTaginfo,Filelist,Fileunion)
            global objmatrix objindex choosematrix
                Taginfo=cellfun(@(x) regexpi(x,':','split'),FileTaginfo.String,'UniformOutput',0);
                Filetype=unique(cellfun(@(x) x{1},Taginfo,'UniformOutput',0));
                filematrix=objmatrix(objindex);
                Filelist.String=[];
                intersect=Fileunion.Value;
                for i=1:length(filematrix)
                    for j=1:length(Filetype)
                        tmpmatrix=eval(['filematrix(i).',Filetype{j}]);
                        tmpTaginfo=cellfun(@(x) strcmp(x{1},Filetype{j}),Taginfo,'UniformOutput',1);
                        tmpindex=obj.getSubject(tmpmatrix,Taginfo(tmpTaginfo),intersect);
                        for k=1:length(tmpindex)
                            if tmpindex(k)
                            Filelist.String=cat(1,Filelist.String,{tmpmatrix(k).Filename});
                            end
                        end
                    end
                end
                Filelist.Value=1;
                choosematrix=[];
                obj.GenerateSelectmatrix(SubjectTaginfo,FileTaginfo,Subjectunion,Fileunion);
        end 
        function obj=Addinfo(obj,Tagchoosepanel,SubjectTaginfo,Datatype)
            SubjectTag=findobj(Tagchoosepanel,'Tag','FileTag');
            SubjectTagValue=findobj(Tagchoosepanel,'Tag','FileTagValue');
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
            TagValuemenu.Value=1;
        end
    end
    methods(Static)
        function GenerateSelectmatrix(SubjectTaginfo,FileTaginfo,Subjectunion,Fileunion)
            global choosematrix objmatrixpath
            Subjectinfo.Value=SubjectTaginfo.String;
            Fileinfo.Value=FileTaginfo.String;
            Subjectinfo.intersect=Subjectunion.Value;
            Fileinfo.intersect=Fileunion.Value;
            choosematrix=neurodataextract.DataSelect(objmatrixpath,Subjectinfo,Fileinfo);
        end
        function index=getSubject(Neurodata,Taginfo,intersect)
            for j=1:length(Taginfo)
                if length(Taginfo{j})<3
                    bool(:,j)=Neurodata.Tagchoose('fileTag',Taginfo{j}{1},Taginfo{j}{2});
                else
                    bool(:,j)=Neurodata.Tagchoose('fileTag',Taginfo{j}{2},Taginfo{j}{3});
                end
            end
            if intersect==1
                index=logical(mean(bool,2));
            else
                index=logical(prod(bool,2));
            end
        end
        function choosematrix=DataSelect(objmatrixpath,Subjectinfo,Fileinfo)
                originmatrix=matfile(objmatrixpath);
                originmatrix=originmatrix.objmatrix;
                Subjectinfo.Value=regexpi(Subjectinfo.Value,':','split');
                index=neurodataextract.getSubject(originmatrix,Subjectinfo.Value,Subjectinfo.intersect);
                Filetype={'LFPdata','EVTdata','SPKdata','Videodata','Neuroresult'};
                choosematrix=originmatrix(index);
                c=1;invalid=[];
                for i=1:length(choosematrix)
                    for j=1:length(Filetype)
                        index=contains(Fileinfo.Value,Filetype{j});
                        tmpmatrix=eval(['choosematrix(i).',Filetype{j}]);
                        if sum(index)~=0
                            Fileinfotmp=regexpi(Fileinfo.Value(index),':','split');
                            fileindx=neurodataextract.getSubject(tmpmatrix,Fileinfotmp,Fileinfo.intersect);
                            eval(['choosematrix(i).',Filetype{j},'=tmpmatrix(fileindx);']);
                            if isempty(tmpmatrix(fileindx)) % 
                                invalid(c)=i;c=c+1;
                                disp(['ignore the file :',choosematrix(i).Datapath,', due to the lack of ',Filetype{j}]);
                                % ignore the choosematrix with lack of Filetype
                            end
                        else
                            eval(['choosematrix(i).',Filetype{j},'=[];']);
                           
                        end                           
                    end
                end
                choosematrix(invalid)=[];
        end      
        function Eventselect(parent,choosematrix)
            if isempty(parent)
                parent=figure('menubar','none','numbertitle','off','name','Choose the eventtype','DeleteFcn',@(~,~) neurodataextract.eventchoosefcn);
            end
            MainWindow=uix.HBox('Parent',parent);   
            controlpanel=uix.VBox('Parent',MainWindow);
            infopanel=uix.CardPanel('Parent',MainWindow,'Tag','Eventinfo');
            uicontrol(controlpanel,'Style','pushbutton','String','Time points','Callback',@(~,~) neurodataextract.eventselectpanel(infopanel,1));
            uicontrol(controlpanel,'Style','pushbutton','String','Time duration','Callback',@(~,~) neurodataextract.eventselectpanel(infopanel,2));
           % uicontrol(controlpanel,'Style','pushbutton','String','Choose the Eventinfo','Tag','Chooseinfo','Callback',@(~,~) neurodataextract.eventchoosefcn);
            Timepointspanel=uix.HBox('Parent',infopanel,'Tag','Timepoints');
            Timeduration=uix.Grid('Parent',infopanel,'Tag','Timeduration');
            Eventtype=[];
            for i=1:length(choosematrix)
                Eventtype=cat(1,Eventtype,choosematrix(i).EVTdata.EVTtype);
            end
            Eventtype=unique(Eventtype);
            % Timepointspanel
            uicontrol(Timepointspanel,'Style','listbox','String',Eventtype,'min',0,'max',3,'Tag','eventtype');
            tmpgrid=uix.Grid('Parent',Timepointspanel);
            uicontrol(tmpgrid,'Style','text','String','begin time');
            uicontrol(tmpgrid,'Style','text','String','end time');
            uicontrol(tmpgrid,'Style','edit','String','-2','Tag','Begintime');
            uicontrol(tmpgrid,'Style','edit','String','2','Tag','Endtime');
            % Timedurationpanel
            set(tmpgrid,'Heights',[-1,-1],'Width',[-1,-2]);
            uicontrol(Timeduration,'Style','text','String','begin time');
            uicontrol(Timeduration,'Style','listbox','String',Eventtype,'Tag','Begintime');
            uicontrol(Timeduration,'Style','text','String','end time');
            uicontrol(Timeduration,'Style','listbox','String',Eventtype,'Tag','Endtime');
            set(Timeduration,'Heights',[-1,-3],'Width',[-1,-1]);
            set(MainWindow,'Width',[-1,-2]);
        end
        function eventselectpanel(infopanel,num)
            infopanel.Selection=num;
        end
        function eventchoosefcn
            % collect eventinfo
            global eventinfo
                tmpobj=findobj(gcf,'Tag','Eventinfo');
                try
                if tmpobj.Selection==1
                    panelobj=findobj(tmpobj,'Tag','Timepoints');
                    Eventtype=findobj(panelobj,'Tag','eventtype');
                    Eventtypelist=Eventtype.String(Eventtype.Value);
                    eventinfo.selecttype=Eventtypelist;
                    begintime=findobj(panelobj,'Tag','Begintime');
                    endtime=findobj(panelobj,'Tag','Endtime');
                    eventinfo.timestart=str2num(begintime.String);
                    eventinfo.timestop=str2num(endtime.String);
                    eventinfo.timetype='timepoint';
                else
                    panelobj=findobj(tmpobj,'Tag','Timeduration');
                    eventinfo.timetype='timeduration';
                    begintime=findobj(panelobj,'Tag','Begintime');
                    endtime=findobj(panelobj,'Tag','Endtime');
                    eventinfo.timestart=begintime.String(begintime.Value);
                    eventinfo.timestop=endtime.String(endtime.Value);
                end
                end
                uiresume;
        end      
        function CheckValid(option)
            global choosematrix
            for i=1:length(choosematrix)
                if isempty(eval(['choosematrix(i).',option]))
                    error(['No',option,'contains in the choosed data in',choosematrix(i).Datapath]);
                end
            end
        end
    end
end

