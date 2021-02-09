classdef EventModified
   % correct the choosed eventtype according to the Video     
    properties
        Eventdata
        Videocontrol
    end
    
    methods
        function obj = cal(obj,objmatrix,DetailsAnalysis)
            global CorrectEvents
            obj.Eventdata=objmatrix.EVTdata;
            CorrectEvents=LoadEvents_neurodata(obj.Eventdata.Filename);
            obj.VideoCorrectGUI(objmatrix.Videodata,DetailsAnalysis);
            uiwait;
        end
        function VideoCorrectGUI(obj,Videodata,DetailsAnalysis,UI)
            import NeuroPlot.videocontrol NeuroPlot.selectpanel
            if isempty(parent)
                UI=figure();
            end
            set(UI,'DeleteFcn',@(~,~) obj.SaveCorrect());
            Mainwindow=uix.VBox('Parent',UI);
            Videopanel=uix.VBox('Parent',Mainwindow);
            obj.Videocontrol=videocontrol();
            obj.Videocontrol=obj.Videocontrol.create('Parent',Videopanel,'Videoobj',Videodata);
            obj.Eventmodifycreate(Mainwindow,DetailsAnalysis);
            set(Mainwindow,'Heights',[-2,-1]);
        end
        function Eventmodifycreate(obj,parent)
            import NeuroPlot.selectpanel
             events=LoadEvents_neurodata(obj.Eventdata.Filename);
             eventdescription=events.description;
             Downpanel=uix.HBox('Parent',parent);
             eventpanel=uix.VBox('Parent',Downpanel);
             tmppanel=selectpanel();
             tmppanel=tmppanel.create('parent',eventpanel,'listtitle',{'Eventtype'},'listtag',{'EventIndex'},'typeTag',{'Eventtype'});
             Eventlist=1:length(eventdescription);
             Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
             tmppanel=tmppanel.assign('typeTag',{'Eventtype'},'typestring',eventdescription,'listtag',{'EventIndex'},'liststring',Eventlist);
             eventmodifypanel=uix.VBox('parent',Downpanel);
             uicontrol('parent',eventmodifypanel,'Style','Text','Tag','eventtime');
             tmpobj=findobj(gcf,'Tag','EventIndex');
             set(tmpobj,'min',1,'max',1); 
             uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Record the corrected time!','Callback',@(~,~) obj.RecordTime(tmpobj));
             uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Save the corrected result','Callback',@(~,~) obj.SaveCorrect());
             uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Show the corrected events','Callback',@(~,~) obj.Showcorrect(tmpobj));
             uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Add a new type of events','Callback',@(~,~) obj.AddEvents(tmppanel));
             addlistener(tmpobj,'Value','PostSet',@(~,~) obj.Geteventtime(tmpobj,obj.Videocontrol));
             tmpobj=findobj(gcf,'Tag','add');
             delete(tmpobj);
             tmpobj=findobj(gcf,'Tag','delete');
             delete(tmpobj);
             tmpobj=findobj(gcf,'Tag','blacklist');
             delete(tmpobj);
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
        function obj=RecordTime(obj,listobj)
            global CorrectEvents
            tmpobj=findobj(gcf,'Tag','videolist');
            videoindex=tmpobj.Value;
            CorrectEvents.time(str2num(listobj.String{listobj.Value}))=obj.Videocontrol.currenttime+obj.Videocontrol.correcttime(videoindex);
            tmpobj=findobj(gcf,'Tag','eventtime');
            tmpobj.String=sprintf('current event time is %.3f',CorrectEvents.time(str2num(listobj.String{listobj.Value})));
        end
        function obj=SaveCorrect(obj)
            global CorrectEvents
            try
                copyfile(obj.Eventdata.Filename,[obj.Eventdata.Filename(1:end-4),'.bak.evt']);
            end
            SaveEvents_neurodata(obj.Eventdata.Filename,CorrectEvents,1);
            uiresume;
        end 
        function obj=Showcorrect(obj,eventlist)
            global CorrectEvents
            figure();
            eventindex=cellfun(@(x) str2num(x),eventlist.String,'UniformOutput',1);
            dataorigin=LoadEvents_neurodata(obj.Eventdata.Filename);
            data(:,1)=eventindex;
            data(:,2)=dataorigin.time(eventindex);
            data(:,3)=CorrectEvents.time(eventindex);
            uitable(gcf,'Data',data,'ColumnNames',{'eventindex','initialized Value','modifyvalue'});  
        end
        function obj=AddEvents(obj,eventpanel)
            global CorrectEvents
                tmpobj=findobj(gcf,'Tag','videolist');
                videoindex=tmpobj.Value;
                eventname=inputdlg('input a new event description!');
                CorrectEvents.description=cat(1,CorrentEvents.description,eventname);
                CorrectEvents.time=cat(1,CorrentEvents.time,obj.Videocontrol.currenttime+obj.Videocontrol.correcttime(videoindex));
        end
        end
end

