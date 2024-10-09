function plotSpikeRaster_neurodata(ax,spikes,Fs,t,varargin)
% plot rasters with given time interval and Fs
 [xPoints,yPoints]=plotSpikeRaster(logical(spikes),'PlotType','vertline2','TimePerBin',1/Fs);
 plot(ax,xPoints*1/Fs+t(1),yPoints);
end