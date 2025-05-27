function shadebar(x,data,color,varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% ignore nans.
[m,n]=size(data);
invalid=isnan(data(1,:))|isinf(data(1,:));
data=data(:,~invalid);
for i=1:size(data,2)
    data(:,i)=smooth(data(:,i));
end
y=mean(data')';
if nargin==4
    error=std(data')';
else
    error=std(data')'/sqrt(n);
end
plot(x,y','color',color);
shadedErrorBar(x,y,error,color,0.2);
end

