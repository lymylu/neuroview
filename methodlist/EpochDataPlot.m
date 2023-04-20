classdef EpochDataPlot <  NeuroPlot.NeuroPlot
    % Plot the raw data in the given event 
    % support the LFPdata, SPKdata, CALdata. 
    properties
        Result
        Resultinfo
    end
    
    methods 
        function obj = GenerateObjects(obj,filemat)
             import NeuroPlot.selectpanel NeuroPlot.commandcontrol
            global Chooseinfo Blacklist Eventpanel Channelpanel Spikepanel spikeclassifier
             NeuroMethod.Checkpath('GUI Layout Toolbox');
             for i=1:length(filemat)
                Chooseinfo(i).Channelindex=[];
                Blacklist(i).Channelindex=[];
                Chooseinfo(i).Eventindex=[];
                Blacklist(i).Eventindex=[];
                Chooseinfo(i).spikename=[];
                Blacklist(i).spikename=[];
                Chooseinfo(i).calcell=[];
                Blacklist(i).calcell=[];
            end
             obj=GenerateObjects@NeuroPlot.NeuroPlot(obj,filemat);   
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
       function obj=Changefilemat(obj,filemat)
            global Channelpanel matvalue Blacklist Eventpanel Spikepanel spikeclassifier currentindex currentResult
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            h=msgbox('Loading data...');
            matvalue=tmpobj.Value;
            currentmat=filemat{matvalue};
            currentResult=NeuroResult(currentmat);    
            % event information
            Eventdescription=currentResult.EVTinfo.eventdescription;
            Eventlist=num2cell(currentResult.EVTinfo.eventselect);
            Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
            Eventpanel=Eventpanel.assign('liststring',Eventlist,'listtag',{'EventIndex'},'typetag',{'Eventtype'},'typestring',Eventdescription,'blacklist',Blacklist(matvalue).Eventindex);
            obj=obj.Loadresult(currentResult,'info');
            if ~isempty(currentResult.LFPdata)
            % lfp information
            Channellist=num2cell(currentResult.LFPinfo.channelselect);
            Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
            Channeldescription=currentResult.LFPinfo.channeldescription;
            Channelpanel=Channelpanel.assign('liststring',Channellist,'listtag',{'ChannelIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',Blacklist(matvalue).Channelindex);
            else
                Channelpanel=[];
            end
            if ~isempty(currentResult.SPKdata)
            % spk information
            SPKdescription=currentResult.SPKinfo.channeldescription;
            Spikelist=currentResult.SPKinfo.name;
            Spikepanel=Spikepanel.assign('liststring',Spikelist,'listtag',{'SpikeIndex'},'typetag',{'Channeltype'},'typestring',SPKdescription,'blacklist',Blacklist(matvalue).spikename);
            else
                Spikepanel=[];
            end
            if ~isempty(currentResult.CALdata)
                % spk information
                SPKdescription=currentResult.CALinfo.channeldescription;
                Spikelist=currentResult.CALinfo.name;
                Spikepanel=Spikepanel.assign('liststring',Spikelist,'listtag',{'SpikeIndex'},'typetag',{'Channeltype'},'typestring',SPKdescription,'blacklist',Blacklist(matvalue).spikename);
            else
                Spikepanel=[];
            end      
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
    end
  methods(Static)
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

