classdef PerieventFiringHistogram < NeuroMethod & NeuroPlot.NeuroPlot
    properties
        psth
        t_spk
        filename=[];
    end
    methods (Access='public')
        %% method for NeuroMethod
        function obj=GenerateObjects(obj,filemat)
            import NeuroPlot.selectpanel NeuroPlot.commandcontrol NeuroPlot.LoadSpikeClassifier
            global Chooseinfo Blacklist Eventpanel Spikepanel spikeclassifier
            NeuroMethod.Checkpath('GUI Layout Toolbox');
            Chooseinfo=[];
            Blacklist=[];
            Eventpanel=[];
            Spikepanel=[];
            for i=1:length(filemat)
                Chooseinfo(i).spikename=[];
                Blacklist(i).spikename=[];
                Chooseinfo(i).Eventindex=[];
                Blacklist(i).Eventindex=[];
            end
            obj = GenerateObjects@NeuroPlot.NeuroPlot(obj,filemat);
             %% generate the ResultSelectPanel and its callbacks
             basetype={'None','Zscore','Subtract','ChangePercent'};
             Figurecommand=uix.Panel('Parent',obj.FigurePanel,'Title','Baselinecorrect');
             FigurecommandPanel=uix.HBox('Parent',Figurecommand,'Padding',5);
             set(obj.FigurePanel,'Heights',[-1,-8,-1,-3,-2]);
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Baselinebegin');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','-2','Tag','baselinebegin');
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Baselineend');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','0','Tag','baselineend');
             uicontrol('Style','popupmenu','Parent',FigurecommandPanel,'String',basetype,'Value',1,'Tag','basecorrect');
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','bin width');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','0.1','Tag','BinWidth');
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','smooth');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','0','Tag','smooth');
             spikeclasspanel=uix.Panel('parent',obj.MainBox,'Tag','SpikeClassPanel','Title','SpikeProperties');
             set(obj.MainBox,'Width',[-1,-3,-1]);
             spikeclassifier=NeuroPlot.SpikeClassifier();
             spikeclassifier=spikeclassifier.create(spikeclasspanel);
             tmpobj=findobj(Spikepanel.parent,'Tag','SpikeIndex');
             addlistener(tmpobj,'Value','PostSet',@(~,~) spikeclassifier.getCurrentIndex);
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             addlistener(tmpobj,'Value','PreSet',@(~,~) obj.saveblacklist(Eventpanel,Spikepanel)); 
             tmpobj=findobj(obj.NP,'Tag','Plotresult');
             addlistener(tmpobj,'Value','PostSet',@(~,~) obj.saveblacklist(Eventpanel,Spikepanel));         
            
             
        end
        function obj=Loadresult(obj,filemat,option)
            variablenames=fieldnames(filemat);  
            switch option
                case 'info'
                    obj.Result=[];
                    index=contains(variablenames,'info');
                    variablenames=variablenames(index);
                case 'data'
                    index=contains(variablenames,{'Result','SPKdata'});
                    variablenames=variablenames(index);
            end  
            for i=1:length(variablenames)
                try
                eval(['obj.',variablenames{i},'=filemat.',variablenames{i}]);
                end
            end
        end
        function Changefilemat(obj,filemat)
             % load the data mat file and define the callback 
             % the filename is the matfile from the neurodataanalysis2.
            global spikeclassifier t Fs matvalue Blacklist Eventpanel Spikepanel currentindex currentmat
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
             h=msgbox(['Loading data:',tmpobj.String(tmpobj.Value)]);  
            matvalue=tmpobj.Value;
            currentmat=filemat{matvalue};
            obj=obj.Loadresult(currentmat,'info');
            Eventdescription=obj.EVTinfo.eventdescription;
            t=obj.EVTinfo.timerange;
            Fs=str2num(obj.SPKinfo.Fs);
            Eventlist=num2cell(obj.EVTinfo.eventselect);
            Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
            Channeldescription=obj.SPKinfo.SPKchanneldescription';
            Spikelist=obj.SPKinfo.spikename;
            Eventpanel=Eventpanel.assign('liststring',Eventlist,'listtag',{'EventIndex'},'typetag',{'Eventtype'},'typestring',Eventdescription,'blacklist',Blacklist(matvalue).Eventindex);
            Spikepanel=Spikepanel.assign('liststring',Spikelist,'listtag',{'SpikeIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',Blacklist(matvalue).spikename);
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
        function Averagealldata(obj,filemat)
            % parameters initilized
            global Spikepanel Eventpanel
            tmpobj1=findobj(obj.NP,'Tag','Channeltype');
            tmpobj2=findobj(obj.NP,'Tag','Eventtype');
            eventtype=1:length(tmpobj2.String);
            channeltype=1:length(tmpobj1.String);
            savepath=uigetdir('PromptString','Choose the save path');
            % begin the loop
            multiWaitbar('calculating',0);
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            for i=1:length(filemat)
                    tmpobj.Value=i; 
                  try
                    obj.Changefilemat(filemat);  
                    for j=1:length(channeltype)
                        for k=1:length(eventtype)
                            if ~strcmp(tmpobj1.String(channeltype(j)),'All')&&~strcmp(tmpobj2.String(eventtype(k)),'All')
                                Spikepanel.getValue({'Channeltype'},{'SpikeIndex'},channeltype(j));
                                Eventpanel.getValue({'Eventtype'},{'EventIndex'},eventtype(k));
                                obj.Resultplotfcn();
                                obj.ResultSavefcn(savepath);
                            end
                        end
                    end
                  end
                multiWaitbar('calculating',i/length(filemat));
            end
            multiWaitbar('calculating','close');
        end
        function Msg(obj,msg,type)
            Msg@NeuroPlot.NeuroPlot(obj,msg,type);
        end
        function objnew=ResultCalfcn(obj)
                global  Chooseinfo matvalue Eventpanel Spikepanel
                [~, binnedraster, binnedspike,binwidth]=obj.GetSUAandMUA('SUA');
                 spikeindex=Spikepanel.getIndex('SpikeIndex');
                 eventindex=Eventpanel.getIndex('EventIndex');
                 Chooseinfo(matvalue).Eventindex=Eventpanel.listorigin(eventindex);
                 Chooseinfo(matvalue).spikename=Spikepanel.listorigin(spikeindex);
                obj.saveblacklist(Eventpanel,Spikepanel);
                objnew=PerieventFiringHistogram();
                objnew.Result.binneddata=binnedspike;
                objnew.Result.rasterdata=binnedraster;
                objnew.Resultinfo.binwidth=binwidth;
                objnew.Params=obj.Params;
                objnew.SPKinfo=obj.SPKinfo;
                objnew.SPKinfo.channelselect=obj.SPKinfo.channelselect(channelindex);
                objnew.SPKinfo.channeldescription=obj.SPKinfo.channeldescription(channelindex);
                objnew.EVTinfo.eventselect=obj.EVTinfo.eventselect(eventindex);
                objnew.EVTinfo.eventdescription=obj.EVTinfo.eventdescription(eventindex);
        end 
         function Resultplotfcn(obj) %% plot the MUA result, for SUA output, using ResultCalfcn
                global  t Fs RasterFigure HistogramFigure currentmat
                if isempty(obj.Result)
                    h=msgbox('initial loading data');
                    obj.Loadresult(currentmat,'data');
                    close(h);
                end
                type=findobj(obj.NP,'Tag','SpikePresent');
                switch type.String
                    case 'MUA'
                [~, binnedraster, binnedspike]=obj.GetSUAandMUA('MUA');
                binnedspike=binnedspike';
                    case 'SUA'
                 [~, binnedraster, ~]=obj.GetSUAandMUA('MUA');
                 [~, ~, binnedspike]=obj.GetSUAandMUA('SUA');
                 for i=1:length(binnedspike)
                     binnedspiketmp(:,:,i)=binnedspike{i};
                 end
                 binnedspike=permute(binnedspiketmp,[2,1,3]);
                end
                RasterFigure.plot(logical(binnedraster),'PlotType','vertline2','TimePerBin',1/Fs,t);
                basebegin=findobj(obj.NP,'Tag','baselinebegin');
                baseend=findobj(obj.NP,'Tag','baselineend');
                basemethod=findobj(obj.NP,'Tag','basecorrect');
                tmpdata=basecorrect(squeeze(mean(binnedspike,2)),linspace(t(1),t(2),size(binnedspike,1)),str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
                smoothwidth=findobj(obj.NP,'Tag','smooth');
                if str2num(smoothwidth.String)~=0
                    tmpdata=smooth(tmpdata,str2num(smoothwidth.String));
                end
                HistogramFigure.plot(linspace(t(1),t(2),size(binnedspike,1)),nanmean(tmpdata,2));
                tmpobj=findobj(obj.NP,'Tag','Savename');
                tmpobj1=findobj(obj.NP,'Tag','Eventtype');
                tmpobj2=findobj(obj.NP,'Tag','Channeltype');
                tmpobj.String=[tmpobj1.String{tmpobj1.Value},'_',tmpobj2.String{tmpobj2.Value}];               
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
         function loadblacklist(obj,filemat)
                msg=loadblacklist@NeuroPlot.NeuroPlot();
                obj.Changefilemat(filemat);
                msgbox(['the blacklist of the files:',msg,' has been added.']);
         end 
          function CreateSaveFigurePanel(obj,FigureOutputBox)
                uicontrol('Parent',FigureOutputBox,'Style','togglebutton','Tag','SpikePresent','Value',1,'String','SUA','Callback',@(~,~) obj.ChangeSpikePresent);
            end
           function ChangeSpikePresent(obj)
                tmpobj=findobj(obj.NP,'Tag','SpikePresent');
                if get(tmpobj,'Value')==1
                    set(tmpobj,'String','SUA');
                else
                     set(tmpobj,'String','MUA');
                end
            end
    end
    methods (Access='private')
       function [Resultoutput, binnedraster, binnedspike,binwidth]=GetSUAandMUA(obj,type)
                global  t Fs Chooseinfo matvalue Eventpanel Spikepanel
                eventindex=Eventpanel.getIndex('EventIndex');
                Chooseinfo(matvalue).Eventindex=Eventpanel.listorigin(eventindex);
                spikeindex=Spikepanel.getIndex('SpikeIndex');
                Chooseinfo(matvalue).spikename=Spikepanel.listorigin(spikeindex);
                tmp=eval('obj.SPKdata(spikeindex,eventindex);');
                tmp=cellfun(@(x) x+min(t),tmp,'UniformOutput',0);
                binnedraster=[]; binnedspike=[]; Resultoutput=[]; 
                switch type
                    case 'MUA'  
                    Resulttmp=cell(1,sum(eventindex));   
                    for i=1:size(tmp,1)
                    for j=1:size(tmp,2)
                        Resulttmp{j}=cat(1,Resulttmp{j},tmp{i,j});
                    end
                    end
                        binwidth=findobj(obj.NP,'Tag','BinWidth');
                     for i=1:length(Resulttmp)
                        Resulttmp{i}=sort(Resulttmp{i});
                        binnedraster(i,:)=(binspikes(Resulttmp{i},Fs,t))';
                        binnedspike(i,:)=(binspikes(Resulttmp{i},1/str2num(binwidth.String),t))';
                     end
                    binnedspike(:,end)=[]; % the end of the result from the function 'binspikes' is NAN, i don't know why.
                    case 'SUA'
                    binnedraster=cell(1,size(tmp,1)); binnedspike=cell(1,size(tmp,1));Resultoutput=cell(1,size(tmp,1));
                    for i=1:size(tmp,1)
                          binwidth=findobj(obj.NP,'Tag','BinWidth');
                          for j=1:size(tmp,2)
                          binnedraster{i}(j,:)=(binspikes(tmp{i,j},Fs,t))';
                          binnedspike{i}(j,:)=(binspikes(tmp{i,j},1/str2num(binwidth.String),t))';
                          end
                          binnedspike{i}(:,end)=[];
                    end
                end        
       end
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
        function neuroresult= cal(params,objmatrix,DetailsAnalysis,resultname)
                 neuroresult = cal@NeuroMethod(params,objmatrix,DetailsAnalysis,resultname,'PerieventFiringHistogram');
        end
        function neuroresult = recal(params,neuroresult,resultname)
            obj=PerieventFiringHistogram();
            obj.Params=params;
            for i=1:size(neuroresult.SPKdata,1) % for each spike
                for j=1:size(neuroresult.SPKdata,2) % for each trial
                    spike(j).time=neuroresult.SPKdata{i,j};
                    if strcmp(params.methodname,'Binspikes')
                        if ~isempty(params.timerange)
                        timerange=linspace(params.timerange(1),params.timerange(2),(params.timerange(2)-params.timerange(1))/params.binwidth+1);
                        [binspike{i,j},binspiket]=binspikes(spike(j).time,1/params.binwidth,timerange);
                        else
                            [binspike{i,j},binpspiket{i,j}]=binspikes(spike(j).time,1/params.binwidth);
                        end
                    end
                end
            end
            obj.psth=binspike;
            obj.t_spk=binspiket;
            try
            neuroresult.addprop(resultname);
            end
            eval(['neuroresult.',resultname,'=obj;']);
        end
        function saveblacklist(eventpanel,spikepanel)
                global Blacklist matvalue
                blacklist=findobj(eventpanel.parent,'Tag','blacklist');
                if ~isempty(blacklist.String)
                Blacklist(matvalue).Eventindex=blacklist.String;
                end
                blacklist=findobj(spikepanel.parent,'Tag','blacklist');
                if ~isempty(blacklist.String)
                Blacklist(matvalue).spikename=blacklist.String;
                end
       end      
        function SelectPanelcreate(ResultSelectPanel)
            global Eventpanel Spikepanel
            ResultSelectBox=uix.VBox('Parent',ResultSelectPanel,'Padding',0);
            ResultSelect_infoselect=uix.HBox('Parent',ResultSelectBox,'Padding',0);
            Eventtypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Eventtypepanel');
            Eventpanel=NeuroPlot.selectpanel;
            Eventpanel=Eventpanel.create('Parent',Eventtypepanel,'listtitle',{'Eventnumber'},'listtag',{'EventIndex'},'typeTag',{'Eventtype'});
            Channeltypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Channeltypepanel');
            Spikepanel=NeuroPlot.selectpanel;
            Spikepanel=Spikepanel.create('Parent',Channeltypepanel,'listtitle',{'Spike name'},'listtag',{'SpikeIndex'},'typeTag',{'Channeltype'});
        end
        function FigurePanelcreate(FigurePanel)
            global RasterFigure HistogramFigure
             Figcontrol1=uix.HBox('Parent',FigurePanel,'Padding',0,'Tag','Figcontrol1');
             Figpanel1=uix.Panel('Parent',FigurePanel,'Title','Raster Plot','Tag','Rasterpanel');
             RasterFigure=NeuroPlot.figurecontrol();
             RasterFigure=RasterFigure.create(Figpanel1,Figcontrol1,'raster');
             Figcontrol2=uix.HBox('Parent',FigurePanel,'Padding',0,'Tag','Figcontrol2');
             Figpanel2=uix.Panel('Parent',FigurePanel,'Title','Histogram','Tag','Histogrampanel');
             HistogramFigure=NeuroPlot.figurecontrol();
             HistogramFigure=HistogramFigure.create(Figpanel2,Figcontrol2,'bar');
        end         
   end
end

