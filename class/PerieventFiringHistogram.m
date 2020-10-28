classdef PerieventFiringHistogram < NeuroMethod & NeuroPlot
    properties
    end
    methods (Access='public')
        %% method for NeuroMethod
        function obj=getParams(obj,timetype)
              switch timetype
                case 'timepoint'
                    msgbox('当前事件为时间点模式，将对每个时间前后固定时间段进行计算');
                case 'duration'
                    msgbox('当前事件为时间段模式，将对每段时间进行拼合后进行计算!');
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
            obj.Description.channeldescription=Spikeoutput.channeldescription;
            obj.Description.channelname=Spikeoutput.channelname;
        end
        function savematfile=writeData(obj,savematfile)
            savematfile=writeData@NeuroMethod(obj,savematfile);
        end
        function obj=GenerateObjects(obj,filemat)
            global Chooseinfo Blacklist
            obj.Checkpath('GUI Layout Toolbox');
            for i=1:length(filemat)
                Chooseinfo(i).spikename=[];
                Blacklist(i).spikename=[];
                Chooseinfo(i).Eventindex=[];
                Blacklist(i).Eventindex=[];
            end
             obj = GenerateObjects@NeuroPlot(obj);
             %% generate the ResultSelectPanel and its callbacks
             ResultSelectBox=uix.VBox('Parent',obj.ResultSelectPanel,'Padding',0);
             SpikeClassifierPanel=uix.HBox('Parent',ResultSelectBox,'Padding',0,'Tag','SpikeClassifier'); 
             ResultSelect_infoselect=uix.HBox('Parent',ResultSelectBox,'Padding',0);
             set(ResultSelectBox,'Heights',[-1,-7]);
             Eventtypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Eventtypepanel');
            obj.selectpanel('Parent',Eventtypepanel,'Tag','EventIndex','command','create','typeTag','Eventtype','typelistener',@(~,src) obj.Eventtypefcn());
             Spiketypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Spiketypepanel');
             obj.selectpanel('Parent',Spiketypepanel,'Tag','SpikeIndex','command','create','typeTag','Channeltype','typelistener',@(~,src) obj.Channeltypefcn());
             uicontrol('Style','pushbutton','Parent',SpikeClassifierPanel,'String','Choose the Spike classifier','Callback',@(~,varargin) obj.LoadSpikeClassifier(SpikeClassifierPanel));
             uicontrol('Style','text','Parent',SpikeClassifierPanel,'String',[]);
             basetype={'None','Zscore','Subtract','ChangePercent'};
             Figcontrol1=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol1');
             Figpanel1=uix.Panel('Parent',obj.FigurePanel,'Title','Raster Plot','Tag','Rasterpanel');
             obj.commandcontrol('Parent',Figcontrol1,'Plottype','raster','Command','create','Linkedaxes',Figpanel1);
             Figcontrol2=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol2');
             Figpanel2=uix.Panel('Parent',obj.FigurePanel,'Title','Histogram','Tag','Histogrampanel');
             obj.commandcontrol('Parent',Figcontrol2,'Plottype','plot','Command','create','Linkedaxes',Figpanel2);
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
             tmpobj=findobj(gcf,'Tag','Plotresult');
             set(tmpobj,'Callback',@(~,src) obj.Resultplotfcn());
             tmpobj=findobj(gcf,'Tag','Resultsave');
             set(tmpobj,'Callback',@(~,src) obj.ResultSavefcn());
             tmpobj=findobj(gcf,'Tag','Matfilename');
             set(tmpobj,'String',cellfun(@(x) x.Properties.Source(1:end-4),filemat,'UniformOutput',0),'Value',1,'Callback',@(~,~) obj.Changefilemat(filemat))
             addlistener(tmpobj,'Value','PreSet',@(~,~) obj.saveblacklist(Eventtypepanel,Spiketypepanel)); 
             tmpobj=findobj(gcf,'Tag','Averagealldata');
             set(tmpobj,'Callback',@(~,~) obj.Averagealldata(filemat));
             tmpobj=findobj(gcf,'Tag','Loadselectinfo');
             set(tmpobj,'Callback',@(~,~) obj.loadblacklist(filemat));
        end
        function obj=Startupfcn(obj,filemat,varargin)
             % load the data mat file and define the callback 
             % the filename is the matfile from the neurodataanalysis2.
            global Result Eventdescription Spiketimedescription Channeldescription Channelname t  FilePath Fs matvalue Blacklist Eventlist
            tmpobj=findobj(gcf,'Tag','Matfilename');
             h=msgbox(['Loading data:',tmpobj.String(tmpobj.Value)]);  
            matvalue=tmpobj.Value;
            FilePath=filemat{matvalue};
            Result=getfield(FilePath.Result,'spiketime');
            Eventdescription=getfield(FilePath.Description,'eventdescription');
            Spiketimedescription=getfield(FilePath.Description,'spiketimedescription');
            Channeldescription=getfield(FilePath.Description,'channeldescription');
            Channelname=getfield(FilePath.Description,'channelname');
            t=getfield(FilePath.Constant,'t');
            try
                Fs=getfield(FilePath.Params,'Fs');
            catch
                Fs=20000;
            end
             close(h);
            tmpevent=findobj(gcf,'Tag','Eventtypepanel');
            try
                 Eventlist=num2cell(getfield(FilePath.Description,'eventselect'));
                 Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
            catch
                Eventlist=cellfun(@(x) num2str(x),num2cell(1:length(Spiketimedescription)),'UniformOutput',0);
            end
            obj.selectpanel('Parent',tmpevent,'Tag','EventIndex','command','assign','assign',Eventlist,'blacklist',Blacklist(matvalue).Eventindex);
            tmpobj=findobj(gcf,'Tag','Eventtype');
            currentstring=tmpobj.String(tmpobj.Value);
             if nargin>3
                 currrentstring=varargin{1};
             end
            set(tmpobj,'String',cat(1,'All',unique(Eventdescription)));
            tmpvalue=find(strcmp(tmpobj.String,currentstring)==true);
             if isempty(tmpvalue) && nargin<3
                 msgbox('no eventtype were found, show the ALL tag');
                 tmpobj.Value=1;
            elseif nargin>3
                 obj.Err();
                 return;
             else
                 tmpobj.Value=tmpvalue;
                 obj.Eventtypefcn();
             end
            Spikelist=[];Channellist=[];
            for i=1:length(Spiketimedescription)
                Spikelist=cat(1,Spikelist,unique(Spiketimedescription{i}));
                Channellist=cat(1,Channellist,unique(Channeldescription{i}));
            end
             tmpspike=findobj(gcf,'Tag','Spiketypepanel');
             obj.selectpanel('Parent',tmpspike,'Tag','SpikeIndex','command','assign','assign',unique(Spikelist),'blacklist',Blacklist(matvalue).spikename);
             tmpobj=findobj(gcf,'Tag','Channeltype');
             currentstring=tmpobj.String(tmpobj.Value);
             if nargin>3
                 currrentstring=varargin{2};
             end
             set(tmpobj,'String',cat(1,'All',unique(Channellist)));
             tmpvalue=find(strcmp(tmpobj.String,currentstring)==true);
             if isempty(tmpvalue) && nargin<3
                 msgbox('no channeltype were found, show the ALL tag');
                 tmpobj.Value=1;
             elseif nargin>3
                 obj.Err();
                 return;
             else
                 tmpobj.Value=tmpvalue;
                 obj.Channeltypefcn();
             end
             tmpobj=findobj(gcf,'Tag','Matfilename');
             obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
        end  
        function Averagealldata(obj,filemat)
            global  t saveresult 
            % parameters initilized
            tmpobj1=findobj(gcf,'Tag','Channeltype');
            channeltype=tmpobj1.String(tmpobj1.Value);
            tmpobj2=findobj(gcf,'Tag','Eventtype');
            eventtype=tmpobj2.String(tmpobj2.Value);
            savenameobj=findobj(gcf,'Tag','Savename');
            savename=savenameobj.String;
            saveresultall.rawdata=[];
            saveresultall.rasterdata=[];
            saveresultall.binneddata=[];
            basebegin=findobj(gcf,'Tag','baselinebegin');
            baseend=findobj(gcf,'Tag','baselineend');
            basemethod=findobj(gcf,'Tag','basecorrect');
            % begin the loop
            multiWaitbar('calculating',0);
            tmpobj=findobj(gcf,'Tag','Matfilename');
            matvalue=tmpobj.Value;
            for i=1:length(filemat)
                    tmpobj.Value=i;
                    obj.Changefilemat(filemat,eventtype,channeltype);    
                    obj.Resultplotfcn();
                    savenameobj.String=savename;
                    obj.ResultSavefcn();
                    saveresultall.binneddata=cat(2,saveresultall.binneddata,saveresult.binneddata);      
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
                spikelist=findobj(gcf,'Tag','SpikeIndex');
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
        function obj=Changefilemat(obj,filemat,varargin)
            if nargin>3
             obj.Startupfcn(filemat,varargin);
            else
                obj.Startupfcn(filemat);
            end
             tmpobj=findobj(gcf,'Tag','Holdonresult');
             if tmpobj.Value==1
                 obj.LoadInfo();
             end
        end
        function commandcontrol(obj,varargin)
            commandcontrol@NeuroPlot(obj,varargin{:})
        end
        function selectpanel(obj,varargin)
            selectpanel@NeuroPlot(obj,varargin{:});
        end
        function Msg(obj,msg,type)
            Msg@NeuroPlot(obj,msg,type);
        end
        function loadblacklist(obj,filemat)
            msg=loadblacklist@NeuroPlot(obj);
            obj.Startupfcn(filemat);
            msgbox(['the blacklist of the files:',msg,' has been added.']);
        end
    end
    methods (Access='private')
        function Resultplotfcn(obj)
                global Result t Fs Resulttmp Spiketimedescription Spiketimedescriptiontmp Channelname Channelnametmp  Blacklist
                tmpobj=findobj(gcf,'Tag','Matfilename');
                matvalue=tmpobj.Value;
                eventlist=findobj(gcf,'Tag','EventIndex');
                Resulttmp=Result(cellfun(@(x) str2num(x),eventlist.String(eventlist.Value),'UniformOutput',1));
                Spiketimedescriptiontmp=Spiketimedescription(cellfun(@(x) str2num(x),eventlist.String(eventlist.Value),'UniformOutput',1));
                Channelnametmp=Channelname(cellfun(@(x) str2num(x),eventlist.String(eventlist.Value),'UniformOutput',1));
                spikelist=findobj(gcf,'Tag','SpikeIndex');
                [Resultoutput, binnedraster, binnedspike]=obj.GetSUAandMUA(spikelist.String(spikelist.Value));
                tmpevent=findobj(gcf,'Tag','Eventtypepanel');
                blacklist=findobj(gcf,'Parent',tmpevent,'Tag','blacklist');
                Blacklist(matvalue).Eventindex=blacklist.String;
                tmpspike=findobj(gcf,'Tag','Spiketypepanel');
                blacklist=findobj(gcf,'Parent',tmpspike,'Tag','blacklist');
                Blacklist(matvalue).spikename=blacklist.String;
                figpanel=findobj(gcf,'Tag','Rasterpanel');  
                delete(findobj(gcf,'Parent',figpanel,'Type','axes'));
                figaxes=axes('Parent',figpanel);
                figaxes.YLim=[0,size(Resultoutput,2)];
                [~,xpoints,ypoints]=plotSpikeRaster(logical(binnedraster),'PlotType','vertline2','TimePerBin',1/Fs);
                basebegin=findobj(gcf,'Tag','baselinebegin');
                baseend=findobj(gcf,'Tag','baselineend');
                basemethod=findobj(gcf,'Tag','basecorrect');
                tmpdata=basecorrect(mean(binnedspike,1)',linspace(t(1),t(2),size(binnedspike,2)),str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
                smoothwidth=findobj(gcf,'Tag','smooth');
                if str2num(smoothwidth.String)~=0
                tmpdata=smooth(tmpdata,str2num(smoothwidth.String));
                end
                tmpparent=findobj(gcf,'Tag','Figcontrol1');
                obj.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',figpanel);
                figpanel=findobj(gcf,'Tag','Histogrampanel');
                delete(findobj(gcf,'Parent',figpanel,'Type','axes'));
                figaxes=axes('Parent',figpanel);
                bar(linspace(t(1),t(2),size(binnedspike,2)),tmpdata);
                tmpobj=findobj(gcf,'Tag','Savename');
                tmpobj1=findobj(gcf,'Tag','Eventtype');
                tmpobj2=findobj(gcf,'Tag','Channeltype');
                tmpobj.String=[tmpobj1.String{tmpobj1.Value},'_',tmpobj2.String{tmpobj2.Value}];
                 tmpparent=findobj(gcf,'Tag','Figcontrol2');
                obj.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',figpanel);
            end
        function [Resultoutput, binnedraster, binnedspike]=GetSUAandMUA(obj,spikename)
                global  t Fs Resulttmp Spiketimedescriptiontmp Channelnametmp
                if class(spikename)=='char'
                    spikename={spikename};
                end
                binwidth=findobj(gcf,'Tag','BinWidth');
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
                binnedspike(:,end)=[];
        end
        function Channeltypefcn(obj)
                global Channeldescription Spiketimedescription
                tmpobj=findobj(gcf,'Tag','Channeltype');
                if tmpobj.Value~=1
                    index=cellfun(@(x) contains(x, tmpobj.String(tmpobj.Value)),Channeldescription,'UniformOutput',0);
                    Spikelist=[];
                    for i=1:length(index)
                       Spikelist=cat(1,Spikelist,unique(Spiketimedescription{i}(index{i})));
                    end
                else
                    Spikelist=[];
                    for i=1:length(Spiketimedescription)
                       Spikelist=cat(1,Spikelist,unique(Spiketimedescription{i}));
                    end
                end
                 tmpobj=findobj(gcf,'Tag','SpikeIndex');
                 set(tmpobj,'String',unique(Spikelist),'Value',1);          
                 tmpobj2=findobj(gcf,'Tag','SpikeClassifier');
                 obj.LoadSpikeClassifier(tmpobj2,tmpobj);
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
            function Eventtypefcn()
               global Eventdescription Eventlist
               tmpobj=findobj(gcf,'Tag','Eventtype');
                if tmpobj.Value~=1
                     value=tmpobj.Value;
                     Eventtype=tmpobj.String;
                     Eventindex=contains(Eventdescription,Eventtype{value});
                     tmpobj=findobj(gcf,'Tag','EventIndex');
                     set(tmpobj,'String',Eventlist(Eventindex),'Value',1);
                else
                    tmpobj=findobj(gcf,'Tag','EventIndex');
                    set(tmpobj,'String',Eventlist,'Value',1);
            	end 
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

