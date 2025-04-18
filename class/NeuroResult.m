classdef NeuroResult < BasicTag & dynamicprops
    % neurodata & analysis results in the subjectlevel.
    properties
         fileTag
         Subjectname
         Filename
    end 
    methods
        function obj = fileappend(obj,filepath)
            obj.Filename=filepath;
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
                if ischar(varargin{1})
                    if isfolder(varargin{1})% h5file directory
                  varargin{1}=matfile(fullfile(varargin{1},'Datainfo.mat'),'Writable',true);
                  obj=NeuroResult();
                    else % matfile format
                    varargin{1}=matfile(varargin{1},'Writable',true);
                    end
                end
                variablenames=fieldnames(varargin{1});
                try
                    invalidindex=ismember(variablenames,'Properties');
                    variablenames(invalidindex)=[];
                end
                data=varargin{1};
                for i=1:length(variablenames)
                try
                eval(['obj.',variablenames{i},'=data.',variablenames{i},';']);
                catch
                     obj.addprop(variablenames{i});
                     eval(['obj.',variablenames{i},'=data.',variablenames{i},';']);
                end
                end
            end
        end
        function data = NeuroResult2Struct(obj)
            variablename=fieldnames(obj);
            for i=1:length(variablename)
                eval(['data.',variablename{i},'=obj.',variablename{i},';']);
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
        function SaveData(obj,savepath,savefilename,format,varname)
            % transform the savemat as hdf5
             variablenames=fieldnames(obj);
            switch format
                case 'matfile'
                    savemat=matfile(fullfile(savepath,[savefilename,'.mat']),'Writable',true);
                    if isempty(varname)||isempty(varname{:})
                    for i=1:length(variablenames)
                        eval(['savemat.',variablenames{i},'=obj.',variablenames{i},';']); 
                    end
                    else
                     for i=1:length(variablenames)
                        eval(['tmp.',variablenames{i},'=obj.',variablenames{i},';']); 
                     end
                     eval(['savemat.',varname{:},'=tmp;']);
                    end
                case 'hdf5'
                    if exist(fullfile(savepath,savefilename,varname))
                        warning(['the result: ',fullfile(savepath,savefilename,varname),'is exist, current result could not be saved']);
                    else
                    mkdir(fullfile(savepath,savefilename,varname));
                    Datafile=matfile(fullfile(savepath,savefilename,varname,'Datainfo.mat'),'Writable',true);
                    datafile={'LFPdata','SPKdata','CALdata'};
                    if isfield(obj,'LFPdata') && ~isempty(obj.LFPdata)
                        LFPdatafile=fullfile(savepath,savefilename,varname,'LFPdata.h5');
                        for i=1:length(obj.LFPdata)
                            h5create(LFPdatafile,['/',num2str(i)],size(obj.LFPdata{i}));
                            h5write(LFPdatafile,['/',num2str(i)],obj.LFPdata{i});
                        end
                        obj.LFPdata=LFPdatafile;
                    end
                    if isfield(obj,'SPKdata') && ~isempty(obj.SPKdata)
                        SPKdatafile=fullfile(savepath,savefilename,varname,'SPKdata.h5');
                        for i=1:size(obj.SPKdata,2)
                            for j=1:size(obj.SPKdata,1)
                            h5create(SPKdatafile,['/',num2str(j),'/',num2str(i)],size(obj.SPKdata{i,j}));
                            h5write(SPKdatafile,['/',num2str(j),'/',num2str(i)],obj.SPKdata{i,j});
                            end
                        end
                        obj.SPKdata=SPKdatafile;
                    end
                    if isfield(obj,'CALdata') && ~isempty(obj.CALdata)
                        CALdatafile=fullfile(savepath,savefilename,varname,'CALdata.h5');
                        for i=1:length(obj.CALdata)
                            h5create(LFPdatafile,['/',num2str(i)],size(obj.CALdata{i}));
                            h5write(LFPdatafile,['/',num2str(i)],obj.CALdata{i});
                        end
                        obj.CALdata=CALdatafile;
                    end
                    for i=1:length(variablenames)
                        if eval(['ismember(class(obj.',variablenames{i},'),NeuroMethod.List)'])
                           Class=eval(['class(obj.',variablenames{i},');']);
                           eval(['obj.',variablenames{i},'.saveh5(fullfile(savepath,savefilename,varname,''',variablenames{i},'.h5''));']);
                           eval(['obj.',variablenames{i},'=',Class,'(fullfile(savepath,savefilename,varname,[variablenames{i},''.h5'']));']);
                        end
                        eval(['Datafile.',variablenames{i},'=obj.',variablenames{i},';']);
                    end    
                    end
                end
        end
        function data=CollectSpikeVariables(obj,Variablenames,catdimensions)
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

                data.Subjectname=cat(2,data.Subjectname,repmat({obj(i).Subjectname},[1,length(obj(i).SPKinfo.SPKchanneldescription)]));
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
                Infopanel=Infopanel.create('listtitle',{'Channelnumber'},'listtag',{'ChannelIndex'},'typeTag',{'Channeltype'});
                Channeldescription=getfield(obj.LFPinfo,'channeldescription');
                Channellist=num2cell(obj.LFPinfo.channelselect);
                Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
                Infopanel=Infopanel.assign('liststring',Channellist,'listtag',{'ChannelIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',obj.LFPinfo.blackchannel);
                tmpobj=findobj(Infopanel.mainpanel,'Tag','blacklist');
                addlistener(tmpobj,'String','PostSet',@(~,~) obj.recordblacklist(Infopanel,'LFP'));
                DataPanel=NeuroPlot.figurecontrol();
                DataPanel=DataPanel.create('plot-baseline',0);
                DataPanel.figpanel.Title='Original LFPs';
               case 'SPKData'
                Infopanel=NeuroPlot.selectpanel;
                Infopanel= Infopanel.create('listtitle',{'Channelnumber'},'listtag',{'SpikeIndex'},'typeTag',{'Channeltype'});
                SPKChanneldescription=getfield(obj.SPKinfo,'SPKchanneldescription');
                SPKnamelist=obj.SPKinfo.spikename;
                Infopanel=Infopanel.assign('liststring',SPKnamelist,'listtag',{'SpikeIndex'},'typetag',{'Channeltype'},'typestring',SPKChanneldescription,'blacklist',obj.SPKinfo.blackspk);   
                tmpobj=findobj(Infopanel.mainpanel,'Tag','blacklist');
                addlistener(tmpobj,'String','PostSet',@(~,~) obj.recordblacklist(Infopanel,'SPK'));
                DataPanel=NeuroPlot.figurecontrol(); 
                DataPanel=DataPanel.create('raster',0);
                DataPanel.figpanel.Title='Raster Spikes';
               case 'EVTinfo'
                 Infopanel=NeuroPlot.selectpanel;
                 switch obj.EVTinfo.timetype
                     case 'timepoint'
                        Infopanel=Infopanel.create('listtitle',{'Eventnumber'},'listtag',{'EventIndex'},'typeTag',{'Eventtype'});  
                        Eventdescription=obj.EVTinfo.eventdescription;
                     case 'timeduration'
                         Infopanel=Infopanel.create('listtitle',{'Eventnumber'},'listtag',{'EventIndex'},'typeTag',{'Eventtype'},'Multiselect','off');  
                         for i=1:size(obj.EVTinfo.eventdescription,1)
                            Eventdescription{i}=cell2mat(obj.EVTinfo.eventdescription(i,:));
                         end
                 end
                 Eventlist=num2cell(obj.EVTinfo.eventselect);
                 Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
                 Infopanel=Infopanel.assign('liststring',Eventlist,'listtag',{'EventIndex'},'typetag',{'Eventtype'},'typestring',Eventdescription,'blacklist',obj.EVTinfo.blackevt);
                 tmpobj=findobj(Infopanel.mainpanel,'Tag','blacklist');
                 addlistener(tmpobj,'String','PostSet',@(~,~) obj.recordblacklist(Infopanel,'EVT'));
            end
        end
        function [LFPdatatmp,lfpt]=readlfp(obj,EVTindex,Channelindex)
            % read the data from NeuroResult object in given event index
            % and channel index
            if strcmp(class(obj.LFPdata),'char') % for h5 file
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
            if strcmp(class(obj.SPKdata),'char') % for h5 file.
                % on working
            else % for matfile
            for i=1:size(obj.SPKdata,1) % for each spike
                if EVTindex(i)
                    SPKdatatmp(:,:,i)=detrend(obj.LFPdata{i},1);
                end
            end
             LFPdatatmp=LFPdatatmp(:,Channelindex,EVTindex);
            end
            if strcmp(obj.EVTinfo.timetype,'timeduration')
                lfpt=linspace(obj.EVTinfo.timestart(EVTindex),obj.EVTinfo.timestop(EVTindex),size(LFPdatatmp,1));
            else 
                lfpt=linspace(obj.EVTinfo.timerange(1),obj.EVTinfo.timerange(2),size(LFPdatatmp,1));
            end
        end
        function plot(obj,typename,PanelManagement)
             % plot the LFPdata, SPKinfo and CALinfo
             EVTinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'EVTinfo'));
             EVTindex=EVTinfo{:}.getIndex('EventIndex');
             switch typename
                 case 'LFPData'
                     LFPinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'LFPinfo'));
                     Channelindex=LFPinfo{:}.getIndex('ChannelIndex');
                     [LFPdatatmp,lfpt]=obj.readlfp(EVTindex,Channelindex);
                     LFPdatatmp=detrend(LFPdatatmp);
                     PanelManagement.Panel{ismember(PanelManagement.Type,'LFPData')}.plot(lfpt,LFPdatatmp);
                 case 'SPKData'
                     %not work yet
                     SPKinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'SPKinfo'));
                     SPKindex=SPKinfo{:}.getIndex('ChannelIndex');
                     [SPKdatatmp,spkt]=obj.readspk(EVTindex,SPKindex);
                     PanelManagement.Panel{ismember(PanelManagement.Type,'SPKData')}.plot(spkt,SPKdatatmp);
             end 
        end
        function obj=AverageSubject(obj,averagetype,averageparams)
            % select the given condition and average within subjects from each neuroresults
            % averagetype 
            % averageparams could be defined as 
            for i=1:length(obj)
                if ismember(averagetype, {'LFPData','SPKData','CALData'})
                        obj(i)=eval(['obj(i).Average',averagetype,'(averageparams);']);
                elseif ismember(class(eval(['obj(i).',averagetype])),NeuroMethod.List)
                        tmpdata=eval(['obj(i).',averagetype,';']);
                        eval(['obj(i).',averagetype,'=tmpdata.AverageSubject(obj(i),averageparams);']);
                end
            end
        end
        function obj=AverageLFPData(obj,averageparams)
            % the LFPdata (ERP type) would be averaged according channel, event dimension for each subject.
               if ~isempty(obj.LFPinfo.blackchannel)
                blackchannel=unique(cellfun(@(x) str2num(x),obj.LFPinfo.blackchannel,'UniformOutput',1));
                blackchannel=ismember(obj.LFPinfo.channelselect,blackchannel);
               else
                    blackchannel=false(size(obj.LFPinfo.channelselect));
               end
              % obj.reservechannel=obj.LFPinfo.channelselect(~blackchannel);
                if ~isempty(obj.EVTinfo.blackevt)
                    blackevt=unique(cellfun(@(x) str2num(x),obj.EVTinfo.blackevt,'UniformOutput',1));
                    blackevt=ismember(obj.EVTinfo.eventselect,blackevt);
                else
                    blackevt=false(size(obj.EVTinfo.eventselect));
                end
               % obj.reserveevt=obj.EVTinfo.eventselect(~blackevt);
                channelname=averageparams.Channel;
                eventname=averageparams.Event;
                baselinetime=averageparams.Baseline;
                baselinecorrectmode=averageparams.Correctmode;
                if ischar(obj.LFPdata)
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
                        tmpS(:,j,:)=mean(LFPdata(:,ismember(obj.LFPinfo.channeldescription,channelname{j})&~blackchannel',:),2);
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
                       tmpS(:,:,j)=mean(LFPdata(:,:,ismember(obj.EVTinfo.eventdescription,eventname{j})&~blackevt),3);
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
            blacklist=findobj(Infopanel.mainpanel,'Tag','blacklist');
            switch recordtype
                case 'EVT'
                    obj.EVTinfo.blackevt=blacklist.String;
                    currentresult.EVTinfo=obj.EVTinfo;
                case 'LFP'
                    obj.LFPinfo.blackchannel=blacklist.String;
                    currentresult.LFPinfo=obj.LFPinfo;
                case 'SPK'
                    obj.SPKinfo.blackspk=blacklist.String;
                    currentresult.SPKinfo=obj.SPKinfo;
            end
        end
    end
end
