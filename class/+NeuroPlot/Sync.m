classdef Sync
    % sychronize function across different panels
    properties
    end
    methods(Static)
        function SyncEvent_Time(eventpanel,timepanel)
            % synchronize event selectpanel to time bars or video time bars
            % timepanel may be a single timecontrol/videocontrol or an array of them,
            % so that a uicontrol Callback can sync every time bar from one function handle.
            assert(strcmp(class(eventpanel),'NeuroPlot.selectpanel'));
            value=eventpanel.getIndex;
            eventtime=str2num(eventpanel.liststring{value});
%             eventtime=eventtime*1000; % transfer to millseconds
            for i=1:numel(timepanel)
                tmp=timepanel(i);
                assert(strcmp(class(tmp),'NeuroPlot.timecontrol')||strcmp(class(tmp),'NeuroPlot.videocontrol'));
                timerelative=findobj(tmp,'Tag','relativetime');
               if strcmp(class(tmp),'NeuroPlot.timecontrol')
                    [~,index]=min(abs(tmp.timestamps-eventtime));
                    set(timerelative,'String',num2str(tmp.timestamps(index)));
                else
                    set(timerelative,'String',num2str(eventtime));
               end
                tmp.settimebar('timerelative');
            end
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
        end
end

