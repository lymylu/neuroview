classdef EventModified < uix.VBox
   % add eventmodified panel and related listeners base on EVTData.gui_plot()
   properties
        OriginEvents
        currentindex
        eventpanel
        currenttime
    end
    
    methods
        function obj=create(obj,parent,eventtablepanel)
            % create the eventmodified panel which linked to eventguiplot
            obj.Parent=parent;
            obj.eventpanel=findobj('Parent',eventtablepanel,'-regexp','Tag','eventpanel');
            for i=1:length(obj.eventpanel)
                if ~isempty(obj.eventpanel(i).typestring)
                obj.OriginEvents(i).description=obj.eventpanel(i).typestring;
                obj.OriginEvents(i).time=cellfun(@(x) str2num(x),obj.eventpanel(i).liststring,'UniformOutput',1);
                else
                    obj.OriginEvents(i).description=[];
                    obj.OriginEvents(i).time=[];
                end
            end
            obj.currentindex=1;
            try
             set(eventtablepanel,'SelectionChangedFcn',@(~,~) obj.ChangeCorrectIndex);
            end
             %uicontrol('Parent',eventmodifypanel,'Style','pushbutton','String','Create new event file','Callback',@(~,~) obj.CreateEventfile());
             uicontrol('Parent',obj,'Style','pushbutton','String','Add current time as a new event','Callback',@(~,~) obj.RecordcurrentTime());
             uicontrol('parent',obj,'Style','pushbutton','String','Correct selected event with current time','Callback',@(~,~) obj.CorrectTime());
             uicontrol('parent',obj,'Style','pushbutton','String','Delete select event','Callback',@(~,~) obj.DeleteTime());
             uicontrol('parent',obj,'Style','pushbutton','String','shift the select events','Callback',@(~,~) obj.Shiftevent());
             uicontrol('parent',obj,'Style','pushbutton','String','modify the event type','Callback',@(~,~) obj.Changedescription());
             %uicontrol('parent',obj,'Style','pushbutton','String','Show the corrected events','Callback',@(~,~) obj.Showcorrect());
             uicontrol('parent',obj,'Style','pushbutton','String','Save the corrected result','Callback',@(~,~) obj.SaveCorrect());
            
        end
        function getCurrenttime(obj,timepanel)
            obj.currenttime=timepanel.currenttime;
        end
        function RecordcurrentTime(obj)
            eventpanel=obj.eventpanel(obj.currentindex);
            text=Taginfoappend(unique(eventpanel.typestring),2);
            if size(eventpanel.liststring,2)~=1
            newlist=cat(2,eventpanel.liststring,{num2str(obj.currenttime)});
            else
              newlist=cat(1,eventpanel.liststring,{num2str(obj.currenttime)});
            end
            if size(eventpanel.typestring,2)~=1    
                newtype=cat(2,eventpanel.typestring,{text});
            else
                newtype=cat(1,eventpanel.typestring,{text});
            end
            obj.eventpanel(obj.currentindex).setdescription(newlist,newtype);
            set(obj.eventpanel(obj.currentindex).listpanel,'Value',length(eventpanel.liststring));
        end
        function CorrectTime(obj)
            index=obj.eventpanel(obj.currentindex).getIndex;
            obj.eventpanel(obj.currentindex).liststring{index}=num2str(obj.currenttime);
            obj.eventpanel(obj.currentindex).setdescription(obj.eventpanel(obj.currentindex).liststring,obj.eventpanel(obj.currentindex).typestring);
            %set(obj.eventpanel(obj.currentindex).listpanel,'Value',find(index==1));
        end
        function ChangeCorrectIndex(obj)
            tablepanel=findobj('Parent',eventguiplot,'Type','uix.TablePanel');
            obj.currentindex=tablepanel.SelectedChild;
        end
        function DeleteTime(obj)
            eventindex=obj.eventpanel(obj.currentindex).getIndex;
            %CorrectEvents(obj.currentindex).time(eventindex)=[];
            %CorrectEvents(obj.currentindex).description(eventindex)=[];
            obj.eventpanel(obj.currentindex).liststring(eventindex)=[];
            obj.eventpanel(obj.currentindex).typestring(eventindex)=[];
            obj.eventpanel(obj.currentindex).setdescription(obj.eventpanel(obj.currentindex).liststring,obj.eventpanel(obj.currentindex).typestring);
        end
        function obj=Descriptionadd(obj,Descriptiontext)
            global DataTaglist
            [text, ~, DataTaglist]=Taginfoappend(DataTaglist,2);
            Descriptiontext.String=['Current description:',text];
        end
        function SaveCorrect(obj)
            events.time=cellfun(@(x) str2num(x),obj.eventpanel(obj.currentindex).liststring,'UniformOutput',1);
            events.description=obj.eventpanel(obj.currentindex).typestring;
            eventfilename=strrep(obj.eventpanel(obj.currentindex).Tag,'_eventpanel','');
            try
                copyfile(eventfilename,[eventfilename(1:end-4),'_bak.evt']);
            end
            SaveEvents_neurodata(eventfilename,events,1);
        end 
        function Showcorrect(obj)
            figure();
            eventpanel=obj.eventpanel(obj.currentindex);
            eventfilename=strrep(obj.eventpanel(obj.currentindex).Tag,'_eventpanel','');
            %eventindex=cellfun(@(x) str2num(x),eventpanel.liststring,'UniformOutput',1);
            dataorigin=LoadEvents_neurodata(eventfilename);
            try
            data(:,1)=num2cell(dataorigin.time);
            catch % dataorigin less than new event
                data(1:length(dataorigin.time),1)=num2cell(dataorigin.time);
            end
            data(:,2)=eventpanel.liststring;
            try
            data(:,3)=dataorigin.description;
            catch
                 data(1:length(dataorigin.description),3)=dataorigin.description;
            end
            data(:,4)=eventpanel.typestring;
            panel=uix.Panel('Parent',gcf);
            uitable('Parent',panel,'Data',data,'ColumnNames',{'origin Value','modify value','origin description','modify description'});
        end
        function obj=Changedescription(obj)
            [text]=Taginfoappend(unique(obj.eventpanel(obj.currentindex).typestring),2);
            eventindex=obj.eventpanel(obj.currentindex).getIndex;
            description=obj.eventpanel(obj.currentindex).typestring;
            description(eventindex)=repmat({text},[sum(eventindex),1]);
            obj.eventpanel(obj.currentindex).setdescription(obj.eventpanel(obj.currentindex).liststring,description);
        end
        function obj=Shiftevent(obj)
            % shift the select events to fix time
            shifttime=inputdlg('input the shift time (s)');
            [text]=Taginfoappend(unique(obj.eventpanel.typestring),2);
            eventtime=cellfun(@(x) str2num(x),obj.eventpanel.listpanel.String,'UniformOutput',1);
            eventtime=eventtime+str2num(shifttime{:});
            neweventtime=cat(1,obj.eventpanel.liststring,cellfun(@(x) num2str(x),num2cell(eventtime),'UniformOutput',0));
            eventdescription=cat(1,obj.eventpanel.typestring,repmat({text},[length(eventtime),1]));
            obj.eventpanel(obj.currentindex).setdescription(neweventtime,eventdescription);
        end  
  end
end

