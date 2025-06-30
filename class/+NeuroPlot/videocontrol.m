classdef videocontrol < uix.VBoxFlex
    % add a video window 
    %  synchonized to the given evt time.
    properties
        offset=0;
        CurrentVideo;
        currentindex;
    end
    properties(SetObservable)
        currenttime;
        timerelative;
    end
    properties (Access = private)
        isUpdating = false % 防递归标志
    end
    methods
        function obj=create(obj,parent,tag,videodata)
            % create the main panel for plot VideoData object;
            obj.Parent=parent;
            obj.Tag=tag;
            Toppanel=uix.HBox('Parent',obj);
            for i=1:length(videodata)
                videoname{i}=videodata(i).Filename;
                obj.offset(i)=str2num(videodata(i).correcttime);
            end
            videolist=uicontrol('Parent',Toppanel,'Style','popupmenu','Tag','videolist','String',videoname,'Value',1);
            uicontrol('Parent',Toppanel,'Style','text','Tag','currenttime');
            Middlepanel=uix.VBox('Parent',obj,'Padding',0);
            Showpanel=uix.Panel('Parent',Middlepanel,'Title','Video show','Padding',0);
            axes('Parent',Showpanel,'Tag','videoshow','NextPlot','replacechildren');
            totaltimebar=uicontrol('Parent',Middlepanel,'Style','slider','Tag','totaltimebar');
            Downpanel=uix.HBox('Parent',obj);
            uicontrol('Parent',Downpanel,'Style','text','String','relative time');
            obj.timerelative=uicontrol('Parent',Downpanel,'Style','edit','String',0,'Tag','relativetime');
            uicontrol('Parent',Downpanel,'Tag','play','String','Play');
            uicontrol('Parent',Downpanel,'Tag','pause','String','Pause','Enable','off');
            uicontrol('Parent',Downpanel,'Tag','preframe','String','Preframe');
            uicontrol('Parent',Downpanel,'Tag','postframe','String','Postframe');
            set(obj,'Height',[-1,-10,-1]);
            set(Middlepanel,'Height',[-9,-1]);
            set(videolist,'Callback',@(~,~) obj.videochangefcn(videolist));
            set(videolist,'Value',1);
            addlistener(obj.timerelative,'String','PostSet',@(~,~) obj.settimebar('timerelative'));
            addlistener(totaltimebar,'Value','PostSet',@(~,~) obj.settimebar('timebar'));
            obj.videochangefcn(videolist);
        end
        function settimebar(obj,option)
            % sychronize the relative, timecurrent and timebar
            if obj.isUpdating
                return;
            end
            obj.isUpdating = true;
            timerelative=findobj(obj,'Tag','relativetime');
            timecurrent=findobj(obj,'Tag','currenttime');
            totaltimebar=findobj(obj,'Tag','totaltimebar');
            videolist=findobj(obj,'Tag','videolist');
            switch option
                case 'timerelative' %sychronize the timecurrent and timebar
                    relativetime=str2num(timerelative.String);
                    tmp=obj.offset-relativetime;
                    tmp(tmp>0)=0;
                    [~,index]=min(abs(tmp));
                    set(videolist,'Value',index);
                    set(totaltimebar,'Value',relativetime);
                    obj.setcurrenttime(timecurrent); 
                case 'timebar' % sychronize timerelative and timecurrent
                    obj.setcurrenttime(timecurrent); 
            end
            obj.isUpdating = false;
        end
        function obj=videochangefcn(obj,videolist)
            % change the timebar and read the video.
             obj.currentindex=videolist.Value;
%              tmpobj=findobj(obj,'Tag','currenttime');
%              tmpobj.String=sprintf('Video intialize at the %.3f sec relatvie to NeuroData.',obj.offset(videolist.Value));
             obj.CurrentVideo=VideoReader(videolist.String{videolist.Value});
             begintime=obj.CurrentVideo.Currenttime+obj.offset(videolist.Value);
             endtime=begintime+obj.CurrentVideo.Duration;
%              timestamps=linspace(begintime,endtime,obj.CurrentVideo.Duration*obj.CurrentVideo.Framerate;
             minStep=round((0.05*10)*obj.CurrentVideo.FrameRate);
             maxStep=round((0.5*10)*obj.CurrentVideo.FrameRate);
             totaltimebar=findobj(obj,'Tag','totaltimebar');
             set(totaltimebar,'Min',begintime,'Max',endtime,'SliderStep',[minStep,maxStep]./obj.CurrentVideo.Duration,'Value',obj.CurrentVideo.Currenttime+obj.offset(obj.currentindex));
             tmpobj=findobj(obj,'Tag','play');
             set(tmpobj,'Enable','on','Callback',@(~,~) obj.Videoplay);
             tmpobj=findobj(obj,'Tag','pause');
             set(tmpobj,'Enable','off','Callback',@(~,~) obj.Videopause);
             tmpobj=findobj(obj,'Tag','preframe');
             set(tmpobj,'Callback',@(~,~) obj.Preframe);
             tmpobj=findobj(obj,'Tag','postframe');
             set(tmpobj,'Callback',@(~,~) obj.Postframe);
        end
        function obj=setcurrenttime(obj,timecurrent)
            totaltimebar=findobj(obj,'Tag','totaltimebar');
            index=totaltimebar.Value;
            obj.currenttime=index;
            timecurrent.String=sprintf(['Current Time in NeuroData = %.3f sec, Current Time in Video = %.3f sec'], obj.currenttime,obj.currenttime-obj.offset(obj.currentindex)); 
        end  
        function obj=Videoplay(obj)
            tmpobj=findobj(obj,'Tag','play');
            set(tmpobj,'Enable','off');
            tmpobj1=findobj(obj,'Tag','pause');
            set(tmpobj1,'Enable','on');
            videolist=findobj(obj,'Tag','videolist');
            timebar=findobj(obj,'Tag','totaltimebar');
            while hasFrame(obj.CurrentVideo)&&strcmp(tmpobj.Enable,'off')
                set(timebar,'Value',obj.currenttime+1/obj.CurrentVideo.FrameRate);
            end
        end
        function obj=Videopause(obj)
            tmpobj=findobj(obj,'Tag','pause');
            set(tmpobj,'Enable','off');
            tmpobj=findobj(obj,'Tag','play');
            set(tmpobj,'Enable','on');
        end
        function obj=Preframe(obj)
            obj.Videopause;
            timebar=findobj(obj,'Tag','totaltimebar');
            set(timebar,'Value',obj.currenttime-1/obj.CurrentVideo.FrameRate);
        end
        function obj=Postframe(obj)
            obj.Videopause;
            timebar=findobj(obj,'Tag','totaltimebar');
            set(timebar,'Value',obj.currenttime+1/obj.CurrentVideo.FrameRate);
        end
    end
end

