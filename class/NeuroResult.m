classdef NeuroResult < BasicTag & dynamicprops
    properties
        LFPdata
        SPKdata
        LFPinfo
        EVTinfo
        SPKinfo
        Subjectname
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
             read_start=round(EVTinfo.timestart.*str2num(LFPData.Samplerate));
             read_until=round(EVTinfo.timestop.*str2num(LFPData.Samplerate));
             for i=1:length(read_start)
                Data{i}=readmulti_frank(LFPData.Filename, str2num(LFPData.Channelnum), chselect, read_start(i), read_until(i));
                Data{i}=Data{i}.*str2num(LFPData.ADconvert);
             end
             obj.LFPinfo.datatype='splitting';
             obj.LFPdata=Data;
             switch EVTinfo.timetype
                 case 'timepoint'
                  obj.LFPinfo.time{1}=linspace(EVTinfo.timerange(1),EVTinfo.timerange(2),size(obj.LFPdata{1},1)); % for plot, time(:,i)=linspace(read_start(i),read_until(i),length(Data{1}));
                 case 'duration'
                     obj.LFPinfo.datatype='splitting';
                     for i=1:length(read_start)
                        obj.LFPinfo.time{i}=linspace(EVTinfo.timestart(i),EVTinfo.timestop(i),size(obj.LFPdata{i},1));
                     end
             end
              obj.EVTinfo=EVTinfo;
              obj.LFPinfo.channelselect=chselect;
              obj.LFPinfo.channeldescription=channeldescription;
              obj.LFPinfo.Fs=str2num(LFPData.Samplerate);
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
            obj.SPKinfo.name=[];
            obj.SPKinfo.channel=[];
            obj.SPKinfo.datatype='splitting';
            obj.SPKinfo.channeldescription=cell(1,1);
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
            obj.SPKinfo.name=[];
            obj.SPKinfo.channel=[];
            obj.SPKinfo.channeldescription=cell(1,1);
            obj.SPKinfo.datatype='splitting';
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
        function data=NeuroResult2Struct(obj)
            variablenames=fieldnames(obj);
            for i=1:length(variablenames)
                eval(['data.',variablenames{i},'=obj.',variablenames{i}]);
            end
        end
        function obj=CombinedSubjectsSpikes(obj,datapath)
              % combined the NeuroResult among Subjects level
              % for spike format, it extract each spike and spike related metadata from all Subjects
              % and save each spike format file as a mat file named
              % {spikesubject}_{spikename}.mat and the Spikeinfo.mat file. 
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
            if strcmp(obj.LFPinfo.datatype,'splitting')
            try
                LFPdatatmp=[];
                for i=1:length(obj.LFPdata) 
                    LFPdatatmp=cat(1,LFPdatatmp,obj.LFPdata{i});
                    obj.LFPinfo.spliceindex(i)=length(LFPdatatmp); % get the index of segments
                end
                obj.LFPdata={LFPdatatmp};
                obj.LFPinfo.datatype='splicing';
            end
            end
            if strcmp(obj.SPKinfo.datatype,'splitting')
            try
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


