function plot_across_y(t,data,scale)
% plot each raw of the data in one figure with the scale * max abs value
% among the column
lagging=max(abs(data));
lagging=cumsum(repmat(max(lagging),[1,size(data,2)]));
lagging=scale*lagging;
plot(t,bsxfun(@minus,data,lagging));
end