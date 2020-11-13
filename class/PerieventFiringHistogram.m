classdef PerieventFiringHistogram < NeuroMethod & NeuroPlot.NeuroPlot
    properties
    end
    methods (Access='public')
        %% method for NeuroMethod
        function obj=getParams(obj,timetype)
              switch timetype
                case 'timepoint'
                    msgbox('��ǰ�¼�Ϊʱ���ģʽ������ÿ��ʱ��ǰ��̶�ʱ��ν��м���');
                case 'duration'
                    msgbox('��ǰ�¼�Ϊʱ���ģʽ������ÿ��ʱ�����ƴ�Ϻ���м���!');
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
            global Chooseinfo Blacklist Eventpanel Spikepanel
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
             % uicontrol('Style','pushbutton','Parent',SpikeClassifierPanel,'String','Choose the Spike classifier','Callback',@(~,varargin) obj.LoadSpikeClassifier(SpikeClassifierPanel));
             % uicontrol('Style','text','Parent',SpikeClassifierPanel,'String',[]);
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
        function obj=Changefilemat(obj,filemat,varargin)
             % load the data mat file and define the callback 
             % the filename is the matfile from the neurodataanalysis2.
            global Result Eventdescription Spiketimedescription Channeldescription Channelname t  FilePath Fs matvalue Blacklist Eventpanel Eventlist Spikepanel Spikelist
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
             tmpobj=findobj(obj.NP,'Tag','Holdonresult');
             if nargin>2
                 obj.Channeltypefcn(varargin{1});
                 if err==1
                     obj.Msg('no channeltype were found, show the ALL tag','replace');
                 end
                 obj.Eventtypefcn(varargin{2});
                 if err==1
                     obj.Msg('no Eventtype were found, show the ALL tag','replace');
                 end
             end
             if tmpobj.Value==1
                 obj.LoadInfo();
             end
        end  
        function Averagealldata(obj,filemat)
            global  t saveresult err
            % parameters initilized
            tmpobj1=findobj(obj.NP,'Tag','Channeltype');
            channeltype=tmpobj1.String(tmpobj1.Value);
            tmpobj2=findobj(obj.NP,'Tag','Eventtype');
            eventtype=tmpobj2.String(tmpobj2.Value);
            savenameobj=findobj(obj.NP,'Tag','Savename');
            savename=savenameobj.String;
            saveresultall.rawdata=[];
            saveresultall.rasterdata=[];
            saveresultall.binneddata=[];
            basebegin=findobj(obj.NP,'Tag','baselinebegin');
            baseend=findobj(obj.NP,'Tag','baselineend');
            basemethod=findobj(obj.NP,'Tag','basecorrect');
            % begin the loop
            multiWaitbar('calculating',0);
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            for i=1:length(filemat)
                    tmpobj.Value=i;
                    obj.Changefilemat(filemat,channeltype,eventtype);  
                    if err==0
                        obj.Resultplotfcn();
                        savenameobj.String=savename;
                        obj.ResultSavefcn();
                        saveresultall.binneddata=cat(2,saveresultall.binneddata,saveresult.binneddata);  
                    else
                        h=msgbox(['no chosen tag were found in,' tmpobj.String(tmpobj.Value),'. Skip.']);
                        close(h);
                    end
                multiWaitbar('calculating',i/length(filemat));
            end
            multiWaitbar('calculating','close');
            tmpresult=cellfun(@(x) mean(x,1),saveresultall.binneddata,'UniformOutput',0);
            binnedspike=cell2mat(tmpresult');
            tmpdata=basecorrect(binnedspike',linspace(t(1),t(2),size(binnedspike,2)),str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
            tmpdata(find(tmpdata==Inf))=NaN;
            figure; subplot(1,2,1);
            bar(linspace(t(1),t(2),size(tmpdata,1)),nanmean(tmpdata,2));
            subplot(1,2,2);
            imagesc(t,1:size(tmpdata,2),tmpdata');
        end
        function saveresult=ResultCalfcn(obj)
                global  Chooseinfo matvalue 
                spikelist=findobj(obj.NP,'Tag','SpikeIndex');
                spikename=spikelist.String(spikelist.Value);
                for i=1:length(spikename)
                    try
                        [Resultoutput{i}, binnedraster{i}, binnedspike{i}]=obj.GetSUAandMUA(spikename{i});
                    catch
                        msgbox(['no spike detect! skip ',spikename{i}]);
                    end
                end
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
            ResultSavefcn@NeuroPlot(path,savename,saveresult);
            ResultSavefcn@NeuroPlot(path,savename,Blacklist(matvalue),'Blacklist');
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
                global  t Fs 
                spikelist=findobj(gcf,'Tag','SpikeIndex');
                [Resultoutput, binnedraster, binnedspike]=obj.GetSUAandMUA(spikelist.String(spikelist.Value));
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
                global  t Fs Result Spiketimedescription
                eventlist=findobj(obj.NP,'Tag','EventIndex');
                spikelist=findobj(obj.NP,'Tag','SpikeIndex');
                Resulttmp=Result(cellfun(@(x) str2num(x),eventlist.String(eventlist.Value),'UniformOutput',1));
                Spiketimedescriptiontmp=Spiketimedescription(cellfun(@(x) str2num(x),eventlist.String(eventlist.Value),'UniformOutput',1));
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
            function LoadInfo()
            global Chooseinfo matvalue
               tmpobj=findobj(gcf,'Tag','SpikeIndex');
               tmpobj.Value=1:length(tmpobj.String);
               Chooseinfo(matvalue).spikename=tmpobj.String;
               tmpobj=findobj(gcf,'Tag','EventIndex');
               Chooseinfo(matvalue).Eventindex=tmpobj.String;
               tmpobj.Value=1:length(tmpobj.String);
            end
            function LoadSpikeClassifier(varargin)
            % varargin{1} is the Type Classifier, varargin{2} is the Spikeindex
                LoadSpikeClassifier@NeuroPlot(varargin);
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

