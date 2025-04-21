classdef DataPlot <  NeuroPlot.NeuroPlot
    % Plot the raw data with the given NeuroData objects.
    % support the LFPdata, SPKdata, EVTdata and Videodata. 
    properties
    end
    
    methods 
        function obj = GenerateObjects(obj,neurodata)
            % according the elements of NeuroData, generate the relavtive
            % objects (LFPdata, SPKdata, EVTdata and/or Videodata) to plot
            if isempty(obj.NP)  
                obj.NP=figure();
            end
            Filepanel=uix.VBoxFlex('Tag','Filepanel'); % file control panel, include file change and file type choose to plot
            uicontrol('Parent',Filepanel,'Tag','Filepath','Style','listbox','String',neurodata.getfield('Datapath'),'Value',1,'Callback',@(~,~) obj.Changefilemat(neurodata));
            Timepanel=uix.VBoxFlex('Tag','Timepanel');% time control panel, include time bar, time jump, time display.
            uicontrol('Parent',Timepanel,'Tag','Timecontrol','Style','slider');
            obj = Changefilemat(obj,neurodata);
             
        end   
        function obj=Changefilemat(obj,neurodata)
            tmpobj=findobj(obj.NP,'Tag','Filepath');
            h=msgbox('Loading data...');
            currentdata=neurodata(tmpobj.Value);
            % each neurondata contains multiple types, each type may contains mulitple files.
            % first is to recognize the types in neurodata.
            filevar={'Videodata','LFPdata','SPKdata','CALdata'};
            for i=1:length(filevar)
            if isfield(currentdata,filevar{i})
                Panel=uix.BoxPanel('Tag',[filevar{i},'Panel'],'Title',[filevar{i},'files']);
                eval(['currentResult.',filevar{i},'.gui_plot(Panel);']);
            end
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

