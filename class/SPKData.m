classdef SPKData< BasicTag
    %SPKDATA spike sorted data management in NEURODATA object
    % support phy and klustakwik file
    % must be defined by SPKData.initialize (defined the channel number and samplerate)
    % See also: NEURODATA, BASICTAG
    properties
        SortingType=[];
        Filename=[];
        Channelnum=[];
        Samplerate=[];
    end
    methods (Access='public')
        function obj =  fileappend(obj)
            % support the .clu. file from KlustaKwik and .npy file from Phy
            Sortinglist={'KlustaKwik','Phy','Inscopix'};
            index=listdlg('PromptString','choose the SortingType of SPKfile','ListString',Sortinglist);
            if isempty(index)
                obj=[];
                return;
            end
            obj.SortingType=Sortinglist{index};
            spikepath = uigetdir('Please select the Path of the sorted files');
            if isnumeric(spikepath)&&spikepath==0
                obj=[];
                return;
            end
            obj.Filename = spikepath;
        end
        function obj = initialize(obj,Channelnum,Samplerate)
            obj.Channelnum=Channelnum;
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
            bool=~isempty(obj.Channelnum)&~isempty(obj.SortingType)&~isempty(obj.Samplerate)&~isempty(obj.fileTag);
        end
        function neuroresult = Extractdata(obj,neuroresult,channelselect,channeldescription,EVTdata)
            if isempty(neuroresult)
                neuroresult=NeuroResult();
            end
            propvars={'SPKinfo','SPKdata','EVTinfo'};
            switch obj.SortingType
                case 'KlustaKwik'
                    [SPKinfo,SPKdata]=obj.ReadSPK_KlustaKwik(channelselect,channeldescription,EVTdata.EVTinfo.time(:,1),EVTdata.EVTinfo.time(:,2));
                case 'Phy'
                    NeuroMethod.Checkpath('npy'); % need mat npy toolbox
                    [SPKinfo,SPKdata]=obj.ReadSPK_Phy(channelselect,channeldescription,EVTdata.EVTinfo.time(:,1),EVTdata.EVTinfo.time(:,2));
            end
            SPKinfo.Fs=str2num(obj.Samplerate);
            if ~isempty(SPKdata)
                for i=1:length(propvars)
                try
                    eval(['addprop(neuroresult,''',propvars{i},''');']);
                end
                end
                neuroresult.SPKinfo=SPKinfo;
                neuroresult.EVTinfo=EVTdata.EVTinfo;
                neuroresult.SPKdata=SPKdata;
            end
        end
        function [SPKinfo,SPKdata] = ReadSPK_KlustaKwik(obj,channelselect,channeldescription,timestart,timestop,timetype)
            %   loading data from the klustakwik sortingtype
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
            SPKdata=cell(1,1);
            spknumber=1;
            for i=1:length(clusterfile)
                clusterchannel=SPKData.SPKchannel(clusterfile{i});
                if logical(sum(ismember(channelselect,clusterchannel)))
                    spk_clu=importdata(clusterfile{i});
                    spk_clu=spk_clu(2:end);
                    spk_time=importdata([strrep(clusterfile{i},'.clu.','.res.')]);
                    spk_time=spk_time/str2num(obj.Samplerate);
                    if isinf(read_until(1))
                        read_until=max(spk_time);
                    end
                    clustername=unique(spk_clu);
                    clustername(clustername==0|clustername==1)=[];
                    clusternum=regexpi(clusterfile{i},'.clu.','split');
                    clusternum=clusternum{end};
                    for j=1:length(clustername)
                        SPKinfo.spikename{spknumber,1}=['cluster',num2str(clusternum),'_',num2str(clustername(j))];
                        SPKinfo.SPKchannel{spknumber,1}=clusterchannel;
                        SPKinfo.SPKchanneldescription(spknumber,1)=unique(channeldescription(ismember(channelselect,clusterchannel)));
                        for k=1:length(read_start)
                            index=spk_clu==clustername(j)&spk_time>=read_start(k)&spk_time<=read_until(k);
                            SPKdata{spknumber,k}=spk_time(index);
                            if ~isinf(read_until(1))
                            SPKinfo.spkt{spknumber,k}=[read_start(k),read_until(k)];
                            else
                                 SPKinfo.spkt{spknumber,k}=[read_start(k),max(spk_time)];
                        
                            end
                        end
                        spknumber=spknumber+1;
                    end
                end
            end
            SPKinfo.blackspk=false([spknumber-1,1]);
        end
        function [SPKinfo,SPKdata,spk_time] = ReadSPK_Phy(obj,channelselect,channeldescription,timestart,timestop)
            % load data for phy format
            SPKinfo.Fs=str2num(obj.Samplerate);
            spk_clu=readNPY(fullfile(obj.Filename,'spike_clusters.npy'));
            spk_time=readNPY(fullfile(obj.Filename,'spike_times.npy'));
            spk_time=double(spk_time)/str2num(obj.Samplerate);
            try
                channel_shanks=readNPY(fullfile(obj.Filename,'channel_shanks.npy'));
                clusternumber=unique(channel_shanks);
            catch
                channel_shanks=readNPY(fullfile(obj.Filename,'channel_groups.npy'));
                clusternumber=unique(channel_shanks);
            end
            channel_map=readNPY(fullfile(obj.Filename,'channel_map.npy'))+1;
            [cluster_info,header,raw]=tsvread(fullfile(obj.Filename,'cluster_info.tsv'));
            group_index=strcmp(header,'group');
            shank_index=strcmp(header,'sh');
            channel_index=strcmp(header,'ch');
            id=strcmp(header,'cluster_id');
            if sum(id)==0 % old phy version;
                id=strcmp(header,'id');
            end
            SPKinfo.datatype='splitting';
            SPKdata=cell(1,1);
            read_start=timestart;
            read_until=timestop;
             if isinf(timestop(1)) % whole file loaded, calculate the precise time
                read_until=max(spk_time);
            end
            spknumber=1;
            if  sum(strcmp(raw(:,group_index),'good'))==0 % no good clusters
                warning(strcat('no spike found in ',obj.Filename));
                SPKdata=[];
                return;
            end
            for i=1:length(clusternumber)
                if logical(sum(ismember(channelselect,channel_map(channel_shanks==clusternumber(i)))))
                    clustername=cluster_info((cluster_info(:,shank_index)==clusternumber(i))&strcmp(raw(:,group_index),'good'),id);
                    
                    for j=1:length(clustername)
                        SPKinfo.spikename{spknumber,1}=['cluster',num2str(clusternumber(i)+1),'_',num2str(clustername(j))];
                        clusterchannel=cluster_info(cluster_info(:,id)==clustername(j),channel_index);
                        SPKinfo.channel{spknumber,1}=clusterchannel+1;
                        SPKinfo.channeldescription(spknumber,1)=unique(channeldescription(ismember(channelselect,clusterchannel+1)));
                        for k=1:length(read_start)
                            index=spk_clu==clustername(j)&spk_time>=read_start(k)&spk_time<=read_until(k);
                            SPKdata{spknumber,k}=spk_time(index);
                            SPKinfo.spkt{spknumber,k}=[read_start(k),read_until(k)];
                        end
                        spknumber=spknumber+1;
                    end
                   
                end
            end
             SPKinfo.blackspk=false([spknumber-1,1]);
        end
        function neuroresult = ReadSPKproperties(obj,neuroresult)
            % get the spike properties from the cell_metrics.cellinfo.mat
            % generated from CellExplorer.
            [~,filename]=fileparts(obj.Filename);
            if exist(fullfile(obj.Filename,strcat(filename,'.cell_metrics.cellinfo.mat')))
                cellinfo=matfile(fullfile(obj.Filename,strcat(filename,'.cell_metrics.cellinfo.mat')));
                cellinfo=getfield(cellinfo,'cell_metrics');
                cellinfospikename=arrayfun(@(x,y) ['cluster',num2str(x),'_',num2str(y)],cellinfo.shankID,cellinfo.cluID,'UniformOutput',0);
                variable={'putativeCellType','firingRate','troughToPeak'};% maybe add all fieldnames of cellinfo in the further?
                index= cellfun(@(x) cellfun(@(y) ~isempty(regexpi(y,['\<',x,'\>'],'match')),cellinfospikename,'UniformOutput',1),neuroresult.SPKinfo.spikename,'UniformOutput',0);
                try
                    index=cellfun(@(x) find(x==1),index,'UniformOutput',1);
                catch
                    error('the cellinfo mat is different from the spike data, should recal the CellExplorer using current clustering result');
                end
                for j=1:length(variable)
                    eval(['neuroresult.SPKinfo.',variable{j},'=cellinfo.',variable{j},'(index);']);
                end
            end
        end
        function hbox=gui_plot(obj,parent)
             % generate gui plot of SPKdata files in a BoxPanel
             % plot from NeuroData instead of NeuroResult
             % contains the spikeselectpanel and SPK raster plot panel with timebar
             % See also: NEURODATA.GUI_PLOT
            hbox = uix.VBox( 'Parent', parent );
            for i=1:length(obj) % for multiple spk files within the subject
                % 1.Add three box panel
                boxPanels = uix.BoxPanel( 'Parent', hbox,'UserData',i,'Title',obj(i).Filename);
                tmppanel = uix.HBoxFlex('Parent', boxPanels);
                % 2.Read origin data
                channeldescription=arrayfun(@(x) num2str(x),1:str2num(obj.Channelnum),'UniformOutput',0);
                switch obj(i).SortingType
                    case 'Phy'
                        [dataInfo, ~,spiketime] = obj(i).ReadSPK_Phy(1:str2num(obj.Channelnum),channeldescription,0,Inf);
                    case 'Klusta'
                        [dataInfo, ~,spiketime] = obj(i).ReadSPK_KlustaKwik(1:str2num(obj.Channelnum), channeldescription,0,Inf);
                end
                SPKPanel = NeuroPlot.selectpanel();
                SPKname=dataInfo.spikename;
                SPKPanel.create(tmppanel,'spikename', SPKname);
                % 3.Prepare timestamps
                timestamps=linspace(min(spiketime),max(spiketime),(max(spiketime)-min(spiketime))*100+1);
                % 4.Raster-scroll control
                figurecontrol = NeuroPlot.figurecontrol();
                figurecontrol = figurecontrol.create(tmppanel, ['fig_', num2str(i)], 'raster-scroll', 'timestamp', timestamps);
                set(tmppanel, 'Width', [-1, -5]);
                addlistener(figurecontrol.timerangepanel, 'currenttime', 'PostSet', @(~,~) obj(i).ShowSPK(SPKPanel, figurecontrol));           
            end   
        end
      
    end
    methods (Access=private)
          function ShowSPK(obj,SPKpanel,figcontrolpanel)
            % gui read the SPKdata from npy or klustakwik formation
            [timestart, timestop]=figcontrolpanel.timerangepanel.gettimerange;
            SPKindex=SPKpanel.getIndex; 
            [SPKinfo, data] = obj.readdata(SPKindex, timestart, timestop);
            % raster
            figcontrolpanel.plot([timestart,timestop],data,[]);
            nClu = numel(SPKinfo.spikename);
            ax=gca;
            ax.YTick = 1:nClu;
            ax.YTickLabel = SPKinfo.spikename;
            currenttime=figcontrolpanel.timerangepanel.getcurrenttime;
            yrange=get(gca,'YLim');
            hold on;
            plot(gca,[currenttime,currenttime],[yrange(1),yrange(2)],'Color','r');
%             hold(ax,'off');
        end
        function [SPKinfo, SPKdata] = readdata(obj,SPKindex, timestart, timestop)
            % read the data for gui_plot
            channeldescription=arrayfun(@(x) num2str(x),1:str2num(obj.Channelnum),'UniformOutput',0);
            switch obj.SortingType
                case 'KlustaKwik'
                    [SPKinfo_all, SPKdata_all] = obj.ReadSPK_KlustaKwik(1:str2num(obj.Channelnum), channeldescription, timestart, timestop, 'duration');
                case 'Phy'
                    [SPKinfo_all, SPKdata_all] = obj.ReadSPK_Phy(1:str2num(obj.Channelnum), channeldescription, timestart, timestop, 'duration');
                otherwise
                    error('Unsupported SortingType');
            end
            if nargin < 2 || isempty(SPKindex)
                SPKindex = 1:length(SPKinfo_all.spikename);
            end
            % Filter the corresponding fields of SPKinfo
            SPKinfo = struct();
            fns = fieldnames(SPKinfo_all);
            for i = 1:length(fns)
                val = SPKinfo_all.(fns{i});
                if iscell(val) || (isnumeric(val) && numel(val) == length(SPKinfo_all.spikename))
                    SPKinfo.(fns{i}) = val(SPKindex);
                else
                    SPKinfo.(fns{i}) = val;
                end
            end
            SPKdata = SPKdata_all(SPKindex, :);
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
            % only for KlustaKwik loading
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