classdef PhaseLocking < NeuroResult & NeuroPlot.NeuroPlot
    % Calculate the spike phase locking value to local field potential
    % using the hilbert transfrom to get the phase information
   
    properties
        
        
    end
    
    methods
        function obj = getParams(obj)
        end     
         function obj = cal(obj,objmatrix,DetailsAnalysis)
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
        %% method for NeuroPlot
          function obj=GenerateObjects(obj,filemat)
             import NeuroPlot.selectpanel NeuroPlot.commandcontrol NeuroPlot.LoadSpikeClassifier
             global Chooseinfo Blacklist  Classpath FilterLFP Spikepanel Channelpanel Eventpanel
             for i=1:length(filemat)
                Chooseinfo(i).Channelindex=[];
                Blacklist(i).Channelindex=[];
                Chooseinfo(i).Eventindex=[];
                Blacklist(i).Eventindex=[];
                Chooseinfo(i).spikename=[];
                Blacklist(i).spikename=[];
                FilterLFP(i).LFP=[];
                FilterLFP(i).Filterband=[];
            end
             obj = GenerateObjects@NeuroPlot.NeuroPlot(obj,filemat);
             % Result select panel
             % Figure Panel, support several Result type 
             Figurecommand=uix.Panel('Parent',obj.FigurePanel,'Title','Params option');
             FigurecommandPanel=uix.HBox('Parent',Figurecommand,'Tag','Params','Padding',5);
             set(obj.FigurePanel,'Heights',[-1,-3,-1,-3,-1,-4,-2]);
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Filter band');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','4 8','Tag','Filterband');
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Spike tolerance number');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','40','Tag','tolerancenumber');
             Classpath=uigetdir('','Choose the root dir which contains the SpikeClass information');
            if Classpath ~=0
                spikeclasspanel=uix.Panel('parent',obj.MainBox,'Tag','SpikeClassPanel','Title','SpikeProperties');
                set(obj.MainBox,'Width',[-1,-3,-1]);
                obj.LoadSpikeClassifier(spikeclasspanel);
            end
         tmpobj=findobj(obj.NP,'Tag','Matfilename');
             addlistener(tmpobj,'Value','PreSet',@(~,~) PhaseLocking.saveblacklist(Channelpanel,Spikepanel,Eventpanel)); 
             tmpobj=findobj(obj.NP,'Tag','Plotresult');
             addlistener(tmpobj,'Value','PostSet',@(~,~) PhaseLocking.saveblacklist(Channelpanel,Spikepanel,Eventpanel));    
          end
          function obj=Changefilemat(obj,filemat)
            global Result Channelpanel t_lfp FilePath Fs_lfp t_spk Fs_spk matvalue Blacklist Eventpanel Spikepanel Classpath
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            h=msgbox('Loading data...');
            matvalue=tmpobj.Value;
            FilePath=filemat{matvalue};
            Result=getfield(FilePath,'Result');
            Fs_lfp=getfield(FilePath.Params,'Fs_lfp');
            Fs_spk=getfield(FilePath.Params,'Fs_spk');
            t_lfp=getfield(FilePath.Constant,'t_lfp');
            t_spk=getfield(FilePath.Constant,'t_spk');
            close(h);
            % event information
            Eventdescription=getfield(FilePath.Description,'eventdescription');
            Eventlist=num2cell(getfield(FilePath.Description,'eventselect'));
            Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
            Eventpanel=Eventpanel.assign('liststring',Eventlist,'listtag',{'EventIndex'},'typetag',{'Eventtype'},'typestring',Eventdescription,'blacklist',Blacklist(matvalue).Eventindex);
            % lfp information
            Channeldescription=getfield(FilePath.Description,'channeldescription');
            Channellist=num2cell(getfield(FilePath.Description,'channelselect'));
            Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
            Channelpanel=Channelpanel.assign('liststring',Channellist,'listtag',{'ChannelIndex'},'typetag',{'Channeltype_LFP'},'typestring',Channeldescription,'blacklist',Blacklist(matvalue).Channelindex);
            % spk information
            Spikelist=fieldnames(Result);
            Spikelist(strcmp(Spikelist,'LFP'))=[];
            SPKdescription=[];
            for i=1:length(Spikelist)
                tmp=eval(['Result.',Spikelist{i}]);
                SPKdescription=cat(1,SPKdescription,tmp.channeldescription);
            end
            Spikepanel=Spikepanel.assign('liststring',Spikelist,'listtag',{'SpikeIndex'},'typetag',{'Channeltype_SPK'},'typestring',SPKdescription,'blacklist',Blacklist(matvalue).spikename);
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
             obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
             if Classpath~=0
                 Filter=[];
                 Filter=obj.GetFilterValue;
                 [~,filename]=fileparts(tmpobj.String{tmpobj.Value});
                 obj.AssignSpikeClassifier(fullfile(Classpath,filename,[filename,'.cell_metrics.cellinfo.mat']));
                 err=obj.SetFilterValue(Filter);
                 obj.setSpikeProperties();
             end
          end
          function Msg(obj,msg,type)
            Msg@NeuroPlot.NeuroPlot(obj,msg,type);
          end
           function ResultSavefcn(obj,varargin)
               global FilePath saveresult matvalue Blacklist
                    saveresult=obj.ResultCalfcn();
                    [path,name]=fileparts(FilePath.Properties.Source);
                     if nargin>1
                         path=varargin{1};
                     end
                    savename=name;
                    ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,saveresult);
                    ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,Blacklist(matvalue),'Blacklist');
           end
             function Resultplotfcn(obj)
                global  t_lfp matvalue Fs_spk t_spk tolerancenumber Eventpanel Channelpanel FilterLFP LFPFigure PhaseFigure RasterFigure
                [spikeraster, spikephase]= obj.GetPhaseLocking('MUA');
                % rasterplot
                RasterFigure.plot(logical(spikeraster),'PlotType','vertline2','TimePerBin',1/Fs_spk,t_spk); 
                % filterLFP
                eventindex=Eventpanel.getIndex('EventIndex');
                Chooseinfo(matvalue).EventIndex=Eventpanel.listorigin(eventindex);
                channelindex=Channelpanel.getIndex('ChannelIndex');
                Chooseinfo(matvalue).ChannelIndex=Channelpanel.listorigin(channelindex);
                LFPFigure.plot(t_lfp,FilterLFP(matvalue).LFP(:,channelindex,eventindex));
                % phase
                 tolerancenum=findobj(obj.NP,'Tag','tolerancenumber');
                 tolerancenumber=str2num(tolerancenum.String);
                PhaseFigure.plot(spikephase,'hist',[],20,true,true,'linewidth',2,'color','r');
                tmpobj=findobj(obj.NP,'Tag','Savename');
                tmpobj1=findobj(obj.NP,'Tag','Eventtype');
                tmpobj2=findobj(obj.NP,'Tag','Channeltype_LFP');
                tmpobj3=findobj(obj.NP,'Tag','Channeltype_SPK');
                tmpobj.String=[tmpobj1.String{tmpobj1.Value},'_',tmpobj2.String{tmpobj2.Value},'_',tmpobj3.String{tmpobj3.Value}];
              
             end
             function saveresult=ResultCalfcn(obj)
                 global  Result t_lfp matvalue Fs_spk Spikepanel Eventpanel Channelpanel FilterLFP t_spk Fs_lfp Chooseinfo
                [~,spikephase,spiketime]=obj.GetPhaseLocking('SUA');
                saveresult.Chooseinfo=Chooseinfo(matvalue);
                obj.saveblacklist(Channelpanel,Spikepanel,Eventpanel);
                saveresult.spiketime=spiketime;
%                 saveresult.spikeraster=spikeraster;
                saveresult.spikephase=spikephase;
                saveresult.FilterLFP=FilterLFP(matvalue);
                saveresult.originLFP=Result.LFP;
                saveresult.t_lfp=t_lfp;
                saveresult.Fs_spk=Fs_spk;
                saveresult.t_spk=t_spk;
                saveresult.Fs_lfp=Fs_lfp;     
                    try
                    [FiringRate,Neurotype]=obj.getSpikeProperties; 
                    saveresult.firingrate=FiringRate;
                    saveresult.celltype=Neurotype;
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
          function loadblacklist(obj,filemat)
            msg=loadblacklist@NeuroPlot.NeuroPlot();
            obj.Changefilemat(filemat);
            msgbox(['the blacklist of the files:',msg,' has been added.']);
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

