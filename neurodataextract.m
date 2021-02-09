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
           Datatype=uicontrol(Tagchoosepanel,'Style','popupmenu','String',{'LFPdata','SPKdata','EVTdata',});
           FileTag=uicontrol(Tagchoosepanel,'Style','popupmenu','Tag','FileTag');
           FileTagValue=uicontrol(Tagchoosepanel,'Style','popupmenu','Tag','FileTagValue');
           addlistener(Datatype,'Value','PostSet', @(~,~) obj.Datatypechangefcn(Datatype,Tagchoosepanel))
           Commandpanel=uix.VBox('Parent',Filegrid);
           FileTaginfopanel=uix.VBox('Parent',Filegrid);
           FileTaginfo=uicontrol(FileTaginfopanel,'Style','Text');
           Fileunion=uicontrol(FileTaginfopanel,'Style','checkbox','Tag','union','String','select the union');
           Filelist=uicontrol(Filegrid,'Style','listbox');
           addlistener(FileTaginfo,'String','PostSet',@(~,~) obj.SelectFile(FileTaginfo,Filelist,Fileunion));
           uicontrol(Commandpanel,'Style','pushbutton','String','Add the File Tag/TagValue','Callback',@(~,~) obj.Addinfo(Tagchoosepanel,FileTaginfo,Datatype));
           uicontrol(Commandpanel,'Style','pushbutton','String','Delete the File Tag/TagValue','Callback',@(~,~) obj.Deleteinfo(FileTaginfo));
           uicontrol(Commandpanel,'Style','pushbutton','String','Select the NeuroData','Callback',@(~,~) obj.GenerateSelectmatrix(SubjectTaginfo,FileTaginfo,Subjectunion,Fileunion));   
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
                    Data=choosematrix(i).LFPdata(j).ReadLFP([],0,inf);
                    for k=1:length(Data.LFPdata)
                        FiltData=[];
                        if length(choosematrix(i).LFPdata(j).Epochframes)==1
                            else
                            end
                                FiltData{k}=eegfilt(Data.LFPdata{k}',str2num(choosematrix(i).LFPdata(j).Samplerate),str2num(x{2}),str2num(x{3}),choosematrix(i).LFPdata(j).Epochframes,str2num(x{4}),str2num(x{5}));
                                FiltData{k}=notchfilter(Data.LFPdata{k}',str2num(choosematrix(i).LFPdata(j).Samplerate),[str2num(x{2}),str2num(x{3})]);
                            if str2num(x{5})==1
                        else    
                            for l=1:length(choosematrix(i).LFPdata(j).Epochframes)
                                 FiltData{k}=eegfilt(Data.LFPdata{k}',str2num(choosematrix(i).LFPdata(j).Samplerate),str2num(x{2}),str2num(x{3}),choosematrix(i).LFPdata(j).Epochframes(k),str2num(x{4}),str2num(x{5}));
                            end
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
        function obj=LFPepoch(obj)
        % epoch 
        global choosematrix eventinfo objmatrixpath objindex
            obj.CheckValid('LFPdata');
            obj.CheckValid('EVTdata');
            originmatrix=matfile(objmatrixpath);
            neuromatrix=originmatrix.objmatrix;
            prompt={'epochfilename'};
            title='input Params';
            lines=1;
            def={'_epoch.lfp'};
            x=inputdlg(prompt,title,lines,def,'on');
            neurodataextract.Eventselect([], choosematrix);
            uiwait;
            for i=1:length(choosematrix)
                if length(choosematrix(i).EVTdata)>1
                    err('Only support the multiple LFP with single Event file for each Subject');
                end
                [timestart, timestop]=choosematrix(i).EVTdata.LoadEVT(eventinfo);
                for j=1:length(choosematrix(i).LFPdata)
                    Data=choosematrix(i).LFPdata(j).ReadLFP([],timestart,timestop);
                    Epochdata=[]; Epochframes=[];
                    Epochdata=cell2mat(Data.LFPdata')';
                    Epochframes=unique(cellfun(@(x) length(x),Data.LFPdata,'UniformOutput',1)); %% equal epochs
                    Epochfilename=strrep(choosematrix(i).LFPdata(j).Filename,'.lfp',x{1});
                    NewLFP=LFPData.Clone(choosematrix(i).LFPdata(j));
                    NewLFP.Filename=Epochfilename;
                    NewLFP.Epochframes=Epochframes;
                    NewLFP.Taginfo('fileTag',informationtype,information);
                    neuromatrix(objindex(i)).LFPdata=horzcat(neuromatrix(objindex(i)).LFPdata,NewLFP);                    
                    fid=fopen(Epochfilename,'w');
                    fwrite(fid,Epochdata,'int16');
                    fclose(fid);
                end         
            end
        end
        function obj=EventModify(obj)
            global choosematrix
            obj.CheckValid('EVTdata');
            for i=1:length(choosematrix)
             if length(choosematrix(i).EVTdata)>1
                err('Only support the multiple LFP with single Event file for each Subject');
             end
            end
            obj.CheckValid('Videodata');
            eventmodify=EventModified();
            eventmodify.cal(choosematrix,obj.mainWindow);
        end
        function obj=DataOutput(obj)
        global choosematrix DetailsAnalysis
                neurodataextract.CheckValid('EVTdata');
                NeuroMethod.getParams(choosematrix);
                savepath=uigetdir('Save Path of the extract data');
                try
                    neurodataextract.CheckValid('LFPdata');
                    bool1=true;
                catch
                    bool1=false;
                end
                try
                    neurodataextract.CheckValid('SPKdata');
                    bool2=true;
                catch
                    bool2=false;
                end
                variablename=inputdlg('Please input the variable name in the Spike name mat file');
                if bool1 && ~bool2
                    for i=1:length(choosematrix)
                        try
                           data=choosematrix(i).loadData(DetailsAnalysis,'LFP');
                           [~,filename]=fileparts(choosematrix(i).Datapath);
                           savematfile=matfile(fullfile(savepath,[filename,'.mat']),'Writable',true);
                           eval(['savematfile.',variablename{:},'=data;']);
                            multiWaitbar('Processing',i/length(choosematrix));
                        end
                    end
                end
                if bool2 && ~bool1
                    multiWaitbar('Processing',0);
                    for i=1:length(choosematrix)
                        data=choosematrix(i).loadData(DetailsAnalysis,'SPKsingle');
                        spikename=fieldnames(data);
                        [~,filename]=fileparts(choosematrix(i).Datapath);
                        for j=1:length(spikename)
                            if strfind(spikename{j},'cluster')
                                savematfile=matfile(fullfile(savepath,[filename,'_',spikename{j},'.mat']),'Writable',true);
                                eval(['savematfile.',variablename{:},'=data.',spikename{j},';']);
                            end
                        end
                        multiWaitbar('Processing',i/length(choosematrix)); 
                    end
                end
                if bool2 && bool1
                    buttonname=questdlg('Subject mat or Spike mat?','mat choose','Subject','Spike','Subject');
                    switch buttonname
                        case 'Subject'
                        for i=1:length(choosematrix)
                            try
                               datalfp=choosematrix(i).loadData(DetailsAnalysis,'LFP');
                               dataspk=choosematrix(i).loadData(DetailsAnalysis,'SPKtime');
                               [~,filename]=fileparts(choosematrix(i).Datapath);
                               savematfile=matfile(fullfile(savepath,[filename,'.mat']),'Writable',true);
                               lfpfield=fieldnames(datalfp);
                               eval(['savematfile.',variablename{:},'=dataspk;']);
                               for j=1:length(lfpfield)
                                   eval(['savematfile.',variablename{:},'=setfield(savematfile.',variablename,',',lfpfield{j},',datalfp.',lfpfield{j},');']);
                               end
                            end
                             multiWaitbar('Processing',i/length(choosematrix)); 
                        end
                        case 'Spike'
                            for i=1:length(choosematrix)
                                 try
                                    datalfp=choosematrix(i).loadData(DetailsAnalysis,'LFP');
                                    lfpfield=fieldnames(datalfp);
                                    dataspk=choosematrix(i).loadData(DetailsAnalysis,'SPKsingle');
                                    spikename=fieldnames(dataspk);
                                    [~,filename]=fileparts(choosematrix(i).Datapath);
                                    for j=1:length(spikename)
                                        if strfind(spikename{j},'cluster')
                                            tmp=[];
                                            savematfile=matfile(fullfile(savepath,[filename,'_',spikename{j},'.mat']),'Writable',true);
                                           try 
                                               eval(['savematfile.',variablename{:},';'])
                                           catch
                                               eval(['savematfile.',variablename{:},'=dataspk.',spikename{j},';']);
                                             for k=1:length(lfpfield)
                                                 eval(['savematfile.',variablename{:},'=setfield(savematfile.',variablename{:},',lfpfield{k},datalfp.',lfpfield{k},');']);
                                             end
                                           end
                                        end
                                    end
                                 end
                                  multiWaitbar('Processing',i/length(choosematrix)); 
                            end
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
                FileTagValue=uicontrol(Tagchoosepanel,'Style','popupmenu','Tag','FileTagValue');
                try
                    obj.setTaginfo(Filematrix,FileTag,FileTagValue);
                end
        end
        function obj=SelectSubject(obj,SubjectTaginfo,Subjectlist,Datatype,Tagchoosepanel,Subjectunion)
            global objindex objmatrix choosematrix
            Taginfo=regexpi(SubjectTaginfo.String,':','split');
            intersect=Subjectunion.Value;
            objindex=obj.getSubject(objmatrix,Taginfo,intersect);
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
        function obj=SelectFile(obj,FileTaginfo,Filelist,Fileunion)
            global objmatrix objindex choosematrix
                Taginfo=cellfun(@(x) regexpi(x,':','split'),FileTaginfo.String,'UniformOutput',0);
                Filetype=unique(cellfun(@(x) x{1},Taginfo,'UniformOutput',0));
                filematrix=objmatrix(objindex);
                Filelist.String=[];
                intersect=Fileunion.Value;
                for i=1:length(filematrix)
                    for j=1:length(Filetype)
                        tmpmatrix=eval(['filematrix(i).',Filetype{j}]);
                        tmpindex=obj.getSubject(tmpmatrix,Taginfo,intersect);
                        for k=1:length(tmpindex)
                            try
                            Filelist.String=cat(1,Filelist.String,{tmpmatrix(tmpindex(k)).Filename});
                            end
                        end
                    end
                end
                Filelist.Value=1;
                choosematrix=[];
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
        end
        function obj=GenerateSelectmatrix(obj,SubjectTaginfo,FileTaginfo,Subjectunion,Fileunion)
            global objmatrixpath choosematrix DetailsAnalysis
            DetailsAnalysis=[];
            Subjectinfo=SubjectTaginfo.String;
            Fileinfo=FileTaginfo.String;
            intersect(1)=Subjectunion.Value;
            intersect(2)=Fileunion.Value;
            choosematrix=obj.DataSelect(objmatrixpath,Subjectinfo,Fileinfo,intersect);
            DetailsAnalysis=vertcat(Subjectinfo,Fileinfo);
        end
    end
    methods(Static)
        function index=getSubject(Neurodata,Taginfo,intersect)
            index=[];
            if intersect==1
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
            else
            for i=1:length(Neurodata)
                for j=1:length(Taginfo)
                    if length(Taginfo{j})<3
                        bool(j)=Neurodata(i).Tagchoose('fileTag',Taginfo{j}{1},Taginfo{j}{2});
                    else
                         bool(j)=Neurodata(i).Tagchoose('fileTag',Taginfo{j}{2},Taginfo{j}{3});
                    end
                end
                if prod(bool)==1
                    index=vertcat(index,i);
                end
            end
            end
        end
        function choosematrix=DataSelect(objmatrixpath,Subjectinfo,Fileinfo,intersect)
                originmatrix=matfile(objmatrixpath);
                originmatrix=originmatrix.objmatrix;
                Subjectinfo=regexpi(Subjectinfo,':','split');
                index=neurodataextract.getSubject(originmatrix,Subjectinfo,intersect(1));
                Filetype={'LFPdata','EVTdata','SPKdata','Videodata'};
                choosematrix=originmatrix(index);
                for i=1:length(choosematrix)
                    for j=1:length(Filetype)
                        index=contains(Fileinfo,Filetype{j});
                        tmpmatrix=eval(['choosematrix(i).',Filetype{j}]);
                        if sum(index)~=0
                            Fileinfotmp=regexpi(Fileinfo(index),':','split');
                            for k=1:length(tmpmatrix)
                                fileindx=neurodataextract.getSubject(tmpmatrix,Fileinfotmp,intersect(2));
                            end
                            eval(['choosematrix(i).',Filetype{j},'=tmpmatrix(fileindx);']);
                        else
                            eval(['choosematrix(i).',Filetype{j},'=[];']);
                        end                           
                    end
                end
        end      
        function CheckValid(option)
            global choosematrix
            if isempty(choosematrix)
                error('No selected NeuroData, please enter the button ''Select the NeuroData''.');
            end
            for i=1:length(choosematrix)
                if isempty(eval(['choosematrix(i).',option]))
                    error(['No',option,'contains in the choosed data in',choosematrix(i).Datapath]);
                end
            end
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
            uicontrol(controlpanel,'Style','pushbutton','String','Choose the Eventinfo','Tag','Chooseinfo','Callback',@(~,~) neurodataextract.eventchoosefcn);
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
                 eventinfo=[];
                tmpobj=findobj(gcf,'Tag','Eventinfo');
                if tmpobj.Selection==1
                    panelobj=findobj(tmpobj,'Tag','Timepoints');
                    Eventtype=findobj(panelobj,'Tag','eventtype');
                    Eventtypelist=Eventtype.String(Eventtype.Value);
                    evttype=[];
                    for i=1:length(Eventtypelist)
                        evttype=[evttype,Eventtypelist{i},','];
                    end
                    evttype(end)=[];
                    eventinfo{1}=['Timetype:timepoint:EVTtype:',evttype];
                    begintime=findobj(panelobj,'Tag','Begintime');
                    endtime=findobj(panelobj,'Tag','Endtime');
                    eventinfo{2}=['Timestart:',begintime.String];
                    eventinfo{3}=['Timestop:',endtime.String];
                else
                    panelobj=findobj(tmpobj,'Tag','Timeduration');
                    eventinfo{1}=['Timetype:timeduration'];
                    begintime=findobj(panelobj,'Tag','Begintime');
                    endtime=findobj(panelobj,'Tag','Endtime');
                    eventinfo{2}=['Timestart:EVTtype:',begintime.String{begintime.Value}];
                    eventinfo{3}=['Timestop:EVTtype:',endtime.String{endtime.Value}];
                end
                eventinfo=eventinfo';
                uiresume;
        end       
    end
end

