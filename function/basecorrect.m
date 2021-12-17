function data=basecorrect(data,time,timebegin,timeend,option)
if ~isempty(data)
index=find(time<=timeend&time>=timebegin);
switch lower(option)
    case 'subtract'
        data=data-repmat(mean(data(index,:,:,:,:),1),[length(time),1,1,1,1]);
    case 'zscore'
        [~,mu,sigma]=zscore(data(index,:,:,:,:));
        data=(data-repmat(mu,[length(time),1,1]))./repmat(sigma,[length(time),1,1,1,1]);
    case 'changepercent'
        data=(data-repmat(mean(data(index,:,:,:,:),1),[length(time),1,1,1,1]))./repmat(mean(data(index,:,:,:,:),1),[length(time),1,1,1,1]);      
    case 'fisherz'
         data=atanh(data);
    case 'normalized'
        data=(data-repmat(min(data(index,:,:,:,:),[],1),[length(time),1,1,1,1]))./(repmat(max(data(index,:,:,:,:),[],1),[length(time),1,1,1,1])-repmat(min(data(index,:,:,:,:),[],1),[length(time),1,1,1,1,1]));
end
    if sum(isnan(data))~=0
        disp('nan warning! basecorrect failure');
        data=data;
    end
else
    data=[];
end
end