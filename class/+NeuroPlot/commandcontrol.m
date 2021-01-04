 function commandcontrol(varargin)
             % create the control panel for different types of figure to
             % show the xlim ylim and clim for the figure
             plottype=[];
             parent=[];
             linkedaxes=[];
             command=[];
             for i = 1:2:length(varargin)
                 switch lower(varargin{i})
                     case 'plottype'
                         plottype=varargin{i+1};
                     case 'parent'
                         parent=varargin{i+1};
                     case 'linkedaxes'
                         linkedaxes=varargin{i+1};
                     case 'command'
                         command=varargin{i+1};
                 end
             end
            if strcmp(command,'create')
             switch plottype
                 case 'imagesc'
                     uicontrol('Style','text','Parent',parent,'String','XLim');
                     uicontrol('Style','edit','Parent',parent,'String',[],'Tag','XLim');
                     uicontrol('Style','text','Parent',parent,'String','YLim');
                     uicontrol('Style','edit','Parent',parent,'String',[],'Tag','YLim');
                     uicontrol('Style','text','Parent',parent,'String','CLim');
                     uicontrol('Style','edit','Parent',parent,'String',[],'Tag','CLim');
                 case 'plot'
                     uicontrol('Style','text','Parent',parent,'String','XLim');
                     uicontrol('Style','edit','Parent',parent,'String',[],'Tag','XLim');
                     uicontrol('Style','text','Parent',parent,'String','YLim');
                     uicontrol('Style','edit','Parent',parent,'String',[],'Tag','YLim');
                     uix.Empty('Parent',parent);
                     uix.Empty('Parent',parent);
                 case 'raster'
                     uicontrol('Style','text','Parent',parent,'String','XLim');
                     uicontrol('Style','edit','Parent',parent,'String',[],'Tag','XLim');
                     uix.Empty('Parent',parent);
                     uix.Empty('Parent',parent);
                     uix.Empty('Parent',parent);
                     uix.Empty('Parent',parent);
                     uix.Empty('Parent',parent);
             end    
                 tmpui=uicontrol('Style','pushbutton','Parent',parent,'String','Replot');
                 if ~isempty(linkedaxes)
                    set(tmpui,'Callback',@(~,varargin) Replot(parent,linkedaxes))
                 end
             elseif strcmp(command,'assign')
                tmpobj=findobj(gcf,'Parent',parent,'Style','edit');
                figaxes=findobj(gcf,'Parent',linkedaxes);
                 for i=1:length(tmpobj)
                     tmpobj(i).String=[];
                    eval(['tmpobj(i).String=num2str(figaxes.',tmpobj(i).Tag,');']);
                 end
            elseif strcmp(command,'changelinkedaxes')
                tmpobj=findobj(gcf,'Parent',parent,'Style','pushbutton');
                set(tmpobj,'Callback',@(~,varargin) obj.Replot(parent,linkedaxes));
             end                      
 end
   function Replot(varargin)
            tmpobj=findobj(gcf,'Parent',varargin{1},'Style','edit');
            figaxes=findobj(gcf,'Parent',varargin{2});
            for i=1:length(tmpobj)
                eval(['figaxes.',tmpobj(i).Tag,'=[',tmpobj(i).String,'];']);
            end
 end