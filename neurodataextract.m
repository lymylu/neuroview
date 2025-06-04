classdef neurodataextract    
    properties
        parent
        mainWindow
    end
    methods
        function obj=CreateGUI(obj,parent)
           global NV
           if isempty(NV.objmatrix)
               [f,p]=uigetfile;
               if f~=0
               NV.objmatrixpath=[p,f];
               matrixinfo=yaml.loadFile(NV.objmartrixpath,"ConvertToArray",true);
               NV.objmatrix=NeuroData(matrixinfo);  
               end
           end
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
           Subjectunion=uicontrol(SubjectTaginfopanel,'Style','checkbox','Tag','union','String','select the union');
           Subjectlist=uicontrol(Subjectgrid,'Style','listbox');    
           uicontrol(Commandpanel,'Style','pushbutton','String','Add the subject Tag/TagValue','Callback',@(~,~) obj.Addinfo(Tagchoosepanel,SubjectTaginfo,[]));
           uicontrol(Commandpanel,'Style','pushbutton','String','Delete the subject Tag/TagValue','Callback',@(~,~) obj.Deleteinfo(SubjectTaginfo));
           obj.Loadobjmatrix;
           obj.setTaginfo(NV.objmatrix,SubjectTag,SubjectTagValue);  
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
           addlistener(SubjectTaginfo,'String','PostSet',@(~,~) obj.SelectSubject(SubjectTaginfo,Subjectlist,Datatype,Tagchoosepanel,Subjectunion));
           %obj.Datatypechangefcn(Datatype,Tagchoosepanel);
        end
        function obj=Overview(obj)
            global NV 
            NV.choosematrix.gui_plot(obj.mainWindow);
        end
        function obj=Reref(obj)
            % generate re-reference data
            global NV
            obj.CheckValid('LFPdata');
            originmatrix=matfile(NV.objmatrixpath,'Writable',true);
            neuromatrix=originmatrix.objmatrix;
            prompt={'rereffilename','rerefchannel, use , to choose multiple channels, empty is average'};
            title='input Params';
            lines=2;
            def={'_reref.lfp',''};
            x=inputdlg(prompt,title,lines,def,'on');
            [informationtype,information]=Taginfoappend([]);
            multiWaitbar('Processing',0);
            for i=1:length(NV.choosematrix)
                for j=1:length(NV.choosematrix(i).LFPdata)
                    try
                    Data=NeuroResult();
                    Data=Data.ReadLFP(NV.choosematrix(i).LFPdata(j),[],[],[]);
                    for k=1:length(Data.LFPdata)
                        ReRefData=[];
                        channel=str2num(x{2});
                        if isempty(channel)
                        ReRefData{k}=Data.LFPdata{k}-mean(Data.LFPdata{k},2);
                        else
                            ReRefData{k}=Data.LFPdata{k}-mean(Data.LFPdata{k}(:,channel),2);
                        end
                    Filtfilename=strrep(NV.choosematrix(i).LFPdata(j).Filename,'.lfp',x{1});
                    NewLFP=LFPData.Clone(NV.choosematrix(i).LFPdata(j));
                    NewLFP.Filename=Filtfilename;
                    NewLFP.Taginfo('fileTag',informationtype,information);
                    neuromatrix(NV.objindex(i)).LFPdata=horzcat(neuromatrix(NV.objindex(i)).LFPdata,NewLFP);
                    fid=fopen(Filtfilename,'w');
                    ReRefData=cell2mat(ReRefData');
                    fwrite(fid,ReRefData','int16');
                    fclose(fid);
                    clear FiltData;
                    end
                    catch ME
                        disp(['Error in',NV.choosematrix(i).Datapath,'.']);
                        error('a');
                    end
                end
                multiWaitbar('Processing',i/length(NV.choosematrix));
            end
            originmatrix.objmatrix=neuromatrix;
            multiWaitbar('Processing','close');       
        end
        function obj=LFPFilter(obj)
            % filt the LFPdata using eegfilt
            global NV
            obj.CheckValid('LFPdata');
            originmatrix=matfile(NV.objmatrixpath,'Writable',true);
            neuromatrix=originmatrix.objmatrix;
%             NeuroMethod.Checkpath('eeglab');
            prompt={'filtfilename','lowcutfreq ','highcutfreq','filtorder','notchfilter'};
            title='input Params';
            lines=2;
            def={'_filt.lfp','0','100','0','0'};
            x=inputdlg(prompt,title,lines,def,'on');
            [informationtype,information]=Taginfoappend([]);
            multiWaitbar('Processing',0);
            for i=1:length(NV.choosematrix)
                for j=1:length(NV.choosematrix(i).LFPdata)
                    try
                    Data=NeuroResult();
                    Data=Data.ReadLFP(NV.choosematrix(i).LFPdata(j),[],[],[]);
                    for k=1:length(Data.LFPdata)
                        FiltData=[];     
                            if str2num(x{5})==1
                                FiltData{k}=notchfilter(Data.LFPdata{k}',str2num(NV.choosematrix(i).LFPdata(j).Samplerate),[str2num(x{2}),str2num(x{3})]);
                            else
                                 FiltData{k}=eegfilt(Data.LFPdata{k}',str2num(NV.choosematrix(i).LFPdata(j).Samplerate),str2num(x{2}),str2num(x{3}),0,str2num(x{4}),str2num(x{5}));
                            end
                    Filtfilename=strrep(NV.choosematrix(i).LFPdata(j).Filename,'.lfp',x{1});
                    NewLFP=LFPData.Clone(NV.choosematrix(i).LFPdata(j));
                    NewLFP.Filename=Filtfilename;
                    NewLFP.Taginfo('fileTag',informationtype,information);
                    neuromatrix(NV.objindex(i)).LFPdata=horzcat(neuromatrix(NV.objindex(i)).LFPdata,NewLFP);
                    fid=fopen(Filtfilename,'w');
                    FiltData=cell2mat(FiltData')';
                    fwrite(fid,FiltData','int16');
                    fclose(fid);
                    clear FiltData;
                    end
                    catch ME
                        disp(['Error in',NV.choosematrix(i).Datapath,'.']);
                        error('a');
                    end
                end
                multiWaitbar('Processing',i/length(NV.choosematrix));
            end
            originmatrix.objmatrix=neuromatrix;
            multiWaitbar('Processing','close');
        end
        function obj=EventModify(obj)
                subguiplot=findobj(obj.mainWindow,'Tag','SingleSubjectPlot');
                eventmodifiedpanel=EventModified();
                eventtablepanel=findobj(subguiplot,'Tag','EventTablePanel');
                if isempty(eventtablepanel)
                    eventtablepanel=uix.TabPanel;
                    eventpanel=NeuroPlot.selectpanel;
                    eventpanel.create(eventtablepanel,'eventpanel',{},'typestring',{});
                % add sync to timebar
                    timepanel=findobj(subguiplot,'-regexp','Tag','timerangepanel');
                    for j=1:length(timepanel)
                        addlistener(eventpanel.listpanel,'Value','PostSet',@(~,~) NeuroPlot.Sync.SyncEvent_Time(eventpanel,timepanel(j))); 
                    end
                    set(eventtablepanel,'Parent',subguiplot);
                    set(subguiplot,'Width',[-7,-1]);
                end
                eventmodifiedpanel=eventmodifiedpanel.create(subguiplot,eventtablepanel); 
                timepanel = findobj(obj.mainWindow,'-regexp','Tag','timerangepanel');
                eventmodifiedpanel.currentindex=1;
                for i=1:length(timepanel)
                    addlistener(timepanel(i),'currenttime','PostSet',@(~,~) eventmodifiedpanel.getCurrenttime(timepanel(i)));
                end
        end
        function obj=DataOutput(obj)
        global NV
            if ~isempty(NV.choosematrix)
                NeuroMethod.getParams(NV.choosematrix);
                savepath=uigetdir('Save Path of the extract data');
                format='matfile'; % could support hdf5 in the future;
                for i=1:length(NV.choosematrix)
                    [totalpath,filename]=fileparts(NV.choosematrix(i).Datapath);
%                     [~,filename]=fileparts(totalpath);
                    try
                    NeuroResult=NV.choosematrix(i).LoadData;
                    NeuroResult.SaveData(savepath,filename,format,[]);
                    catch ME
                        disp(ME);
                    end
                    multiWaitbar('loading data',i/length(NV.choosematrix));
                end
            end
        end
        function obj=FiringProperties(obj)
            global NV
               obj.CheckValid(NV.choosematrix,'SPKdata');
               NeuroMethod.Checkpath('Cellexplorer');
               for i=1:length(NV.choosematrix)
                   FiringProperties.cal(NV.choosematrix(i)); 
                   multiWaitbar('Processing...', i/length(NV.choosematrix));
               end
               multiWaitbar('Processsing...','close');
        end         
    end
    methods(Access='private')
        function obj=Datatypechangefcn(obj,Datatype,Tagchoosepanel)   
            global NV
                NV.Filematrix=[];
                singleobj=NV.objmatrix(NV.objindex);
                subtype=Datatype.String{Datatype.Value};
                filename=[];
                for i=1:length(singleobj)
                   try
                   for j=1:length(eval(['singleobj(i).',subtype]))
                    NV.Filematrix=[NV.Filematrix,eval(['singleobj(i).',subtype,'(j)'])];
                   end
                   end
                end
                FileTag=findobj(Tagchoosepanel,'Tag','FileTag');
                FileTagValue=findobj(Tagchoosepanel,'Tag','FileTagValue');
                delete(FileTag);
                delete(FileTagValue);
                FileTag=uicontrol(Tagchoosepanel,'Style','popupmenu','Tag','FileTag');
                FileTagValue=uicontrol(Tagchoosepanel,'Style','popupmenu','Tag','FileTagValue','Value',1);
                try
                    obj.setTaginfo(NV.Filematrix,FileTag,FileTagValue);
                end
        end
        function obj=SelectSubject(obj,SubjectTaginfo,Subjectlist,Datatype,Tagchoosepanel,Subjectunion)
            global NV
            %Taginfo=regexpi(SubjectTaginfo.String,':','split');
            if Subjectunion.Value
                [tmp.objmatrix,NV.objindex]=NV.objmatrix.choose(cat(1,SubjectTaginfo.String,{'union'}));
            else
                [tmp.objmatrix,NV.objindex]=NV.objmatrix.choose(cat(1,SubjectTaginfo.String,{'intersect'}));
            end
            listString=[];
            for i=1:length(tmp.objmatrix)
                 listString{i}=tmp.objmatrix(i).Datapath;
            end
            Subjectlist.String=listString;
            obj.Datatypechangefcn(Datatype,Tagchoosepanel);
            Subjectlist.Value=1;
            NV.choosematrix=[];
        end
        function obj=SelectFile(obj,SubjectTaginfo,Subjectunion,FileTaginfo,Filelist,Fileunion)
            global NV
               Taginfo=cellfun(@(x) regexpi(x,',','split'),FileTaginfo.String,'UniformOutput',0);
               Filetype=unique(cellfun(@(x) x{1},Taginfo,'UniformOutput',0));
            if Subjectunion.Value
                Subjecttag=cat(1,SubjectTaginfo.String,{'union'});
            else
                Subjecttag=cat(1,SubjectTaginfo.String,{'intersect'});
            end
            % transfer FileTaginfo to each Datatype for Neurodata.choose.
            Fileinfo=FileTaginfo.String;
            if Fileunion.Value
                combinetype={'union'};
            else
                combinetype={'intersect'};
            end
            input=[];
            for i=1:length(Filetype)
                eval([Filetype{i},'_info=[];']);
                for j=1:length(Fileinfo)
                if contains(Fileinfo{j},Filetype{i})
                    eval([Filetype{i},'_info=cat(1,',Filetype{i},'_info,Taginfo{i}(2));']);
                end
                end
                eval([Filetype{i},'_info=cat(1,',Filetype{i},'_info,combinetype);']);
                input=cat(2,input,'''',Filetype{i},''',',Filetype{i},'_info,');
            end
            eval(['NV.choosematrix=NV.objmatrix.choose(Subjecttag,',input(1:end-1),');']);
            filelist=NV.choosematrix.listfile;
            if ~isempty(filelist)
                set(Filelist,'String',cellstr(NV.choosematrix.listfile));
            else
                set(Filelist,'String',[]);
            end
        end 
        function obj=Addinfo(obj,Tagchoosepanel,SubjectTaginfo,Datatype)
            SubjectTag=findobj(Tagchoosepanel,'Tag','FileTag');
            SubjectTagValue=findobj(Tagchoosepanel,'Tag','FileTagValue');
            if isempty(Datatype)
            SubjectTaginfo.String=unique(vertcat(SubjectTaginfo.String,{[SubjectTag.String{SubjectTag.Value},':',SubjectTagValue.String{SubjectTagValue.Value}]}));
            else 
            SubjectTaginfo.String=unique(vertcat(SubjectTaginfo.String,{[Datatype.String{Datatype.Value},',',SubjectTag.String{SubjectTag.Value},':',SubjectTagValue.String{SubjectTagValue.Value}]}));
            end
        end
        function obj=Deleteinfo(obj,SubjectTaginfo)
            index=listdlg('PromptString','Please Choose the Tag/TagValue(s) to Delete!','ListString',SubjectTaginfo.String,'Selectionmode','Multiple');
            SubjectTaginfo.String(index)=[];
        end
        function obj=Loadobjmatrix(obj)
            global NV
            if isempty(NV.objmatrix)
                 [f,p]=uigetfile();
                Taginfo=yaml.loadFile([p,f],'ConvertToArray',true);
                NV.objmatrix=NeuroData(Taginfo);
            end
        end
        function obj=setTaginfo(obj,neurodata,Tagmenu,Tagvaluemenu)
            TagInfo=neurodata.getTaginfo('Tagname:Tagvalue','fileTag');
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
        function Eventselect(parent,choosematrix)
            if isempty(parent)
                parent=figure('menubar','none','numbertitle','off','name','Choose the eventtype','DeleteFcn',@(~,~) neurodataextract.eventchoosefcn);
            end
            MainWindow=uix.HBox('Parent',parent);   
            controlpanel=uix.VBox('Parent',MainWindow);
            infopanel=uix.CardPanel('Parent',MainWindow,'Tag','Eventinfo');
            uicontrol(controlpanel,'Style','pushbutton','String','Time points','Callback',@(~,~) neurodataextract.eventselectpanel(infopanel,1));
            uicontrol(controlpanel,'Style','pushbutton','String','Time duration','Callback',@(~,~) neurodataextract.eventselectpanel(infopanel,2));
            %uicontrol(controlpanel,'Style','pushbutton','String','Choose the Eventinfo','Tag','Chooseinfo','Callback',@(~,~) neurodataextract.eventchoosefcn);
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
        function CheckValid(choosematrix,option)
            % keep all neurodata object contains the [option] type of files
            for i=1:length(choosematrix)
                if isempty(eval(['choosematrix(i).',option]))
                    error(['No',option,'contains in the choosed data in',choosematrix(i).Datapath]);
                end
            end
        end
    end
end

