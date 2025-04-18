classdef SPKData< BasicTag
     properties
        SortingType=[];
        Filename=[];
        Samplerate=[];
        fileTag=[];
    end
    methods (Access='public')
        function obj =  fileappend(obj)
            % support the .clu. file from KlustaKwik and .npy file from Phy
            Sortinglist={'KlustaKwik','Phy','Inscopix'};
            index=listdlg('PromptString','choose the SoringType of SPKfile','ListString',Sortinglist);
            obj.SortingType=Sortinglist{index};
            spikepath=uigetdir('Please select the Path of the sorted files');
            obj.Filename=spikepath;
        end
        function obj = initialize(obj, Samplerate)
            obj.Samplerate=Samplerate;
        end
        function obj = Taginfo(obj, Tagname,informationtype, information)
            obj = Taginfo@BasicTag(obj,Tagname,informationtype,information);
        end
        function bool = Tagchoose(obj,Tagname, informationtype, information)
             bool = Tagchoose@BasicTag(obj,Tagname,informationtype,information);
         end          
       function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
             [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                  [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
       end
       function bool = check(obj)
             bool=~isempty(obj.SortType)&~isempty(obj.Samplerate)&~isempty(obj.fileTag);
       end
       function neuroresult = Readdata(obj,neuroresult,channelselect,channeldescription,EVTinfo)
           if isempty(neuroresult) 
            neuroresult=NeuroResult();
           end
            propvars={'SPKinfo','SPKdata','EVTinfo'};
            for i=1:length(propvars)
                try
                eval(['addprop(neuroresult,''',propvars{i},''');']);
                end
            end
           switch obj.SortingType
                case 'KlustaKwik'
                    neuroresult=obj.ReadSPK_KlustaKwik(neuroresult,channelselect,channeldescription,EVTinfo);
                case 'Phy'
                    NeuroMethod.Checkpath('npy'); % need mat npy toolbox
                    neuroresult=obj.ReadSPK_Phy(neuroresult,channelselect,channeldescription,EVTinfo);
           end
       end 
        function neuroresult = ReadSPK_KlustaKwik(obj,neuroresult,channelselect,channeldescription,EVTinfo)
            %   loading data from the klustakwik sortingtype
            SPKinfo.timerange=[EVTinfo.timestart,EVTinfo.timestop];
            SPKinfo.Fs=obj.Samplerate;
            cd(obj.Filename);
            read_start=EVTinfo.timestart;
            read_until=EVTinfo.timestop;
            clusterfile=dir([obj.Filename,'/*.clu.*']);
            clusterfile=struct2table(clusterfile);
            clusterfile=clusterfile.name;
            if ischar(clusterfile)
                clusterfile1{1}=clusterfile;
                clusterfile=clusterfile1;
            end
            SPKinfo.datatype='splitting';
            SPKinfo.blackspk=[];
            SPKdata=cell(1,1);
            spknumber=1;
            for i=1:length(clusterfile)
                clusterchannel=SPKData.SPKchannel(clusterfile{i});
                if logical(sum(ismember(channelselect,clusterchannel)))
                    spk_clu=importdata(clusterfile{i});
                    spk_clu=spk_clu(2:end);
                    spk_time=importdata([strrep(clusterfile{i},'.clu.','.res.')]);
                    spk_time=spk_time/str2num(obj.Samplerate);
                    clustername=unique(spk_clu);
                    clustername(clustername==0|clustername==1)=[];
                    clusternum=regexpi(clusterfile{i},'.clu.','split');
                    clusternum=clusternum{end};
                   for j=1:length(clustername)
                        SPKinfo.spikename{spknumber}=['cluster',num2str(clusternum),'_',num2str(clustername(j))];
                        SPKinfo.SPKchannel{spknumber}=clusterchannel;
                        SPKinfo.SPKchanneldescription(spknumber)=unique(channeldescription(ismember(channelselect,clusterchannel)));
                         for k=1:length(read_start)
                            index=spk_clu==clustername(j)&spk_time>=read_start(k)&spk_time<=read_until(k);  
                            SPKdata{spknumber,k}=spk_time(index);
                            if strcmp(EVTinfo.timetype,'timepoint')
                                SPKdata{spknumber,k}=SPKdata{spknumber,k}-read_start(k);
                            end
                         end
                      spknumber=spknumber+1;   
                   end
                end
            end
            neuroresult.SPKinfo=SPKinfo;
            neuroresult.EVTinfo=EVTinfo;
            neuroresult.SPKdata=SPKdata;
        end
        function neuroresult = ReadSPK_Phy(obj,neuroresult,channelselect,channeldescription,EVTinfo)
            SPKinfo.Fs=str2num(obj.Samplerate);
            cd(obj.Filename);
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
            SPKinfo.datatype='splitting';
            SPKinfo.blackspk=[];
            SPKdata=cell(1,1);
            read_start=EVTinfo.timestart;
            read_until=EVTinfo.timestop;
            spknumber=1;
            for i=1:length(clusternumber)
                if logical(sum(ismember(channelselect,channel_map(channel_shanks==clusternumber(i))+1)))
                    clustername=cluster_info((cluster_info(:,shank_index)==clusternumber(i))&strcmp(raw(:,group_index),'good'),id);
                    for j=1:length(clustername)
                        SPKinfo.name{spknumber}=['cluster',num2str(clusternumber(i)),'_',num2str(clustername(j))];
                        clusterchannel=cluster_info(cluster_info(:,id)==clustername(j),channel_index);
                        SPKinfo.channel{spknumber}=clusterchannel+1;
                        SPKinfo.channeldescription(spknumber)=unique(channeldescription(ismember(channelselect,clusterchannel+1)));
                         for k=1:length(read_start)
                            index=spk_clu==clustername(j)&spk_time>=read_start(k)&spk_time<=read_until(k);  
                            SPKdata{spknumber,k}=spk_time(index);
                              if strcmp(EVTinfo.timetype,'timepoint')
                                SPKdata{spknumber,k}=SPKdata{spknumber,k}-read_start(k);
                            end
                         end
                         spknumber=spknumber+1;
                    end
                end
            end
            neuroresult.SPKinfo=SPKinfo;
            neuroresult.EVTinfo=EVTinfo;
            neuroresult.SPKdata=SPKdata;
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