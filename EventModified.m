classdef EventModified
   % options
   % 1.correct the choosed eventtype according to the Video;  
   % 2.if no Video object selected, add/delete and shift the choosed event time point
   % and modify the related event description;
   % 3.if no event file selected but the videodata exist, create a new event file;
    properties
        EVTdata
        Videocontrol
    end
    
    methods
        function obj = cal(obj,choosematrix,Mainwindow,option)
            global DataTaglist
            DataTaglist=[];
            for i=1:length(choosematrix)
                filelist{i}=choosematrix(i).Datapath;
            end
            parent=uix.VBoxFlex('Parent',Mainwindow);
            switch option
                case 'Event_Video'
                    Subjectpanel=uicontrol('Parent',parent,'Style','popupmenu','String',filelist,'Tag','Subjectlist');
                    parent1=uix.VBoxFlex('Parent',parent);
                    set(Subjectpanel,'Callback',@(~,~) obj.Subject_EVfcn(Subjectpanel,choosematrix,parent1));
                    obj.Subject_EVfcn(Subjectpanel,choosematrix,parent1);
                    set(parent,'Heights',[-1,-14]);
                case 'Event'
                    Subjectpanel=uicontrol('Parent',parent,'Style','listbox','String',filelist,'Tag','Subjectlist','max',3,'min',1);
                    set(Subjectpanel,'Callback',@(~,~) obj.Subject_Efcn(Subjectpanel,choosematrix,parent));
                case 'noEvent_Video'
                    Subjectpanel=uicontrol('Parent',parent,'Style','popupmenu','String',filelist,'Tag','Subjectlist');
                    parent1=uix.VBoxFlex('Parent',parent);
                    newEvent=inputdlg('Input the new event file name');
                    set(Subjectpanel,'Callback',@(~,~) obj.Subject_nEVfcn(Subjectpanel,choosematrix,parent1,newEvent));
                    obj.Subject_nEVfcn(Subjectpanel,choosematrix,parent1,newEvent);
                    set(parent,'Heights',[-1,-14]);
            end
        end
        function Subject_EVfcn(obj,Subjectpanel,choosematrix,parent)
            % modify the exsit event file using the Video
            global Subjectnum CorrectEvents
                Subjectnum=Subjectpanel.Value;
                obj.EVTdata=choosematrix(Subjectnum).EVTdata;
                eventdata=LoadEvents_neurodata(choosematrix(Subjectnum).EVTdata.Filename);
                CorrectEvents.time=eventdata.time;
                CorrectEvents.description=eventdata.description;
                object=findobj(parent);
                delete(object(2:end));
                obj=obj.VideoCorrectGUI(choosematrix,parent);
                obj=obj.EventmodifyGUI(choosematrix,parent,[]);
                set(parent,'Heights',[-1,-1]);
        end
        function Subject_nEVfcn(obj,Subjectpanel,choosematrix,parent,newEvent)
            % create the new event using the Video
            global Subjectnum CorrectEvents
                Subjectnum=Subjectpanel.Value;
                CorrectEvents.time=[];
                CorrectEvents.description=[];
                object=findobj(parent);
                delete(object(2:end));
                obj=obj.VideoCorrectGUI(choosematrix,parent);
                obj=obj.EventmodifyGUI(choosematrix,parent,fullfile(Subjectpanel.String{Subjectnum},newEvent{:}));
                set(parent,'Heights',[-1,-1]);
        end
        function Subject_Efcn(obj,Subjectpanel,choosematrix,parent)
            % modify the event description, modify the event using the
            % exist event.
        end
        function obj=VideoCorrectGUI(obj,choosematrix,parent)
            import NeuroPlot.videocontrol NeuroPlot.selectpanel
            global Subjectnum
            if isempty(parent)
                parent=figure();
            end
            set(parent,'DeleteFcn',@(~,~) obj.SaveCorrect());
            Videopanel=uix.VBox('Parent',parent);
            obj.Videocontrol=NeuroPlot.videocontrol();
            Videodata=choosematrix(Subjectnum).Videodata;
            obj.Videocontrol.create('Parent',Videopanel,'Videoobj',Videodata);
        end
        function obj=EventmodifyGUI(obj,choosematrix,parent,newEventname)
            import NeuroPlot.selectpanel
            global Subjectnum 
            if isempty(newEventname) % modify the exist event according to the video
             obj.EVTdata=choosematrix(Subjectnum).EVTdata;
             eventdata=LoadEvents_neurodata(choosematrix(Subjectnum).EVTdata.Filename);
             eventdescription=eventdata.description;
             Downpanel=uix.HBox('Parent',parent);
             eventpanel=uix.VBox('Parent',Downpanel);
             tmppanel=selectpanel();
             tmppanel=tmppanel.create('parent',eventpanel,'listtitle',{'Eventtype'},'listtag',{'EventIndex'},'typeTag',{'Eventtype'});
             Eventlist=1:length(eventdescription);
             Eventlist=arrayfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
             tmppanel=tmppanel.assign('typeTag',{'Eventtype'},'typestring',eventdescription,'listtag',{'EventIndex'},'liststring',Eventlist);
             eventmodifypanel=uix.VBox('parent',Downpanel);
             uicontrol('parent',eventmodifypanel,'Style','Text','Tag','eventtime');
             tmpobj=findobj(gcf,'Tag','EventIndex');
             tmpobj1=findobj(gcf,'Tag','Eventtype');
             description=tmpobj1.String{tmpobj1.Value};
             set(tmpobj,'min',1,'max',1); 
             uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Record the corrected time!','Callback',@(~,~) obj.RecordTime(tmpobj,obj.Videocontrol,description));
             uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Save the corrected result','Callback',@(~,~) obj.SaveCorrect());
             uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Show the corrected events','Callback',@(~,~) obj.Showcorrect(tmpobj));
             addlistener(tmpobj,'Value','PostSet',@(~,~) obj.Geteventtime(tmpobj,obj.Videocontrol));
             tmpobj=findobj(gcf,'Tag','add');
             delete(tmpobj);
             tmpobj=findobj(gcf,'Tag','delete');
             delete(tmpobj);
             tmpobj=findobj(gcf,'Tag','blacklist');
             delete(tmpobj);
            else
             obj.EVTdata.Filename=newEventname;
             Downpanel=uix.HBox('Parent',parent);
             Descriptionpanel=uix.VBox('Parent',Downpanel);
             eventmodifypanel=uix.VBox('Parent',Downpanel);
             Descriptiontext=uicontrol('Parent',Descriptionpanel,'Style','text');
             uicontrol('Parent',Descriptionpanel,'Style','pushbutton','String','Description Define','Callback',@(~,~) obj.Descriptionadd(Descriptiontext));
             tmpobj=uicontrol('Parent',Descriptionpanel,'Style','listbox','String',[],'Tag','EventIndex');
             uicontrol('parent',eventmodifypanel,'Style','Text','Tag','eventtime');
             addlistener(tmpobj,'Value','PostSet',@(~,~) obj.Geteventtime(tmpobj,obj.Videocontrol));
             uicontrol('Parent',eventmodifypanel,'Style','pushbutton','String','add a new corrected time!','Callback',@(~,~) obj.RecordnewTime(tmpobj,obj.Videocontrol,Descriptiontext));
             uicontrol('Parent',eventmodifypanel,'Style','pushbutton','String','modify the corrected time!','Callback',@(~,~) obj.RecordTime(tmpobj,obj.Videocontrol,Descriptiontext));
             uicontrol('Parent',eventmodifypanel,'Style','pushbutton','String','delete the select corrected time!','Callback',@(~,~) obj.DeleteTime(tmpobj));
             uicontrol('Parent',eventmodifypanel,'Style','pushbutton','String','Save the corrected result','Callback',@(~,~) obj.SaveCorrect());
            end
        end
        function obj=DeleteTime(obj,listobj)
            global CorrectEvents
            eventindex=str2num(listobj.String{listobj.Value});
            CorrectEvents.time(eventindex)=[];
            CorrectEvents.description(eventindex)=[];
            listobj.String(listobj.Value)=[];
            try
                for i=1:length(listobj.String)
                    newstring{i}=num2str(i);
                end
                listobj.String=newstring;
                listobj.Value=1;
            end  
            if isempty(CorrectEvents.time)
                CorrectEvents.description=[];
            end
        end
        function obj=Descriptionadd(obj,Descriptiontext)
            global DataTaglist
            [text, ~, DataTaglist]=Taginfoappend(DataTaglist,2);
            Descriptiontext.String=text;
        end
        function obj=Geteventtime(obj,listobj,videoobj)
            global CorrectEvents
            time=CorrectEvents.time(str2num(listobj.String{listobj.Value}));
            tmpobj=findobj(gcf,'Tag','eventtime');
            tmpobj.String=sprintf('current event time is %.3f',time);
            for i=1:length(videoobj.correcttime)
                latency(i)=time-videoobj.correcttime(i);
            end
            [~,index]=min(latency(find(latency>0)));
            tmpobj=findobj(gcf,'Tag','videolist');
            set(tmpobj,'Value',index);
            
        end
        function obj=RecordnewTime(obj,listobj,videocontrol,descriptionpanel)
            if isempty(listobj.String)
                listobj.String={1};
            else
                listobj.String=cat(1,listobj.String,{num2str(str2num(listobj.String{end})+1)});
            end
            listobj.Value=length(listobj.String);
            obj.RecordTime(listobj,videocontrol,descriptionpanel);
        end
        function obj=RecordTime(obj,listobj,videocontrol,descriptionpanel)
            global CorrectEvents
            if ischar(descriptionpanel)
                description=descriptionpanel;
            else
                description=descriptionpanel.String;
            end
            eventindex=str2num(listobj.String{listobj.Value});
            tmpobj=findobj(gcf,'Tag','videolist');
            videoindex=tmpobj.Value;
            CorrectEvents.time(eventindex)=videocontrol.currenttime+videocontrol.correcttime(videoindex);
            try
                tmpobj=findobj(gcf,'Tag','eventtime');
                tmpobj.String=sprintf('current event time is %.3f',CorrectEvents.time(eventindex));
            end
            CorrectEvents.description{eventindex}=description;
        end
        function obj=SaveCorrect(obj)
            global CorrectEvents
            try
                copyfile(obj.EVTdata.Filename,[obj.EVTdata.Filename(1:end-4),'.bak.evt']);
            end
            SaveEvents_neurodata(obj.EVTdata.Filename,CorrectEvents,1);
        end 
        function obj=Showcorrect(obj,eventlist)
            global CorrectEvents
            figure();
            eventindex=cellfun(@(x) str2num(x),eventlist.String,'UniformOutput',1);
            dataorigin=LoadEvents_neurodata(obj.EVTdata.Filename);
            data(:,1)=eventindex;
            data(:,2)=dataorigin.time(eventindex);
            data(:,3)=CorrectEvents.time(eventindex);
            uitable(gcf,'Data',data,'ColumnNames',{'eventindex','initialized Value','modifyvalue'});  
        end
        end
end

