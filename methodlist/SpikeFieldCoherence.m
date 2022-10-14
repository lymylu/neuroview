classdef SpikeFieldCoherence < NeuroResult & NeuroPlot.NeuroPlot
    % Calculate the spike field coherence using chronux toolbox
    %
    properties
        Methodname='SpikeFieldCoherence';
        Params
        Result
    end
    methods
        function obj=inherit(obj,neuroresult)
                     variablenames=fieldnames(neuroresult);
                for i=1:length(variablenames)
                    eval(['obj.',variablenames{i},'=neuroresult.',variablenames{i}]);
                end
        end
        function obj = getParams(obj)
             prompt={'taper size','fpass','pad','slide window size and step'};
            title='input Params';
            lines=4;
            def={'3 5','0 100','0','0.5 0.1'};
            x=inputdlg(prompt,title,lines,def,'on');
            obj.Params.methodname='Multi-taper'; % using chronux method
            obj.Params.windowsize=str2num(x{4});
            obj.Params.fpass=str2num(x{2});
            obj.Params.pad=str2num(x{3});
            obj.Params.tapers=str2num(x{1});
            obj.Params.err=0;
            obj.Params.trialave=0;
            NeuroMethod.Checkpath('chronux');                  
        end     
        function obj = cal(obj,objmatrix,DetailsAnalysis)
            if strcmp(class(objmatrix),'NeuroData')
                dataoutput=objmatrix.LoadData(DetailsAnalysis);
            else
                tmpdata=matfile(objmatrix.Datapath);
                dataoutput=eval(['NeuroResult(tmpdata.',DetailsAnalysis,')']);
            end
             obj=obj.inherit(dataoutput);
             obj.Params.Fs=dataoutput.LFPinfo.Fs;
             obj.Params.Fs_spk=dataoutput.SPKinfo.Fs;
             switch dataoutput.EVTinfo.timetype
                 case 'timeduration'
                     dataoutput=dataoutput.Split2Splice;
             end
            dataall=[];
            obj.Params.windowfunction=kaiser(obj.Params.windowsize(1)*obj.Params.Fs,25); %%add a kaiser window
            for i=1:length(dataoutput.LFPdata)
                dataall=cat(3,dataall,dataoutput.LFPdata{i});
            end
            for j=1:size(dataoutput.SPKdata,1)
                        for i=1:length(dataoutput.SPKdata(j,:))
                            x(i).spiketime=dataoutput.SPKdata{j,i};
                        end
                    for i=1:size(dataall,2) % for each channel
                    [Coherence(:,:,i,:),~,~,~,~,t,f]=cohgramcpt(squeeze(dataall(:,i,:)),x,obj.Params.windowsize,obj.Params,0);
                    end
                    obj.Result.Coherence(:,:,i,:,j)=Coherence(:,:,i,:); % coherence is a time*frequency*channel*event*spike matrix include nan;
                end           
            obj.Result.t_lfp=t; % may be modified ~_~
            obj.Result.f_lfp=f;
         end
        %% method for SpikeFieldCoherence
         function obj=GenerateObjects(obj,filemat)
             import NeuroPlot.selectpanel NeuroPlot.commandcontrol NeuroPlot.LoadSpikeClassifier
             global Chooseinfo Blacklist Eventpanel Spikepanel spikeclassifier Channelpanel
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
             spikeclasspanel=uix.Panel('parent',obj.MainBox,'Tag','SpikeClassPanel','Title','SpikeProperties');
             set(obj.MainBox,'Width',[-1,-3,-1]);
             spikeclassifier=NeuroPlot.SpikeClassifier();
             spikeclassifier=spikeclassifier.create(spikeclasspanel);
             tmpobj=findobj(Spikepanel.parent,'Tag','SpikeIndex');
             addlistener(tmpobj,'Value','PostSet',@(~,~) spikeclassifier.getCurrentIndex);
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             addlistener(tmpobj,'Value','PreSet',@(~,~) obj.saveblacklist(Eventpanel,Channelpanel,Spikepanel)); 
             tmpobj=findobj(obj.NP,'Tag','Plotresult');
             addlistener(tmpobj,'Value','PostSet',@(~,~) obj.saveblacklist(Eventpanel,Channelpanel,Spikepanel));     
         end
         function obj=Loadresult(obj,filemat,option)
            variablenames=fieldnames(filemat);  
            switch option
                case 'info'
                    obj.Result=[];
                    index=contains(variablenames,'info');
                    variablenames=variablenames(index);
                case 'data'
                    index=contains(variablenames,{'Result','SPKdata','LFPdata'});
                    variablenames=variablenames(index);
            end  
            for i=1:length(variablenames)
                try
                eval(['obj.',variablenames{i},'=filemat.',variablenames{i}]);
                end
            end
        end
         function obj=Changefilemat(obj,filemat)
            global Channelpanel matvalue Blacklist Eventpanel Spikepanel spikeclassifier currentindex currentmat
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            h=msgbox('Loading data...');
            matvalue=tmpobj.Value;
            currentmat=filemat{matvalue};
            obj=obj.Loadresult(currentmat,'info');
            % event information
            Eventlist=num2cell(obj.EVTinfo.eventselect);
            Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
            Eventdescription=obj.EVTinfo.eventdescription;
            Eventpanel=Eventpanel.assign('liststring',Eventlist,'listtag',{'EventIndex'},'typetag',{'Eventtype'},'typestring',Eventdescription,'blacklist',Blacklist(matvalue).Eventindex);
            % lfp information
            Channellist=num2cell(obj.LFPinfo.channelselect);
            Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
            Channeldescription=obj.LFPinfo.channeldescription;
            Channelpanel=Channelpanel.assign('liststring',Channellist,'listtag',{'ChannelIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',Blacklist(matvalue).Channelindex);
            % spk information
            SPKdescription=obj.SPKinfo.channeldescription;
            Spikelist=obj.SPKinfo.name;
            Spikepanel=Spikepanel.assign('liststring',Spikelist,'listtag',{'SpikeIndex'},'typetag',{'Channeltype'},'typestring',SPKdescription,'blacklist',Blacklist(matvalue).spikename);
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
            currentindex=logical(ones(length(Spikelist),1));
            spikeclassifier=spikeclassifier.assign(obj);
            tmpobj=findobj(Spikepanel.parent,'Tag','SpikeIndex');
            addlistener(tmpobj,'Value','PostSet',@(~,~) spikeclassifier.getCurrentIndex);
            tmpobj=findobj(spikeclassifier.parent,'Tag','filter');
            set(tmpobj,'Callback',@(~,~) obj.GetFilterValue);
            obj.GetFilterValue;
         end
         function loadblacklist(obj,filemat)
            msg=loadblacklist@NeuroPlot.NeuroPlot();
            obj.Changefilemat(filemat);
            msgbox(['the blacklist of the files:',msg,' has been added.']);
          end
         function Msg(obj,msg,type)
            Msg@NeuroPlot.NeuroPlot(obj,msg,type);
          end
         function obj=Averagealldata(obj,filemat)
               global Channelpanel Eventpanel Spikepanel
                multiWaitbar('calculating',0);
                 multiWaitbar('Calculating...',0);
                 tmpobj=findobj(obj.NP,'Tag','Matfilename');
                 SpikeFieldCoherence.saveblacklist(Channelpanel,Spikepanel,Eventpanel);
                 savepath=uigetdir('PromptString','Choose the save path');
                 for i=1:length(tmpobj.String)
                tmpobj.Value=i; 
                obj.Changefilemat(filemat);
                  tmpobj1=findobj(Channelpanel.parent,'Tag','Channeltype');
                channeltype=1:length(tmpobj1.String);
                 tmpobj2=findobj(Eventpanel.parent,'Tag','Eventtype');
                 eventtype=1:length(tmpobj2.String);
                 tmpobj3=findobj(Spikepanel.parent,'Tag','Channeltype');
                 spiketype=1:length(tmpobj3.String);
                for j=1:length(channeltype)
                    for k=1:length(eventtype)
                        for l=1:length(spiketype)
                            try
                            if ~strcmp(tmpobj1.String{j},'All')&&~strcmp(tmpobj2.String{k},'All')&&~strcmp(tmpobj3.String{l},'All')
                                Channelpanel.getValue({'Channeltype'},{'ChannelIndex'},channeltype(j));
                                Eventpanel.getValue({'Eventtype'},{'EventIndex'},eventtype(k));
                                Spikepanel.getValue({'Channeltype'},{'SpikeIndex'},spiketype(l));
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
         function Resultplotfcn(obj)
                global  Spikepanel Eventpanel Channelpanel RasterFigure SFCFigure LFPFigure
                if isempty(obj.Result)
                    h=msgbox('initial loading data');
                    obj.Loadresult(currentmat,'data');
                    close(h);
                end
                obj.saveblacklist(Channelpanel,Spikepanel,Eventpanel);
                [originLFP,originspike,spikefieldcoherence,rasterspike]= obj.GetSpikeFieldCoherence('MUA');
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
                    objnew=obj.ResultCalfcn();
                    [path,name]=fileparts(FilePath.Properties.Source);
                     if nargin>1
                         path=varargin{1};
                     end
                    savename=name;
                    ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,saveresult);
                    ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,Blacklist(matvalue),'Blacklist');
         end
         function saveresult=ResultCalfcn(obj)
                 global  matvalue Spikepanel Eventpanel Channelpanel Chooseinfo
                [originLFP,originspike,spikefieldcoherence]=obj.GetSpikeFieldCoherence('SUA');
                saveresult.Chooseinfo=Chooseinfo(matvalue);
                obj.saveblacklist(Channelpanel,Spikepanel,Eventpanel);
                saveresult.Chooseinfo=Chooseinfo(matvalue);
                saveresult.originspike=originspike;
                saveresult.originLFP=originLFP;
                saveresult.spikefieldcoherence=spikefieldcoherence;  
%                 saveresult.spikeraster=spikeraster;
                try
              [FiringRate,Neurotype]=obj.getSpikeProperties;  
              saveresult.firingrate=FiringRate;
                saveresult.celltype=Neurotype;
                end
            end
    end
    methods(Access='private')   
        function  [originLFP,originspike,spikefieldcoherence,binnedraster]=GetSpikeFieldCoherence(obj,option)
            global Channelpanel Eventpanel Spikepanel Chooseinfo
            eventindex=Eventpanel.getIndex('EventIndex');
            Chooseinfo(matvalue).Eventindex=Eventpanel.listorigin(eventindex);
            channelindex=Channelpanel.getIndex('ChannelIndex');
            Chooseinfo(matvalue).Channelindex=Channelpanel.listorigin(channelindex);
            spikeindex=Spikepanel.getIndex('SpikeIndex');
            Chooseinfo(matvalue).spikename=Spikepanel.listorigin(spikeindex);
            spikename=Spikepanel.listorigin(spikeindex);
            for i=1:length(spikename)
                tmp=eval(['obj.Result.',spikename{i}]);
                spikefieldcoherence(:,:,:,:,i)=tmp.spikefieldcoherence(:,:,channelindex,eventindex);    
                Resulttmp=cell(1,length(find(eventindex==1)));
                tmpspiketime=tmp.spiketime(eventindex);
                for j=1:length(tmpspiketime)
                        Resulttmp{j}=cat(1,Resulttmp{j},tmpspiketime{j});
                end
            end
            originLFP=Result.LFP(:,channelindex,eventindex);
            switch option
                case 'MUA'
                    spikefieldcoherence=nanmean(spikefieldcoherence,5);
            end
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
                global spikeclass Spikepanel
                   Spikepanel=Spikepanel.assign('liststring',obj.SPKinfo.Spikelist,'listtag',{'SpikeIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',Blacklist(matvalue).spikename);
                   Filter=spikeclass.GetFilterValue();
            end
            function err=SetFilterValue(Filter)
                global spikeclass Spikepanel
                err=spikeclass.SetFilterValue(Filter,Spikepanel);
            end
            function saveblacklist(eventpanel,lfppanel,spikepanel)
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