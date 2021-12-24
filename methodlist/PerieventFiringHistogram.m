classdef PerieventFiringHistogram < NeuroMethod & NeuroPlot.NeuroPlot
    properties
    end
    methods (Access='public')
        %% method for NeuroMethod
        function obj=getParams(obj)
        end
        function obj=cal(obj,objmatrix,DetailsAnalysis)
            Spikeoutput=objmatrix.loadData(DetailsAnalysis,'SPK');
            timerange=Spikeoutput.timerange;
            Timetype=cellfun(@(x) contains(x,'Timetype:'),DetailsAnalysis,'UniformOutput',1);
            Timetype=regexpi(DetailsAnalysis{Timetype},':','split');
            spikename=fieldnames(Spikeoutput);
            obj.Result=[];
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
            obj.Constant.t=[timestart, timestop];
            obj.Description.eventdescription=Spikeoutput.eventdescription;
            obj.Description.eventselect=Spikeoutput.eventselect;
            obj.methodname='PerieventFiringHistogram';
            obj.Params.Fs=Spikeoutput.Fs;
            obj.Description.channeldescription=Spikeoutput.channeldescription;
            obj.Description.channelname=Spikeoutput.channelname;
        end
        function savematfile=writeData(obj,savematfile)
            savematfile=writeData@NeuroMethod(obj,savematfile);
        end
        function obj=GenerateObjects(obj,filemat)
            import NeuroPlot.selectpanel NeuroPlot.commandcontrol NeuroPlot.LoadSpikeClassifier
            global Chooseinfo Blacklist Eventpanel Spikepanel  Classpath
            obj.Checkpath('GUI Layout Toolbox');
            Chooseinfo=[];
            Blacklist=[];
            Eventpanel=[];
            Spikepanel=[];
            Classpath=[];
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
            Classpath=uigetdir('','Choose the root dir which contains the SpikeClass information');
            if Classpath ~=0
                spikeclasspanel=uix.Panel('parent',obj.MainBox,'Tag','SpikeClassPanel','Title','SpikeProperties');
                set(obj.MainBox,'Width',[-1,-3,-1]);
                obj.LoadSpikeClassifier(spikeclasspanel);
            end
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             addlistener(tmpobj,'Value','PreSet',@(~,~) obj.saveblacklist(Eventpanel,Spikepanel)); 
             tmpobj=findobj(obj.NP,'Tag','Plotresult');
             addlistener(tmpobj,'Value','PostSet',@(~,~) obj.saveblacklist(Eventpanel,Spikepanel));         
        end
        function Changefilemat(obj,filemat,varargin)
             % load the data mat file and define the callback 
             % the filename is the matfile from the neurodataanalysis2.
            global Result Eventdescription Channeldescription t  FilePath Fs matvalue Blacklist Eventpanel Eventlist Spikepanel Spikelist Classpath
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
             h=msgbox(['Loading data:',tmpobj.String(tmpobj.Value)]);  
            matvalue=tmpobj.Value;
            FilePath=filemat{matvalue};
            Result=getfield(FilePath,'Result');
            Eventdescription=getfield(FilePath.Description,'eventdescription');
            t=getfield(FilePath.Constant,'t');
            Fs=getfield(FilePath.Params,'Fs');
            Fs=str2num(Fs);
             close(h);
            Eventlist=num2cell(getfield(FilePath.Description,'eventselect'));
            Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
            Spikelist=fieldnames(Result);
            Channeldescription=[]
            for i=1:length(Spikelist)
                tmp=eval(['Result.',Spikelist{i}]);
                Channeldescription=cat(1,Channeldescription,tmp.channeldescription);
            end
            Eventpanel=Eventpanel.assign('liststring',Eventlist,'listtag',{'EventIndex'},'typetag',{'Eventtype'},'typestring',Eventdescription,'blacklist',Blacklist(matvalue).Eventindex);
            Spikepanel=Spikepanel.assign('liststring',Spikelist,'listtag',{'SpikeIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',Blacklist(matvalue).spikename);
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
             if nargin>2
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
        function obj=Startupfcn(obj,filemat,varargin)
                obj.Changefilemat(filemat);
        end
        function Msg(obj,msg,type)
            Msg@NeuroPlot.NeuroPlot(obj,msg,type);
        end
        function saveresult=ResultCalfcn(obj)
                global  Chooseinfo matvalue Eventpanel Spikepanel
                [Resultoutput, binnedraster, binnedspike]=obj.GetSUAandMUA('SUA');
                saveresult.Chooseinfo=Chooseinfo(matvalue);
                obj.saveblacklist(Eventpanel,Spikepanel);
                saveresult.rawdata=Resultoutput;
                saveresult.rasterdata=binnedraster;
                saveresult.binneddata=binnedspike;
                try
                [FiringRate,Neurotype]=obj.getSpikeProperties; 
                saveresult.firingrate=FiringRate;
                saveresult.celltype=Neurotype;
                end
        end 
         function Resultplotfcn(obj) %% plot the MUA result, for SUA output, using ResultCalfcn
                global  t Fs RasterFigure HistogramFigure
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
                RasterFigure.plot(logical(binnedraster),'PlotType','vertline2','TimePerBin',1/Fs);
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
                obj.Startupfcn(filemat);
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
       function [Resultoutput, binnedraster, binnedspike]=GetSUAandMUA(obj,type)
                global  t Fs Result Chooseinfo matvalue Eventpanel Spikepanel
                eventindex=Eventpanel.getIndex('EventIndex');
                Chooseinfo(matvalue).Eventindex=Eventpanel.listorigin(eventindex);
                spikeindex=Spikepanel.getIndex('SpikeIndex');
                Chooseinfo(matvalue).spikename=Spikepanel.listorigin(spikeindex);
                spikename=Spikepanel.listorigin(spikeindex);
                switch type
                    case 'MUA'  
                        Resulttmp=cell(1,sum(eventindex)); binnedraster=[]; binnedspike=[]; Resultoutput=[];
                    for i=1:length(spikename)
                    tmp=eval(['Result.',spikename{i},'.spiketime']);
                    tmp=tmp(eventindex);
                    for j=1:length(tmp)
                        Resulttmp{j}=cat(1,Resulttmp{j},tmp{j});
                    end
                    end
                        binwidth=findobj(obj.NP,'Tag','BinWidth');
                     for i=1:length(Resulttmp)
                        Resulttmp{i}=sort(Resulttmp{i});
                        binnedraster(i,:)=(binspikes(Resulttmp{i},Fs,t))';
                        binnedspike(i,:)=(binspikes(Resulttmp{i},1/str2num(binwidth.String),t))';
                        Resultoutput{i}=Resulttmp{i};
                     end
                    binnedspike(:,end)=[]; % the end of the result from the function 'binspikes' is NAN, i don't know why.
                    case 'SUA'
                    binnedraster=cell(1,length(spikename)); binnedspike=cell(1,length(spikename));Resultoutput=cell(1,length(spikename));
                    for i=1:length(spikename)
                          tmp=eval(['Result.',spikename{i},'.spiketime']);
                          tmp=tmp(eventindex);
                          binwidth=findobj(obj.NP,'Tag','BinWidth');
                          for j=1:length(tmp)
                          binnedraster{i}(j,:)=(binspikes(tmp{j},Fs,t))';
                          binnedspike{i}(j,:)=(binspikes(tmp{j},1/str2num(binwidth.String),t))';
                          end
                          binnedspike{i}(:,end)=[];
                          Resultoutput{i}=tmp;
                    end
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

