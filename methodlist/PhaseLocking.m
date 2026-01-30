classdef PhaseLocking < NeuroMethod & NeuroResult & NeuroPlot.NeuroPlot
    % Calculate the spike phase locking value to local field potential
    % using the hilbert transfrom to get the phase information
    % SPKPhase is the cell {spike,event}(spikenumber*channel)
    % t_spk is the cell{spike}(time) timepoint returns the relative time; timeduration returns the abs time
    % replace neuroresult.LFPdata to the filtered LFPData {event}(time*channel)
    properties
        SpikePhase
        t_spk
        rayleigh_p
        rayleigh_z
        resultantlength
        prefer_angle
    end
    methods (Access='public')
        function obj=PhaseLocking(varargin)
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
            Figurepanel=Figurepanel.create([],'PhaseLocking',strcat('roseplot'));
            Figurepanel.figpanel.Title=variablename;
         end
         function [spikephase,spiketime]=load(obj,spikeindex,eventindex,timeindex,channelindex)
            if ~isempty(obj.Filename)
                [spikephase,spiketime]=obj.Loadh5(spikeindex,eventindex,timeindex,channelindex);
            else
                spikephase=obj.Loadmat('SpikePhase',{spikeindex,eventindex},{timeindex,channelindex});
                spiketime=obj.Loadmat('t_spk',{spikeindex,eventindex},{timeindex});
            end
         end
         function [spikephase,spiketime]=Loadh5(obj,SpikeIndex,EventIndex,TimeIndex,ChannelIndex)
             spikephase=Loadh5@NeuroResult(obj,obj.Filename,'/spike/event/time*channel','/SpikePhase',{SpikeIndex,EventIndex},{TimeIndex,ChannelIndex});
             spiketime=Loadh5@NeuroResult(obj,obj.Filename,'/spike/event/time','/t_spk',{EventIndex},{TimeIndex});
         end
         function info=Saveh5(obj,dirname)
             name=obj.getTaginfo('Tagvalue','fileTag');
             for c=1:length(obj)
                 savefilename=fullfile(dirname,name{c});
                 info(c)=PhaseLocking();
                 info(c).fileTag=obj(c).fileTag;
                 info(c).Filename=savefilename;
                 Saveh5@NeuroResult(obj,savefilename,'SpikePhase','/spike/event/time*channel','/SpikePhase');
                 Saveh5@NeuroResult(obj,savefilename,'t_spk','/spike/event/time','/SpikePhase');
                 variablenames=fieldnames(obj(c).Params);
                 for i=1:length(variablenames)
                    tmp=eval(['obj(c).Params.',variablenames{i},';']);
                    eval(['info(c).Params.',variablenames{i},'=tmp;']);
                 end
             end
         end
        function plot(obj,Figurepanel,PanelManagement)
            global spikephase_all spiketime_all
            SPKinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'SPKinfo'));
            EVTinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'EVTinfo'));
            LFPinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'LFPinfo'));
            eventindex=EVTinfo.getIndex;
            spikeindex=SPKinfo.getIndex;
            channelindex=LFPinfo.getIndex;
            [spikephase,spiketime]=obj.load(spikeindex,eventindex,-1,channelindex);
            spikephase=cellfun(@(x) nanmean(x,2),spikephase,'UniformOutput',0);
            spikephase_all=[];spiketime_all=[];
            for i=1:size(spikephase,1)
                for j=1:size(spikephase,2)
                    try
                    spikephase_all=cat(1,spikephase_all,spikephase{i,j});
                    spiketime_all=cat(1,spiketime_all,spiketime{i,j});
                    catch
                        a=1;
                    end
                end
            end
            Figurepanel.plot(spikephase_all,spiketime_all);
        end
        function obj=AverageSubject(obj,neuroresult,averageparams)
             if ~ isempty(neuroresult.SPKinfo.blackspk)
                 blackspk=neuroresult.SPKinfo.blackspk;
             else
                 blackspk=false(size(neuroresult.SPKinfo.spikename));
             end
             if ~ isempty(neuroresult.EVTinfo.blackevt)
                 blackevt=neuroresult.EVTinfo.blackevt;
             else
                 blackevt=false(size(neuroresult.EVTinfo.eventselect));
             end
             if ~ isempty(neuroresult.LFPinfo.blackchannel)
                 blackchannel=neuroresult.LFPinfo.blackchannel;
             else
                 blackchannel=false(size(neuroresult.LFPinfo.channeldescription));
             end
            spkname=averageparams.Spike;
            eventname=averageparams.Event;
            channelname=averageparams.Channel;
            tolerancenumber=averageparams.tolerancenumber;
            timerange=averageparams.Timerange;
            obj.averageParams=averageparams;
            [spikephase,spiketime]=obj.load(true(length(blackspk),1),true(length(blackevt),1),-1,true(length(blackchannel),1));
            % spikephase is {spike,event}(time*channel))
            tmpspikephase=[];tmpspiketime=[];
            if strcmp(lower(spkname),'all')
                  for j=1:size(spikephase,2)
                      for i=1:size(spikephase,1)
                          if ~isempty(spikephase{i,j})&&~blackspk(i)
                            tmpspikephase{1,j}=cat(1,tmpspikephase{j},spikephase{i,j});
                            tmpspiketime{1,j}=cat(1,tmpspiketime,spiketime{i,j});
                          end
                      end
                  end
            elseif strcmp(lower(spkname),'none')
                tmpspikephase=spikephase(~blackspk,:);
                tmpspiketime=spiketime(~blackspk,:);
            end
            spikephase=tmpspikephase;
            spiketime=tmpspiketime;
            tmpspikephase=[];tmpspiketime=[];
            if strcmp(lower(eventname),'none')
                tmpspikephase=spikephase(:,~blackevt);
                tmpspiketime=spiketime(:,~blackevt);
            elseif strcmp(lower(eventname),'all')
                for i=1:size(spikephase,1)
                    for j=1:size(spikephase,2)
                        tmpspikephase{i,1}=cat(1,tmpspikephase{i,1},spikephase{i,j});
                    end
                end
                spikephase=tmpspikephase;
                spiketime=tmpspiketime;
            else
                if strcmp(lower(eventname),'separate')
                    eventname=unique(neuroresult.EVTinfo.description);
                end
                tmpspikephase=cell(size(spikephase,1),length(eventname));
                tmpspiketime=cell(size(spiketime,1),length(eventname));
                for i=1:size(spikephase,1)
                    for j=1:length(eventname)
                        tmpphase=spikephase(i,ismember(neuroresult.EVTinfo.description,eventname{j})&~blackevt);
                        tmptime=spiketime(i,ismember(neuroresult.EVTinfo.description,eventname{j})&~blackevt);
                        for k=1:length(tmpphase)
                            tmpspikephase{i,j}=cat(1,tmpspikephase{i,j},tmpphase{k});
                            tmpspiketime{i,j}=cat(1,tmpspiketime{i,j},tmptime{k});
                        end
                    end
                end
                averageparams.Event=eventname;
            end
            spikephase=tmpspikephase;
            spiketime=tmpspiketime;
            if strcmp(lower(channelname),'none')
                spikephase=cellfun(@(x) x(:,~blackchannel),spikephase,'UniformOutput',0);
            elseif strcmp(lower(channelname),'all')
                spikephase=cellfun(@(x) x(:,~blackchannel),spikephase,'UniformOutput',0);
            else
                if strcmp(lower(channelname),'separate')
                    channelname=unique(neuroresult.LFPinfo.channeldescription);
                end
                tmpspikephase=cell(size(spikephase));
                for i=1:size(channelname)
                    tmpphase=cellfun(@(x) mean(x(:,ismember(neuroresult.LFPinfo.channeldescription,channelname{i})),2),spikephase,'UniformOutput',0);
                    tmpspikephase=cellfun(@(x,y) cat(2,x,y),tmpspikephase,tmpphase,'UniformOutput',0);
                end
                spikephase=tmpspikephase;
                averageparams.Channel=channelname;
            end
            if ~isempty(timerange)
                spikephase=cellfun(@(x,y) x(y>timerange(1)&y<timerange(2),:),spikephase,spiketime,'UniformOutput',0);
                spiketime=cellfun(@(x) x(x>timerange(1)&x<timerange(2),:),spiketime,'UniformOutput',0);
            end
            [rayleigh_p,rayleigh_z,resultantlength,prefer_angle]=cellfun(@(x) PhaseLocking.rayleigh_test(x,tolerancenumber),spikephase,'UniformOutput',0);
            obj.rayleigh_p=rayleigh_p;
            obj.rayleigh_z=rayleigh_z;
            obj.resultantlength=resultantlength;
            obj.prefer_angle=prefer_angle;
            obj.SpikePhase=spikephase;
            obj.t_spk=spiketime;
         end
    end
    methods(Static)
        function Params=getParams
            prompt={'fpass'};
            title='input Params';
            lines=1;
            def={'4 8'};
            x=inputdlg(prompt,title,lines,def,'on');
            Params.fpass=str2num(x{1});
        end
        function [spikephase,spiketime]=getSpikephase(phaseLFP,t,spiketime) 
            % this may cause some bugs in the spike phase?
            if ~isempty(spiketime)
            phaseLFP=timeseries(phaseLFP,linspace(t(1),t(end),length(phaseLFP)));
            phaseLFP=resample(phaseLFP,linspace(t(1),t(end),10000*(t(end)-t(1))+1));
            time=round(phaseLFP.time,4);
            for i=1:length(spiketime)     
                spikephase(i,1)=phaseLFP.Data(ismember(time,round(spiketime(i),4)))';
            end
            else
                spikephase=[];
            end
        end
        function neuroresult = cal(params,objmatrix,resultname)
            neuroresult = cal@NeuroMethod(params,objmatrix,resultname,'PhaseLocking');
        end
        function neuroresult = recal(params,neuroresult,resultname)
            if isprop(neuroresult,'PhaseLocking')
                currentname=neuroresult.PhaseLocking.getTaginfo('Tagvalue','fileTag');
                if contains(resultname,currentname)
                    warning([resultname,'is in the current result, skip.']);
                    return;
                end
            end
            obj=PhaseLocking();
            obj.Params=params;
            % % get the LFP data
            multiWaitbar(['Calculating',char(neuroresult.Subjectname)],0);
            process=0;
            for j=1:length(neuroresult.LFPdata) % for each trial
                EEG=pop_importdata('data',neuroresult.LFPdata{j}','srate',neuroresult.LFPinfo.Fs,'nbchan',length(neuroresult.LFPinfo.channeldescription));
                FiltData=pop_eegfiltnew(EEG,'locutoff',params.fpass(1),'hicutoff',params.fpass(2));
                neuroresult.LFPdata{j}=FiltData.data';
                for i=1:size(neuroresult.SPKdata,1) % for each spike
                    if ~isempty(neuroresult.SPKdata{i,j})
                    spikephase=[];
                    PhaseLFP=hilbert(neuroresult.LFPdata{j});
                    t=neuroresult.EVTinfo.time(j,:);
                    for k=1:size(PhaseLFP,2) % for each channel
                        [spikephase(:,k)]=PhaseLocking.getSpikephase(angle(PhaseLFP(:,k)),t,neuroresult.SPKdata{i,j});                      
                    end
                    switch neuroresult.EVTinfo.timetype
                        case 'timepoint'
                            obj.t_spk{i,j}=neuroresult.SPKdata{i,j}-neuroresult.EVTinfo.time(j,1)+neuroresult.EVTinfo.timerange(1);
                        case 'timeduration'
                            obj.t_spk{i,j}=neuroresult.SPKdata{i,j};
                    end
                    obj.SpikePhase{i,j}=spikephase;
                    else
                        obj.SpikePhase{i,j}=nan(1,size(PhaseLFP,2));
                        obj.t_spk{i,j}=nan;
                    end
                end
                 process=process+1/(size(neuroresult.LFPdata,2));
                 multiWaitbar(['Calculating',char(neuroresult.Subjectname)],process);
            end    
            obj.Taginfo('fileTag','Name',resultname);
            try
                neuroresult.addprop('PhaseLocking');
                neuroresult.PhaseLocking=obj;
            catch
                neuroresult.PhaseLocking=cat(1,neuroresult.PhaseLocking,obj);
            end  
         end
        function replot(figaxes,spikephase,spiketime,varargin)
            % plot function for spike phase 
             tolerancenumber=40;
            if nargin<2 % for figurecontrol.replot
               global spikephase_all spiketime_all
                spikephase=spikephase_all;
                spiketime=spiketime_all;
            end
            if nargin<4
                PhaseFigure=findobj('Tag','PhaseLocking');
                timewidth=findobj(PhaseFigure.commandpanel,'Tag','TimeLim');
                timewidth_value=str2num(timewidth.String);
                histwidth=findobj(PhaseFigure.commandpanel,'Tag','Width');
                histwidth_value=str2num(histwidth.String);
                tmpobj=findobj(PhaseFigure.figpanel,'type','axes');
                tmphold=findobj(PhaseFigure.commandpanel,'Style','popupmenu','Tag','Hold');
            else
                p=inputParser;
                addParameter(p,'Timerange',[],@isnumeric);
                addParameter(p,'Binwidth',20,@isnumeric);
                parse(p,varargin{:});
                timewidth_value=p.Results.Timerange;
                histwidth_value=p.Result.Binwidth;
            end
            % plot function
                if strcmp(tmphold.String{tmphold.Value},'width')  
                      axes(PhaseFigure.figpanel);
                    % if ~length(spikephase)>tolerancenumber
                    %  disp('the spike counts are lower than the tolerancenumber! using all spike counts to estimate phase locking value');
                    % end
                     phasewidth=linspace(-pi,pi,histwidth_value);
                     h=circ_plot(spikephase,'hist',[],phasewidth,true,true,'linewidth',2,'color','r');
                     timewidth.String=num2str([min(spiketime),max(spiketime)]);
                     [b,a]=hist(spikephase,histwidth_value);
                     [p,z]=circ_rtest(a,(b./sum(b)*tolerancenumber)');
                     text(0,0,num2str(p));
                        % set(h,'Parent',figaxes);
                elseif strcmp(tmphold.String{tmphold.Value},'time&width')
                      axes(PhaseFigure.figpanel);
                      phasewidth=linspace(-pi,pi,histwidth_value);
                      circ_plot(spikephase(spiketime>timewidth_value(1)&spiketime<timewidth_value(2)),'hist',[],histwidth_value,true,true,'linewidth',2,'color','r');
                      [b,a]=hist(spikephase(spiketime>timewidth_value(1)&spiketime<timewidth_value(2)),phasewidth);
                      [p,z]=circ_rtest(a,(b./sum(b)*tolerancenumber)');
                      text(0,0,num2str(p));
                       %set(h,'Parent',figaxes);
                end
           
            end
        function averageparams=getAverageparams(varargin)
            p=inputParser;
            addParameter(p,'Spike','none');
            addParameter(p,'Event','separate',@NeuroMethod.CheckAverageInput);
            addParameter(p,'Channel','none',@NeuroMethod.CheckAverageInput);
            addParameter(p,'Timerange',[0,1]);
            addParameter(p,'tolerancenumber',40);
            if nargin>1
                parse(p,varargin{:});
                averageparams=p.Results;
            else
                title='PhaseLocking average params';
                prompt={'spike class model (name-value/values)','channel average mode','event average mode','time range','tolerancenumber'};
                lines=4;
                def={'none','none','separate','0,1','40'};
                output=inputdlg(prompt,title,lines,def,'on');
                averageparams.Spike=output{1};
                [~,averageparams.Channel]=NeuroMethod.CheckAverageInput(output{2});
                [~,averageparams.Event]=NeuroMethod.CheckAverageInput(output{3});
                averageparams.Timerange=str2num(output{4});
                averageparams.tolerancenumber=str2num(output{5});
            end
        end
        function [p,z,length,angle]=rayleigh_test(spikephase,tolerancenumber)
                NeuroMethod.Checkpath('CircStat');
              if ~isempty(spikephase)
                if isempty(tolerancenumber)
                    for i=1:size(spikephase,2)
                        length(1,i)=circ_r(spikephase(:,i));
                        [p(1,i),z(1,i)]=circ_rtest(spikephase(:,i));
                        angle(1,i)=circ_mean(spikephase(:,i));
                    end
                elseif size(spikephase,1)>=tolerancenumber
                    rng('default');
                    valid=randperm(size(spikephase,1),tolerancenumber);
                    spikephase=spikephase(valid,:);
                    for i=1:size(spikephase,2)
                        length(1,i)=circ_r(spikephase(:,i));
                        [p(1,i),z(1,i)]=circ_rtest(spikephase(:,i));
                        angle(1,i)=circ_mean(spikephase(:,i));
                    end
                elseif size(spikephase,1)<tolerancenumber
                    warning('not enough spikes to estimate rayleigh test')
                    for i=1:size(spikephase,2)
                        p(1,i)=nan;
                        z(1,i)=nan;
                        length(1,i)=nan;
                        angle(1,i)=nan;
                    end
                end
              else
                  warning('no spikes in this event epoch to estimate rayleigh test')
                        p=[];
                        z=[];
                        length=[];
                        angle=[];
              end
          end
        end
    end


