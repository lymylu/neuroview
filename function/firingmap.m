function [firing_rate_map, occupancy, spike_count_map, x_edges, y_edges] = firingmap(spike_times, position_times, positions, bin_size, varargin)
%[firing_rate_map, occupancy, x_edges, y_edges] = firingmap(spike_times, position_times, positions, bin_size)
% generate spatial firing map from raw spike times and continunous position sample
% modified from DEEPSEEK
p=inputParser;
addParameter(p,'x_edges',[]);
addParameter(p,'y_edges',[]);
addParameter(p,'timetolerance',0); % exclude the occupancy below 0.3s
parse(p,varargin{:});
% 基于连续轨迹计算空间平均放电率
    % 创建位置分箱
    x_min = min(positions(:,1));
    x_max = max(positions(:,1));
    y_min = min(positions(:,2));
    y_max = max(positions(:,2));  
    if bin_size<(x_max-x_min)
    x_edges = x_min:bin_size:x_max;
    else
        x_edges=x_min:1:x_max;
    end
    if bin_size<(y_max-y_min)
        y_edges = y_min:bin_size:y_max;
    else
        y_edges=y_min:1:y_max;
    end
    if ~isempty(p.Results.x_edges)
        x_edges=p.Results.x_edges;
    end
    if ~isempty(p.Results.y_edges)
        y_edges=p.Results.y_edges;
    end
    % 初始化地图
    occupancy = zeros(length(x_edges), length(y_edges));
    spike_count_map = zeros(size(occupancy));

    % 插值得到连续轨迹
    if length(position_times) > 1
        %fprintf('处理轨迹段: ');
        
        for i = 1:length(position_times)-1
            if mod(i, 1000) == 0
                %fprintf('%d/%d ', i, length(position_times)-1);
            end
            
            t_start = position_times(i);
            t_end = position_times(i+1);
            duration = t_end - t_start;
            
            % 线性插值计算轨迹
            x_start = positions(i,1);
            x_end = positions(i+1,1);
            y_start = positions(i,2);
            y_end = positions(i+1,2);
            
            % 找到在此期间发生的放电
            spike_mask = (spike_times >= t_start) & (spike_times < t_end);
            current_spikes = spike_times(spike_mask);
            
            % 处理每个放电事件
            for j = 1:length(current_spikes)
                spike_time = current_spikes(j);
                % 计算放电时的位置
                alpha = (spike_time - t_start) / duration;
                x_spike = x_start + alpha * (x_end - x_start);
                y_spike = y_start + alpha * (y_end - y_start);
                
                % 添加到放电计数地图
                spike_count_map=add_to_map(spike_count_map, x_spike, y_spike, x_edges, y_edges, 1);
            end
            
            % 计算轨迹段的停留时间贡献
            % 使用中点位置代表整个段
            x_mid = (x_start + x_end) / 2;
            y_mid = (y_start + y_end) / 2;
            occupancy=add_to_map(occupancy, x_mid, y_mid, x_edges, y_edges, duration);
        end
       % fprintf('\n');
    end
    
    % 计算放电率地图
    valid_bins = occupancy > p.Results.timetolerance;
    occupancy(~valid_bins)=0;
    firing_rate_map = spike_count_map ./ occupancy;
    firing_rate_map(isinf(firing_rate_map)|isnan(firing_rate_map))=nan;
    firing_rate_map=reshape(firing_rate_map,size(occupancy));
    % 平滑处理
    firing_rate_map = smooth_firing_rate(firing_rate_map, occupancy);
end

function map=add_to_map(map, x, y, x_edges, y_edges, value)
% 向地图中添加值
    x_idx = find(x_edges <= x, 1, 'last');
    y_idx = find(y_edges <= y, 1, 'last');
    
    if ~isempty(x_idx) && ~isempty(y_idx) && x_idx <= length(x_edges) && y_idx <=length(y_edges)
        map(x_idx, y_idx) = map(x_idx, y_idx) + value;
    end
end

function smoothed_map = smooth_firing_rate(firing_rate_map, occupancy)
% 对放电率地图进行平滑处理，只平滑有数据的区域
    kernel = fspecial('gaussian', [3 3], 0.7);
    
    % 只对有停留的区域进行平滑
    valid_mask = occupancy > 0;
    temp_map = firing_rate_map;
    temp_map(~valid_mask) = NaN;
    
    % 使用nanconv进行平滑，避免无数据区域的影响
    smoothed_map = nanconv(temp_map, kernel, 'same');
    %smoothed_map=conv2(temp_map,kernel,'same');
    % 恢复无数据区域为nan
    smoothed_map(~valid_mask) = nan ;
end

