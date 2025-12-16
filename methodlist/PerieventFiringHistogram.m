classdef PerieventFiringHistogram < NeuroMethod & NeuroPlot.NeuroPlot & NeuroResult
    %PERIEVENTFIRINGHISTOGRAM: calculate PSTH from NeuroData object
    % can be managed as BasicTag object and be ploted as NeuroPlot.NeuroPlot object
    % See also: NEURORESULT, NEUROMETHOD, NEUROPLOT.NEUROPLOT

    properties
        psth
        t_spk
        filename=[];
    end
    methods (Access='public')
        function obj=PerieventFiringHistogram(varargin)
            if nargin==1
                data=varargin{1};
                for i=1:length(data)
                    varname=fieldnames(data(i));
                    for j=1:length(varname)
                        eval(['obj(i).',varname{j},'=data(i).',varname{j},';']);
                    end
                end
            end
        end
         % method for Basic Tag
        function obj = Taginfo(obj, Tagname, informationtype, information)
            try
                addprop(obj,Tagname);
            end
            obj=Taginfo@BasicTag(obj,Tagname,informationtype, information);
        end
        function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
             [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                  [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
        end
        % methods for NeuroPlot
        function Figurepanel=createplot(obj,variablename,varargin)
            Figurepanel=NeuroPlot.figurecontrol;
            Figurepanel=Figurepanel.create([],'PerieventFiringHistogram',strcat('bar',varargin{1}));
            Figurepanel.figpanel.Title=variablename;
        end
        function [psth_tmp,t_spk]=load(obj,eventindex,spikeindex)
            % load the data from PerieventFiringHistogram object for give channel and event
            % for plot function
             if ~isempty(obj.filename) % load from h5file mode.
                [psth_tmp,t_spk]=obj.Loadh5(spikeindex,eventindex);
             else
                psth_tmp=obj.Loadmat('psth',{spikeindex,eventindex},{-1});
                t_spk=obj.Loadmat('t_spk',{spikeindex,eventindex},{-1});
            end
        end
        function plot(obj,Figurepanel,PanelManagement)
            SPKinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'SPKinfo'));
            EVTinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'EVTinfo'));
            eventindex=EVTinfo.getIndex;
            spikeindex=SPKinfo.getIndex;
            [P_tmp,t_spk]=obj.load(eventindex,spikeindex); % cell {spike*event}
            try % for timepoint mode, transfer the matrix to time*spike*event
                P_tmp=reshape(cell2mat(P_tmp),[],size(P_tmp,1),size(P_tmp,2));
                t_spk=unique(cell2mat(t_spk));
                % for spike duration plot, using scoll mode
            end
            Figurepanel.plot(t_spk,P_tmp);
        end
        function obj=AverageSubject(obj,neuroresult,averageparams)
            % generate the averaged spike firing function from given spike class and eventname
            % 'all' means average all data ,'none': no average,'separate': average for each type
            % cell(string) means average among each string type.
            % generate averaged data
            % See also: NEURODATA.AVERAGESUBJECT
            if ~isempty(neuroresult.SPKinfo.blackspk)
                 blackspk=neuroresult.SPKinfo.blackspk;
            else
                 blackspk=false(size(neuroresult.SPKinfo.spikename));
            end
            if ~isempty(neuroresult.EVTinfo.blackevt)
                  blackevt=neuroresult.EVTinfo.blackevt;
            else
                blackevt=false(size(neuroresult.EVTinfo.eventselect));
            end
            spkname=averageparams.Spike;
            eventname=averageparams.Event;
            baselinetime=averageparams.Baseline;
            baselinecorrectmode=averageparams.Correctmode;
            averagefirst=averageparams.AverageBeforeCorrection;
            [PSTH,t_spk]=obj.load(true(length(blackevt),1),true(length(blackspk),1));
            try % for timepoint mode, the matrix is time*event*spike       
                PSTH=reshape(cell2mat(PSTH),[],size(PSTH,1),size(PSTH,2));
                t_spk=unique(cell2mat(t_spk));
            end
            %% PSTH is the matrix time*spike*evt
            if ~isempty(baselinetime)&~averagefirst
               PSTH=basecorrect(PSTH,t_spk,baselinetime(1),baselinetime(2),baselinecorrectmode);
            end
            if strcmp(lower(spkname), 'all')
               PSTH=nanmean(PSTH(:,~blackspk,:),2);
            elseif strcmp(lower(spkname),'none')
               PSTH=PSTH(:,~blackspk,:);
            % spike class average is on working
            end
            if strcmp(lower(eventname),'all')
                PSTH=mean(PSTH(:,:,~blackevt),3);
            elseif strcmp(lower(eventname),'none')
                PSTH=PSTH(:,:,~blackevt);
            else
                if strcmp(lower(eventname),'separate')
                    eventname=unique(neuroresult.EVTinfo.description);
                end
                tmpS=[];
                for j=1:length(eventname)
                   tmpS(:,:,j)=mean(PSTH(:,:,ismember(neuroresult.EVTinfo.description,eventname{j})&~blackevt),3);
                end
                PSTH=tmpS;
            end
            if ~isempty(baselinetime)&averagefirst
               PSTH=basecorrect(PSTH,t_spk,baselinetime(1),baselinetime(2),baselinecorrectmode);
            end
            obj.psth=PSTH;
            obj.t_spk=t_spk;
        end
        function [PSTH,t_spk]=Loadh5(obj,SpikeIndex,EVTIndex)
            % See also:NEURORESULT.Loadh5
                t_spk=obj.Loadh5@NeuroResult(obj.filename,'/event/time','/t_spk',{EVTIndex},{-1,-1});
                try
                 currenttime=findobj('Tag','currenttime');
                 currentrange=findobj('Tag','timerange');
                 currenttime=str2num(currenttime.String);
                 currentrange=str2num(currentrange.String);
                 t_spk=obj.t_spk{:};
                 [~,index1]=min(abs(t_lfp-(currenttime+currentrange(1))));
                 [~,index2]=min(abs(t_lfp-(currenttime+currentrange(2))));
                 TimeIndex=false(size(t_lfp));
                 TimeIndex(index1:index2)=true;
             catch
                 TimeIndex=-1;
                end
             PSTH=obj.Loadh5@NeuroResult(obj.filename,'/spike/event/time','/psth',{SpikeIndex,EVTIndex},{TimeIndex,-1});
             t_spk=obj.Loadh5@NeuroResult(obj.filename,'/event/time','/t_spk',{EVTIndex},{TimeIndex,-1});
        end
        function info=Saveh5(obj,dirname)
            % transfer Spectrogram objects to the h5 file according to each
            % fileTag.Name.
            % See also: NEURORESULT.SAVEH5
            name=obj.getTaginfo('Tagvalue','fileTag');
            for c=1:length(obj)
                filename=fullfile(dirname,name{c});
                info(c).fileTag=obj(c).fileTag;
                info(c).filename=filename;
                Saveh5@NeuroResult(obj,filename,'psth','/spike/event/time','/psth');
                Saveh5@NeuroResult(obj,filename,'t_spk','/event/time','/t_spk');
                variablenames=fieldnames(obj(c).Params);
                for i=1:length(variablenames)
                    tmp=eval(['obj(c).Params.',variablenames{i},';']);
                    eval(['info(c).Params.',variablenames{i},'=tmp;']);
                end
            end
        end
        function obj=slice(obj,neuroresult,varargin)
            p=inputParser;
            addParameter(p,'SPKindex',~neuroresult.SPKinfo.blackspk,@islogical);
            addParameter(p,'EVTindex',~neuroresult.EVTinfo.blackevt,@islogical);
            parse(p,varargin{:});
            [obj.psth,obj.t_spk]=obj.load(p.Results.EVTindex,p.Results.SPKindex);
        end
    end
    methods (Access='private')
       function GetFilterValue(obj)
           % on working
            global Spikepanel filterindex matvalue Blacklist spikeclassifier
                spikeclassifier.filterSpike;
                Channeldescription=obj.SPKinfo.channeldescription;
                Spikelist=obj.SPKinfo.name;
                Spikepanel=Spikepanel.assign('liststring',Spikelist(filterindex),'listtag',{'SpikeIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription(filterindex),'blacklist',Blacklist(matvalue).spikename);
       end
       
    end
    methods(Static)
        function params=getParams
            %% gaussian smooth or raw data for binspikes
             method=listdlg('PromptString','Select the PSTH method','ListString',{'binspike','gaussian'});
             switch method
                 case 1
                    prompt={'binwidth','trialaverage','SUAorMUA'};
                    title='Binspikes using Chronux';
                    lines=2;
                    def={'0.1','0','SUA'};
                    x=inputdlg(prompt,title,lines,def,'on');
                    params.binwidth=str2num(x{1});
                    params.methodname='Binspikes';
                    params.trialaverage=str2num(x{2});
                    params.unitmode=x{3};
                 case 2
                    prompt={'gaussian width','trialaverage','SUAorMUA'};
                    title='psth using Chronux';
                    lines=2;
                    def={'0.1','1','SUA'};
                    x=inputdlg(prompt,title,lines,def,'on');
                    params.binwidth=str2num(x{1});
                    params.methodname='Gaussian';
                    params.trialaverage=str2num(x{2}); 
                    params.unitmode=x{3};
             end
        end
        function neuroresult= cal(params,objmatrix,resultname)
                 neuroresult = cal@NeuroMethod(params,objmatrix,resultname,'PerieventFiringHistogram');
        end
        function neuroresult = recal(params,neuroresult,resultname)
            % neuroresult.psth:{spike,event}(time*1)
            % neuroresult.t_spk:{event}(time,1)
            if isprop(neuroresult,'PerieventFiringHistogram')
                currentname=neuroresult.PerieventFiringHistogram.getTaginfo('Tagvalue','fileTag');
                if contains(resultname,currentname)
                    warning([resultname,'is in the current result, skip.']);
                    return;
                end
            end
            obj=PerieventFiringHistogram();
            obj.Params=params;
            for i=1:size(neuroresult.SPKdata,1) % for each spike
                for j=1:size(neuroresult.SPKdata,2) % for each trial spike*trial
                    spike(j).time=neuroresult.SPKdata{i,j};
                    if strcmp(params.methodname,'Binspikes')
                        %if ~isempty(params.timerange)
                        timerange=linspace(neuroresult.SPKinfo.spkt{i,j}(1),neuroresult.SPKinfo.spkt{i,j}(2),(neuroresult.SPKinfo.spkt{i,j}(2)-neuroresult.SPKinfo.spkt{i,j}(1))/params.binwidth+1);
                        if strcmp(neuroresult.EVTinfo.timetype,'timepoint')
                            timerange=linspace(0,neuroresult.EVTinfo.timerange(2)-neuroresult.EVTinfo.timerange(1),(neuroresult.EVTinfo.timerange(2)-neuroresult.EVTinfo.timerange(1))/params.binwidth+1);
                        end
                        [obj.psth{i,j},obj.t_spk{j}]=binspikes(spike(j).time,1/params.binwidth,timerange+neuroresult.SPKinfo.spkt{i,j}(1));
                        obj.t_spk{j}=obj.t_spk{j}';
                        if strcmp(neuroresult.EVTinfo.timetype,'timepoint')
                           obj.t_spk{j}=linspace(neuroresult.EVTinfo.timerange(1),neuroresult.EVTinfo.timerange(2),(neuroresult.EVTinfo.timerange(2)-neuroresult.EVTinfo.timerange(1))/params.binwidth+1)';
                        end
                        %else
                         %   [binspike{i,j},binspiket{i,j}]=binspikes(spike(j).time,1/params.binwidth);
                        %end
                    elseif strcmp(params.methodname,'Gaussian')
                        warning('gaussian estimation using all trials for each eventtype')
                        % on working.
                    end
                end
            end
            obj.Taginfo('fileTag','Name',resultname);
            try
            neuroresult.addprop('PerieventFiringHistogram');
            neuroresult.PerieventFiringHistrogram=obj;
            catch
                neuroresult.PerieventFiringHistogram=cat(1,neuroresult.PerieventFiringHistogram,obj);
            end
        end  
        function averageparams=getAverageparams(varargin)
            % Average the binspike data according the spike type and event
            % type
            p=inputParser;
            addParameter(p,'Spike','none');
            addParameter(p,'Event','seperate',@NeuroMethod.CheckAverageInput);
            addParameter(p,'Baseline',[-1,0],@isnumeric);
            addParameter(p,'Correctmode','zscore',@ischar);
            addParameter(p,'AverageBeforeCorrection',false,@islogical);
            if nargin>1
                parse(p,varargin{:});
                averageparams=p.Results;
            else
            title='PSTH average params';
            prompt={'spike class mode (name-value/values) ','event average mode','baselinecorrect','baselinecorrect mode','Average Before Correction'};
            lines=4;
            def={'none','separate','-1,0','zscore','0'};  
            output=inputdlg(prompt,title,lines,def,'on');
            averageparams.Spike=output{1};
            [~,averageparams.Event]=Neutomethod.CheckAverageInput(output{2});
            averageparams.Baseline=str2num(output{3});
            averageparams.Correctmode=output{4};
            averageparams.AverageBeforeCorretion=logical(str2num(output{5}));
            end
        end
    end
end

