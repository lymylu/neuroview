classdef timecontrol<uix.HBox
    % generate the timebar to control the data with time scrolling
    properties
        timestamps
    end
    properties(SetObservable)
        timerelative
        currenttime
    end
    properties (Access = private)
        isUpdating = false % 防递归标志
    end
    methods
        function obj = create(obj,parent,tag,timestamps)
            % the data contains timestamps for timecontrol
            % for nphys data, it the
            % linspace(timebegin,timeend,timepoints);
            % for video data, it the linspace(timebegin,timeend,numframes);
            % timestamps is the length of file, (for seconds, note that due to the max limits of the slider bar for Matlab, 
            % the max time is 1e6 s);
            % the step of timestamps is for minimal steps 
            % the step of seconds is for maximum steps.
            obj.timestamps=timestamps;
            obj.Parent=parent;
            obj.Tag=tag;
            uicontrol('Parent',obj,'Style','text','String','relative time');
            obj.timerelative=uicontrol('Parent',obj,'Style','edit','String',num2str(min(obj.timestamps)),'Tag','relativetime');
            uicontrol('Parent',obj,'Style','text','String','time range');
            timerange=uicontrol('Parent',obj,'Style','edit','Tag','timerange'); 
            %obj.totaltimebar=NeuroPlot.timeslider('Parent',obj,'Tag','timeslider');
            totaltimebar=uicontrol('Parent',obj,'Style','slider','Tag','totaltimebar');
            uicontrol('Parent',obj,'Style','text','String','','Tag','currenttime');
            %obj.sliderstamps=double(1:1:length(timestamps));
            minStep=round((0.05*10)/(obj.timestamps(2)-obj.timestamps(1)));
            maxStep=round((0.5*10)/(obj.timestamps(2)-obj.timestamps(1)));
            set(timerange,'String','0 10','Callback',@(~,~) obj.changetimebar);
            set(totaltimebar,'Min',min(timestamps),'Max',max(timestamps),'SliderStep',[minStep,maxStep]./(length(timestamps)),'Value',min(timestamps));
            set(obj,'Widths',[-1,-1,-1,-1,-5,-1]);
            set(obj.timerelative,'Callback',@(~,~) obj.settimebar('timerelative'));
            addlistener(totaltimebar,'Value','PostSet',@(~,~) obj.settimebar('timebar'));
            set(timerange,'String','0 10');% show the first 10s of the data
        end
        function changetimebar(obj)
            timerange=findobj(obj,'Tag','timerange');
            v=str2num(timerange.String);
            timelength=v(2)-v(1); % seconds
            minStep=round((0.05*timelength)/(obj.timestamps(2)-obj.timestamps(1)));
            maxStep=round((0.5*timelength)/(obj.timestamps(2)-obj.timestamps(1)));
            timebar=findobj(obj,'Tag','totaltimebar');
            if minStep/length(obj.timestamps)<1e-6
                error('the step is to short, MatLab only support the step>1e-6, not the step is %6.f (timerange/file time points)',minstep);
            end
            set(timebar,'SliderStep',[minStep,maxStep]./length(obj.timestamps));
        end
            
        function settimebar(obj,option)
            % sychronize the relative, timecurrent and timebar
            if obj.isUpdating
                return; % 阻断递归
            end
            obj.isUpdating = true;
            timerelative=findobj(obj.Parent,'Tag','relativetime');
            timecurrent=findobj(obj,'Tag','currenttime');
            totaltimebar=findobj(obj,'Tag','totaltimebar');
            switch option
                case 'timerelative' %sychronize the timecurrent and timebar
                    relativetime=str2num(timerelative.String);
                    [~,index]=min(abs(obj.timestamps-relativetime));
                    set(totaltimebar,'Value',obj.timestamps(index));
                    obj.setcurrenttime(timecurrent); 
                case 'timebar' % sychronize timerelative and timecurrent
                    index=round(totaltimebar.Value);
                    %timerelative.String=obj.timestamps(index);
                    obj.setcurrenttime(timecurrent); 
            end
            obj.isUpdating = false;
        end
        function  setcurrenttime(obj,timecurrent)
            totaltimebar=findobj(obj,'Tag','totaltimebar');
            index=totaltimebar.Value;
            timecurrent.String=index;
            obj.currenttime=index;
        end
        function currenttime=getcurrenttime(obj)
            timecurrent=findobj(obj.Parent,'Tag','currenttime');
            currenttime=str2num(timecurrent.String);
        end
        function relativetime=getrelativetime(obj)
            timerelative=findobj(obj.Parent,'Tag','relativetime');
            relativetime=str2num(timerelative.String);
        end
        function [timestart,timestop]=gettimerange(obj)
            timerange=findobj(obj.Parent,'Tag','timerange');
            timerange=str2num(timerange.String)+obj.currenttime;
            timestart=timerange(1);
            timestop=timerange(2);
        end
    end
end