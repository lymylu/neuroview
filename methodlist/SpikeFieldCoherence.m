classdef SpikeFieldCoherence < NeuroMethod & NeuroPlot.NeuroPlot
    % Calculate the spike field coherence using chronux toolbox
    %
    properties
    end
    methods
        function obj = getParams(obj)
             prompt={'taper size','fpass','pad','slide window size and step'};
            title='input Params';
            lines=4;
            def={'3 5','0 100','0','0.5 0.1'};
            x=inputdlg(prompt,title,lines,def,'on');
            obj.Params.methodname='Multi-taper';
            obj.Params.windowsize=str2num(x{4});
            obj.Params.fpass=str2num(x{2});
            obj.Params.pad=str2num(x{3});
            obj.Params.tapers=str2num(x{1});
            obj.Params.err=0;
            obj.Params.trialave=0;
            obj.Checkpath('chronux');                  
        end     
         function obj = cal(obj,objmatrix,DetailsAnalysis)
             obj.Result=[];
            obj.methodname='SpikeFieldCoherence';
            % % get the LFP data
            if strcmp(class(objmatrix),'NeuroData')
            obj.Params.Fs=str2num(objmatrix.LFPdata.Samplerate);
            LFPoutput = objmatrix.loadData(DetailsAnalysis,'LFP');
            % %  get the SPKdata
            obj.Params.Fs_spk=str2num(objmatrix.SPKdata.Samplerate);
            Spikeoutput = objmatrix.loadData(DetailsAnalysis,'SPK');
            Timetype=cellfun(@(x) contains(x,'Timetype:'),DetailsAnalysis,'UniformOutput',1);
            Timetype=regexpi(DetailsAnalysis{Timetype},':','split');
            else
                tmpdata=matfile(objmatrix.Datapath);
                LFPoutput=eval(['tmpdata.',DetailsAnalysis{:}]);
                obj.Params.Fs=str2num(LFPoutput.Fs);
                timestart=min(LFPoutput.relativetime);
                timestop=max(LFPoutput.relativetime);
                Spikeoutput=LFPoutput;
            end
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
                            data{i}=data{i}-timerange(i,1); %keep the spike time positive
                        end
                end
                    for i=1:length(data)
                        x(i).spiketime=data{i};
                    end
                    for i=1:size(obj.Result.LFP,2) % for each channel
                    [Coherence(:,:,i,:),~,~,~,~,t,f]=cohgramcpt(squeeze(obj.Result.LFP(:,i,:)),x,obj.Params.windowsize,obj.Params,0);
                    end
                    eval(['Spikeoutput.',spikename{j},'.spiketime=data;']);
                    eval(['Spikeoutput.',spikename{j},'.spikefieldcoherence=Coherence;']);
                    eval(['obj.Result.',spikename{j},'=Spikeoutput.',spikename{j},';']);
                end    
            end
            obj.Description.eventdescription=LFPoutput.eventdescription;
            obj.Description.eventselect=LFPoutput.eventselect;
            obj.Description.channeldescription=LFPoutput.channeldescription;
            obj.Description.channelselect=LFPoutput.channelselect;
            obj.Constant.t_spk=[timestart, timestop];
            obj.Constant.t_lfp=t+timestart;
            obj.Constant.f_lfp=f;
         end
        %% method for SpikeFieldCoherence
          function obj=GenerateObjects(obj,filemat)
             import NeuroPlot.selectpanel NeuroPlot.commandcontrol NeuroPlot.LoadSpikeClassifier
             global Chooseinfo Blacklist Channelpanel Eventpanel Spikepanel Classpath LFPFigure SFCFigure RasterFigure
             for i=1:length(filemat)
                Chooseinfo(i).Channelindex=[];
                Blacklist(i).Channelindex=[];
                Chooseinfo(i).Eventindex=[];
                Blacklist(i).Eventindex=[];
                Chooseinfo(i).spikename=[];
                Blacklist(i).spikename=[];
            end
             obj = GenerateObjects@NeuroPlot.NeuroPlot(obj,filemat);
             Figurecommand=uix.Panel('Parent',obj.FigurePanel,'Title','Params option');
             FigurecommandPanel=uix.HBox('Parent',Figurecommand,'Tag','Params','Padding',5);
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Baselinebegin');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','-2','Tag','baselinebegin');
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Baselineend');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','0','Tag','baselineend');
             set(obj.FigurePanel,'Heights',[-1,-3,-1,-3,-1,-4,-2]);
             Classpath=uigetdir('','Choose the root dir which contains the SpikeClass information');
            if Classpath ~=0
                spikeclasspanel=uix.Panel('parent',obj.MainBox,'Tag','SpikeClassPanel','Title','SpikeProperties');
                set(obj.MainBox,'Width',[-1,-3,-1]);
                obj.LoadSpikeClassifier(spikeclasspanel);
            end
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             addlistener(tmpobj,'Value','PreSet',@(~,~) obj.saveblacklist(Eventpanel,Channelpanel,Spikepanel)); 
             tmpobj=findobj(obj.NP,'Tag','Plotresult');
             addlistener(tmpobj,'Value','PostSet',@(~,~) obj.saveblacklist(Eventpanel,Channelpanel,Spikepanel));     
          end
          function obj=Changefilemat(obj,filemat,varargin)
            global Result Channelpanel t_spk FilePath t_sfc f_sfc Fs_spk matvalue Blacklist Eventpanel Spikepanel Classpath
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            h=msgbox('Loading data...');
            matvalue=tmpobj.Value;
            FilePath=filemat{matvalue};
            Result=FilePath.Result;
            Fs_spk=getfield(FilePath.Params,'Fs_spk');
            t_spk=getfield(FilePath.Constant,'t_spk');
            t_sfc=getfield(FilePath.Constant,'t_lfp');
            f_sfc=getfield(FilePath.Constant,'f_lfp');
            close (h);
            % event information
            Eventdescription=getfield(FilePath.Description,'eventdescription');
            Eventlist=num2cell(getfield(FilePath.Description,'eventselect'));
            Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
            Eventpanel=Eventpanel.assign('liststring',Eventlist,'listtag',{'EventIndex'},'typetag',{'Eventtype'},'typestring',Eventdescription,'blacklist',Blacklist(matvalue).Eventindex);
            % lfp information
            Channeldescription=getfield(FilePath.Description,'channeldescription');
            Channellist=num2cell(getfield(FilePath.Description,'channelselect'));
            Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
            Channelpanel=Channelpanel.assign('liststring',Channellist,'listtag',{'ChannelIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',Blacklist(matvalue).Channelindex);
            % spk information
            Spikelist=fieldnames(Result);
            Spikelist(strcmp(Spikelist,'LFP'))=[];
            SPKdescription=[];
            for i=1:length(Spikelist)
                tmp=eval(['Result.',Spikelist{i}]);
                SPKdescription=cat(1,SPKdescription,tmp.channeldescription);
            end
            Spikepanel=Spikepanel.assign('liststring',Spikelist,'listtag',{'SpikeIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',Blacklist(matvalue).spikename);
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
             obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
             if nargin>2
                 Channelpanel.getValue({'Channeltype'},{'ChannelIndex'},varargin{1});
                 Spikepanel.getValue({'Channeltype'},{'SpikeIndex'},varargin{2});
                 Eventpanel.getValue({'Eventtype'},{'EventIndex'},varargin{3});
             end
             if Classpath~=0
                 Filter=[];
                 Filter=obj.GetFilterValue;
                 [~,filename]=fileparts(tmpobj.String{tmpobj.Value});
                 obj.AssignSpikeClassifier(fullfile(Classpath,filename,[filename,'.cell_metrics.cellinfo.mat']));
                 err=obj.SetFilterValue(Filter);
                 obj.setSpikeProperties();
             end
          end
          function obj=Startupfcn(obj,filemat,varargin)
                obj.Changefilemat(filemat);
          end
          function loadblacklist(obj,filemat)
            msg=loadblacklist@NeuroPlot.NeuroPlot();
            obj.Startupfcn(filemat);
            msgbox(['the blacklist of the files:',msg,' has been added.']);
          end
          function Msg(obj,msg,type)
            Msg@NeuroPlot.NeuroPlot(obj,msg,type);
          end
          function obj=Averagealldata(obj,filemat)
               global Channelpanel Eventpanel Spikepanel
                multiWaitbar('calculating',0);
                 tmpobj1=findobj(Channelpanel.parent,'Tag','Channeltype');
                channeltype=1:length(tmpobj1.String);
                 tmpobj2=findobj(Eventpanel.parent,'Tag','Eventtype');
                 eventtype=1:length(tmpobj2.String);
                 tmpobj3=findobj(Spikepanel.parent,'Tag','Channeltype');
                 spiketype=1:length(tmpobj3.String);
                 multiWaitbar('Calculating...',0);
                 tmpobj=findobj(obj.NP,'Tag','Matfilename');
                 SpikeFieldCoherence.saveblacklist(Channelpanel.parent,Spikepanel.parent,Eventpanel.parent);
                 savepath=uigetdir('PromptString','Choose the save path');
                 for i=1:length(tmpobj.String)
                tmpobj.Value=i; 
                obj.Changefilemat(filemat);
                for j=1:length(channeltype)
                    for k=1:length(eventtype)
                        for l=1:length(spiketype)
                            if ~strcmp(tmpobj1.String{j},'All')&&~strcmp(tmpobj2.String{k},'All')&&~strcmp(tmpobj3.String{l},'All')
                    Channelpanel.getValue({'Channeltype'},{'ChannelIndex'},channeltype(j));
                    Eventpanel.getValue({'Eventtype'},{'EventIndex'},eventtype(k));
                    Spikepanel.getValue({'Channeltype'},{'SpikeIndex'},spiketype(l));
                    try
                        obj.Resultplotfcn();
                        obj.ResultSavefcn(savepath);
                    catch
                        disp(['Error',tmpobj.String{i},'Skip']);
                    end
                            end
                    end
                end
                multiWaitbar('Calculating..',i/length(filemat));
            end
            multiWaitbar('Calculating','close');
        end
          end
         function Resultplotfcn(obj)
                global  t_spk Fs_spk Spikepanel Eventpanel Channelpanel t_sfc f_sfc RasterFigure SFCFigure LFPFigure Result
                obj.saveblacklist(Channelpanel,Spikepanel,Eventpanel);
                [originLFP,originspike,spikefieldcoherence,rasterspike]= obj.GetSpikeFieldCoherence;
                RasterFigure.plot(logical(rasterspike),'PlotType','vertline2','TimePerBin',1/Fs_spk,t_spk);
                basebegin=findobj(obj.NP,'Tag','baselinebegin');
                baseend=findobj(obj.NP,'Tag','baselineend');
                basemethod=findobj(obj.NP,'Tag','basecorrect_origin');
                LFP_t=linspace(t_spk(1),t_spk(2),size(originLFP,1));
                tmpdata=basecorrect(originLFP,LFP_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
                LFPFigure.plot(LFP_t,tmpdata);
                basemethod=findobj(obj.NP,'Tag','basecorrect_sfc');
                tmpdata=squeeze(nanmean(nanmean(spikefieldcoherence,3),4))
                tmpdata=basecorrect(tmpdata,t_sfc,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
                h=fspecial('gaussian',[3,3],1);
                tmpdata=imfilter(tmpdata,h);
                SFCFigure.plot(t_sfc,f_sfc,tmpdata');
                tmpobj=findobj(obj.NP,'Tag','Savename');
                tmpobj1=findobj(obj.NP,'Tag','Eventtype');
                tmpobj2=findobj(obj.NP,'Tag','Channeltype');
                tmpobj.String=[tmpobj1.String{tmpobj1.Value},'_',tmpobj2(1).String{tmpobj2(1).Value},'_',tmpobj2(2).String{tmpobj2(2).Value}];
         end 
         function ResultSavefcn(obj,varargin)
             global matvalue Chooseinfo FilePath Blacklist
              [originLFP,originspike,spikefieldcoherence]=obj.GetSpikeFieldCoherence();
              [FiringRate,Neurotype]=obj.getSpikeProperties;
                saveresult.Chooseinfo=Chooseinfo(matvalue);
                saveresult.originspike=originspike;
                saveresult.originLFP=originLFP;
                saveresult.spikefieldcoherence=spikefieldcoherence;  
                saveresult.firingrate=FiringRate;
                saveresult.celltype=Neurotype;
            [path,name]=fileparts(FilePath.Properties.Source);
             if nargin>2
                 path=varargin{2};
             end
            savename=name;
            ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,saveresult);
            ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,Blacklist(matvalue),'Blacklist');
         end
    end
    methods(Access='private')   
        function  [originLFP,originspike,spikefieldcoherence,binnedraster]=GetSpikeFieldCoherence(obj)
            global Channelpanel Eventpanel Spikepanel Result matvalue Fs_spk t_spk Chooseinfo
            eventindex=Eventpanel.getIndex('EventIndex');
            Chooseinfo(matvalue).EventIndex=Eventpanel.listorigin(eventindex);
            channelindex=Channelpanel.getIndex('ChannelIndex');
            Chooseinfo(matvalue).ChannelIndex=Channelpanel.listorigin(channelindex);
            spikeindex=Spikepanel.getIndex('SpikeIndex');
            Chooseinfo(matvalue).spikename=Spikepanel.listorigin(spikeindex);
            spikename=Spikepanel.listorigin(spikeindex);
            for i=1:length(spikename)
                tmp=eval(['Result.',spikename{i}]);
                spikefieldcoherence(:,:,:,:,i)=tmp.spikefieldcoherence(:,:,channelindex,eventindex);    
                Resulttmp=cell(1,length(find(eventindex==1)));
                tmpspiketime=tmp.spiketime(eventindex);
                for j=1:length(tmpspiketime)
                        Resulttmp{j}=cat(1,Resulttmp{j},tmpspiketime{j});
                end
            end
            originLFP=Result.LFP(:,channelindex,eventindex);
            spikefieldcoherence=nanmean(spikefieldcoherence,5);
            for i=1:length(Resulttmp)
                    Resulttmp{i}=sort(Resulttmp{i});
                    binnedraster(i,:)=(binspikes(Resulttmp{i}+t_spk(1),Fs_spk,t_spk))';
                    originspike{i}=Resulttmp{i};
            end
        end
    end
    methods(Static)
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
            function saveblacklist(lfppanel,spikepanel,eventpanel)
                global Blacklist matvalue
                blacklist=findobj(eventpanel.parent,'Tag','blacklist');
                Blacklist(matvalue).Eventindex=blacklist.String;
                blacklist=findobj(spikepanel.parent,'Tag','blacklist');
                Blacklist(matvalue).spikename=blacklist.String;
                blacklist=findobj(lfppanel.parent,'Tag','blacklist');
                Blacklist(matvalue).Channelindex=blacklist.String;
            end         
            function SelectPanelcreate(ResultSelectPanel)
                global Eventpanel Channelpanel Spikepanel
                 ResultSelectBox=uix.VBox('Parent',ResultSelectPanel,'Padding',0);
                 ResultSelect_infoselect=uix.HBox('Parent',ResultSelectBox,'Padding',0);
                 Eventtypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Eventtypepanel');
                 Eventpanel=NeuroPlot.selectpanel;
                 Eventpanel=Eventpanel.create('Parent',Eventtypepanel,'listtitle',{'Eventnumber'},'listtag',{'EventIndex'},'typeTag',{'Eventtype'});
                 Channeltypepanel=uix.Grid('Parent',ResultSelect_infoselect,'Tag','Channeltypepanel'); 
                 Channelpanel=NeuroPlot.selectpanel;
                 Channelpanel=Channelpanel.create('Parent',Channeltypepanel,'listtitle',{'Channel:LFP'},'listtag',{'ChannelIndex'},'typeTag',{'Channeltype'});
                 Spiketypepanel=uix.Grid('Parent',ResultSelect_infoselect,'Tag','Spiketypepanel'); 
                 Spikepanel=NeuroPlot.selectpanel;
                 Spikepanel=Spikepanel.create('Parent',Spiketypepanel,'listtitle',{'Channel:SPK'},'listtag',{'SpikeIndex'},'typeTag',{'Channeltype'});
                 set(ResultSelect_infoselect,'Width',[-1,-1,-1]);
            end
            function FigurePanelcreate(FigurePanel)
                global LFPFigure RasterFigure SFCFigure
                 basetype={'None','Zscore','Subtract','ChangePercent'};
                 Figcontrol1=uix.HBox('Parent',FigurePanel,'Padding',0,'Tag','Figcontrol1');
                 uicontrol('Style','popupmenu','Parent',Figcontrol1,'String',basetype,'Tag','basecorrect_origin');
                 Figpanel1=uix.Panel('Parent',FigurePanel,'Title','origin LFP','Tag','originLFPpanel');
                 LFPFigure=NeuroPlot.figurecontrol();
                 LFPFigure=LFPFigure.create(Figpanel1,Figcontrol1,'plot');
                 Figcontrol2=uix.HBox('Parent',FigurePanel,'Padding',0,'Tag','Figcontrol2');
                 Figpanel2=uix.Panel('Parent',FigurePanel,'Title','Raster Plot','Tag','Rasterpanel');
                 RasterFigure=NeuroPlot.figurecontrol();
                 RasterFigure=RasterFigure.create(Figpanel2,Figcontrol2,'raster');
                 Figcontrol3=uix.HBox('Parent',FigurePanel,'Padding',0,'Tag','Figcontrol3');
                 uicontrol('Style','popupmenu','Parent',Figcontrol3,'String',basetype,'Tag','basecorrect_sfc');
                 Figpanel3=uix.Panel('Parent',FigurePanel,'Title','SpikeFieldCoherence','Tag','SpikeFieldpanel');
                 SFCFigure=NeuroPlot.figurecontrol();
                 SFCFigure=SFCFigure.create(Figpanel3,Figcontrol3,'imagesc');
            end
    end
end