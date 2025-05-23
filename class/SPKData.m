classdef SPKData< BasicTag
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
            obj.SortingType=Sortinglist{index};
            spikepath = uigetdir('Please select the Path of the sorted files');
            obj.Filename = spikepath;
        end
        function obj = initialize(obj,Channelnum,Samplerate)
            obj.Channelnum=Channelnum;
            obj.Samplerate=Samplerate;
        end
        function bool= Tagchoose(obj,informationtype,information)
            bool=Tagchoose@BasicTag(obj,'fileTag',informationtype,information);
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
            SPKinfo.channelselect=channelselect;
            SPKinfo.channeldescription=channeldescription;
            SPKinfo.Fs=str2num(obj.Samplerate);
            SPKinfo.blackchannel=[];
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
        function [SPKinfo,SPKdata,spk_time] = ReadSPK_Phy(obj,channelselect,channeldescription,timestart,timestop,timetype)
            SPKinfo.Fs=str2num(obj.Samplerate);
            cd(obj.Filename);
            spk_clu=readNPY(fullfile(obj.Filename,'spike_clusters.npy'));
            spk_time=readNPY(fullfile(obj.Filename,'spike_times.npy'));
            spk_time=double(spk_time)/str2double(obj.Samplerate);
            channel_shanks=readNPY(fullfile(obj.Filename,'channel_shanks.npy'));
            channel_map=readNPY(fullfile(obj.Filename,'channel_map.npy'))+1;
            [cluster_info,header,raw]=tsvread(fullfile(obj.Filename,'cluster_info.tsv'));
            group_index=strcmp(header,'group');
            shank_index=strcmp(header,'sh');
            channel_index=strcmp(header,'ch');
            id=strcmp(header,'cluster_id');
            clusternumber=unique(channel_shanks);
            SPKinfo.datatype='splitting';
            SPKinfo.blackspk=[];
            SPKdata=cell(1,1);
            read_start=timestart;
            read_until=timestop;
            spknumber=1;
            for i=1:length(clusternumber)
                if logical(sum(ismember(channelselect,channel_map(channel_shanks==clusternumber(i)))))
                    clustername=cluster_info((cluster_info(:,shank_index)==clusternumber(i))&strcmp(raw(:,group_index),'good'),id);
                    for j=1:length(clustername)
                        SPKinfo.spikename{spknumber}=['cluster',num2str(clusternumber(i)),'_',num2str(clustername(j))];
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
            hbox = uix.VBox( 'Parent', parent );
            for i=1:length(obj) % for multiple spk files within the subject
                % 1.Add three box panel
                boxPanels = uix.BoxPanel( 'Parent', hbox,'UserData',i,'Title',obj(i).Filename);
                tmppanel = uix.HBoxFlex('Parent', boxPanels);
                % 2.Channel selector
                channeldescription=arrayfun(@(x) num2str(x),1:str2num(obj.Channelnum),'UniformOutput',0);
                switch obj(i).SortingType
                    case 'Phy'
                        [dataInfo, ~,spiketime] = obj(i).ReadSPK_Phy(1:str2num(obj.Channelnum),channeldescription,0,Inf,'duration');
                    case 'Klusta'
                        [dataInfo, ~,spiketime] = obj(i).ReadSPK_KlustaKwik(1:str2num(obj.Channelnum), channeldescription,0,Inf,'duration');
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
        function ShowSPK(obj,SPKpanel,figcontrolpanel)
            % gui read the SPKdata from npy or klustakwik formation
            [timestart, timestop]=figcontrolpanel.timerangepanel.gettimerange;
            SPKindex=SPKpanel.getIndex(strcat('List_',SPKpanel.Tag)); 
            [SPKinfo, data] = obj.readdata(SPKindex, timestart, timestop);
            % raster
            figcontrolpanel.plot([], []);
            ax = gca; cla(ax); hold(ax, 'on');
            nClu = numel(SPKinfo.spikename);
            for clusterIdx = 1:nClu
                spikeTimes = data{clusterIdx};
                if ~isempty(spikeTimes)
                    yTop    = nClu - (clusterIdx - 1) + 0.4;
                    yBottom = nClu - (clusterIdx - 1) - 0.4;
                    X = [spikeTimes'; spikeTimes'];
                    Y = repmat([yBottom; yTop], 1, numel(spikeTimes));
                    line(ax, X, Y, 'LineWidth', 0.5, 'Color', 'k');
                end
            end
            % Draw current time line
            currenttime = figcontrolpanel.timerangepanel.getcurrenttime;
            yL = ax.YLim;
            plot(ax, [currenttime currenttime], yL, 'r', 'LineWidth', 1);
            ax.XLim = [timestart, timestop];
            ax.YLim = [0.5, nClu + 0.5];
            ax.YDir = 'reverse';
            ax.YTick = 1:nClu;
            ax.YTickLabel = SPKinfo.spikename;
            hold(ax,'off');
        end
    end
    methods (Access=private)
        function [SPKinfo, SPKdata] = readdata(obj,SPKindex, timestart, timestop)
            channeldescription=arrayfun(@(x) num2str(x),1:str2double(obj.Channelnum),'UniformOutput',0);
            switch obj.SortingType
                case 'KlustaKwik'
                    [SPKinfo_all, SPKdata_all] = obj.ReadSPK_KlustaKwik(1:str2double(obj.Channelnum), channeldescription, timestart, timestop, 'duration');
                case 'Phy'
                    [SPKinfo_all, SPKdata_all, ~] = obj.ReadSPK_Phy(1:str2double(obj.Channelnum), channeldescription, timestart, timestop, 'duration');
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