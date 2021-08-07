classdef imagesc3D_YLP
 % add New window of multiple imagesc plots to show the 3-D matrix fuction from 3 perpendicular
% views (i.e. 3 (e1-e2 planes), 1 (e2-e3 planes), 2 (e3-e1 planes), )) in 
% slice by slice fashion with mouse based slice browsing and window and 
% level adjustment control.
    properties
        parent=[];
        Plotaxes=[];
        Controlpanel=[];
    end
    
    methods
        function obj = create(obj,parent,subplots)
            %   create subplots of imagesc 3D panel
            %   example imagesc3D.create(gcf,[4,4]) to show up to 16
            %   subplots  by 4*4
            MainPanel=uix.VBoxFlex('Parent',parent,'Padding',4);
            Plotpanel=uix.GridFlex('Parent',MainPanel,'Padding',0);
            for i=1:subplots(1)*subplots(2)
                obj.Plotaxes{i}=uix.Panel('Parent',Plotpanel,'Padding',15);
            end
            set(Plotpanel,'Height',ones(subplots(1),1).*-1,'Width',ones(subplots(2),1).*-1);
            tmppanel=uix.VBox('Parent',MainPanel);
            obj.Controlpanel=uix.VBox('Parent',tmppanel);
            uicontrol(obj.Controlpanel,'Style', 'text','Tag','slicetext'),
            uicontrol(obj.Controlpanel,'Style', 'slider','Tag','slicebar');
            tmppanel=uix.HBox('Parent',obj.Controlpanel);
            uicontrol(tmppanel,'Style','text','String','Xlim');
            xtmpobj=uicontrol(tmppanel,'Style','edit','Tag','Xlim');
            uicontrol(tmppanel,'Style','text','String','Ylim');
            ytmpobj=uicontrol(tmppanel,'Style','edit','Tag','Ylim');
            uicontrol(tmppanel,'Style','text','String','Zlim');
            ztmpobj=uicontrol(tmppanel,'Style','edit','Tag','Zlim');
            uicontrol(tmppanel,'Style','popupmenu','String',{'X&Y','X&Z','Y&Z'},'Value',1,'Tag','showtype');
            set(MainPanel,'Height',[-10,-1]);
            set(obj.Controlpanel,'Height',[-1,-1,-1]);
        end
        
        function obj=plot(obj,varargin)
            %  plot the data matrix in the specific position
            %  if data is 4-D the 4th dimesion will be plotted in the
            %  subplots.
            p=inputParser;
            addRequired(p,'x',@(x) isnumeric(x));
            addRequired(p,'y',@(x) isnumeric(x));
            addRequired(p,'z',@(x) isnumeric(x));
            addRequired(p,'data',@(x) isnumeric(x));
            addRequired(p,'clim',@(x) isnumeric(x)); 
            addParameter(p,'xlim',[],@(x) isnumeric(x));
            addParameter(p,'ylim',[],@(x) isnumeric(x));
            addParameter(p,'zlim',[],@(x) isnumeric(x));
            addParameter(p,'parent',[]);
            addParameter(p,'subplottitle',[]);
            parse(p,varargin{:});
            data=p.Results.data; crange=p.Results.clim;
                if isempty(p.Results.parent)
                    obj.parent=figure();
                else
                    obj.parent=p.Results.parent;
                end
                subplots(1)=round(sqrt(size(data,4)));
                subplots(2)=ceil(size(data,4)/subplots(1));
                obj=obj.create(obj.parent,subplots);
                typeobj=findobj(obj.Controlpanel,'Tag','showtype');
                xtmpobj=findobj(obj.Controlpanel,'Tag','Xlim');
                set(xtmpobj,'String',num2str([min(p.Results.x),max(p.Results.x)]));
                ytmpobj=findobj(obj.Controlpanel,'Tag','Ylim');
                set(ytmpobj,'String',num2str([min(p.Results.y),max(p.Results.y)]));
                ztmpobj=findobj(obj.Controlpanel,'Tag','Zlim');
                set(ztmpobj,'String',num2str([min(p.Results.z),max(p.Results.z)]));
                sliderobj=findobj(obj.Controlpanel,'Tag','slicebar');
                set(sliderobj,'Min',1,'Max',length(p.Results.z),'Value',1,'SliderStep',[1/(length(p.Results.z)-1) 10/(length(p.Results.z)-1)],'Callback', @(~,~) obj.SilderChange(data,p.Results.x,p.Results.y,p.Results.z,crange));
                addlistener(sliderobj,'Value','PostSet',@(~,~) obj.ShowSliceValue(data,p.Results.x,p.Results.y,p.Results.z,crange,p.Results.subplottitle));
                addlistener(xtmpobj,'String','PostSet', @(~,~) obj.Axischange(p.Results.x,p.Results.y,p.Results.z));
                addlistener(ytmpobj,'String','PostSet', @(~,~) obj.Axischange(p.Results.x,p.Results.y,p.Results.z));
                addlistener(ztmpobj,'String','PostSet', @(~,~) obj.Axischange(p.Results.x,p.Results.y,p.Results.z));
                set(typeobj,'Callback',@(~,~) obj.showtypeChange(data,p.Results.x,p.Results.y,p.Results.z,crange,p.Results.subplottitle));
                set (obj.parent, 'WindowScrollWheelFcn', @(object,eventdata) obj.mouseScroll(object,eventdata));  
                if ~isempty(p.Results.xlim)
                    xrange=[p.Results.xlim(1),p.Results.xlim(2)];
                    set(xtmpobj,'String',num2str(xrange));
                end
                if ~isempty(p.Results.ylim)
                    yrange=[p.Results.ylim(1),p.Results.ylim(2)];
                    set(ytmpobj,'String',num2str(yrange));
                end
                if ~isempty(p.Results.zlim)
                    zrange=[p.Results.zlim(1),p.Results.zlim(2)];
                    set(ztmpobj,'String',num2str(zrange));
                end
                 obj.showtypeChange(data,p.Results.x,p.Results.y,p.Results.z,crange,p.Results.subplottitle);
               
        end
        function obj=Axischange(obj,x,y,z)
            tmptype=findobj(obj.Controlpanel,'Tag','showtype');
            xtmpobj=findobj(obj.Controlpanel,'Tag','Xlim');
            ytmpobj=findobj(obj.Controlpanel,'Tag','Ylim');
            ztmpobj=findobj(obj.Controlpanel,'Tag','Zlim');
            sliderobj=findobj(obj.Controlpanel,'Tag','slicebar');
            switch tmptype.String{tmptype.Value}
                case 'X&Y'
                    for i=1:length(obj.Plotaxes)
                        try
                            set(obj.Plotaxes{i},'Xlim',str2num(xtmpobj.String));
                            set(obj.Plotaxes{i},'Ylim',str2num(ytmpobj.String));
                        end
                    end
                    try
                           zrange=str2num(ztmpobj.String);
                           [~,minIndex]=min(abs(z-zrange(1)));
                           [~,maxIndex]=min(abs(z-zrange(2)));
                           set(sliderobj,'Min',minIndex,'Max',maxIndex,'Value',minIndex,'SliderStep',[1/(maxIndex-minIndex) 10/(maxIndex-minIndex)]); 
                           set(ztmpobj,'String',num2str([z(minIndex),z(maxIndex)]));
                    end
                case 'X&Z'
                    for i=1:length(obj.Plotaxes)
                        try
                            set(obj.Plotaxes{i},'Xlim',str2num(xtmpobj.String));
                            set(obj.Plotaxes{i},'Ylim',str2num(ztmpobj.String));
                        end
                    end
                    try
                           yrange=str2num(ytmpobj.String);
                           [~,minIndex]=min(abs(y-yrange(1)));
                           [~,maxIndex]=min(abs(y-yrange(2)));
                           set(sliderobj,'Min',minIndex,'Max',maxIndex,'Value',minIndex,'SliderStep',[1/(maxIndex-minIndex) 10/(maxIndex-minIndex)]); 
                           set(ytmpobj,'String',num2str([y(minIndex),y(maxIndex)]));
                    end
                case 'Y&Z'
                      for i=1:length(obj.Plotaxes)
                        try
                            set(obj.Plotaxes{i},'Xlim',str2num(ytmpobj.String));
                            set(obj.Plotaxes{i},'Ylim',str2num(ztmpobj.String));
                        end
                      end
                    try
                            xrange=str2num(xtmpobj.String);
                          [~,minIndex]=min(abs(x-xrange(1)));
                           [~,maxIndex]=min(abs(x-xrange(2)));
                           set(sliderobj,'Min',minIndex,'Max',maxIndex,'Value',minIndex,'SliderStep',[1/(maxIndex-minIndex) 10/(maxIndex-minIndex)]); 
                           set(xtmpobj,'String',num2str([x(minIndex),x(maxIndex)]));
                    end
            end      
        end
        function obj=SilderChange(obj,data,x,y,z,c,subplottitle)
            tmptype=findobj(obj.Controlpanel,'Tag','showtype');
            xtmpobj=findobj(obj.Controlpanel,'Tag','Xlim');
            ytmpobj=findobj(obj.Controlpanel,'Tag','Ylim');
            ztmpobj=findobj(obj.Controlpanel,'Tag','Zlim');
            sliderobj=findobj(obj.Controlpanel,'Tag','slicebar');
            xrange=str2num(xtmpobj.String);
            yrange=str2num(ytmpobj.String);
            zrange=str2num(ztmpobj.String);
            xindex=find(x>=min(xrange)&x<=max(xrange));
            yindex=find(y>=min(yrange)&y<=max(yrange));
            zindex=find(z>=min(zrange)&z<=max(zrange));
            for i=1:length(obj.Plotaxes) 
                try 
                    t=tiledlayout(obj.Plotaxes{i},3,3);
                    ax1=nexttile(t,1,[2,2]);
                    ax2=nexttile(t,3,[2,1]);
                    ax3=nexttile(t,7,[1,2]);
                    ax4=nexttile(t,9,[1,1]);
                catch
                    ax1=axes(obj.Plotaxes{i});
                end
            switch tmptype.String{tmptype.Value}
                case 'X&Y'
                        try 
                            imagesc(ax1,x,y,squeeze(data(:,:,sliderobj.Value,i))',c);
                            set(ax1,'Xlim',xrange,'Ylim',yrange);  
                            plot(ax2,squeeze(mean(data(xindex,:,sliderobj.Value,i),1)),y);
                            set(ax2,'Ylim',yrange); 
                            plot(ax3,x,squeeze(mean(data(:,yindex,sliderobj.Value,i),2)));
                            set(ax3,'Xlim',xrange);
                            plot(ax4,z,squeeze(mean(mean(data(xindex,yindex,:,i),1),2))); 
                            hold on; plot(ax4,sliderobj.Value,squeeze(mean(mean(data(xindex,yindex,sliderobj.Value,i),1),2)),'O');
                            set(ax4,'Xlim',zrange);
                        end
                case 'X&Z'
                        try 
                            imagesc(ax1,x,z,squeeze(data(:,sliderobj.Value,:,i))',c);
                            set(ax1,'Xlim',xrange,'Ylim',zrange)
                            plot(ax2,z,squeeze(mean(data(xindex,sliderobj.Value,:,i),1)));
                            set(ax2,'Xlim',zrange);view(90);
                            plot(ax3,x,squeeze(mean(data(:,sliderobj.Value,zindex,i),3)));
                            set(ax3,'Xlim',xrange);
                            plot(ax4,y,squeeze(mean(mean(data(xindex,:,zindex,i),1),2))); 
                            hold on; plot(ax4,sliderobj.Value,squeeze(mean(mean(data(xindex,sliderobj.Value,zindex,i),1),2)),'O');
                            set(ax4,'Xlim',yrange);
                       end
                case 'Y&Z'
                         try 
                            imagesc(ax1,y,z,squeeze(data(sliderobj.Value,:,:,i))',c);
                            set(ax1,'Xlim',yrange,'Ylim',zrange);
                            plot(ax2,z,squeeze(mean(data(sliderobj.Value,yindex,:,i),2)));
                            set(ax2,'Xlim',zrange);view(90);
                            plot(ax3,y,squeeze(mean(data(sliderobj.Value,:,zindex,i),3)));
                            set(ax3,'Xlim',xrange);
                            plot(ax4,x,squeeze(mean(mean(data(:,yindex,zindex,i),1),2))); 
                            hold on; plot(ax4,sliderobj.Value,squeeze(mean(mean(data(sliderobj.Value,yindex,zindex,i),1),2)),'O');
                            set(ax4,'Xlim',xrange);
                         end
            end
            try 
                axis(ax1,'xy');
                set(obj.Plotaxes{i},'Title',subplottitle{i});
            end
                
            end
                    
        end
        function obj=showtypeChange(obj,data,x,y,z,c,subplottitle)
%                tmptype=findobj(obj.Controlpanel,'Tag','showtype');
%                xtmpobj=findobj(obj.Controlpanel,'Tag','Xlim');
%                ytmpobj=findobj(obj.Controlpanel,'Tag','Ylim');
%                ztmpobj=findobj(obj.Controlpanel,'Tag','Zlim');
%                sliderobj=findobj(obj.Controlpanel,'Tag','slicebar');
               obj.Axischange(x,y,z);
               obj.ShowSliceValue(data,x,y,z,c,subplottitle);
        end
        function obj=ShowSliceValue(obj,data,x,y,z,c,subplottitle)
            tmptext=findobj(obj.Controlpanel,'Tag','slicetext');
            tmptype=findobj(obj.Controlpanel,'Tag','showtype');
            sliderobj=findobj(obj.Controlpanel,'Tag','slicebar');
            sliderobj.Value=round(sliderobj.Value);
            switch tmptype.String{tmptype.Value}
                case 'X&Y'
                    set(tmptext,'String',[num2str(z(sliderobj.Value)),' / ',num2str(min(z)),'-',num2str(max(z))]);
                case 'X&Z'
                     set(tmptext,'String',[num2str(y(sliderobj.Value)),' / ',num2str(min(y)),'-',num2str(max(y))]);
                case 'Y&Z'
                     set(tmptext,'String',[num2str(x(sliderobj.Value)),' / ',num2str(min(x)),'-',num2str(max(x))]);
            end
            obj.SilderChange(data,x,y,z,c,subplottitle);
        end
        function mouseScroll (obj,object, eventdata)
          sliderobj=findobj(obj.Controlpanel,'Tag','slicebar');
          UPDN = eventdata.VerticalScrollCount;
          S=sliderobj.Value;
        S = S - UPDN;
        if (S < sliderobj.Min)
            S = sliderobj.Min;
        elseif (S > sliderobj.Max)
            S = sliderobj.Max;
        end
        set(sliderobj,'Value',S);
        end
    end
end

