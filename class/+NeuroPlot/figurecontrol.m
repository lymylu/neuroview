classdef figurecontrol
    %   plot different types of figures in neuroview with their unique command control bar    
    properties
        mainpanel
        figpanel
        commandpanel
        plottype
        figpanel_multiple
        baselinepanel
    end
    
    methods
        function obj = create(obj,plottype,multiple,varargin)
            %  create figurecontrol objects 
            %  plot type ->'plot' : plot LFP data  (origin, PSD) 
            %                'bar': plot binned spike data (PSTH)
            %            'imagesc': plot  time-frequency data (Spectrum or Connectivity)
            %             'raster': plot origin spike data
            %           'roseplot': plot spike phase locked data
            obj.mainpanel=uix.VBox();
            obj.commandpanel=uix.HBox('Parent',obj.mainpanel,'Padding',0);
            if multiple==1
                obj.figpanel_multiple=uix.TabPanel('Parent',obj.mainpanel);
            else
                obj.figpanel=uix.Panel('Parent',obj.mainpanel);
            end
            set(obj.mainpanel,'Heights',[-1,-3]);
            if contains(plottype,'baseline')
                obj.baselinepanel=uix.HBox('Parent',obj.mainpanel);
                 uicontrol('Style','popupmenu','Parent',obj.baselinepanel,'String',{'None','Zscore','Subtract','ChangePercent'},'Tag','basecorrectmethod');
                 uicontrol('Style','text','Parent',obj.baselinepanel,'String','Baselinebegin');
                 uicontrol('Style','edit','Parent',obj.baselinepanel,'String','-2','Tag','baselinebegin');
                 uicontrol('Style','text','Parent',obj.baselinepanel,'String','Baselineend');
                 uicontrol('Style','edit','Parent',obj.baselinepanel,'String','0','Tag','baselineend');
                set(obj.mainpanel,'Heights',[-1,-3,-1]);
            end
             uicontrol('Style','text','Parent',obj.commandpanel,'String','XLim');
             uicontrol('Style','edit','Parent',obj.commandpanel,'String',[],'Tag','XLim');
            switch plottype
                case {'imagesc','imagesc-baseline','imagesc-scoll','imagesc-baseline-scroll'}
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','YLim');
                     uicontrol('Style','edit','Parent',obj.commandpanel,'String',[],'Tag','YLim');
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','CLim');
                     uicontrol('Style','edit','Parent',obj.commandpanel,'String',[],'Tag','CLim');
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','hold on');
                     uicontrol('Style','popupmenu','Parent',obj.commandpanel,'String',{'none','x','y','c','x&y','x&c','y&c','x&y&c'},'Tag','Hold');           
                case {'bar','bar-baseline','bar-scroll','bar-baseline-scroll'}
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','XLim');
                     uicontrol('Style','edit','Parent',obj.commandpanel,'String',[],'Tag','XLim');
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','YLim');
                     uicontrol('Style','edit','Parent',obj.commandpanel,'String',[],'Tag','YLim');
                     uix.Empty('Parent',obj.commandpanel);
                     uix.Empty('Parent',obj.commandpanel);
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','hold on');
                     uicontrol('Style','popupmenu','Parent',obj.commandpanel,'String',{'none','x','y','x&y'},'Tag','Hold');
                case {'plot','plot-baseline','plot-scroll','plot-baseline-scroll'}
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','XLim');
                     uicontrol('Style','edit','Parent',obj.commandpanel,'String',[],'Tag','XLim');
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','YLim');
                     uicontrol('Style','edit','Parent',obj.commandpanel,'String',[],'Tag','YLim');
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','Plot type');
                     uicontrol('Style','popupmenu','Parent',obj.commandpanel,'String',{'average','overlapx','separatex','overlapy','separatey'},'Tag','plotType');
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','hold on');
                     uicontrol('Style','popupmenu','Parent',obj.commandpanel,'String',{'none','x','y','x&y'},'Tag','Hold');
                  case {'raster'}
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','XLim');
                     uicontrol('Style','edit','Parent',obj.commandpanel,'String',[],'Tag','XLim');
                     uix.Empty('Parent',obj.commandpanel);
                     uix.Empty('Parent',obj.commandpanel);
                     uix.Empty('Parent',obj.commandpanel);
                     uix.Empty('Parent',obj.commandpanel);
                     uix.Empty('Parent',obj.commandpanel);
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','hold on');
                     uicontrol('Style','popupmenu','Parent',obj.commandpanel,'String',{'none','x'},'Tag','Hold');
                  case 'roseplot'
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','XLim');
                     uicontrol('Style','edit','Parent',obj.commandpanel,'String',[],'Tag','XLim');
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','PhaseWidth');
                     uicontrol('Style','edit','Parent',obj.commandpanel,'String',[],'Tag','Width');
                     uix.Empty('Parent',obj.commandpanel);
                     uix.Empty('Parent',obj.commandpanel);
                     uix.Empty('Parent',obj.commandpanel);
                     uicontrol('Style','text','Parent',obj.commandpanel,'String','hold on');
                     uicontrol('Style','popupmenu','Parent',obj.commandpanel,'String',{'none','x','width','x&width'},'Tag','Hold');
              end   
            tmpui=uicontrol('Style','pushbutton','Parent',obj.commandpanel,'String','Replot'); 
             obj.plottype=plottype;
             set(tmpui,'Callback',@(~,~) obj.Replot)
        end
        function obj= plot(obj,varargin)
            % plot data in the figcontrol object
            delete(findobj('Parent',obj.figpanel,'Type','axes')); % clear previous panel
            figaxes=axes('Parent',obj.figpanel);
            switch obj.plottype
                case {'imagesc','imagesc-baseline'}
                    if strcmp(obj.plottype,'imagesc-baseline')
                        basecorrectmethod=findobj(obj.mainpanel,'Tag','basecorrectmethod');
                        basecorrectmethod=basecorrectmethod.String{basecorrectmethod.Value};
                        baselinebegin=findobj(obj.mainpanel,'Tag','baselinebegin');
                        baselinebegin=str2num(baselinebegin.String);
                        baselineend=findobj(obj.mainpanel,'Tag','baselineend');
                        baselineend=str2num(baselineend.String);
                        tmpdata=basecorrect(varargin{end},varargin{1},baselinebegin,baselineend,basecorrectmethod);
                    end
                    imagesc(figaxes,varargin{1:end-1},nanmean(nanmean(tmpdata,3),4)');
                    axis xy; 
                case {'plot','plot-baseline'}
                    tmpdata=varargin{2};
                    if strcmp(obj.plottype,'plot-baseline')
                        basecorrectmethod=findobj(obj.mainpanel,'Tag','basecorrectmethod');
                        basecorrectmethod=basecorrectmethod.String{basecorrectmethod.Value};
                        baselinebegin=findobj(obj.mainpanel,'Tag','baselinebegin');
                        baselinebegin=str2num(baselinebegin.String);
                        baselineend=findobj(obj.mainpanel,'Tag','baselineend');
                        baselineend=str2num(baselineend.String);
                        tmpdata=basecorrect(tmpdata,varargin{1},baselinebegin,baselineend,basecorrectmethod);
                    end
                    tmpplot=findobj(obj.commandpanel,'Tag','plotType');
                    if ~isempty(tmpplot)
                 switch tmpplot.String{tmpplot.Value}
                     case 'average' 
                         tmpdata=squeeze(mean(mean(tmpdata,3),2));
                         plot(figaxes,varargin{1},tmpdata);
                     case 'overlapx'
                         tmpdata=squeeze(mean(tmpdata,2));
                         plot(varargin{1},tmpdata);
                     case 'overlapy'
                         tmpdata=squeeze(mean(tmpdata,3));
                         plot(varargin{1},tmpdata);
                     case 'separatex'
                         tmpdata=squeeze(mean(tmpdata,2));
                         lagging=max(abs(tmpdata));
                         lagging=cumsum(repmat(max(lagging),[1,size(tmpdata,2)]));
                         plot(varargin{1},bsxfun(@minus,tmpdata,lagging));
                     case 'separatey'
                         tmpdata=squeeze(mean(tmpdata,3));
                         lagging=max(abs(tmpdata));
                         lagging=cumsum(repmat(max(lagging),[1,size(tmpdata,2)]));
                         plot(varargin{1},bsxfun(@minus,tmpdata,lagging));
                 end
                    else
                        plot(varargin{:});
                    end
                    axis tight
                case {'bar','bar-baseline'}
                    bar(varargin{:});
                case 'raster'
                    [~,xPoints,yPoints]=plotSpikeRaster(varargin{1:end-1});
                    plot(figaxes,xPoints*varargin{end-1}+varargin{end}(1),yPoints);
                    axis tight
                case 'roseplot'
                    circ_plot(varargin{:});
            end
                obj.Replot();
        end
        function obj= Replot(obj)      
            tmpobj=findobj(obj.commandpanel,'Style','edit');
            figaxes=findobj(obj.figpanel,'Type','axes');
            tmphold=findobj(obj.commandpanel,'Style','popupmenu','Tag','Hold');
            if strcmp(obj.plottype,'roseplot')
                PhaseLocking.replot();
            else
            for i=1:length(tmpobj)
                if ~isempty(strfind(tmphold.String{tmphold.Value},lower(tmpobj(i).Tag(1))))
                eval(['figaxes.',tmpobj(i).Tag,'=[',tmpobj(i).String,'];']);
                else
                     eval(['tmpobj(i).String=num2str(figaxes.',tmpobj(i).Tag,');']);
                end
            end
            end
        end
        function obj= ChangeLinked(obj)
            tmpobj=findobj(gcf,'Parent',obj.figpanel_multiple);
            obj.figpanel=tmpobj(obj.figpanel_multiple.Selection);
        end
        function setSlider(obj,Sliderrange,Slider,time)
            value=num2str(Sliderrange.String);
            set(Slider,'SliderStep',[time/(value*10),time/value]);
        end
    end
end

