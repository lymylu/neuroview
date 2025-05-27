function plotSpikeRaster_neurodata(ax,spikes,timerange,spikecolor)
% plot rasters with given time interval and Fs
% spikes is the cell N*1,each contains one neurons time points)
for i=1:length(spikes)
    spiketimes = spikes{i};
    if ~isempty(spiketimes)
        ytop=length(spikes)-(i-1)+0.4;
        ybottom=length(spikes)-(i-1)-0.4;
        xPoints=[spiketimes';spiketimes';nan(size(spiketimes))'];
        yPoints=repmat([ybottom;ytop;nan],1,numel(spiketimes));
        hold on;
        if ~isempty(spikecolor)
            plot(ax,xPoints(:),yPoints(:),'LineWidth',0.5,'Color',spikecolor(i,:));
        else
            plot(ax,xPoints(:),yPoints(:),'LineWidth',0.5);
        end
    end 
end
set(ax,'XLim',timerange);
end