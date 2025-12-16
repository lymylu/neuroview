classdef PhaseLocking < NeuroResult & NeuroPlot.NeuroPlot & BasicTag
    % Calculate the spike phase locking value to local field potential
    % using the hilbert transfrom to get the phase information
    % SPKPhase is the cell {spike,event}(spikenumber*channel)
    % provide the filtered LFPData {event}(time*channel)
    % t_lfp of filtered LFPData is the same as neuroresult.LFPinfo.time
    properties
        SPKPhase
        LFPfilter
        t_lfp
        Params
        filename=[];
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
            Figurepanel1=NeuroPlot.figurecontrol;
            Figurepanel1=Figurepanel.create([],'PhaseLocking',strcat('roseplot'));
            Figurepanel1.figpanel.Title=variablename;
            Figurepanel2=NeuroPlot.figurecontrol;
            Figurepanel2=Figurepanel2.create([],'FilteredLFP',strcat('plot',varargin{1}));
            Figurepanel2.figpanel.Title=variablename;
            Figurepanel=cat(1,Figurepanel1,Figurepanel2);
        end
        function [lfpfilter,t_lfp]=load_filterlfp(obj,channelindex,spikeindex,eventindex)
            if ~isempty(obj.filename) % load from h5file mode
                [lfpfilter,t_lfp]=obj.readlfp(channelindex,eventindex);
            else
                lfpfilter=cellfun(@(x) x(:,channelindex),obj.LFPfilter(eventindex),'UniformOutput',0);
                t_lfp=obj.t_lfp;
                if ~isnumeric(obj.t_lfp)
                    t_lfp=obj.t_lfp{eventindex};
                else
                    t_lfp=obj.t_lfp;
                end
            end
        end
        function spikephase=load_spikephase(obj,spikeindex,channelindex,eventindex)
            if ~isempty(obj.filename)
                spkphase=obj.readspk(spikeindex,channelindex,eventindex);
            else
                spkphase=cellfun(@(x) x(:,channelindex),obj.SPKPhase(spikeindex,eventindex),'UniformOutput',0);
            end
        end
        function plot(obj,Figurepanel,PanelManagement)
            SPKinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'SPKinfo'));
            LFPinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'LFPinfo'));
            EVTinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'EVTinfo'));
            eventindex=EVTinfo.getIndex;
            spikeindex=SPKinfo.getIndex;
            channelindex=LFPinfo.getIndex;
            if ismember(Figurepanel.plottype,'plot') % plot the filtered LFP
                [lfpfilter,t_lfp]=obj.load_filterlfp(channelindex,eventindex);
                lfpfilter=reshape(cell2mat(lfpfilter),size(lfpfilter{1},1),size(lfpfilter{1},2),[]);
                Figurepanel.plot(t_lfp,lfpfilter);
            elseif ismember(Figurepanel.plottype,'rose')
                spikephase=obj.load_spikephase(spikeindex,eventindex);
                Figurepanel.plot(spikephase);
            end
        end
        function [lfpfilter,t_lfp]=readlfp(obj,ChannelIndex,EVTIndex)
            EVTatt=h5info(obj.filename,'/LFPfilter');
            try
            t_lfp=h5read(obj.filename,'/t_lfp');
            end
            d=1;
             for i=1:length(EVTatt.Datasets)
                c=1;
                 if EVTIndex(i)
                     if islogical(EVTIndex(i))
                        eventindex=i;
                     else
                        eventindex=EVTIndex(i);
                     end
                        datatmpsize=h5info(obj.filename,['/LFPfilter/',num2str(eventindex)]);
                     try
                         t_lfp{d}=h5read(obj.filename,['/t_lfp/',num2str(eventindex)]);
                     end
                     try
                         currenttime=findobj('Tag','currenttime');
                         currentrange=findobj('Tag','timerange');
                         currenttime=str2num(currenttime.String);
                         currentrange=str2num(currentrange.String);
                         [~,index1]=min(abs(t_lfp-(currenttime+currentrange(1))));
                         [~,index2]=min(abs(t_lfp-(currenttime+currentrange(2))));
                         t_lfp=t_lfp(index1:index2);
                         index2=index2-index1+1;
                     catch
                         index1=1;index2=datatmpsize.Dataspace.Size(1);
                     end
                     for j=1:length(ChannelIndex)
                         if ChannelIndex(j)
                            LFPdatatmp{d}(:,c)=h5read(obj.filename,['/LFPfilter/',num2str(eventindex)],[index1,1,j],[index2,datatmpsize.Dataspace.Size(2),1]);
                            c=c+1;
                         end
                     end
                     d=d+1;
                 end
             end
             end
        function Averagealldata(obj,filemat)
             global Channelpanel Spikepanel Eventpanel
             multiWaitbar('calculating',0);
             multiWaitbar('Calculating...',0);
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             savepath=uigetdir('PromptString','Choose the save path');
            % begin the loop
            multiWaitbar('calculating',0);
            for i=1:length(tmpobj.String)
                tmpobj.Value=i; 
                obj.Changefilemat(filemat);
                  tmpobj1=findobj(Channelpanel.parent,'Tag','Channeltype_LFP');
                channeltype=1:length(tmpobj1.String);
                 tmpobj2=findobj(Eventpanel.parent,'Tag','Eventtype');
                 eventtype=1:length(tmpobj2.String);
                 tmpobj3=findobj(Spikepanel.parent,'Tag','Channeltype_SPK');
                 spiketype=1:length(tmpobj3.String);
                for j=1:length(channeltype)
                    for k=1:length(eventtype)
                        for l=1:length(spiketype)
                   try
                   if ~strcmp(tmpobj1.String{j},'All')&&~strcmp(tmpobj2.String{k},'All')&&~strcmp(tmpobj3.String{l},'All')                
                          Channelpanel.getValue({'Channeltype_LFP'},{'ChannelIndex'},channeltype(j));
                           Eventpanel.getValue({'Eventtype'},{'EventIndex'},eventtype(k));
                           Spikepanel.getValue({'Channeltype_SPK'},{'SpikeIndex'},spiketype(l));       
                        obj.Resultplotfcn();
                        obj.ResultSavefcn(savepath);
                    end
                   catch
                        disp(['Error',tmpobj.String{i},'Skip']);
                    end
                    end
                end
                multiWaitbar('Calculating..',i/length(filemat));
            end
            multiWaitbar('Calculating','close');
            end
         end
    end
    methods(Access='private')
        function  [spikeraster,spikephase,spiketime]=GetPhaseLocking(obj,type)
            global Result FilterLFP matvalue Fs_lfp t_lfp Chooseinfo Fs_spk t_spk Eventpanel Channelpanel Spikepanel spiketime spikephase
            spikephase=[]; spiketime=[];
            params=findobj(obj.NP,'Tag','Filterband');
            filterband=str2num(params.String);
            if isempty(FilterLFP(matvalue).LFP) || sum(FilterLFP(matvalue).Filterband ~=filterband)~=0
                FilterLFP(matvalue).Filterband=filterband;
                for i=1:size(Result.LFP,3)
                    tmp=eegfilt(Result.LFP(:,:,i)',Fs_lfp,filterband(1),filterband(2));
                    FilterLFP(matvalue).LFP(:,:,i)=tmp';
                end
            end
            eventindex=Eventpanel.getIndex('EventIndex');
            Chooseinfo(matvalue).Eventindex=Eventpanel.listorigin(eventindex);
            channelindex=Channelpanel.getIndex('ChannelIndex');
            Chooseinfo(matvalue).Channelindex=Channelpanel.listorigin(channelindex);
            LFPhilbert=hilbert(FilterLFP(matvalue).LFP(:,channelindex,eventindex));
            phaseLFP=atan2(imag(LFPhilbert),real(LFPhilbert));
            phaseLFP=squeeze(mean(phaseLFP,2));    
            phaseLFP=timeseries(phaseLFP,t_lfp);% using timeseries object for following resample to get phase
            spikeindex=Spikepanel.getIndex('SpikeIndex');
            Chooseinfo(matvalue).spikename=Spikepanel.listorigin(spikeindex);
            Spikename=Spikepanel.listorigin(spikeindex);
            Resulttmp=cell(1,length(find(eventindex==1)));
            switch type
                case 'MUA'
            for i=1:length(Spikename)
                tmp=eval(['Result.',Spikename{i},'.spiketime']);
                tmp=tmp(eventindex);
                for j=1:length(tmp)
                    Resulttmp{j}=cat(1,Resulttmp{j},tmp{j});
                end
            end
             for i=1:length(Resulttmp)
                    Resulttmp{i}=sort(Resulttmp{i});
                    spikeraster(i,:)=(binspikes(Resulttmp{i},Fs_spk,t_spk))';
             end
             spikephase=[];spiketime=[];
            for i=1:length(Spikename)
                tmp=eval(['Result.',Spikename{i}]);  
                [spikephasetmp,spiketimetmp]=PhaseLocking.getSpikephase(phaseLFP,t_lfp,tmp.spiketime(eventindex));
                spikephasetmp=cell2mat(spikephasetmp)';
                spiketimetmp=cell2mat(spiketimetmp');
                spikephase=cat(1,spikephase,spikephasetmp);
                spiketime=cat(1,spiketime,spiketimetmp);
            end
            case 'SUA'
                for i=1:length(Spikename)
                   tmp=eval(['Result.',Spikename{i}]);
                   [spikephase{i},spiketime{i}]=PhaseLocking.getSpikephase(phaseLFP,t_lfp,tmp.spiketime(eventindex));
                   for j=1:length(tmp.spiketime) 
                   spikeraster{i}(j,:)=(binspikes(tmp.spiketime{j},Fs_spk,t_spk))';
                   end
                end
            end
        end
    end
    methods(Static)
            function [spikephase,spiketime]=getSpikephase(phaseLFP,t,spiketime) 
                % this may cause some bugs in the spike phase?
            phaseLFP=resample(phaseLFP,linspace(t(1),t(end),10000*(t(end)-t(1))+1));
            time=round(phaseLFP.time,4);
            for i=1:length(spiketime)     
                spikephase{i}=phaseLFP.data(ismember(time,round(spiketime{i},4)),i)';
            end
            end
            function obj = cal(obj,neurorsult,DetailsAnalysis)
            obj.methodname='PhaseLocking';
            LFPoutput=[]; Spikeoutput=[]; obj.Result=[];
            % % get the LFP data
            obj.Params.Fs_lfp=str2num(objmatrix.LFPdata.Samplerate);
            LFPoutput = objmatrix.loadData(DetailsAnalysis,'LFP');
            % %  get the SPKdata
            obj.Params.Fs_spk=str2num(objmatrix.SPKdata.Samplerate);
            Spikeoutput = objmatrix.loadData(DetailsAnalysis,'SPK');
            Timetype=cellfun(@(x) contains(x,'Timetype:'),DetailsAnalysis,'UniformOutput',1);
            Timetype=regexpi(DetailsAnalysis{Timetype},':','split');
            dataall=[];
            % % %something wrong, wait for further correction (could not support duration mode)
            for i=1:length(LFPoutput.LFPdata)
                dataall=cat(3,dataall,LFPoutput.LFPdata{i});
            end
            obj.Result.LFP=dataall;
             timestart=cellfun(@(x) contains(x,'Timestart'),DetailsAnalysis,'UniformOutput',1);
             timestart=str2num(strrep(DetailsAnalysis{timestart},'Timestart:',''));
             timestop=cellfun(@(x) contains(x,'Timestop'),DetailsAnalysis,'UniformOutput',1);
             timestop=str2num(strrep(DetailsAnalysis{timestop},'Timestop:',''));
            spectime=linspace(timestart,timestop,size(dataall,1));
            spikename=fieldnames(Spikeoutput);
            timerange=Spikeoutput.timerange;
            for j=1:length(spikename)
                if strfind(spikename{j},'cluster')
                    data=eval(['Spikeoutput.',spikename{j},'.spiketime']);
                switch Timetype{2}
                    case 'timeduration' % % %  wait for further correction
                        duration=timerange(:,2)-timerange(:,1);
                        duration=cumsum(duration);
                        obj.Constant.t=duration(end);
                        duration=[0;duration(1:end-1)];
                        for i=1:length(duration)
                            data{i}=data{i}-timerange(i,1)+duration(i)
                        end
                    case 'timepoint'
                        timestart=cellfun(@(x) contains(x,'Timestart'),DetailsAnalysis,'UniformOutput',1);
                        timestart=str2num(strrep(DetailsAnalysis{timestart},'Timestart:',''));
                        timestop=cellfun(@(x) contains(x,'Timestop'),DetailsAnalysis,'UniformOutput',1);
                        timestop=str2num(strrep(DetailsAnalysis{timestop},'Timestop:',''));
                        for i=1:length(data)
                            data{i}=data{i}-timerange(i,1)+timestart;
                        end
                end
                    eval(['Spikeoutput.',spikename{j},'.spiketime=data']);
                    eval(['obj.Result.',spikename{j},'=Spikeoutput.',spikename{j},';']);
                end
            end
            obj.Description.eventdescription=LFPoutput.eventdescription;
            obj.Description.eventselect=LFPoutput.eventselect;
            obj.Description.channeldescription=LFPoutput.channeldescription;
            obj.Description.channelselect=LFPoutput.channelselect;
            obj.Constant.t_spk=[timestart, timestop];
            obj.Constant.t_lfp=spectime;
         end
            function replot 
                global PhaseFigure spiketime spikephase t_spk tolerancenumber
                    timewidth=findobj(PhaseFigure.commandpanel,'Tag','XLim');
                    timewidth_value=str2num(timewidth.String);
                    histwidth=findobj(PhaseFigure.commandpanel,'Tag','Width');
                    histwidth_value=str2num(histwidth.String);
                    tmpobj=findobj(PhaseFigure.figpanel,'type','axes');
                    tmphold=findobj(PhaseFigure.commandpanel,'Style','popupmenu','Tag','Hold');
                    if strcmp(tmphold.String{tmphold.Value},'x')
                        delete(tmpobj);
                        axes(PhaseFigure.figpanel);
                        if ~length(spikephase)>tolerancenumber
                         disp('the spike counts are lower than the tolerancenumber! using all spike counts to estimate phase locking value');
                        end
                        circ_plot(spikephase(spiketime>timewidth_value(1)&spiketime<timewidth_value(2)),'hist',[],20,true,true,'linewidth',2,'color','r');
                        histwidth.String=num2str(20);
                        phasewidth=linspace(-pi,pi,20);
                        [b,a]=hist(spikephase(spiketime>timewidth_value(1)&spiketime<timewidth_value(2)),phasewidth);
                        [p,z]=circ_rtest(a,(b./sum(b)*tolerancenumber)');
                        text(0,0,num2str(p));
                    elseif strcmp(tmphold.String{tmphold.Value},'width')
                          delete(tmpobj);
                          axes(PhaseFigure.figpanel);
                        if ~length(spikephase)>tolerancenumber
                         disp('the spike counts are lower than the tolerancenumber! using all spike counts to estimate phase locking value');
                        end
                         phasewidth=linspace(-pi,pi,histwidth_value);
                          circ_plot(spikephase,'hist',[],phasewidth,true,true,'linewidth',2,'color','r');
                           timewidth.String=num2str(t_spk);
                          [b,a]=hist(spikephase,histwidth_value);
                            [p,z]=circ_rtest(a,(b./sum(b)*tolerancenumber)');
                           text(0,0,num2str(p));
                    elseif strcmp(tmphold.String{tmphold.Value},'x&width')
                          delete(tmpobj);
                          axes(PhaseFigure.figpanel);
                       if ~length(spikephase)>tolerancenumber
                         disp('the spike counts are lower than the tolerancenumber! using all spike counts to estimate phase locking value');
                       end
                        phasewidth=linspace(-pi,pi,histwidth_value);
                          circ_plot(spikephase(spiketime>timewidth_value(1)&spiketime<timewidth_value(2)),'hist',[],histwidth_value,true,true,'linewidth',2,'color','r');
                           [b,a]=hist(spikephase(spiketime>timewidth_value(1)&spiketime<timewidth_value(2)),phasewidth);
                              [p,z]=circ_rtest(a,(b./sum(b)*tolerancenumber)');
                           text(0,0,num2str(p));
                    else
                         timewidth.String=num2str(t_spk);
                         histwidth.String=num2str(20);
                         if ~length(spikephase)>tolerancenumber
                         disp('the spike counts are lower than the tolerancenumber! using all spike counts to estimate phase locking value');
                        end
                          [b,a]=hist(spikephase);
                         [p,z]=circ_rtest(a,(b./sum(b)*tolerancenumber)');
                           text(0,0,num2str(p));
                    end
            end
            function LoadSpikeClassifier(parent)
                global spikeclass 
                import NeuroPlot.SpikeClassifier
                spikeclass=SpikeClassifier();
                spikeclass=spikeclass.create('Parent',parent);
            end
            function setSpikeProperties
                global spikeclass Spikepanel
                    tmpobj=findobj(Spikepanel.parent,'Tag','SpikeIndex');
                    addlistener(tmpobj,'Value','PostSet',@(~,~) spikeclass.SetSpikeProperties(tmpobj));           
            end
            function [firingrate,neurotype]=getSpikeProperties
                global spikeclass Spikepanel
                    tmpobj=findobj(Spikepanel.parent,'Tag','SpikeIndex');
                    [firingrate,neurotype]=spikeclass.GetSpikeProperties(tmpobj);
            end
            function AssignSpikeClassifier(classifierpath)
            % varargin{1} is the Type Classifier, varargin{2} is the Spikeindex
                import NeuroPlot.SpikeClassifier
                global Channeldescription spikeclass Spikepanel
                spikeclass=spikeclass.assign(classifierpath,Channeldescription,Spikepanel);
            end
            function Filter=GetFilterValue()
                global spikeclass
                   Filter=spikeclass.GetFilterValue();
            end
            function err=SetFilterValue(Filter)
                global spikeclass Spikepanel
                err=spikeclass.SetFilterValue(Filter,Spikepanel);
            end
            function SelectPanelcreate(ResultSelectPanel)
                global Eventpanel Spikepanel Channelpanel
             ResultSelectBox=uix.VBox('Parent',ResultSelectPanel,'Padding',0);
             ResultSelect_infoselect=uix.HBox('Parent',ResultSelectBox,'Padding',0);
             Eventtypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Eventtypepanel');
             Eventpanel=NeuroPlot.selectpanel;
             Eventpanel=Eventpanel.create('Parent',Eventtypepanel,'listtitle',{'Eventnumber'},'listtag',{'EventIndex'},'typeTag',{'Eventtype'});
             Channeltypepanel=uix.Grid('Parent',ResultSelect_infoselect,'Tag','Channeltypepanel'); 
             Channelpanel=NeuroPlot.selectpanel;
             Channelpanel=Channelpanel.create('Parent',Channeltypepanel,'listtitle',{'Channel:LFP'},'listtag',{'ChannelIndex'},'typeTag',{'Channeltype_LFP'});
             Spiketypepanel=uix.Grid('Parent',ResultSelect_infoselect,'Tag','Spiketypepanel'); 
             Spikepanel=NeuroPlot.selectpanel;
             Spikepanel=Spikepanel.create('Parent',Spiketypepanel,'listtitle',{'Channel:SPK'},'listtag',{'SpikeIndex'},'typeTag',{'Channeltype_SPK'});
             set(ResultSelect_infoselect,'Width',[-1,-1,-1]);
            end
            function FigurePanelcreate(FigurePanel)
                global LFPFigure RasterFigure PhaseFigure
             Figcontrol1=uix.HBox('Parent',FigurePanel,'Padding',0,'Tag','Figcontrol1');
             Figpanel1=uix.Panel('Parent',FigurePanel,'Title','Filtered LFP','Tag','FilterLFPpanel');
             LFPFigure=NeuroPlot.figurecontrol;
             LFPFigure=LFPFigure.create(Figpanel1,Figcontrol1,'plot');
             Figcontrol2=uix.HBox('Parent',FigurePanel,'Padding',0,'Tag','Figcontrol2');
             Figpanel2=uix.Panel('Parent',FigurePanel,'Title','Raster Plot','Tag','Rasterpanel');
             RasterFigure=NeuroPlot.figurecontrol;
             RasterFigure=RasterFigure.create(Figpanel2,Figcontrol2,'raster');
             Figcontrol3=uix.HBox('Parent',FigurePanel,'Padding',0,'Tag','Figcontrol3');
             Figpanel3=uix.Panel('Parent',FigurePanel,'Title','Phase Locking','Tag','PhaseLockingpanel');
             PhaseFigure=NeuroPlot.figurecontrol;
             PhaseFigure=PhaseFigure.create(Figpanel3,Figcontrol3,'roseplot');
            end
            function saveblacklist(lfppanel,spikepanel,eventpanel)
                global Blacklist matvalue
                blacklist=findobj(eventpanel.parent,'Tag','blacklist');
                Blacklist(matvalue).Eventindex=blacklist.String;
                blacklist=findobj(spikepanel.parent,'Tag','blacklist');
                Blacklist(matvalue).spikename=blacklist.String;
                blacklist=findobj(lfppanel.parent,'Tag','blacklist');
                Blacklist(matvalue).Channelindex=blacklist.String;
          end  
    end
end

