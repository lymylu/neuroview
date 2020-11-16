classdef PerieventFiringHistogram < NeuroMethod & NeuroPlot.NeuroPlot
    properties
    end
    methods (Access='public')
        %% method for NeuroMethod
        function obj=getParams(obj,timetype)
            switch timetype
                 case 'timepoint'
                    msgbox('the timepoint mode will cal each timepoint as individual epochs');
                case 'duration'
                    msgbox('the duration mode will combine several epochs as a continuous epoch');
            end
        end
        function obj=cal(obj,objmatrix,DetailsAnalysis)
            Spikeoutput=objmatrix.loadData(DetailsAnalysis,'SPKtime');
            timerange=Spikeoutput.timerange;
            data=Spikeoutput.spiketime;
            Timetype=cellfun(@(x) contains(x,'Timetype:'),DetailsAnalysis,'UniformOutput',1);
            Timetype=regexpi(DetailsAnalysis{Timetype},':','split');
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
                    obj.Constant.t=[timestart, timestop];
            end
            obj.Result.spiketime=data;
            obj.Description.eventdescription=Spikeoutput.eventdescription;
            obj.Description.eventselect=Spikeoutput.eventselect;
            obj.Description.spiketimedescription=Spikeoutput.spikename;
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
            global Chooseinfo Blacklist Eventpanel Spikepanel Classpath
            obj.Checkpath('GUI Layout Toolbox');
            for i=1:length(filemat)
                Chooseinfo(i).spikename=[];
                Blacklist(i).spikename=[];
                Chooseinfo(i).Eventindex=[];
                Blacklist(i).Eventindex=[];
            end
            obj = GenerateObjects@NeuroPlot.NeuroPlot(obj);
         
             %% generate the ResultSelectPanel and its callbacks
             ResultSelectBox=uix.VBox('Parent',obj.ResultSelectPanel,'Padding',0);
             SpikeClassifierPanel=uix.HBox('Parent',ResultSelectBox,'Padding',0,'Tag','SpikeClassifier'); 
             ResultSelect_infoselect=uix.HBox('Parent',ResultSelectBox,'Padding',0);
             set(ResultSelectBox,'Heights',[-1,-7]);
             Eventtypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Eventtypepanel');
             Eventpanel=selectpanel;
             Eventpanel=Eventpanel.create('Parent',Eventtypepanel,'listtitle',{'Eventnumber'},'listtag',{'EventIndex'},'typeTag',{'Eventtype'});
             Channeltypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Channeltypepanel');
             Spikepanel=selectpanel;
             Spikepanel=Spikepanel.create('Parent',Channeltypepanel,'listtitle',{'Spike name'},'listtag',{'SpikeIndex'},'typeTag',{'Channeltype'});
             basetype={'None','Zscore','Subtract','ChangePercent'};
             Figcontrol1=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol1');
             Figpanel1=uix.Panel('Parent',obj.FigurePanel,'Title','Raster Plot','Tag','Rasterpanel');
             NeuroPlot.commandcontrol('Parent',Figcontrol1,'Plottype','raster','Command','create','Linkedaxes',Figpanel1);
             Figcontrol2=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol2');
             Figpanel2=uix.Panel('Parent',obj.FigurePanel,'Title','Histogram','Tag','Histogrampanel');
             NeuroPlot.commandcontrol('Parent',Figcontrol2,'Plottype','plot','Command','create','Linkedaxes',Figpanel2);
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
                obj.LoadSpikeClassifier();
            end
             tmpobj=findobj(obj.NP,'Tag','Plotresult');
             set(tmpobj,'Callback',@(~,src) obj.Resultplotfcn());
             tmpobj=findobj(obj.NP,'Tag','Resultsave');
             set(tmpobj,'Callback',@(~,src) obj.ResultSavefcn());
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             set(tmpobj,'String',cellfun(@(x) x.Properties.Source(1:end-4),filemat,'UniformOutput',0),'Value',1,'Callback',@(~,~) obj.Changefilemat(filemat))
             addlistener(tmpobj,'Value','PreSet',@(~,~) obj.saveblacklist(Eventtypepanel,Channeltypepanel)); 
             tmpobj=findobj(obj.NP,'Tag','Averagealldata');
             set(tmpobj,'Callback',@(~,~) obj.Averagealldata(filemat));
             tmpobj=findobj(obj.NP,'Tag','Loadselectinfo');
             set(tmpobj,'Callback',@(~,~) obj.loadblacklist(filemat));
        end
        function err=Changefilemat(obj,filemat,varargin)
             % load the data mat file and define the callback 
             % the filename is the matfile from the neurodataanalysis2.
            global Result Eventdescription Spiketimedescription Channeldescription Channelname t  FilePath Fs matvalue Blacklist Eventpanel Eventlist Spikepanel Spikelist Classpath
            err=1;
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
             h=msgbox(['Loading data:',tmpobj.String(tmpobj.Value)]);  
            matvalue=tmpobj.Value;
            FilePath=filemat{matvalue};
            Result=getfield(FilePath.Result,'spiketime');
            Eventdescription=getfield(FilePath.Description,'eventdescription');
            Spiketimedescription=getfield(FilePath.Description,'spiketimedescription');
            Channeldescription=getfield(FilePath.Description,'channeldescription');
            Channelname=getfield(FilePath.Description,'channelname');
            try 
                tmp=getfiled(FilePath.Constant,'spiketime');
                t=tmp.t;
            catch
                t=getfield(FilePath.Constant,'t');
            end
            try
                Fs=getfield(FilePath.Params,'Fs');
            catch
                Fs=20000;
            end
             close(h);
            Eventlist=num2cell(getfield(FilePath.Description,'eventselect'));
            Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
            Spikelist=[];Channellist=[];
            for i=1:length(Spiketimedescription)
                Spikelist=cat(1,Spikelist,Spiketimedescription{i});
                Channellist=cat(1,Channellist,Channeldescription{i});
            end
            [Spikelist,ia]=unique(Spikelist);
            Channeldescription=Channellist(ia);
            Eventpanel=Eventpanel.assign('liststring',Eventlist,'listtag',{'EventIndex'},'typetag',{'Eventtype'},'typestring',Eventdescription,'blacklist',Blacklist(matvalue).Eventindex);
            Spikepanel=Spikepanel.assign('liststring',Spikelist,'listtag',{'SpikeIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',Blacklist(matvalue).spikename);
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
             if nargin>2
                 Spikepanel.getValue({'Channeltype'},{'SpikeIndex'},varargin{1});
                 Eventpanel.getValue({'Eventtype'},{'EventIndex'},varargin{2});
             end
             if Classpath~=0
                 Filter=[];
                 Filter=obj.GetFilterValue;
                 [~,filename]=fileparts(tmpobj.String{tmpobj.Value});
                 obj.AssignSpikeClassifier(fullfile(Classpath,filename,[filename,'.cell_metrics.cellinfo.mat']));
                 err=obj.SetFilterValue(Filter);
             end
           end  
        function Averagealldata(obj,filemat)
            % parameters initilized
            global Spikepanel Eventpanel
            tmpobj1=findobj(obj.NP,'Tag','Channeltype');
            tmpobj2=findobj(obj.NP,'Tag','Eventtype');
            eventtype=1:length(tmpobj2.String);
            channeltype=1:length(tmpobj1.String);
            % begin the loop
            multiWaitbar('calculating',0);
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            for i=1:length(filemat)
                    tmpobj.Value=i; 
                    err=obj.Changefilemat(filemat);  
                    if ~err
                        for j=1:length(channeltype)
                            for k=1:length(eventtype)
                                Spikepanel.getValue({'Channeltype'},{'SpikeIndex'},channeltype(j));
                                Eventpanel.getValue({'Eventtype'},{'EventIndex'},eventtype(k));
                                try
                                    obj.Resultplotfcn();
                                    obj.ResultSavefcn();
                                end
                            end
                        end
                    end
                multiWaitbar('calculating',i/length(filemat));
            end
            multiWaitbar('calculating','close');
        end
        function saveresult=ResultCalfcn(obj)
                global  Chooseinfo matvalue Spikelist
                spikelist=findobj(obj.NP,'Tag','SpikeIndex');
                spikename=spikelist.String(spikelist.Value);
                spikeindex=cellfun(@(x) cellfun(@(y) ~isempty(regexpi(y,['\<',x,'\>'],'match')),Spikelist,'UniformOutput',1),spikelist.String(spikelist.Value),'UniformOutput',0);
                spikeindex=logical(sum(cell2mat(spikeindex'),2));
                spikename=Spikelist(spikeindex);
                for i=1:length(spikename)
                    try
                        [Resultoutput{i}, binnedraster{i}, binnedspike{i}]=obj.GetSUAandMUA(spikename{i});
                    catch
                        msgbox(['no spike detect! skip ',spikename{i}]);
                    end
                end
                Chooseinfo(matvalue).spikename=spikename;
                saveresult.Chooseinfo=Chooseinfo(matvalue);
                saveresult.rawdata=Resultoutput;
                saveresult.rasterdata=binnedraster;
                saveresult.binneddata=binnedspike;    
        end 
        function ResultSavefcn(obj)
            global FilePath saveresult matvalue Blacklist
            obj.Msg('Save the selected result...','replace');
            saveresult=obj.ResultCalfcn();
            [path,name]=fileparts(FilePath.Properties.Source);
            savename=name;
            ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,saveresult);
            ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,Blacklist(matvalue),'Blacklist');
            obj.Msg('Save done!','replace');
        end
        function obj=Startupfcn(obj,filemat,varargin)
                obj.Changefilemat(filemat);
        end
        function Msg(obj,msg,type)
            Msg@NeuroPlot.NeuroPlot(obj,msg,type);
        end
        function loadblacklist(obj,filemat)
            msg=loadblacklist@NeuroPlot(obj);
            obj.Startupfcn(filemat);
            msgbox(['the blacklist of the files:',msg,' has been added.']);
        end
    end
    methods (Access='private')
        function Resultplotfcn(obj)
                global  t Fs Chooseinfo matvalue 
                eventpanel=findobj(gcf,'Tag','Eventtypepanel');
                channelpanel=findobj(gcf,'Tag','Channeltypepanel');
                obj.saveblacklist(eventpanel,channelpanel);
                spikelist=findobj(gcf,'Tag','SpikeIndex');
                [Resultoutput, binnedraster, binnedspike]=obj.GetSUAandMUA(spikelist.String(spikelist.Value));
                Chooseinfo(matvalue).spikename=spikelist.String(spikelist.Value);
                figpanel=findobj(obj.NP,'Tag','Rasterpanel');  
                delete(findobj(obj.NP,'Parent',figpanel,'Type','axes'));
                figaxes=axes('Parent',figpanel);
                figaxes.YLim=[0,size(Resultoutput,2)];
                [~,xpoints,ypoints]=plotSpikeRaster(logical(binnedraster),'PlotType','vertline2','TimePerBin',1/Fs);
                basebegin=findobj(obj.NP,'Tag','baselinebegin');
                baseend=findobj(obj.NP,'Tag','baselineend');
                basemethod=findobj(obj.NP,'Tag','basecorrect');
                tmpdata=basecorrect(mean(binnedspike,1)',linspace(t(1),t(2),size(binnedspike,2)),str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
                smoothwidth=findobj(obj.NP,'Tag','smooth');
                if str2num(smoothwidth.String)~=0
                    tmpdata=smooth(tmpdata,str2num(smoothwidth.String));
                end
                tmpparent=findobj(obj.NP,'Tag','Figcontrol1');
                NeuroPlot.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',figpanel);
                figpanel=findobj(obj.NP,'Tag','Histogrampanel');
                delete(findobj(obj.NP,'Parent',figpanel,'Type','axes'));
                figaxes=axes('Parent',figpanel);
                bar(linspace(t(1),t(2),size(binnedspike,2)),tmpdata);
                tmpobj=findobj(obj.NP,'Tag','Savename');
                tmpobj1=findobj(obj.NP,'Tag','Eventtype');
                tmpobj2=findobj(obj.NP,'Tag','Channeltype');
                tmpobj.String=[tmpobj1.String{tmpobj1.Value},'_',tmpobj2.String{tmpobj2.Value}];
                 tmpparent=findobj(obj.NP,'Tag','Figcontrol2');
                NeuroPlot.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',figpanel);
                
            end
        function [Resultoutput, binnedraster, binnedspike]=GetSUAandMUA(obj,spikename)
                global  t Fs Result Spiketimedescription Chooseinfo matvalue Eventlist
                eventlist=findobj(obj.NP,'Tag','EventIndex');
                Chooseinfo(matvalue).Eventindex=eventlist.String(eventlist.Value);
                eventindex=ismember(Eventlist,eventlist.String(eventlist.Value));
                Resulttmp=Result(eventindex);
                Spiketimedescriptiontmp=Spiketimedescription(eventindex);
                if class(spikename)=='char'
                    spikename={spikename};
                end
                binwidth=findobj(obj.NP,'Tag','BinWidth');
                for i=1:length(Resulttmp)
                    indextmp=cellfun(@(x) cellfun(@(y) ~isempty(regexpi(y,['\<',x,'\>'],'match')),Spiketimedescriptiontmp{i},'UniformOutput',1),spikename,'UniformOutput',0);
                    index{i}=[];
                    for j=1:length(indextmp)
                        index{i}=vertcat(index{i},find(indextmp{j}==1));
                    end
                    binnedraster(i,:)=binspikes(Resulttmp{i}(index{i}),Fs,t);
                    binnedspike(i,:)=binspikes(Resulttmp{i}(index{i}),1/str2num(binwidth.String),t);
                    Resultoutput{i}=Resulttmp{i}(index{i});
                end
                binnedspike(:,end)=[]; % the end of the result from the function 'binspikes' is NAN, i don't know why.
        end
    end
    methods(Static)
            function LoadSpikeClassifier()
                global spikeclass 
                import NeuroPlot.SpikeClassifier
                tmpobj=findobj(gcf,'Tag','SpikeClassPanel');
                spikeclass=SpikeClassifier();
                spikeclass=spikeclass.create('Parent',tmpobj);
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
                blacklist=findobj(gcf,'Parent',eventpanel,'Tag','blacklist');
                Blacklist(matvalue).Eventindex=blacklist.String;
                blacklist=findobj(gcf,'Parent',spikepanel,'Tag','blacklist');
                Blacklist(matvalue).spikename=blacklist.String;
            end         
    end
end

