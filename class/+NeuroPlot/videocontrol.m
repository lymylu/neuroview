classdef videocontrol < handle
    % add a video window 
    %  synchonized to the given evt time.
    properties
        parent=[]
        correcttime=0;
        CurrentVideo;
        FrameBuffer=[];
    end
    properties(SetObservable)
        currenttime;
        timebar
        synctag % sync time slider for other time slider.
    end
    methods
        function obj=create(obj,parent,videodata)
            % create the main panel for plot VideoData object;
            if ~isempty(parent)
                obj.parent=parent;
                Toppanel=uix.HBox('Parent',obj.parent);
            else
                Toppanel=uix.HBox();
            end
            for i=1:length(videodata)
                videoname{i}=videodata(i).Filename;
                obj.correcttime(i)=videodata(i).correcttime;
            end
            videolist=uicontrol('Parent',Toppanel,'Style','popupmenu','Tag','videolist','String',videoname,'Value',1);
            uicontrol('Parent',Toppanel,'Style','text','Tag','videotime');
            uicontrol('Parent',Toppanel,'Style','text','Tag','correcttime');
            Midpanel=uix.VBox('Parent',parent,'Padding',0);
            Showpanel=uix.Panel('Parent',Midpanel,'Title','Video show','Padding',0);
            axes('Parent',Showpanel,'Tag','videoshow','NextPlot','replacechildren');
            obj.timebar=uicontrol('Parent',Midpanel,'Style','slider','Tag','timebar');
            Downpanel=uix.HBox('Parent',parent);
            uicontrol('Parent',Downpanel,'Style','text','String','relative time');
            timerelative=uicontrol('Parent',Downpanel,'Style','edit','String',0,'Tag','videorelativetime');
            addlistener(timerelative,'String','PostSet',@(~,~) obj.changetimebar(videolist,obj.timebar));
            uicontrol('Parent',Downpanel,'Style','text','String','FrameWidth');
            timeband=uicontrol('Parent',Downpanel,'Style','edit','Tag','timeband','String','0,60'); % read the first 60s of the video
            addlistener(timeband,'String','PostSet',@(~,~) obj.changetimebar(videolist,obj.timebar));
            addlistener(videolist,'Value','PostSet',@(~,~) obj.videochangefcn(videolist,obj.timebar));
            addlistener(obj.timebar,'Value','PostSet',@(~,~) obj.GetFrame(obj.timebar));
            uicontrol('Parent',Downpanel,'Tag','play','String','Play','Callback',@(~,~) obj.Videoplay());
            uicontrol('Parent',Downpanel,'Tag','pause','String','Pause','Enable','off','Callback',@(~,~) obj.Videopause());
            uicontrol('Parent',Downpanel,'Tag','preframe','String','Preframe','Callback', @(~,~) obj.Preframe(obj.timebar));
            uicontrol('Parent',Downpanel,'Tag','postframe','String','Postframe','Callback',@(~,~) obj.Postframe(obj.timebar));
            set(parent,'Height',[-1,-10,-1]);
            set(Midpanel,'Height',[-9,-1]);
            obj.videochangefcn(videolist,obj.timebar);
        end
        
        function obj=changetimebar(obj,videolist,timebar)
            timeband=findobj(obj.parent,'Tag','timeband');
            timerelative=findobj(obj.parent,'Tag','videorelativetime');
            timerelative=str2num(timerelative.String);
            tmp=str2num(timeband.String);
            timerange=timerelative+tmp;
            try
                obj.CurrentVideo=mmread(videolist.String{videolist.Value},[],tmp);        
                set(timebar,'min',1,'max',length(obj.CurrentVideo.frames),'SliderStep',[1,10]./length(obj.CurrentVideo.frames),'Value',1);
            catch
                obj.CurrentVideo=VideoReader(videolist.String{videolist.Value});
                obj.CurrentVideo.Currenttime=timerange(1);
                obj.FrameBuffer=[];
                i=1;c=1;
                while hasFrame(obj.CurrentVideo)
                    obj.FrameBuffer(i).frame=readFrame(obj.CurrentVideo);
                    obj.FrameBuffer(i).time=obj.CurrentVideo.Currenttime;
                    if obj.FrameBuffer(i).time>timerelative
                        barvalue(c)=i;
                        c=c+1;
                    end
                    i=i+1;
                    if obj.CurrentVideo.Currenttime>timerange(2)
                        break;
                    end
                end
                set(timebar,'min',1,'max',length(obj.FrameBuffer),'SliderStep',[1,10]./length(obj.FrameBuffer),'Value',min(barvalue));
                % set the timebar value to the nearest frame relative to timerelative
                obj.GetFrame(timebar);
            end
end
function obj=videochangefcn(obj,videolist,timebar)
    % change the timebar around current time
           obj.changetimebar(videolist,timebar);
             tmpobj=findobj(gcf,'Tag','play');
             set(tmpobj,'Enable','on');
             tmpobj=findobj(gcf,'Tag','pause');
             set(tmpobj,'Enable','off');
             tmpobj2=findobj(gcf,'Tag','videotime');
             addlistener(obj,'currenttime','PostSet',@(~,~) obj.Getcurrenttime(tmpobj2,videolist));
             tmpobj=findobj(gcf,'Tag','correcttime');
             tmpobj.String=sprintf('Video intialize at the %.3f sec relatvie to NeuroData.',obj.correcttime(videolist.Value));
             obj.Showframe(1);             
        end
        function obj=Getcurrenttime(obj,videotime,videolist)
             videotime.String=sprintf(['Current Time in NeuroData = %.3f sec, Current Time in Video = %.3f sec'], obj.currenttime+obj.correcttime(videolist.Value),obj.currenttime);
                
        end
        function obj=GetFrame(obj,sliderbar)
            obj.Showframe(round(sliderbar.Value));
%             framenumber.String=sprintf('Frame number in AVI = %.0f', round(sliderbar.Value));
        end
        function obj=Showframe(obj,framenum)
            tmpobj=findobj(gcf,'Tag','videoshow');
            try
                imshow(flip(obj.CurrentVideo.frames(framenum).cdata),'Parent',tmpobj);
                obj.currenttime=obj.CurrentVideo.times(framenum); % for mmread
            catch
                imshow(obj.FrameBuffer(framenum).frame,'Parent',tmpobj);
                obj.currenttime=obj.FrameBuffer(framenum).time; % for VideoReader
            end
                
        end
        function obj=Videoplay(obj)
            tmpobj=findobj(gcf,'Tag','play');
            set(tmpobj,'Enable','off');
            tmpobj=findobj(gcf,'Tag','pause');
            set(tmpobj,'Enable','on');
            tmpobj1=findobj(gcf,'Tag','timebar');
            while tmpobj1.Value<tmpobj1.Max
                if strcmp(tmpobj.Enable,'on')
                   set(tmpobj1,'Value',tmpobj1.Value+1);
                   try 
                    pause(2/obj.CurrentVideo.rate);
                   catch
                       pause(2/obj.CurrentVideo.FrameRate);
                   end
                else
                    break;
                end
            end
        end
        function obj=Videopause(obj)
            tmpobj=findobj(gcf,'Tag','pause');
            set(tmpobj,'Enable','off');
            tmpobj=findobj(gcf,'Tag','play');
            set(tmpobj,'Enable','on');
        end
        function obj=Preframe(obj,timebar)
            timebar.Value=timebar.Value-1;
        end
        function obj=Postframe(obj,timebar)
            timebar.Value=timebar.Value+1;
        end
            
    end
end

