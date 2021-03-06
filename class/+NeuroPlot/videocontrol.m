classdef videocontrol < handle
    % add a video window 
    %  synchonized to the given evt time.
    properties
        correcttime=0;
        CurrentVideo;
        timelist=0;
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
            addlistener(videolist,'Value','PostSet',@(~,src) obj.videochangefcn(videolist));
            uicontrol('Parent',Toppanel,'Style','text','Tag','videotime');
            framenumber=uicontrol('Parent',Toppanel,'Style','text');
            uicontrol('Parent',Toppanel,'Style','text','Tag','correcttime');
            Midpanel=uix.VBox('Parent',parent,'Padding',0);
            Showpanel=uix.Panel('Parent',Midpanel,'Title','Video show','Padding',0);
            axes('Parent',Showpanel,'Tag','videoshow','NextPlot','replacechildren');
            timebar=uicontrol('Parent',Midpanel,'Style','slider','Tag','timebar');
            addlistener(timebar,'Value','PostSet',@(~,~) obj.GetFrame(timebar,framenumber));
            Downpanel=uix.HBox('Parent',parent);
            uicontrol('Parent',Downpanel,'Tag','play','String','Play','Callback',@(~,~) obj.Videoplay());
            uicontrol('Parent',Downpanel,'Tag','pause','String','Pause','Enable','off','Callback',@(~,~) obj.Videopause());
            uicontrol('Parent',Downpanel,'Tag','postframe','String','Postframe (F)','Callback',@(~,~) obj.Postframe(timebar));
            uicontrol('Parent',Downpanel,'Tag','preframe','String','Preframe (R)','Callback', @(~,~) obj.Preframe(timebar));
            set(parent,'Height',[-1,-10,-1]);
            set(Midpanel,'Height',[-9,-1]);
            obj.videochangefcn(videolist);
        end
        
        function obj=videochangefcn(obj,videolist)
            obj.CurrentVideo=mmread(videolist.String{videolist.Value});
            obj.timelist=obj.CurrentVideo.times;
            numFrame=obj.CurrentVideo.nrFramesTotal;
            tmpobj=findobj(gcf,'Tag','play');
            set(tmpobj,'Enable','on');
            tmpobj=findobj(gcf,'Tag','pause');
            set(tmpobj,'Enable','off');
            tmpobj=findobj(gcf,'Tag','timebar');
            set(tmpobj,'min',1,'max',numFrame,'SliderStep',[1,10]./numFrame,'Value',1);
            tmpobj2=findobj(gcf,'Tag','videotime');
             addlistener(obj,'currenttime','PostSet',@(~,~) obj.Getcurrenttime(tmpobj,tmpobj2));
             tmpobj=findobj(gcf,'Tag','correcttime');
             tmpobj.String=sprintf('Video intialize at the %.3f sec relatvie to NeuroData.',obj.correcttime(videolist.Value));
             obj.Showframe(1);
        end
        function obj=Getcurrenttime(obj,sliderbar,videotime)
            videotime.String=sprintf('Current Time in AVI = %.3f sec', obj.currenttime);
        end
        function obj=GetFrame(obj,sliderbar,framenumber)
            obj.Showframe(round(sliderbar.Value));
            framenumber.String=sprintf('Frame number in AVI = %.0f', round(sliderbar.Value));
        end
        function obj=Showframe(obj,framenum)
            tmpobj=findobj(gcf,'Tag','videoshow');
            imshow(flip(obj.CurrentVideo.frames(framenum).cdata),'Parent',tmpobj);
            obj.currenttime=obj.timelist(framenum);
        end
        function obj=Videoplay(obj)
            tmpobj=findobj(gcf,'Tag','play');
            set(tmpobj,'Enable','off');
            tmpobj=findobj(gcf,'Tag','pause');
            set(tmpobj,'Enable','on');
            tmpobj1=findobj(gcf,'Tag','timebar')
            while tmpobj1.Value<tmpobj1.Max
                if strcmp(tmpobj.Enable,'on')
                   set(tmpobj1,'Value',tmpobj1.Value+1);
                    pause(2/obj.CurrentVideo.rate);
                else
                    break;
                end
            end
        end
        function obj=Videopause(obj,timebar)
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

