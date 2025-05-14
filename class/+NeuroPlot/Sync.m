classdef Sync
    % sychronize function across different panels
    properties
    end
    methods(Static)
        function SyncEvent_Time(eventpanel,timepanel)
            assert(strcmp(class(eventpanel),'NeuroPlot.selectpanel'));
            assert(strcmp(class(timepanel),'NeuroPlot.timecontrol'));
            value=eventpanel.listpanel.Value;
            eventtime=str2num(eventpanel.liststring{value});
%             eventtime=eventtime*1000; % transfer to millseconds
            timerelative=findobj('Parent',timepanel,'Tag','relativetime');
            timecurrent=findobj('Parent',timepanel,'Tag','currenttime');
            [~,index]=min(abs(timepanel.timestamps-eventtime));
            set(timerelative,'String',num2str(timepanel.timestamps(index)));
            timepanel.settimebar('timerelative');
        end
        function SyncSelect(selectpanel1,selectpanel2)
            assert(class(selectpanel1),'NeuroPlot.selectpanel');
            assert(class(selectpanel2),'NeuroPlot.selectpanel');
            assert(isequal(selectpanel1.liststring,selectpanel2.liststring));
            assert(isequal(selectpanel1.typestring,selectpanel2.typestring));
            if ~isempty(selectpanel1.typestring)
                selectpanel2.typepanel.Value=selectpanel1.typepanel.Value;
            end
            selectpanel2.listpanel.Value=selectpanel1.listpanel.Value;
        end
        function SyncTime(timepanel1,timepanel2)
            assert(class(timepanel1),'NeuroPlot.timecontrol');
            assert(class(timepanel2),'NeuroPlot.timecontrol');
            timestamp2=timepanel2.timestamps;
            [~,index]=min(abs(timestamp2-timepanel1.totaltimebar.Value));
            timepanel2.totaltimebar.Value=timepanel2.timestamps(index);
        end
        
    end
end

