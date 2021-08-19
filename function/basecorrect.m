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
end
else
    data=[];
end
end