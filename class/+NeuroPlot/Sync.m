classdef Sync
    % sychronize function across different panels
    properties
    end
    methods(Static)
        function SyncEvent_Time(eventpanel,timepanel)
            % synchronize event selectpanel to time bars or video time bars
            assert(strcmp(class(eventpanel),'NeuroPlot.selectpanel'));
            assert(strcmp(class(timepanel),'NeuroPlot.timecontrol')||strcmp(class(timepanel),'NeuroPlot.videocontrol'));
            value=eventpanel.getIndex;
            eventtime=str2num(eventpanel.liststring{value});
%             eventtime=eventtime*1000; % transfer to millseconds
            timerelative=findobj(timepanel,'Tag','relativetime');
           if strcmp(class(timepanel),'NeuroPlot.timecontrol')
                [~,index]=min(abs(timepanel.timestamps-eventtime));
                set(timerelative,'String',num2str(timepanel.timestamps(index)));
            else
                set(timerelative,'String',num2str(eventtime));
           end
            timepanel.settimebar('timerelative');
        end
        function SyncSelect(selectpanel1,selectpanel2)
            % synchronize different selectpanel (e.g., LFP channels, Event trials or SPK clusters)
            assert(strcmp(class(selectpanel1),'NeuroPlot.selectpanel'));
            assert(strcmp(class(selectpanel2),'NeuroPlot.selectpanel'));
            assert(isequal(selectpanel1.liststring,selectpanel2.liststring));
            assert(isequal(selectpanel1.typestring,selectpanel2.typestring));
            if ~isempty(selectpanel1.typestring)
                selectpanel2.typepanel.Value=selectpanel1.typepanel.Value;
            end
            selectpanel2.listpanel.Value=selectpanel1.listpanel.Value;
        end
        function SyncTime(timepanel1,timepanel2)
            % synchronize different time bars of LFPdata(s) and SPKdata(s)
            assert(strcmp(class(timepanel1),'NeuroPlot.timecontrol')||strcmp(class(timepanel1),'NeuroPlot.videocontrol'));
            assert(strcmp(class(timepanel2),'NeuroPlot.timecontrol')||strcmp(class(timepanel2),'NeuroPlot.videocontrol'));
            timerelative2=findobj(timepanel2,'Tag','relativetime');
            timerelative1=findobj(timepanel1,'Tag','relativetime');
            set(timerelative1,'String',num2str(timepanel1.currenttime));
            if strcmp(class(timepanel2),'NeuroPlot.timecontrol')
                [~,index]=min(abs(timepanel2.timestamps-timepanel1.currenttime));
                set(timerelative2,'String',num2str(timepanel2.timestamps(index)));
            else
                set(timerelative2,'String',num2str(timepanel1.currenttime));
            end
            timepanel2.settimebar('timerelative');
        end 
        function SyncEvent_Video(eventpanel,videopanel)
        end
        function SyncTime_Video(timepanel,videopanel)
        end
        function SyncVideo_Time(videopanel,timepanel)
        end
    end
end

