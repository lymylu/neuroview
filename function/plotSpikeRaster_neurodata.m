function plotSpikeRaster_neurodata(ax,timerange,spikes,spikecolor)
% plot rasters with given time interval and Fs
% spikes is the cell N*M,contains N neurons with M trials 
% if M>1 yaxes show the trials, else yaxes show the neurons
if size(spikes,2)>1
    spikes=spikes';
end
for i=1:size(spikes,1)
    for j=1:size(spikes,2)
    spiketimes = spikes{i,j};
    if ~isempty(spiketimes)
        % ytop=length(spikes)-(i-1)+0.4;
        % ybottom=length(spikes)-(i-1)-0.4;
         ytop=i+0.4;
        ybottom=i-0.4;
        xPoints=[spiketimes';spiketimes';nan(size(spiketimes))'];
        yPoints=repmat([ybottom;ytop;nan],1,numel(spiketimes));
        hold on;
        if ~isempty(spikecolor)&&isnumeric(spikecolor)
            plot(ax,xPoints(:),yPoints(:),'LineWidth',0.5,'Color',spikecolor(i,:));
        elseif ischar(spikecolor)
            plot(ax,xPoints(:),yPoints(:),'LineWidth',0.5,'Color',spikecolor);
        else
            plot(ax,xPoints(:),yPoints(:),'LineWidth',0.5);
        end
    end
    end
end
set(ax,'XLim',timerange);
end