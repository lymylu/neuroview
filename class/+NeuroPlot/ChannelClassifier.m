classdef ChannelClassifier < uix.VBoxFlex
    % open a interactive figure to show the mapping of channel and select
    % the channels by polygon or points
    % could add new tag of channels
    properties
        ChannelPosition
        ChannelTag
        hAxes % for plotting channel position
        linkedselectpanel
        SelectedChannels
        hChannelMarkers
    end
    events
        highlightSelectChannel
    end
    methods
         function channels = getChannelIndex(obj)
            % 通过多边形或点选择通道索引
            % selectionType: 'polygon' 或 'point'
            selectmode=findobj(obj,'Tag','selectmode');
            selectionType=selectmode.String{selectmode.Value};
            switch selectionType
                case 'polygon'
                    title(obj.hAxes, '绘制多边形选择通道，双击结束', ...
                        'FontSize', 10, 'Color', 'blue');
                    hPoly = drawpolygon(obj.hAxes);
                    vertices = hPoly.Position;
                    delete(hPoly);
                    
                    % 判断哪些通道在多边形内
                    channels = inpolygon(...
                        obj.ChannelPosition(:, 2), ...
                        obj.ChannelPosition(:, 3), ...
                        vertices(:, 1), vertices(:, 2));
                    channels = find(channels);
                    
                case 'point'
                    title(obj.hAxes, '点击选择通道，按Enter结束', ...
                        'FontSize', 10, 'Color', 'blue');
                    [x, y] = getpts(obj.hAxes);
                    
                    % 找到最近的通道
                    channels = [];
                    for i = 1:length(x)
                        distances = sqrt(...
                            (obj.ChannelPosition(:, 2) - x(i)).^2 + ...
                            (obj.ChannelPosition(:, 3) - y(i)).^2);
                        [~, idx] = min(distances);
                        channels = [channels; idx];
                    end
            end         
            obj.SelectedChannels = channels;
            obj.highlightSelectedChannels();
            obj.SyncSelectedtoLinkedpanel();
         end
         function highlightSelectedChannels(obj)
            % 高亮显示选中的通道
            if ~isempty(obj.hChannelMarkers)
                delete(obj.hChannelMarkers);
            end
            
            if isempty(obj.SelectedChannels)
                return;
            end
            
            hold(obj.hAxes, 'on');
            obj.hChannelMarkers = plot(obj.hAxes, ...
                obj.ChannelPosition(obj.SelectedChannels, 2), ...
                obj.ChannelPosition(obj.SelectedChannels, 3), ...
                'ro', 'MarkerSize', 10, 'LineWidth', 2);
            hold(obj.hAxes, 'off');
         end
         function SyncSelectedtoLinkedpanel(obj)
             channelpanel=obj.linkedselectpanel;% NeuroPlot.selectpanel
             channelstring=channelpanel.listpanel.String;
             selectedChannel=cellfun(@(x) num2str(x),num2cell(obj.ChannelPosition(obj.SelectedChannels,1)),'UniformOutput',0);
             selectindex=ismember(channelstring,selectedChannel);
             set(channelpanel.listpanel,'Value',find(selectindex==1));
         end
         function getLinkedChannelPanel(obj)
             global NV
             channelpanel=findobj(NV.PlotPanel,'Tag','ChannelIndex');
             if length(channelpanel)==1
                 obj.linkedselectpanel=channelpanel;
             end
         end
         function plotChannelPosition(obj)
            if isstruct(obj.ChannelPosition)
                [h grid_or_val plotrad_or_grid, xmesh, ymesh]=topoplot([],obj.ChannelPosition);
            elseif isnumeric(obj.ChannelPosition)
                gscatter(obj.hAxes,obj.ChannelPosition(:,2),obj.ChannelPosition(:,3));
                text(obj.ChannelPosition(:,2),obj.ChannelPosition(:,3),num2str(obj.ChannelPosition(:,1)));
            end
         end
    end
    methods(Static)
        function obj=create(parent,varargin)
            if isempty(parent)
                parent=figure;
            end
            p=inputParser;
            addParameter(p,'ChannelPosition',[],@(x)isstruct(x)||isnumeric(x));
            addParameter(p,'LinkedChannelPanel',[],@(x) isa(x,'NeuroPlot.selectpanel'));
            parse(p);
            if isempty(p.Results.ChannelPosition)
                global currentresult
                if isfield(currentresult.ChannelTag,'ChannelPosition')
                ChannelPosition=currentresult.ChannelTag.ChannelPosition;
                else
                    error('No channel position was detected!');
                end
            end
            obj=NeuroPlot.ChannelClassifier('Parent',parent);
            obj.ChannelPosition=ChannelPosition;
            toolbar=uix.HBox('Parent',obj);
            uicontrol(toolbar,'Style','text','String','select mode');
            selectmode=uicontrol(toolbar,'Style','popupmenu','String',{'polygon','point'},'Tag','selectmode');
            obj.getLinkedChannelPanel();
            obj.hAxes=axes(obj);
            obj.plotChannelPosition();
            set(selectmode,'Callback',@(~,~) obj.getChannelIndex());
        end
    end
end