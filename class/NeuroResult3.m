classdef NeuroResult < BasicTag & dynamicprops
    % neurodata & analysis results in the subjectlevel.
    properties
        LFPdata
        SPKdata
        LFPinfo
        EVTinfo
        SPKinfo
        CALdata
        CALinfo
        Subjectname
        fileTag
    end    
    properties(Access='protected')
        LFPfilename=[];
        SPKfilename=[];
        EVTfilename=[];
    end
    methods
        function obj = NeuroResult(varargin)
            if nargin==1
                 variablenames=fieldnames(varargin{1});
                 data=varargin{1};
            for i=1:length(variablenames)
                try
                eval(['obj.',variablenames{i},'=data.',variablenames{i}]);
                catch
                     obj.addprop(variablenames{i});
                     eval(['obj.',variablenames{i},'=data.',variablenames{i}]);
                end
            end
            end
        end
        function obj = ReadLFP(obj,LFPData,chselect,channeldescription,EVTinfo)
            if isempty(EVTinfo) % loading entire file!
             read_start=0; read_until=inf;
            else
             read_start=round(EVTinfo.timestart.*str2num(LFPData.Samplerate));
             read_until=round(EVTinfo.timestop.*str2num(LFPData.Samplerate));
            end
            if isempty(chselect) % load all channel
                chselect=1:str2num(LFPData.Channelnum);
            end
             for i=1:length(read_start)
                Data{i}=readmulti_frank(LFPData.Filename, str2num(LFPData.Channelnum), chselect, read_start(i), read_until(i));
                Data{i}=Data{i}.*str2num(LFPData.ADconvert);
             end
             
             obj.LFPdata=Data;
            if ~isempty(EVTinfo)
             switch EVTinfo.timetype
                 case 'timepoint'
                  obj.LFPinfo.time{1}=linspace(EVTinfo.timerange(1),EVTinfo.timerange(2),size(obj.LFPdata{1},1)); % for plot, time(:,i)=linspace(read_start(i),read_until(i),length(Data{1}));
                  obj.LFPinfo.datatype='splitting';
                 case 'duration'
                     obj.LFPinfo.datatype='splitting';
                     for i=1:length(read_start)
                        obj.LFPinfo.time{i}=linspace(EVTinfo.timestart(i),EVTinfo.timestop(i),size(obj.LFPdata{i},1));
                     end
             end
              obj.EVTinfo=EVTinfo;
            end
              obj.LFPinfo.channelselect=chselect;
              obj.LFPinfo.channeldescription=channeldescription;
              obj.LFPinfo.Fs=str2num(LFPData.Samplerate);
              obj.LFPinfo.blackchannel=[];
         end
        function obj = ReadSPK(obj,SPKData,channelselect,channeldescription,EVTinfo)
             switch SPKData.SortingType
                case 'KlustaKwik'
                    obj=obj.ReadSPK_KlustaKwik(SPKData,channelselect,channeldescription,EVTinfo);
                case 'Phy'
                    NeuroMethod.Checkpath('npy');
                    obj=obj.ReadSPK_Phy(SPKData,channelselect,channeldescription,EVTinfo);
                 case 'Inscopix'
                    obj=obj.ReadSPK_Inscopix(SPKData,EVTinfo);
             end
            obj.EVTinfo=EVTinfo;
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
        function obj = ReadSPK_KlustaKwik(obj,SPKData,channelselect,channeldescription,EVTinfo)
            %   loading data from the klustakwik sortingtype
            obj.SPKinfo.timerange=[EVTinfo.timestart,EVTinfo.timestop];
            obj.SPKinfo.Fs=SPKData.Samplerate;
            cd(SPKData.Filename);
            read_start=EVTinfo.timestart;
            read_until=EVTinfo.timestop;
            clusterfile=dir('*.clu.*');
            clusterfile=struct2table(clusterfile);
            clusterfile=clusterfile.name;
            if ischar(clusterfile)
                clusterfile1{1}=clusterfile;
                clusterfile=clusterfile1;
            end
            obj.SPKinfo.datatype='splitting';
            obj.SPKinfo.blackspk=[];
            obj.SPKdata=cell(1,1);
            spknumber=1;
            for i=1:length(clusterfile)
                clusterchannel=NeuroResult.SPKchannel(clusterfile{i});
                if logical(sum(ismember(channelselect,clusterchannel)))
                    spk_clu=importdata(clusterfile{i});
                    spk_clu=spk_clu(2:end);
                    spk_time=importdata([strrep(clusterfile{i},'.clu.','.res.')]);
                    spk_time=spk_time/str2num(SPKData.Samplerate);
                    clustername=unique(spk_clu);
                    clustername(clustername==0|clustername==1)=[];
                    clusternum=regexpi(clusterfile{i},'.clu.','split');
                    clusternum=clusternum{end};
                   for j=1:length(clustername)
                        obj.SPKinfo.spikename{spknumber}=['cluster',num2str(clusternum),'_',num2str(clustername(j))];
                        obj.SPKinfo.SPKchannel{spknumber}=clusterchannel;
                        obj.SPKinfo.SPKchanneldescription(spknumber)=unique(channeldescription(ismember(channelselect,clusterchannel)));
                         for k=1:length(read_start)
                            index=spk_clu==clustername(j)&spk_time>=read_start(k)&spk_time<=read_until(k);  
                            obj.SPKdata{spknumber,k}=spk_time(index);
                            if strcmp(EVTinfo.timetype,'timepoint')
                                obj.SPKdata{spknumber,k}=obj.SPKdata{spknumber,k}-read_start(k);
                            end
                         end
                      spknumber=spknumber+1;   
                   end
                end
            end
        end
        function obj = ReadSPK_Phy(obj,SPKData,channelselect,channeldescription,EVTinfo)
            obj.SPKinfo.Fs=str2num(SPKData.Samplerate);
            cd(SPKData.Filename);
            spk_clu=readNPY('spike_clusters.npy');
            spk_time=readNPY('spike_times.npy');
            spk_time=double(spk_time)/obj.SPKinfo.Fs;
            channel_shanks=readNPY('channel_shanks.npy');
            channel_map=readNPY('channel_map.npy')+1;
            [cluster_info,header,raw]=tsvread('cluster_info.tsv');
            group_index=strcmp(header,'group');
            shank_index=strcmp(header,'sh');
            channel_index=strcmp(header,'ch');
            id=strcmp(header,'id');
            clusternumber=unique(channel_shanks);
            obj.SPKinfo.datatype='splitting';
            obj.SPKinfo.blackspk=[];
            obj.SPKdata=cell(1,1);
            read_start=EVTinfo.timestart;
            read_until=EVTinfo.timestop;
            spknumber=1;
            for i=1:length(clusternumber)
                if logical(sum(ismember(channelselect,channel_map(channel_shanks==clusternumber(i))+1)))
                    clustername=cluster_info((cluster_info(:,shank_index)==clusternumber(i))&strcmp(raw(:,group_index),'good'),id);
                    for j=1:length(clustername)
                        obj.SPKinfo.name{spknumber}=['cluster',num2str(clusternumber(i)),'_',num2str(clustername(j))];
                        clusterchannel=cluster_info(cluster_info(:,id)==clustername(j),channel_index);
                        obj.SPKinfo.channel{spknumber}=clusterchannel+1;
                        obj.SPKinfo.channeldescription(spknumber)=unique(channeldescription(ismember(channelselect,clusterchannel+1)));
                         for k=1:length(read_start)
                            index=spk_clu==clustername(j)&spk_time>=read_start(k)&spk_time<=read_until(k);  
                            obj.SPKdata{spknumber,k}=spk_time(index);
                              if strcmp(EVTinfo.timetype,'timepoint')
                                obj.SPKdata{spknumber,k}=obj.SPKdata{spknumber,k}-read_start(k);
                            end
                         end
                         spknumber=spknumber+1;
                    end
                end
            end
        end
        function obj = ReadSPKproperties(obj,cellinfopath)
            % get the spike properties from the cell_metrics.cellinfo.mat
            % generated from CellExplorer.
              if exist(fullfile(cellinfopath,[obj.Subjectname,'.cell_metrics.cellinfo.mat']))
                cellinfo=matfile(fullfile(cellinfopath,[obj.Subjectname,'.cell_metrics.cellinfo.mat']));
                cellinfo=getfield(cellinfo,'cell_metrics');
                cellinfospikename=arrayfun(@(x,y) ['cluster',num2str(x),'_',num2str(y)],cellinfo.shankID,cellinfo.cluID,'UniformOutput',0);
                variable={'putativeCellType','firingRate','troughToPeak'};% maybe add all fieldnames of cellinfo in the further?
                index= cellfun(@(x) cellfun(@(y) ~isempty(regexpi(y,['\<',x,'\>'],'match')),cellinfospikename,'UniformOutput',1),obj.SPKinfo.spikename,'UniformOutput',0);
                try
                    index=cellfun(@(x) find(x==1),index,'UniformOutput',1);
                catch
                    error('the cellinfo mat is different from the spike data, should recal the CellExplorer using current clustering result');
                end
                 for j=1:length(variable)
                     eval(['obj.SPKinfo.',variable{j},'=cellinfo.',variable{j},'(index);']);
                 end
              end
        end
        function SaveData(obj,varargin)
            % transform the savemat as hdf5
            if nargin==4
                filepath=varargin{1};
                filename=varargin{2};
                variablename=varargin{3};
                savemat=matfile(fullfile(filepath,[filename,'.mat']),'Writable',true);
                eval(['savemat.',variablename{:},'=obj.NeuroResult2Struct([]);']);       
            else
                data=varargin{1};
                obj.NeuroResult2Struct(data);
            end
        end
        function data=NeuroResult2Struct(obj,data)
           variablenames=fieldnames(obj);
            for i=1:length(variablenames)
                eval(['data.',variablenames{i},'=obj.',variablenames{i}]);
            end
        end
        function obj=CombinedSubjects(obj,datafilelist)
              % combined the NeuroResult among Subjects level
%               obj.EVTinfo.timestart=[];obj.EVTinfo.timestop=[];
%               for i=1:length(datafilelist)
%                   tmpmat=matfile(datafilelist);
%                  obj.LFPdata=cat(2,obj.LFPdata,tmpmat.LFPdata;
%                  tmpEVTinfo=tmpmat.EVTinfo;
%                  obj.EVTinfo.timestart=cat(2,obj.EVTinfo.timestart,tmpEVTinfo.timestart);
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

                % data.Subjectname=cat(2,data.Subjectname,repmat({obj(i).Subjectname},[1,length(obj(i).SPKinfo.SPKchanneldescription)]));
            end
         end
        function obj=Split2Splice(obj)
            % from Splitting mode to Splicing mode, the epoches were spliced.
            % in this transformation , the trial number is 1.
            try
            if strcmp(obj.LFPinfo.datatype,'splitting')
                LFPdatatmp=[];
                for i=1:length(obj.LFPdata) 
                    LFPdatatmp=cat(1,LFPdatatmp,obj.LFPdata{i});
                    obj.LFPinfo.spliceindex(i)=length(LFPdatatmp); % get the index of segments
                end
                obj.LFPdata={LFPdatatmp};
                obj.LFPinfo.datatype='splicing';
            end
            end
            try
            if strcmp(obj.SPKinfo.datatype,'splitting')   
                SPKtimecorretion=cumsum(obj.EVTinfo.timestop-obj.EVTinfo.timestart);
                SPKtimecorretion=[0;SPKtimecorretion];
                for j=1:size(obj.SPKdata,1)
                    SPKdatatmp{j}=[];
                    for i=1:size(obj.SPKdata,2)
                        SPKdatatmp{j}=cat(1,SPKdatatmp{j},obj.SPKdata{j,i}-obj.EVTinfo.timestart(i)+SPKtimecorretion(i));
                    end
                end
                obj.SPKinfo.datatype='splicing'; 
                obj.SPKdata=SPKdatatmp;
                obj.SPKinfo.spliceindex=SPKtimecorrection;
            end
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
        function [Infopanel, DataPanel]=createplot(obj,variablename)
         import NeuroPlot.selectpanel NeuroPlot.figurecontrol
            % generate the panels to plot LFPdata, SPKdata,CALdata and EVTinfo
%             Infopanel=uix.Panel();DataPanel=uix.BoxPanel();
            switch variablename
               case 'LFPdata'
                Infopanel=NeuroPlot.selectpanel;
                Infopanel=Infopanel.create('listtitle',{'Channelnumber'},'listtag',{'ChannelIndex'},'typeTag',{'Channeltype'});
                Channeldescription=getfield(obj.LFPinfo,'channeldescription');
                Channellist=num2cell(obj.LFPinfo.channelselect);
                Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
                Infopanel=Infopanel.assign('liststring',Channellist,'listtag',{'ChannelIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',obj.LFPinfo.blackchannel);
                DataPanel=NeuroPlot.figurecontrol();
                if strcmp(obj.EVTinfo.timetype,'timepoint')
                    DataPanel=DataPanel.create('plot-baseline',0);
                else
                    DataPanel=DataPanel.create('plot',0);
                end
                DataPanel.figpanel.Title='Original LFPs';
               case 'SPKdata'
                Infopanel=NeuroPlot.selectpanel;
                Infopanel= Infopanel.create('listtitle',{'Channelnumber'},'listtag',{'ChannelIndex'},'typeTag',{'Channeltype'});
                SPKChanneldescription=getfield(obj.SPKinfo,'SPKchanneldescription');
                SPKnamelist=obj.SPKinfo.spikename;
                Infopanel=Infopanel.assign('liststring',SPKnamelist,'listtag',{'ChannelIndex'},'typetag',{'Channeltype'},'typestring',SPKChanneldescription,'blacklist',obj.SPKinfo.blackspk);   
                DataPanel=NeuroPlot.figurecontrol(); 
                DataPanel=DataPanel.create('raster',0);
                DataPanel.figpanel.Title='Raster Spikes';
               case 'EVTinfo'
                 Infopanel=NeuroPlot.selectpanel;
                 Infopanel=Infopanel.create('listtitle',{'Eventnumber'},'listtag',{'EventIndex'},'typeTag',{'Eventtype'});  
                 Eventdescription=obj.EVTinfo.eventdescription;
                 Eventlist=num2cell(obj.EVTinfo.eventselect);
                 Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
                 Infopanel=Infopanel.assign('liststring',Eventlist,'listtag',{'EventIndex'},'typetag',{'Eventtype'},'typestring',Eventdescription,'blacklist',obj.EVTinfo.blackevt);
            end
         end
         function plot(obj,typename,PanelManagement)
             % plot the LFPdata, SPKinfo and CALinfo
             EVTinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'EVTinfo'));
             switch typename
                 case 'LFPdata'
                     LFPinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'LFPinfo'));
                     for i=1:length(obj.LFPdata)
                         LFPdatatmp(:,:,i)=obj.LFPdata{i};
                     end
                     LFPdatatmp=LFPdatatmp(:,LFPinfo{:}.getIndex('ChannelIndex'),EVTinfo{:}.getIndex('EventIndex'));
                     PanelManagement.Panel{ismember(PanelManagement.Type,'LFPdata')}.plot(linspace(obj.EVTinfo.timerange(1),obj.EVTinfo.timerange(2),size(LFPdatatmp,1)),LFPdatatmp);
                 case 'SPKdata'
                     SPKinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'SPKinfo'));
             end
         end
    end
    methods(Static)
         function clusterchannel=SPKchannel(clusterfile)
                clusterchannel=[];
                    try
                    clunumber=regexpi(clusterfile,'.clu.','split');
                    xmlfilename=[clunumber{1},'.xml'];
                    xml=xml_read(xmlfilename);  
                    clusterchannel=xml.spikeDetection.channelGroups.group(str2num(clunumber{2})).channels.channel;
                    clusterchannel=cellfun(@(x) x+1,clusterchannel,'UniformOutput',1);
                    catch
                        clusterchannel=clusterchannel+1;
                    end
         end
         
end

end
