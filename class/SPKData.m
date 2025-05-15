classdef SPKData< BasicTag
     properties
        SortingType=[];
        Filename=[];
        Samplerate=[];
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
       function neuroresult = Extractdata(obj,neuroresult,channelselect,channeldescription,EVTinfo)
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
                    [SPKinfo,SPKdata]=obj.ReadSPK_KlustaKwik(channelselect,channeldescription,EVTinfo.timestart,EVTinfo.timestop,EVTinfo.timetype);
                case 'Phy'
                    NeuroMethod.Checkpath('npy'); % need mat npy toolbox
                    [SPKinfo,SPKdata]=obj.ReadSPK_Phy(channelselect,channeldescription,EVTinfo.timestart,EVTinfo.timestop,EVTinfo.timetype);
           end
            neuroresult.SPKinfo=SPKinfo;
            neuroresult.EVTinfo=EVTinfo;
            neuroresult.SPKdata=SPKdata;
       end 
       function [SPKinfo,SPKdata] = ReadSPK_KlustaKwik(obj,channelselect,channeldescription,timestart,timestop,timetype)
            %   loading data from the klustakwik sortingtype
            SPKinfo.timerange=[EVTinfo.timestart,EVTinfo.timestop];
            SPKinfo.Fs=obj.Samplerate;
            cd(obj.Filename);
            read_start=timestart;
            read_until=timestop;
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
                            if strcmp(timetype,'timepoint')
                                SPKdata{spknumber,k}=SPKdata{spknumber,k}-read_start(k);
                            end
                         end
                      spknumber=spknumber+1;   
                   end
                end
            end
        end
       function [SPKinfo,SPKdata] = ReadSPK_Phy(obj,channelselect,channeldescription,timestart,timestop,timetype)
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
            read_start=timestart;
            read_until=timestop;
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
                              if strcmp(timetype,'timepoint')
                                SPKdata{spknumber,k}=SPKdata{spknumber,k}-read_start(k);
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
       function hbox=gui_plot(obj,parent)
             % generate gui plot of LFPdata files in a BoxPanel 
             % plot from NeuroData instead of NeuroResult
             % contains the channelselectpanel and LFP plot panel with timebar
                hbox = uix.VBox( 'Parent', parent );
                for i=1:length(obj) % for multiple lfp files within the subject
                % Add three box panels.
                boxPanels(i) = uix.BoxPanel( 'Parent', hbox,'UserData',i,'Title',obj(i).Filename);
                tmppanel1=uix.HBoxFlex('Parent',boxPanels(i)); % left is the channellist, right is the figure axes and timebar      
                channelpanel(i)=NeuroPlot.selectpanel();
                Channellist=arrayfun(@(x) num2str(x),1:str2num(obj.Channelnum),'UniformOutput',0);
                channelpanel(i).create(tmppanel1,strcat('channelpanel_',obj(i).Filename),Channellist);
                timerange=obj.getSPKTimerange();
                timestamps=linspace(0,timerange,timerange)/str2num(obj.Samplerate);
                figurecontrol(i)=NeuroPlot.figurecontrol();
                figurecontrol(i)=figurecontrol(i).create(tmppanel1,strcat('figurepanel_',obj(i).Filename),'raster');
                set(tmppanel1,'Width',[-1,-5]);
                addlistener(figurecontrol(i).timerangepanel,'currenttime','PostSet',@(~,~) obj(i).ShowSPK(channelpanel(i),figurecontrol(i)));
                end
         end
        function ShowSPK(obj,channelpanel,figcontrolpanel)
             % gui read the SPKdata from npy or klustakwik formation 
             [timestart,timestop]=figcontrolpanel.timerangepanel.gettimerange;
             channelindex=channelpanel.getIndex(strcat('List_',channelpanel.Tag));
             data=SPKData.readdata(obj.Filename,str2num(obj.Channelnum),channelindex,timestart,timestop,'timeduration');
             time=linspace(timestart,timestop,length(data));
             figcontrolpanel.plot(time,data');
             currenttime=figcontrolpanel.timerangepanel.getcurrenttime;
             yrange=get(gca,'YLim');
             hold on;
             plot(gca,[currenttime,currenttime],[yrange(1),yrange(2)],'Color','r');
        end
    end
    methods(Static)
        function obj=SPKData(varargin)
              if nargin==1
             varname=fieldnames(varargin{1});
             data=varargin{1};
             for j=1:length(data)
                 obj(j)=SPKData();
             for i=1:length(varname)
                 eval(['obj(j).',varname{i},'=data(j).',varname{i},';']);
             end
             end
             end
        end
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