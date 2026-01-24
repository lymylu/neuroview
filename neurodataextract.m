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
               matrixinfo=yaml.loadFile(NV.objmatrixpath,"ConvertToArray",true);
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
        function obj=Interpolate(obj)
            % interpolate the bad channel of the LFPdata files
            % for silicon probe, using
            % preprocessing_tool.get_kriging_channel_weights (need python)
            % for eeg, using pop_interp in EEGlab toolbox
            global NV
            obj.CheckValid(NV.choosematrix,'LFPdata');
            neuromatrix=NV.objmatrix;
            NeuroMethod.Checkpath('eeglab');
            prompt={'interpolatefilename'};
            title='input Params';
            lines=1;
            def={'_interpolate.lfp'};
            x=inputdlg(prompt,title,lines,def,'on');
            [informationtype,information]=Taginfoappend([]);
            multiWaitbar('Processing',0);
            for i=1:length(NV.choosematrix)
                for j=1:length(NV.choosematrix(i).LFPdata)
                    Data=NV.choosematrix(i).LFPdata(j).Extractdata([],[],[],[]);
                    % for k=1:length(Data.LFPdata)
                    if isfield(NV.choosematrix(i).ChannelTag,'ChannelPosition')&&isstruct(NV.choosematrix(i).ChannelTag.ChannelPosition)&&isfield(NV.choosematrix(i).ChannelTag,'Bad')
                        ChannelPosition=NV.choosematrix(i).ChannelTag.ChannelPosition;
                        for c=1:length(ChannelPosition)
                            ChannelPosition(i).labels=char(ChannelPosition(i).labels);
                        end
                    % construct EEG struct to use EEG interpolate 
                        EEG=pop_importdata('data',Data.LFPdata{1}','srate',str2num(NV.choosematrix(i).LFPdata(j).Samplerate),'nbchan',str2num(NV.choosematrix(i).LFPdata(j).Channelnum),'chanlocs',NV.choosematrix(i).ChannelTag.ChannelPosition);
                        try
                        badchannel=str2num(NV.choosematrix(i).ChannelTag.Bad);
                        end
                        EEG=pop_interp(EEG,badchannel,x{2});
                        data=EEG.data;
                        clear EEG; 
                    elseif isfield(NV.choosematrix(i).ChannelTag,'ChannelPosition')&&isnumeric(NV.choosematrix(i).ChannelTag.ChannelPosition)&&isfield(NV.choosematrix(i).ChannelTag,'Bad')
                        ChannelPosition=NV.choosematrix(i).ChannelTag.ChannelPosition(:,2:3); % x y coordinates
                        sigma_um=diff(unique(sort(ChannelPosition(:,2))));
                        sigma_um=sigma_um(1);
                        goodposition=true([size(ChannelPosition,1),1]);
                        badposition=false([size(ChannelPosition,1),1]);
                        badposition(str2num(NV.choosematrix(i).ChannelTag.Bad))=true;
                        goodposition(str2num(NV.choosematrix(i).ChannelTag.Bad))=false;
                        weights=get_kriging_channel_weights(ChannelPosition(goodposition,:), ChannelPosition(badposition,:), sigma_um);
                        Data.LFPdata{1}(:,badposition)=Data.LFPdata{1}(:,goodposition)*double(weights);
                        data=Data.LFPdata{1}';
                    else 
                        warning(strcat('No channel position, bad channel in ', NV.choosematrix(i).LFPdata(j).Filename, ', skip.'))
                        continue;
                    end
                    [~,file,ext]=fileparts(NV.choosematrix(i).LFPdata(j).Filename);
                    Filtfilename=strrep(NV.choosematrix(i).LFPdata(j).Filename,ext,x{1});
                    NewLFP=NV.choosematrix(i).LFPdata(j).clone;
                    NewLFP.Filename=Filtfilename;
                    NewLFP.Taginfo('fileTag',informationtype,information);
                    NV.objmatrix(NV.objindex(i)).LFPdata=horzcat(NV.objmatrix(NV.objindex(i)).LFPdata,NewLFP);
                    fid=fopen(Filtfilename,'w');
                    fwrite(fid,data,'int16');
                    fclose(fid);
                end
                multiWaitbar('Processing',i/length(NV.choosematrix));
            end
              
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
            obj.CheckValid(NV.choosematrix,'LFPdata');
            neuromatrix=NV.objmatrix;
            NeuroMethod.Checkpath('eeglab');
            prompt={'filtfilename','lowcutfreq ','highcutfreq','notchfilter'};
            title='input Params';
            lines=2;
            def={'_filt.lfp','0','100','0'};
            x=inputdlg(prompt,title,lines,def,'on');
            [informationtype,information]=Taginfoappend([]);
            multiWaitbar('Processing',0);
            for i=1:length(NV.choosematrix)
                for j=1:length(NV.choosematrix(i).LFPdata)
                    Data=NV.choosematrix(i).LFPdata(j).Extractdata([],[],[],[]);
                    FiltData=[];
                    EEG=pop_importdata('data',Data.LFPdata{1}','srate',str2num(NV.choosematrix(i).LFPdata(j).Samplerate),'nbchan',str2num(NV.choosematrix(i).LFPdata(j).Channelnum));
                    FiltData=pop_eegfiltnew(EEG,'locutoff',str2num(x{2}),'hicutoff',str2num(x{3}),'revfilt',str2num(x{4}));
                    [~,file,ext]=fileparts(NV.choosematrix(i).LFPdata(j).Filename);
                    Filtfilename=strrep(NV.choosematrix(i).LFPdata(j).Filename,ext,x{1});
                    NewLFP=NV.choosematrix(i).LFPdata(j).clone;
                    NewLFP.Filename=Filtfilename;
                    NewLFP.Taginfo('fileTag',informationtype,information);
                    NV.objmatrix(NV.objindex(i)).LFPdata=horzcat(NV.objmatrix(NV.objindex(i)).LFPdata,NewLFP);
                    fid=fopen(Filtfilename,'w');
                    fwrite(fid,FiltData.data,'int16');
                    fclose(fid);
                    clear FiltData;
                end
                multiWaitbar('Processing',i/length(NV.choosematrix));
            end
            multiWaitbar('Processing','close');
        end
        function obj=EventModify(obj)
                subguiplot=findobj(obj.mainWindow,'Tag','SingleSubjectPlot');
                eventmodifiedpanel=EventModified();
                eventtablepanel=findobj(subguiplot,'Tag','EventTablePanel');
                if isempty(eventtablepanel)
                    [f,p]=uiputfile('*.evt','Input the Save name of the new event');
                    eventtablepanel=uix.TabPanel;
                    eventpanel=NeuroPlot.selectpanel;
                    eventpanel.create(eventtablepanel,[p,f,'_eventpanel'],{},'typestring',{});
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
               
                for i=1:length(timepanel)
                    addlistener(timepanel(i),'currenttime','PostSet',@(~,~) eventmodifiedpanel.getCurrenttime(timepanel(i)));
                end
        end
        function obj=DataOutput(obj)
        global NV
            if ~isempty(NV.choosematrix)
                NeuroMethod.getParams(NV.choosematrix);
                resultname=inputdlg('name the variable name of this calculation');
                switch questdlg('save the result in each subject dirs or in a new dir?','select dirs','subject dirs','new dir','subject dirs')
                    case 'subject dirs'
                        savefilepath=[];
                    case 'new dir'
                        savefilepath=uigetdir('the save path');
                end
                saveformatlist={'matfile','hdf5'};
                saveformat=listdlg("PromptString",'select the saveformat','ListString',saveformatlist);
                saveformat=saveformatlist{saveformat};
                for i=1:length(NV.choosematrix)
                    result=NV.choosematrix(i).ReadData;
                    if isempty(savefilepath)
                    mkdir(fullfile(NV.choosematrix(i).Datapath,'Result'));
                    savefilepath=fullfile(NV.choosematrix(i).Datapath,'Result');
                    result.SaveData(savefilepath,resultname{:},saveformat);
                    else
                   try
                    [~,filename,ext]=fileparts(NV.choosematrix(i).Datapath);
                    filename=fullfile(filename,ext);
                   catch
                        filename=NV.choosematrix(i).Subjectname;
                   end
                    result.SaveData(savefilepath,filename,saveformat);
                    end
                    resultinfo=NeuroResult;
                    resultinfo.Subjectname=result.Subjectname;
                    resultinfo.Filename=result.Filename;
                    resultinfo.fileTag=result.fileTag;
                    resultinfo=resultinfo.Taginfo('fileTag','Dataepoch',resultname{:});
                    try
                        addprop(NV.objmatrix(NV.objindex(i)),'Neuroresult');
                    end
                    NV.objmatrix(NV.objindex(i)).Neuroresult=cat(2,NV.objmatrix(NV.objindex(i)).Neuroresult,resultinfo);
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
                % eval([Filetype{i},'_info=[];']);
                % for j=1:length(Fileinfo)
                % if contains(Fileinfo{j},Filetype{i})
                %     eval([Filetype{i},'_info=cat(1,',Filetype{i},'_info,Taginfo{j}(2));']);
                % end
                % end
                % 
                eval([Filetype{i},'_info=cellfun(@(x) strrep(x,[''',Filetype{i},',''],''''),Fileinfo(contains(Fileinfo,''',Filetype{i},''')),''UniformOutput'',0);']);
                eval([Filetype{i},'_info=cat(1,',Filetype{i},'_info,combinetype);']);
                input=cat(2,input,'''',Filetype{i},''',',Filetype{i},'_info,');
            end
            eval(['[NV.choosematrix,NV.objindex]=NV.objmatrix.choose(Subjecttag,',input(1:end-1),');']);
            filelist=NV.choosematrix.list('Filename');
            if ~isempty(filelist)
                set(Filelist,'String',cellstr(NV.choosematrix.list('Filename')));
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
        function addduration(Timeduration)
            begintime=findobj(Timeduration,'Tag','eventbegin');
            endtime=findobj(Timeduration,'Tag','eventend');
            eventdescription=findobj(Timeduration,'Tag','eventdescription');
            %timestartindex=begintime.liststring(begintime.getIndex());
            timestartdescription=unique(begintime.liststring(begintime.getIndex()));
            %timestopindex=endtime.liststring(endtime.getIndex());
            timestopdescription=unique(endtime.liststring(endtime.getIndex()));
            description=eventdescription.String;
            set(eventdescription,'String',cat(1,description,{append(timestartdescription{:},' ',timestopdescription{:})}));
        end
        function delduration(Timeduration)
            eventdescription=findobj(Timeduration,'Tag','eventdescription');
            index=eventdescription.Value;
            description=eventdescription.String;
            description(index)=[];
            set(eventdescription,'String',description);
        end        
        function eventselectpanel(infopanel,num)
            infopanel.Selection=num;
        end
        function eventchoosefcn
            % collect eventinfo
            % for timepoint mode, eventinfo contains timetype,
            % timestart/timestop (numeric),selectdescription(cell),
            % for timeduration mode, eventinfo contains timetype,
            % timestart/timestop (cell).
            global eventinfo
                tmpobj=findobj(gcf,'Tag','Eventinfo');
                if tmpobj.Selection==1
                    panelobj=findobj(tmpobj,'Tag','eventpoint');
                    eventinfo.selectdescription=panelobj.liststring(panelobj.getIndex());
                    %eventinfo.selectdescription=unique(panelobj.typestring(panelobj.getIndex()));
                    begintime=findobj(tmpobj,'Tag','Begintime');
                    endtime=findobj(tmpobj,'Tag','Endtime');
                    eventinfo.timestart=str2num(begintime.String);
                    eventinfo.timestop=str2num(endtime.String);
                    eventinfo.timetype='timepoint';
                else
                    panelobj=findobj(tmpobj,'Tag','Timeduration');
                    eventinfo.timetype='timeduration';
                    eventdescription=findobj(tmpobj,'Tag','eventdescription');
                    description=eventdescription.String;
                    if ~isempty(description)
                        description=cellfun(@(x) regexpi(x,' ','split'),description,'UniformOutput',0);
                        eventinfo.timestart=cellfun(@(x) x{1}, description,'UniformOutput',0);
                        eventinfo.timestop=cellfun(@(x) x{2}, description,'UniformOutput',0);
                        eventinfo.timetype='timeduration';
                    else
                        error('No duration segment was selected');
                    end
                uiresume;
                end
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

