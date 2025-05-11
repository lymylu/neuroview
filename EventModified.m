classdef EventModified
   % add eventmodified panel and related listeners base on NeuroData.gui_plot()
   % options
   % 1.correct the choosed eventtype according to the Video;  
   % 2.if no Video object selected, add/delete and shift the choosed event time point
   % and modify the related event description;
   % 3.if no event file selected but the videodata exist, create a new event file;
   properties
        EVTdata
        videopanel
        eventpanel
    end
    
    methods
        function obj = cal(obj,choosematrix,Mainwindow,option)
            for i=1:length(choosematrix)
                filelist{i}=choosematrix(i).Datapath;
            end
            choosematrix(i).gui_plot();
            parent=uix.VBoxFlex('Parent',Mainwindow);
            switch option
                case 'Event_Video'
                    Subjectpanel=uicontrol('Parent',parent,'Style','popupmenu','String',filelist,'Tag','Subjectlist');
                    parent1=uix.HBoxFlex('Parent',parent);
                    set(Subjectpanel,'Callback',@(~,~) obj.Subject_EVfcn(Subjectpanel,choosematrix,parent1));
                    obj.Subject_EVfcn(Subjectpanel,choosematrix,parent1);
                    set(parent,'Heights',[-1,-14]);
                case 'Event'
                    Subjectpanel=uicontrol('Parent',parent,'Style','listbox','String',filelist,'Tag','Subjectlist','max',3,'min',1);
                    parent1=uix.VBoxFlex('Parent',parent);
                    set(Subjectpanel,'Callback',@(~,~) obj.Subject_Efcn(Subjectpanel,choosematrix,parent1));
                    obj.Subject_Efcn(Subjectpanel,choosematrix,parent1);
                    set(parent,'Heights',[-1,-10]);
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
                obj=obj.EventmodifyGUI(choosematrix,parent,'EV',[]);
                set(parent,'Width',[-8,-2]);
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
                obj=obj.EventmodifyGUI(choosematrix,parent,'nEV',fullfile(Subjectpanel.String{Subjectnum},newEvent{:}));
                set(parent,'Width',[-8,-2]);
        end
        function Subject_Efcn(obj,Subjectpanel,choosematrix,parent)
            % modify the event description, modify the event using the
            % exist event.
            global Subjectnum CorrectEvents
            Subjectnum=Subjectpanel.Value;
            obj.EVTdata=choosematrix(Subjectnum).EVTdata;
            eventdata=LoadEvents_neurodata(choosematrix(Subjectnum).EVTdata.Filename);
            CorrectEvents.time=eventdata.time;
            CorrectEvents.description=eventdata.description;
            object=findobj(parent);
            delete(object(2:end));
            obj=obj.EventmodifyGUI(choosematrix,parent,'E',[]);
        end
        function obj=VideoCorrectGUI(obj,choosematrix,parent)
            import NeuroPlot.videocontrol NeuroPlot.selectpanel
            global Subjectnum
            if isempty(parent)
                parent=figure();
            end
            set(parent,'DeleteFcn',@(~,~) obj.SaveCorrect());
            Videopanel=uix.VBox('Parent',parent);
            obj.videopanel=NeuroPlot.videocontrol();
            Videodata=choosematrix(Subjectnum).Videodata;
            obj.videopanel.create(Videopanel,Videodata);
        end
        function obj=EventmodifyGUI(obj,choosematrix,parent,option,newEventname)
            import NeuroPlot.selectpanel
            global Subjectnum 
           switch option
             case 'EV' % modify the exist event according to the video
             obj.EVTdata=choosematrix(Subjectnum).EVTdata;
             eventdata=LoadEvents_neurodata(choosematrix(Subjectnum).EVTdata.Filename);
             eventdescription=eventdata.description;
             Downpanel=uix.HBox('Parent',parent);
             obj.eventpanel=NeuroPlot.selectpanel();
             Eventlist=1:length(eventdescription);
             Eventlist=arrayfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
             obj.eventpanel=obj.eventpanel.create(Downpanel,{'EventIndex'},Eventlist,'typestring',eventdescription,'multiselect','off');
             eventmodifypanel=uix.VBox('parent',Downpanel);
             uicontrol('parent',eventmodifypanel,'Style','Text','Tag','eventtime');
             uicontrol('Parent',eventmodifypanel,'Style','pushbutton','String','Record a new time','Callback',@(~,~) obj.RecordnewTime());
             uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Correct current time','Callback',@(~,~) obj.CorrectTime());
             uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Save the corrected result','Callback',@(~,~) obj.SaveCorrect());
             uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Show the corrected events','Callback',@(~,~) obj.Showcorrect());
             addlistener(obj.eventpanel.listpanel{1},'Value','PostSet',@(~,~) obj.Geteventtime())
           case 'nEV' % modify a new event file with video.
             obj.EVTdata.Filename=newEventname;
             Downpanel=uix.HBox('Parent',parent);
             obj.eventpanel=NeuroPlot.selectpanel();
%              Eventlist=1:length(eventdescription);
%              Eventlist=arrayfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
             obj.eventpanel=obj.eventpanel.create(Downpanel,{'EventIndex'},{[]},'typestring',{[]},'multiselect','off');
             eventmodifypanel=uix.VBox('parent',Downpanel);
             uicontrol('parent',eventmodifypanel,'Style','Text','Tag','eventtime');
             uicontrol('Parent',eventmodifypanel,'Style','pushbutton','String','Record a new time','Callback',@(~,~) obj.RecordnewTime());
             uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Correct current time','Callback',@(~,~) obj.CorrectTime());
             uicontrol('Parent',eventmodifypanel,'Style','pushbutton','String','delete the select corrected time!','Callback',@(~,~) obj.DeleteTime());
             uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Save the corrected result','Callback',@(~,~) obj.SaveCorrect());
             case 'E'
              obj.EVTdata=choosematrix(Subjectnum).EVTdata;
              eventdata=LoadEvents_neurodata(choosematrix(Subjectnum).EVTdata.Filename);
              eventdescription=eventdata.description;
              Downpanel=uix.HBox('Parent',parent);
              obj.eventpanel=NeuroPlot.selectpanel();
              Eventlist=1:length(eventdescription);
              Eventlist=arrayfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
              obj.eventpanel=obj.eventpanel.create(Downpanel,{'EventIndex'},Eventlist,'typestring',eventdescription,'multiselect','off');
              eventmodifypanel=uix.VBox('parent',Downpanel);
              uicontrol('parent',eventmodifypanel,'Style','Text','Tag','eventtime'); 
              uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','modify the description','Callback',@(~,~) obj.Changedescription());
              uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Create shifted events','Callback',@(~,~) obj.Shiftevents());
              uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','delete selected events','Callback',@(~,~) obj.DeleteTime());
              uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Save the corrected result','Callback',@(~,~) obj.SaveCorrect());
              uicontrol('parent',eventmodifypanel,'Style','pushbutton','String','Show the corrected events','Callback',@(~,~) obj.Showcorrect());
           end
        end
        function obj=DeleteTime(obj)
            global CorrectEvents
            eventindex=cellfun(@(x) str2num(x),obj.eventpanel.listpanel.String(obj.eventpanel.listpanel.Value),'UniformOutput',1);
            CorrectEvents.time(eventindex)=[];
            CorrectEvents.description(eventindex)=[];
            obj.eventpanel.liststring(eventindex)=[];
            obj.eventpanel.typestring(eventindex)=[];
            obj.eventpanel.setdescription(liststring,typestring);
        end
        function obj=Descriptionadd(obj,Descriptiontext)
            global DataTaglist
            [text, ~, DataTaglist]=Taginfoappend(DataTaglist,2);
            Descriptiontext.String=['Current description:',text];
        end
        function obj=Geteventtime(obj)
            % listobj,videoobj,and descriptionobj
            global CorrectEvents
            eventpanel=obj.eventpanel;
            videopanel=obj.videopanel;
            time=CorrectEvents.time(str2num(eventpanel.listpanel{1}.String{eventpanel.listpanel{1}.Value}));
            tmpobj=findobj(gcf,'Tag','eventtime');
            tmpobj.String=sprintf('current event time is %.3f',time);
            % % % find the video splitted files which match the select event
            for i=1:length(videopanel.correcttime)
                latency(i)=time-videopanel.correcttime(i);
            end
            [~,index]=min(latency(find(latency>0)));
            tmpobj=findobj(gcf,'Tag','videolist');
            set(tmpobj,'Value',index);
            % % % % %
            timerelative=findobj('Tag','videorelativetime');
            set(timerelative,'String',num2str(time-videopanel.correcttime));
%                 set(timeband,'String',[num2str(time+range(1)-videopanel.correcttime),',',num2str(time+range(2)-videopanel.correcttime)]);            
        end
        function obj=RecordnewTime(obj)
            % record the correct time as a new event and write into eventpanel
            eventpanel=obj.eventpanel;
            videopanel=obj.videopanel;
            text=Taginfoappend(unique(eventpanel.typestring),2);
            if size(eventpanel.liststring,2)>1
            newlist=cat(2,eventpanel.liststring,num2str(length(eventpanel.liststring)+1));
            else
              newlist=cat(1,eventpanel.liststring,num2str(length(eventpanel.liststring)+1));
            end
            if size(eventpanel.typestring,2)>1    
                newtype=cat(2,eventpanel.typestring,{text});
            else
                newtype=cat(1,eventpanel.typestring,{text});
            end
            eventpanel.setdescription(newlist,newtype);
            set(eventpanel.listpanel{1},'Value',length(eventpanel.liststring));
            obj.CorrectTime();
        end
        function obj=CorrectTime(obj)
            % modify the selected event by video time
            global CorrectEvents
            eventpanel=obj.eventpanel;
            videopanel=obj.videopanel;
            eventindex=eventpanel.getIndex(['List_',eventpanel.tag{1}]);
            tmpobj=findobj(gcf,'Tag','videolist');
            videoindex=tmpobj.Value;
            CorrectEvents.time(eventindex)=videopanel.currenttime+videopanel.correcttime(videoindex);
            try
                tmpobj=findobj(gcf,'Tag','eventtime');
                tmpobj.String=sprintf('current event time is %.3f',CorrectEvents.time(eventindex));
            end
            CorrectEvents.description=eventpanel.typestring;
        end
        function obj=SaveCorrect(obj)
            global CorrectEvents
            try
                copyfile(obj.EVTdata.Filename,[obj.EVTdata.Filename(1:end-4),'.bak.evt']);
            end
            SaveEvents_neurodata(obj.EVTdata.Filename,CorrectEvents,1);
        end 
        function obj=Showcorrect(obj)
            global CorrectEvents
            figure();
            eventpanel=obj.eventpanel;
            eventindex=cellfun(@(x) str2num(x),eventpanel.liststring,'UniformOutput',1);
            dataorigin=LoadEvents_neurodata(obj.EVTdata.Filename);
            data(:,1)=num2cell(eventindex);
            try
            data(:,2)=num2cell(dataorigin.time(eventindex));
            catch % dataorigin less than new event
                data(1:length(dataorigin.time),2)=num2cell(dataorigin.time);
            end
            data(:,3)=num2cell(CorrectEvents.time(eventindex));
            try
            data(:,4)=dataorigin.description(eventindex);
            catch
                 data(1:length(dataorigin.description),4)=dataorigin.description;
            end
            data(:,5)=CorrectEvents.description(eventindex);
            panel=uix.Panel('Parent',gcf);
            uitable('Parent',panel,'Data',data,'ColumnNames',{'eventindex','origin Value','modify value','origin description','modify description'});  
        end
        function obj=Changedescription(obj)
            global CorrectEvents
            [text]=Taginfoappend(unique(obj.eventpanel.typestring),2);
            eventindex=obj.eventpanel.getIndex(['List_',obj.eventpanel.tag{1}]);
            description=obj.eventpanel.typestring;
            description(eventindex)=repmat({text},[sum(eventindex),1]);
            CorrectEvents.description=description;
            obj.eventpanel.setdescription(obj.eventpanel.liststring,description);
        end
        function obj=Shiftevents(obj)
            global CorrectEvents
            eventindex=obj.eventpanel.getIndex(['List_',obj.eventpanel.tag{1}]);
            shifttime=inputdlg('input the shift time (s)');
            [text]=Taginfoappend(unique(obj.eventpanel.typestring),2);
            CorrectEvents.time=cat(1,CorrectEvents.time,CorrectEvents.time(eventindex)+str2num(shifttime{:}));
            CorrectEvents.description=cat(1,CorrectEvents.description,repmat({text},[sum(eventindex),1]));
            Eventlist=1:length(CorrectEvents.description);
            Eventlist=arrayfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
            obj.eventpanel.setdescription(Eventlist,CorrectEvents.description);
        end  
  end
end

