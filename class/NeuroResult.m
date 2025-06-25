classdef NeuroResult < BasicTag & dynamicprops
    % analysis results in the subjectlevel. could be managed by NeuroData
    properties
         Filename
         Subjectname
    end 
    methods
         function obj =  fileappend(obj)
            % support the .clu. file from KlustaKwik and .npy file from Phy
            ResultType={'HDF5','Matfile'};
            index=listdlg('PromptString','choose the format of the Result','ListString',ResultType);
            switch index
                case 1
                    Resultpath = uigetdir('Please select the Path of the result');
                case 2
                    Resultpath =uigetfile('*.mat','Please select the matfile');
            end
            obj.Filename = Resultpath;
        end
        function obj = Taginfo(obj, Tagname, informationtype, information)
            obj=Taginfo@BasicTag(obj,Tagname,informationtype, information);
        end
        function bool = Tagchoose(obj,Tagname,informationtype, information)
             bool=Tagchoose@BasicTag(obj,Tagname,informationtype,information);
        end
        function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
             [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                  [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
        end
        function obj = NeuroResult(varargin)
            if nargin==1
             varname=fieldnames(varargin{1});
             data=varargin{1};
             for j=1:length(data)
                 obj(j)=NeuroResult();
             for i=1:length(varname)
                 eval(['obj(j).',varname{i},'=data(j).',varname{i},';']);
             end
             end
            end
        end
        function obj = ReadCAL(obj,CALData,EVTinfo)
            %% not work well!
%             read_start=EVTinfo.timestart;
%             read_until=EVTinfo.timestop;
%             data=importdata(CALData.Filename);
%             cellname=regexpi(data.textdata{1,1},',','split');
%             validindex=ismember(data.colheaders,' accepted');
%             validindex=find(validindex==1);
%             obj.CALinfo.name=cellname(validindex);
%             timelist=data.data(:,1);
%             for i=1:length(validindex)
%                 for j=1:length(read_start)
%                     obj.CALdata{i,j}=data.data(timelist>=read_start(j)&timelist<=read_until(j),validindex(i));
%                 end
%             end
%             % using fast oopsi to get the spike time and save in SPKdata
%             V.dt=1/str2num(CALData.Samplerate);
%             for i=1:size(obj.CALdata,1)
%                 for j=1:size(obj.CALdata,2)
%                     V.T=length(obj.CALdata{i,j});
%                     try
%                     [~, obj.SPKdata{i,j}] = foopsi(obj.CALdata{i,j});
%                     catch
%                         a=1;
%                     end
%                     %obj.SPKdata{i,j}=fast_oopsi(obj.CALdata{i,j},V);
%                 end
%             end
%             obj.SPKinfo.name=obj.CALinfo.name;
%             obj.SPKinfo.channeldescription=repmat({'default'},[1,length(obj.CALinfo.name)]);
%             obj.SPKinfo.channel=repmat({1},[1,length(obj.CALinfo.name)]);
        end
        function SaveData(obj,savepath,savefilename,format)
            % clear the obj and save to the given file as HDF5 or mat
             variablenames=fieldnames(obj);
            switch format
                case 'matfile'
                    if exist(fullfile(savepath,[savefilename,'.mat']))
                        warning(['the result: ',fullfile(savepath,[savefilename,'.mat']),'is exist, current result could not be saved']);
                    else
                        savemat=matfile(fullfile(savepath,[savefilename,'.mat']),'Writable',true);
                        for i=1:length(variablenames)
                            eval(['savemat.',variablenames{i},'=obj.',variablenames{i},';']); 
                        end
                        obj.Filename=fullfile(savepath,savefilename);
                    end
                case 'hdf5'
                    if exist(fullfile(savepath,savefilename))
                        warning(['the result: ',fullfile(savepath,savefilename),'is exist, current result could not be saved']);
                    else
                    mkdir(fullfile(savepath,savefilename));
                    Datafile=matfile(fullfile(savepath,savefilename,'Datainfo.mat'),'Writable',true);% remove in future?
                    datafile={'LFPdata','SPKdata','CALdata'};
                    if isprop(obj,'LFPdata') && ~isempty(obj.LFPdata)
                        LFPdatafile=fullfile(savepath,savefilename,'LFPdata.h5');
                        for i=1:length(obj.LFPdata)
                            h5create(LFPdatafile,['/',num2str(i)],size(obj.LFPdata{i}));
                            h5write(LFPdatafile,['/',num2str(i)],obj.LFPdata{i});
                        end
                        obj.LFPdata=LFPdatafile;
                    end
                    if isprop(obj,'SPKdata') && ~isempty(obj.SPKdata)
                        SPKdatafile=fullfile(savepath,savefilename,'SPKdata.h5');
                        for i=1:size(obj.SPKdata,2)
                            for j=1:size(obj.SPKdata,1)
                            if ~isempty(obj.SPKdata{j,i})          
                              h5create(SPKdatafile,['/',num2str(j),'/',num2str(i)],size(obj.SPKdata{j,i}));
                              h5write(SPKdatafile,['/',num2str(j),'/',num2str(i)],obj.SPKdata{j,i});
                            else
                              h5create(SPKdatafile,['/',num2str(j),'/',num2str(i)],[inf,1],'ChunkSize',[1,1]); 
                            end
                            end
                        end
                        obj.SPKdata=SPKdatafile;
                    end
                    if isprop(obj,'CALdata') && ~isempty(obj.CALdata)
                        CALdatafile=fullfile(savepath,savefilename,'CALdata.h5');
                        for i=1:length(obj.CALdata)
                            h5create(LFPdatafile,['/',num2str(i)],size(obj.CALdata{i}));
                            h5write(LFPdatafile,['/',num2str(i)],obj.CALdata{i});
                        end
                        obj.CALdata=CALdatafile;
                    end
                    obj.Filename=fullfile(savepath,savefilename);
                    for i=1:length(variablenames)
                        if eval(['ismember(class(obj.',variablenames{i},'),NeuroMethod.List)'])
                           Class=eval(['class(obj.',variablenames{i},');']);
                           eval(['obj.',variablenames{i},'=obj.',variablenames{i},'.saveh5(fullfile(savepath,savefilename));']);
                        end
                        eval(['Datafile.',variablenames{i},'=obj.',variablenames{i},';']);
                    end 
                    yaml.dumpFile(fullfile(savepath,savefilename,'Datainfo.yaml'),obj.struct());
                    end
                end
        end
        function data=CollectVariables(obj,Variablenames,catdimensions)
            % cat the defined Variablenames in multiple NeuroResult obj
            % according to the defined cat dimensions.
            for i=1:length(Variablenames)
                eval(['data.',Variablenames{i},'=[];']);
            end
            data.Subjectname=[];
            for i=1:length(obj)
                for j=1:length(Variablenames)
                   try
                   eval(['data.',Variablenames{j},'=cat(catdimensions(j),data.',Variablenames{j},',obj(i).',Variablenames{j},');']);
                   catch
                       error(['error cat in the',Variablenames{j},' of the ',obj(i).Subjectname,]);
                   end
                end
                data.Subjectname=cat(2,data.Subjectname,repmat({obj(i).Subjectname},[1,length(obj(i).SPKinfo.channeldescription)]));
            end
         end
        function obj=Split2Splice(obj)
            % from Splitting mode to Splicing mode, the epoches were spliced.
            % in this transformation , the trial number is 1.
            try
            %if strcmp(obj.LFPinfo.datatype,'splitting')
                LFPdatatmp=[];
                for i=1:length(obj.LFPdata) 
                    LFPdatatmp=cat(1,LFPdatatmp,obj.LFPdata{i});
                    obj.LFPinfo.spliceindex(i)=length(LFPdatatmp); % get the index of segments
                end
                obj.LFPdata={LFPdatatmp};
                %obj.LFPinfo.datatype='splicing';
            %end
            end
            try
            %if strcmp(obj.SPKinfo.datatype,'splitting')   
                SPKtimecorretion=cumsum(obj.EVTinfo.timestop-obj.EVTinfo.timestart);
                SPKtimecorretion=[0;SPKtimecorretion];
                for j=1:size(obj.SPKdata,1)
                    SPKdatatmp{j}=[];
                    for i=1:size(obj.SPKdata,2)
                        SPKdatatmp{j}=cat(1,SPKdatatmp{j},obj.SPKdata{j,i}-obj.EVTinfo.timestart(i)+SPKtimecorretion(i));
                    end
                end
                %obj.SPKinfo.datatype='splicing'; 
                obj.SPKdata=SPKdatatmp;
                obj.SPKinfo.spliceindex=SPKtimecorrection;
           % end
            end
           
        end
        function obj=Splice2Split(obj)
            % from Splicing mode to Splitting mode, the epoches were splitted.
        end
        function plotvariable=getPlotnames(obj)
            variablenames=fieldnames(obj);
            for i=1:length(variablenames)
                variableclass{i}=eval(['class(obj.',variablenames{i},');']);
                variablevalid(i)=eval(['~isempty(obj.',variablenames{i},');']);
            end
            plotvariable=table(variablenames(variablevalid),variableclass(variablevalid)');
        end
        function [Infopanel, DataPanel]=createplot(obj,variablename,varargin)
         import NeuroPlot.selectpanel NeuroPlot.figurecontrol
            % generate the panels to plot LFPdata, SPKdata,CALdata and EVTinfo
%             Infopanel=uix.Panel();DataPanel=uix.BoxPanel();
            switch variablename
               case 'LFPData'
                Infopanel=NeuroPlot.selectpanel;
                Channeldescription=getfield(obj.LFPinfo,'channeldescription');
                Channellist=num2cell(obj.LFPinfo.channelselect);
                Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
                Infopanel=Infopanel.create([],'ChannelIndex',Channellist,'typestring',Channeldescription,'blacklist',true);
                addlistener(Infopanel,'blacklist','PostSet',@(~,~) obj.recordblacklist(Infopanel,'LFP'));
                DataPanel=NeuroPlot.figurecontrol();
                DataPanel=DataPanel.create([],'LFPdatapanel','plot-baseline');
                DataPanel.figpanel.Title='Original LFPs';
               case 'SPKData'
                Infopanel=NeuroPlot.selectpanel;
                SPKChanneldescription=getfield(obj.SPKinfo,'channeldescription');
                SPKchannel=getfield(obj.SPKinfo,'channel');
                channeltype=unique(SPKChanneldescription);
                SPKnamelist=obj.SPKinfo.spikename;
                Infopanel= Infopanel.create([],'ChannelIndex',SPKnamelist,'typestring',SPKChanneldescription,'blacklist',true);
                addlistener(Infopanel,'blacklist','PostSet',@(~,~) obj.recordblacklist(Infopanel,'SPK'));
                DataPanel=NeuroPlot.figurecontrol(); 
                DataPanel=DataPanel.create([],'SPKdatapanel','raster');
                DataPanel.figpanel.Title='Raster Spikes';
               case 'EVTinfo'
                 Infopanel=NeuroPlot.selectpanel;
                 Eventlist=num2cell(obj.EVTinfo.eventselect);
                 Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
                 switch obj.EVTinfo.timetype
                     case 'timepoint'
                         Eventdescription=obj.EVTinfo.eventdescription;
                         Infopanel=Infopanel.create([],'EventIndex',Eventlist,'typestring',Eventdescription,'blacklist',true);
                     case 'timeduration'
                         for i=1:size(obj.EVTinfo.eventdescription,1)
                            Eventdescription{i}=cell2mat(obj.EVTinfo.eventdescription(i,:));
                         end
                         Infopanel=Infopanel.create([],'EventIndex',Eventlist,'typestring',Eventdescription,'blacklist',true,'multiselect','off');
                 end
                addlistener(Infopanel,'blacklist','PostSet',@(~,~) obj.recordblacklist(Infopanel,'EVT'));
            end
        end
        function [LFPdatatmp,lfpt]=readlfp(obj,EVTindex,Channelindex)
            % read the data from NeuroResult object in given event index
            % and channel index
            if strcmp(class(obj.LFPdata),'char')||strcmp(class(obj.LFPdata),'string') % for h5 file
                 EVTatt=h5info(obj.LFPdata,'/');
                d=1;
                 for i=1:length(EVTatt.Datasets)
                     if EVTindex(i)
                         c=1;
                         datatmpsize=h5info(obj.LFPdata,['/',EVTatt.Datasets(i).Name]);
                          lfpt=linspace(obj.EVTinfo.timestart(i),obj.EVTinfo.timestop(i),datatmpsize.Dataspace.Size(1));
                         try
                         currenttime=findobj('Tag','currenttime');
                         currentrange=findobj('Tag','timerange');
                         currenttime=str2num(currenttime.String);
                         currentrange=str2num(currentrange.String);
                         [~,index1]=min(abs(lfpt-(currenttime+currentrange(1))));
                         [~,index2]=min(abs(lfpt-(currenttime+currentrange(2))));
                         lfpt=lfpt(index1:index2);
                         index2=index2-index1+1;
                         catch
                             index1=1;index2=datatmpsize.Dataspace.Size(1);
                         end
                         for j=1:length(Channelindex)
                             if Channelindex(j)
                                LFPdatatmp(:,c,d)=h5read(obj.LFPdata,['/',EVTatt.Datasets(i).Name],[index1,j],[index2,1]);
                                c=c+1;
                             end
                         end
                         d=d+1;
                     end
                 end
            else % for matfile
            for i=1:length(obj.LFPdata)
                 LFPdatatmp(:,:,i)=detrend(obj.LFPdata{i},1);
            end
             LFPdatatmp=LFPdatatmp(:,Channelindex,EVTindex);
            end
            if strcmp(obj.EVTinfo.timetype,'timeduration')
                lfpt=linspace(obj.EVTinfo.timestart(EVTindex),obj.EVTinfo.timestop(EVTindex),size(LFPdatatmp,1));
            else 
                lfpt=linspace(obj.EVTinfo.timerange(1),obj.EVTinfo.timerange(2),size(LFPdatatmp,1));
            end
        end
        function [SPKdatatmp,spkt]=readspk(obj,EVTindex,Spikeindex)
            if strcmp(class(obj.SPKdata),'char')||strcmp(class(obj.SPKdata),'string') % for h5 file.
                 EVTatt=h5info(obj.SPKdata,'/');
                d=1;
                for i=1:length(EVTindex)
                    if EVTindex(i)
                    c=1;
                    for j=1:length(Spikeindex)
                        if Spikeindex(j)
                        SPKdatatmp{c,d}=h5read(obj.SPKdata,['/',num2str(j),'/',num2str(i)]);
                        spkt{c,d}=obj.SPKinfo.spkt{j,i};
                        c=c+1;
                       
                        end
                    end 
                    d=d+1;
                    end
                end
            else 
                SPKdatatmp=obj.SPKdata(Spikeindex,EVTindex);
                spkt=obj.SPKinfo.spkt(Spikeindex,EVTindex);
            end
            if strcmp(obj.EVTinfo.timetype,'timepoint')
                for i=1:size(SPKdatatmp,1)
                    for j=1:size(SPKdatatmp,2)
                        try
                            SPKdatatmp{i,j}=SPKdatatmp{i,j}-spkt{i,j}(1)+obj.EVTinfo.timerange(1);
                        end
                    end
                end
                spkt=spkt{1,1}-spkt{1,1}(1)+obj.EVTinfo.timerange(1);
            else % timeduration in the future;
                
            end
        end
        function plot(obj,typename,PanelManagement)
             % plot the LFPdata, SPKinfo and CALinfo
             EVTinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'EVTinfo'));
             EVTindex=EVTinfo{:}.getIndex;
             switch typename
                 case 'LFPData'
                     LFPinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'LFPinfo'));
                     Channelindex=LFPinfo{:}.getIndex;
                     [LFPdatatmp,lfpt]=obj.readlfp(EVTindex,Channelindex);
                     LFPdatatmp=detrend(LFPdatatmp);
                     PanelManagement.Panel{ismember(PanelManagement.Type,'LFPData')}.plot(lfpt,LFPdatatmp);
                 case 'SPKData'
                     %not work yet
                     SPKinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'SPKinfo'));
                     SPKindex=SPKinfo{:}.getIndex;
                     [SPKdatatmp,spkt]=obj.readspk(EVTindex,SPKindex);
                     PanelManagement.Panel{ismember(PanelManagement.Type,'SPKData')}.plot(spkt,SPKdatatmp,'black');
             end 
        end
        function obj=AverageSubject(obj,averagetype,averageparams)
            % select the given condition and average within subjects from each neuroresults
            % averagetype 
            % averageparams could be defined as 
            dataoutput=NeuroResult();
            for i=1:length(obj)
                for j=1:length(averagetype)
                if contains(averagetype{j}, {'LFPData','SPKData','CALData'})
                        obj(i)=eval(['obj(i).Average',averagetype{j},'(averageparams{j});']);
                elseif contains(averagetype{j},NeuroMethod.List)
                        tmpdata=eval(['obj(i).',averagetype{j},';']);
                        eval(['obj(i).',averagetype{j},'=tmpdata.AverageSubject(obj(i),averageparams{j});']);
                end
                end
            end
        end
        function obj=AverageLFPData(obj,averageparams)
            % the LFPdata (ERP type) would be averaged according channel, event dimension for each subject.
               if ~isempty(obj.LFPinfo.blackchannel)
%                 blackchannel=unique(cellfun(@(x) str2num(x),obj.LFPinfo.blackchannel,'UniformOutput',1));
%                 blackchannel=ismember(obj.LFPinfo.channelselect,blackchannel);
                    blackchannel=obj.LFPinfo.blackchannel;
               else
                    blackchannel=false(size(obj.LFPinfo.channelselect));
               end
              % obj.reservechannel=obj.LFPinfo.channelselect(~blackchannel);
                if ~isempty(obj.EVTinfo.blackevt)
%                     blackevt=unique(cellfun(@(x) str2num(x),obj.EVTinfo.blackevt,'UniformOutput',1));
%                     blackevt=ismember(obj.EVTinfo.eventselect,blackevt);  
                      blackevt=obj.EVTinfo.blackevt;
                else
                    blackevt=false(size(obj.EVTinfo.eventselect));
                end
               % obj.reserveevt=obj.EVTinfo.eventselect(~blackevt);
                channelname=averageparams.Channel;
                eventname=averageparams.Event;
                baselinetime=averageparams.Baseline;
                baselinecorrectmode=averageparams.Correctmode;
                if ischar(obj.LFPdata)||isstring(obj.LFPdata)
                    [LFPdata,lfpt]=obj.readlfp(true(length(blackevt),1),true(length(blackchannel),1));
                % LFPdata is the matrix time*channel*event.
                end
                if ~isempty(baselinetime)
                    LFPdata=basecorrect(LFPdata,lfpt,baselinetime(1),baselinetime(2),baselinecorrectmode);
                end
                if strcmp(lower(channelname), 'all') 
                    LFPdata=mean(LFPdata(:,~blackchannel,:),2);
                elseif strcmp(lower(channelname),'none')
                    LFPdata=LFPdata(:,~blackchannel,:);
                else
                    if strcmp(lower(channelname),'separate')
                         channelname=unique(obj.LFPinfo.channeldescription);
                    end
                    tmpS=[];
                    for j=1:length(channelname)
                        tmpS(:,j,:)=mean(LFPdata(:,ismember(obj.LFPinfo.channeldescription,channelname{j})&~blackchannel,:),2);
                    end
                    LFPdata=tmpS;
                end
                if strcmp(lower(eventname),'all')
                    LFPdata=mean(LFPdata(:,:,~blackevt),3);
                elseif strcmp(lower(eventname),'none')
                    LFPdata=LFPdata(:,:,~blackevt);
                else
                    if strcmp(lower(eventname),'separate')
                        eventname=unique(obj.EVTinfo.eventdescription);
                    end
                    tmpS=[];
                    for j=1:length(eventname)
                       tmpS(:,:,j)=mean(LFPdata(:,:,ismember(o.EVTinfo.eventdescription,eventname{j})&~blackevt),3);
                    end
                    LFPdata=tmpS;
                end
                obj.LFPdata=LFPdata;
            end
        function obj=AverageSPKData(obj,averageparams)
            % on working
        end
        function obj=AverageCALData(obj,averageparams)
            % on working
        end
        function bool = check(obj)
             bool=~isempty(obj.fileTag);
        end
    end         

    methods(Static)
        function obj = readNeuroResult(varargin)
            % generate the detail Result from the given path or file (not for NeuroData)
            if nargin==1 
                data=varargin{1}; 
                if ischar(data)||isstring(data)
                    if isfolder(data)% h5file directory
                        data=matfile(fullfile(varargin{1},'Datainfo.mat'),'Writable',true);
                    else % matfile format
                        data=matfile(data,'Writable',true);
                    end
                    varname=whos(data);
                    varname=struct2table(varname);
                    varname=varname.name;
                else
                    varname=fieldnames(data);
                end
                    obj=NeuroResult();
                    for i=1:length(varname)
                        %index=contains(subobjectname,varname{i},'IgnoreCase',true);
                        if ~isempty(eval(['data.',varname{i}]))
                             try
                                addprop(obj,varname{i});
                             end
                            try
                                eval(['obj.',varname{i},'=',varname{i},'(data.',varname{i},');']);
                            catch
                                eval(['obj.',varname{i},'=data.',varname{i},';']);
                            end
                        end
                    end
            end
        end
         function adjustNewPath(path)
             Datainfo=matfile(fullfile(path,'Datainfo.mat'),'Writable',true);
             varname=fieldnames(Datainfo);
             varlist={'LFPdata','SPKdata','CALdata'};
             vartype='Spectrogram';
             for i=1:length(varname)
                 try 
                     x=eval(['Datainfo.',varname{i}]);
                     if (isstring(x)||ischar(x))&& ismember(varname{i},varlist)
                         eval(['Datainfo.',varname{i},'=char(fullfile(path,"',varname{i},'.h5"));']);
                     elseif strcmp(class(x),vartype)
                         x.filename=fullfile(path,[varname{i},'.h5']);
                          eval(['Datainfo.',varname{i},'=x;']);
                     end
                 end
             end
         end        
end
    methods(Access=private)
        function obj=recordblacklist(obj,Infopanel,recordtype)
            global currentresult
            switch recordtype
                case 'EVT'
                    obj.EVTinfo.blackevt=Infopanel.blacklist;
                    currentresult.EVTinfo=obj.EVTinfo;
                case 'LFP'
                    obj.LFPinfo.blackchannel=Infopanel.blacklist;
                    currentresult.LFPinfo=obj.LFPinfo;
                case 'SPK'
                    obj.SPKinfo.blackspk=Infopanel.blacklist;
                    currentresult.SPKinfo=obj.SPKinfo;
            end
        end
    end
end
