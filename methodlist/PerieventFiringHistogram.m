classdef PerieventFiringHistogram < NeuroMethod & NeuroPlot.NeuroPlot & BasicTag
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
        function Figurepanel=createplot(obj,variablename)
            Figurepanel=NeuroPlot.figurecontrol;
            Figurepanel=Figurepanel.create([],'PerieventFiringHistogram','bar-baseline');
            Figurepanel.figpanel.Title=variablename;
        end
        function [psth_tmp,t_spk]=load(obj,spikeindex,eventindex)
            % load the data from PerieventFiringHistogram object for given
            % channel and event
             if ~isempty(obj.filename) % load from h5file mode.
            [psth_tmp,t_spk]=obj.readh5(spikeindex,eventindex);
             else
                % psth_tmp=[];
                psth_tmp=obj.psth(:,spikeindex,eventindex);
                % for i=1:size(psth,1)
                %     for j=1:size(psth,2)
                %         psth_tmp(:,i,j)=psth{i,j};
                %     end
                % end
                t_spk=obj.t_spk;
            end
        end
        function plot(obj,Figurepanel,PanelManagement)
            SPKinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'SPKinfo'));
            EVTinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'EVTinfo'));
            eventindex=EVTinfo{:}.getIndex;
            channelindex=SPKinfo{:}.getIndex;
            [P_tmp,t_spk]=obj.load(channelindex,eventindex);
            Figurepanel.plot(t_spk,P_tmp);
        end
        function obj=AverageSubject(obj,neuroresult,averageparams)
            % generate the averaged spike firing function from given spike class and eventname
            % 'all' means average all data ,'none': no average,'separate': average for each type
            % cell(string) means average among each string type.
            % generate averaged data
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
            if ischar(obj.filename)||isstring(obj.filename)
                [PSTH,t_spk]=obj.readh5(true(length(blackspk),1),true(length(blackevt),1));
            else
                PSTH=obj.psth;
                t_spk=obj.t_spk;
            end
            %% PSTH is the matrix time*spike*evt
            if ~isempty(baselinetime)
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
                    eventname=unique(neuroresult.EVTinfo.eventdescription);
                end
                tmpS=[];
                for j=1:length(eventname)
                   tmpS(:,:,j)=mean(PSTH(:,:,ismember(neuroresult.EVTinfo.eventdescription,eventname{j})&~blackevt),3);
                end
                PSTH=tmpS;
            end
          
            obj.psth=PSTH;
        end
        function [P,t_spk]=readh5(obj,SPKIndex,EVTIndex)
            % only for timepoint mode. timeduration is on working.
            EVTatt=h5info(obj.filename,'/psth');
            t_spk=h5read(obj.filename,'/t_spk');
            d=1;
             for i=1:length(SPKIndex) 
                 c=1;
                 if SPKIndex(i)
                     for j=1:length(EVTIndex)
                         if EVTIndex(j)
                            P(:,c,d)=h5read(obj.filename,['/psth/',num2str(i),'/',num2str(j)]);
                            c=c+1; 
                         end
                     end
                     d=d+1;
                 end
             end  
        end
        function info=saveh5(obj,dirname)
            % transfer Spectrogram objects to the h5 file according to each
            % fileTag.Name.
            name=obj.getTaginfo('Tagvalue','fileTag');
            for c=1:length(obj)
                filename=fullfile(dirname,name{c});
                info(c).fileTag=obj(c).fileTag;
                info(c).filename=filename;
                for i=1:size(obj(c).psth,2)
                    for j=1:size(obj(c).psth,1)
                    h5create(filename,['/psth/',num2str(j),'/',num2str(i)],size(obj(c).psth{j,i}));
                    h5write(filename,['/psth/',num2str(j),'/',num2str(i)],obj(c).psth{j,i});
                    end
                end
    %           h5writeatt(filename,'/','methodname','Spectrogram');
                h5create(filename,'/t_spk',size(obj(c).t_spk));
                h5write(filename,'/t_spk',obj(c).t_spk);
                variablenames=fieldnames(obj(c).Params);
                for i=1:length(variablenames)
                    tmp=eval(['obj(c).Params.',variablenames{i},';']);
                    eval(['info(c).Params.',variablenames{i},'=tmp;']);
                end
            end
        end
    end
    methods (Access='private')
       function GetFilterValue(obj)
            global Spikepanel filterindex matvalue Blacklist spikeclassifier
                spikeclassifier.filterSpike;
                Channeldescription=obj.SPKinfo.channeldescription;
                Spikelist=obj.SPKinfo.name;
                Spikepanel=Spikepanel.assign('liststring',Spikelist(filterindex),'listtag',{'SpikeIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription(filterindex),'blacklist',Blacklist(matvalue).spikename);
       end
       
    end
    methods(Static)
        function params=getParams
            %% gaussian smooth or raw data for binspikes? 
             method=listdlg('PromptString','Select the PSTH method','ListString',{'binspike','gaussian'});
             switch method
                 case 1
                    prompt={'binwidth','trialaverage','SUAorMUA','timerange'};
                    title='Binspikes using Chronux';
                    lines=2;
                    def={'0.1','0','SUA',''};
                    x=inputdlg(prompt,title,lines,def,'on');
                    params.binwidth=str2num(x{1});
                    params.methodname='Binspikes';
                    params.trialaverage=str2num(x{2});
                    params.unitmode=x{3};
                    params.timerange=str2num(x{4});
                 case 2
                    prompt={'gaussian width','trialaverage','SUAorMUA','timerange'};
                    title='psth using Chronux';
                    lines=2;
                    def={'0.1','1','SUA',''};
                    x=inputdlg(prompt,title,lines,def,'on');
                    params.binwidth=str2num(x{1});
                    params.methodname='Gaussian';
                    params.trialaverage=str2num(x{2}); 
                    params.unitmode=x{3};
                    params.timerange=str2num(x{4});
             end
        end
        function neuroresult= cal(params,objmatrix,resultname)
                 neuroresult = cal@NeuroMethod(params,objmatrix,resultname,'PerieventFiringHistogram');
        end
        function neuroresult = recal(params,neuroresult,resultname)
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
                for j=1:size(neuroresult.SPKdata,2) % for each trial
                    spike(j).time=neuroresult.SPKdata{i,j};
                    if strcmp(params.methodname,'Binspikes')
                        %if ~isempty(params.timerange)
                        timerange=linspace(neuroresult.SPKinfo.spkt{i,j}(1),neuroresult.SPKinfo.spkt{i,j}(2),(neuroresult.SPKinfo.spkt{i,j}(2)-neuroresult.SPKinfo.spkt{i,j}(1))/params.binwidth+1);
                        [binspike(:,i,j),binspiket]=binspikes(spike(j).time,1/params.binwidth,timerange);
                        %else
                         %   [binspike{i,j},binpspiket{i,j}]=binspikes(spike(j).time,1/params.binwidth);
                        %end
                    elseif strcmp(params.methodname,'Gaussian')
                        warning('gaussian estimation using all trials for each eventtype')
                        % on working.
                    end
                end
            end
            obj.psth=binspike;
            obj.t_spk=linspace(params.timerange(1),params.timerange(2),(params.timerange(2)-params.timerange(1))/params.binwidth+1);
            obj.Taginfo('fileTag','Name',resultname);
            try
            neuroresult.addprop('PerieventFiringHistogram');
            neuroresult.PerieventFiringHistrogram=obj;
            catch
                neuroresult.PerieventFiringHistogram=cat(1,neuroresult.PerieventFiringHistogram,obj);
            end
        end  
        function averageparams=getAverageparams()
            % Average the binspike data according the spike type and event
            % type
            title='PSTH average params';
            prompt={'spike class mode (name-value/values) ','event average mode','baselinecorrect','baselinecorrect mode'};
            lines=4;
            def={'none','separate','-1,0','zscore'};  
            output=inputdlg(prompt,title,lines,def,'on');
            averageparams.Spike=output{1};
            averageparams.Event=output{2};
            averageparams.Baseline=str2num(output{3});
            averageparams.Correctmode=output{4};
        end
    end
end

