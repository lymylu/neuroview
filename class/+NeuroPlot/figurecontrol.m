classdef figurecontrol
    %   plot different types of figures in neuroview with their unique command control bar    
    properties
        figpanel
        commandpanel
        plottype
        figpanel_multiple
    end
    
    methods
        function obj = create(obj,figpanel,commandpanel,plottype)
            %  create figurecontrol objects 
            %  plot type ->'plot' : plot LFP data  (origin, PSD) 
            %                      'bar': plot binned spike data (PSTH)
            %                      'imagesc': plot  time-frequency data (Spectrum or Connectivity)
            %                      'raster': plot origin spike data
            %                      'roseplot': plot spike phase locked data
            uicontrol('Style','text','Parent',commandpanel,'String','XLim');
            uicontrol('Style','edit','Parent',commandpanel,'String',[],'Tag','XLim');
              switch plottype
                 case {'imagesc'}
                     uicontrol('Style','text','Parent',commandpanel,'String','YLim');
                     uicontrol('Style','edit','Parent',commandpanel,'String',[],'Tag','YLim');
                     uicontrol('Style','text','Parent',commandpanel,'String','CLim');
                     uicontrol('Style','edit','Parent',commandpanel,'String',[],'Tag','CLim');
                     uicontrol('Style','text','Parent',commandpanel,'String','hold on');
                     uicontrol('Style','popupmenu','Parent',commandpanel,'String',{'none','x','y','c','x&y','x&c','y&c','x&y&c'},'Tag','Hold');           
                  case 'bar'
                     uicontrol('Style','text','Parent',commandpanel,'String','YLim');
                     uicontrol('Style','edit','Parent',commandpanel,'String',[],'Tag','YLim');
                     uix.Empty('Parent',commandpanel);
                     uix.Empty('Parent',commandpanel);
                     uicontrol('Style','text','Parent',commandpanel,'String','hold on');
                     uicontrol('Style','popupmenu','Parent',commandpanel,'String',{'none','x','y','x&y'},'Tag','Hold');
                  case {'plot'}
                     uicontrol('Style','text','Parent',commandpanel,'String','YLim');
                     uicontrol('Style','edit','Parent',commandpanel,'String',[],'Tag','YLim');
                     uicontrol('Style','text','Parent',commandpanel,'String','Plot type');
                     uicontrol('Style','popupmenu','Parent',commandpanel,'String',{'average','overlapx','separatex','overlapy','separatey'},'Tag','plotType');
                     uicontrol('Style','text','Parent',commandpanel,'String','hold on');
                     uicontrol('Style','popupmenu','Parent',commandpanel,'String',{'none','x','y','x&y'},'Tag','Hold');
                  case {'raster'}
                     uix.Empty('Parent',commandpanel);
                     uix.Empty('Parent',commandpanel);
                     uix.Empty('Parent',commandpanel);
                     uix.Empty('Parent',commandpanel);
                     uix.Empty('Parent',commandpanel);
                     uicontrol('Style','text','Parent',commandpanel,'String','hold on');
                     uicontrol('Style','popupmenu','Parent',commandpanel,'String',{'none','x'},'Tag','Hold');
                  case 'roseplot'
                     uicontrol('Style','text','Parent',commandpanel,'String','PhaseWidth');
                     uicontrol('Style','edit','Parent',commandpanel,'String',[],'Tag','Width');
                     uix.Empty('Parent',commandpanel);
                     uix.Empty('Parent',commandpanel);
                     uix.Empty('Parent',commandpanel);
                     uicontrol('Style','text','Parent',commandpanel,'String','hold on');
                     uicontrol('Style','popupmenu','Parent',commandpanel,'String',{'none','x','width','x&width'},'Tag','Hold');
              end   
            tmpui=uicontrol('Style','pushbutton','Parent',commandpanel,'String','Replot'); 
             obj.commandpanel=commandpanel;
             if strcmp(class(figpanel),'uix.TabPanel')
                 obj.figpanel_multiple=figpanel;
             else
                obj.figpanel=figpanel;
             end
             obj.plottype=plottype;
             set(tmpui,'Callback',@(~,~) obj.Replot)
        end
        function obj= plot(obj,varargin)
            % plot data in the figcontrol object
            delete(findobj('Parent',obj.figpanel,'Type','axes')); % clear previous panel
            figaxes=axes('Parent',obj.figpanel);
            switch obj.plottype
                case 'imagesc'
                    imagesc(varargin{:});
                    axis xy; 
                case 'plot'
                    tmpdata=varargin{2};
                    tmpplot=findobj(obj.commandpanel,'Tag','plotType');
                    if ~isempty(tmpplot)
                 switch tmpplot.String{tmpplot.Value}
                     case 'average' 
                         tmpdata=squeeze(mean(mean(tmpdata,3),2));
                         plot(varargin{1},tmpdata);
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
                case 'bar'
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
    end
end

