classdef videocontrol < handle
    % add a video window 
    %  synchonized to the given evt time.
    properties
        correcttime=0;
        CurrentVideo;
        timelist=0;
        framebuffer=[];
    end
    properties(SetObservable)
        currenttime;
    end
    methods
        function obj=create(obj,varargin)
            varinput={'parent','videoobj','linkedevent'};
            default={[],[],[]};
            for i=1:length(varinput)
               eval([varinput{i},'=default{i};']);
           end
            for i = 1:2:length(varargin)
                     varindex=find(ismember(varinput,lower(varargin{i}))==1);
                     eval([varinput{varindex},'=varargin{i+1};']);
            end
            Toppanel=uix.HBox('Parent',parent);
            for i=1:length(videoobj)
                videoname{i}=videoobj(i).Filename;
                obj.correcttime(i)=videoobj(i).correcttime;
            end
            videolist=uicontrol('Parent',Toppanel,'Style','popupmenu','Tag','videolist','String',videoname,'Value',1)
            uicontrol('Parent',Toppanel,'Style','text','Tag','videotime');
            uicontrol('Parent',Toppanel,'Style','text','Tag','correcttime');
            Midpanel=uix.VBox('Parent',parent,'Padding',0);
            Showpanel=uix.Panel('Parent',Midpanel,'Title','Video show','Padding',0);
            axes('Parent',Showpanel,'Tag','videoshow','NextPlot','replacechildren');
            timebar=uicontrol('Parent',Midpanel,'Style','slider','Tag','timebar');
            Downpanel=uix.HBox('Parent',parent);
            uicontrol('Parent',Downpanel,'Style','text','String','FrameWidth');
            timeband=uicontrol('Parent',Downpanel,'Style','edit','Tag','timeband','String','0,60'); % read the first 60s of the video
            addlistener(timeband,'String','PostSet',@(~,~) obj.changetimebar(videolist,timebar,timeband));
            addlistener(videolist,'Value','PostSet',@(~,~) obj.videochangefcn(videolist,timeband,timebar));
            addlistener(timebar,'Value','PostSet',@(~,~) obj.GetFrame(timebar));
            uicontrol('Parent',Downpanel,'Tag','play','String','Play','Callback',@(~,~) obj.Videoplay());
            uicontrol('Parent',Downpanel,'Tag','pause','String','Pause','Enable','off','Callback',@(~,~) obj.Videopause());
            uicontrol('Parent',Downpanel,'Tag','postframe','String','Postframe (F)','Callback',@(~,~) obj.Postframe(timebar));
            uicontrol('Parent',Downpanel,'Tag','preframe','String','Preframe (R)','Callback', @(~,~) obj.Preframe(timebar));
            set(parent,'Height',[-1,-10,-1]);
            set(Midpanel,'Height',[-9,-1]);
            obj.videochangefcn(videolist,timeband,timebar);
        end
        
        function obj=changetimebar(obj,videolist,timebar,timeband)
            tmp=str2num(timeband.String);
            try
                obj.CurrentVideo=mmread(videolist.String{videolist.Value},[],tmp);        
                set(timebar,'min',1,'max',length(obj.CurrentVideo.frames),'SliderStep',[1,10]./length(obj.CurrentVideo.frames),'Value',1);
            catch
                obj.CurrentVideo=VideoReader(videolist.String{videolist.Value});
                obj.CurrentVideo.Currenttime=tmp(1);
                i=1;
                while hasFrame(obj.CurrentVideo)
                    obj.framebuffer(i).frame=readFrame(obj.CurrentVideo);
                    obj.framebuffer(i).time=obj.CurrentVideo.Currenttime;
                    i=i+1;
                    if obj.CurrentVideo.Currenttime>tmp(2)
                        break;
                    end
                end
                set(timebar,'min',1,'max',length(obj.FrameBuffer),'SliderStep',[1,10]./length(obj.FrameBuffer),'Value',1);
                obj.GetFrame(timebar);
            end
end
        function obj=videochangefcn(obj,videolist,timeband,timebar)
           obj.changetimebar(videolist,timebar,timeband);
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
             videotime.String=sprintf('Current Time in NeuroData = %.3f sec', obj.currenttime+obj.correcttime(videolist.Value));
        end
        function obj=GetFrame(obj,sliderbar)
            obj.Showframe(round(sliderbar.Value));
%             framenumber.String=sprintf('Frame number in AVI = %.0f', round(sliderbar.Value));
        end
        function obj=Showframe(obj,framenum)
            tmpobj=findobj(gcf,'Tag','videoshow');
            try
                imshow(flip(obj.CurrentVideo.frames(framenum).cdata),'Parent',tmpobj);
                obj.currenttime=obj.CurrentVideo.times(framenum);
            catch
                imshow(obj.FrameBuffer(framenum).frame,'Parent',tmpobj);
                obj.currenttime=obj.FrameBuffer(framenum).time;
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

