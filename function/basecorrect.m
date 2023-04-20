function data=basecorrect(data,time,timebegin,timeend,option)
if ~isempty(data)
index=find(time<=timeend&time>=timebegin);
switch lower(option)
    case 'subtract'
        data=data-repmat(mean(data(index,:,:,:,:),1),[length(time),1,1,1,1]);
    case 'zscore'
        [~,mu,sigma]=zscore(data(index,:,:,:,:));
%         if mu==0 && sigma==0 % % no spike in the given interval;
%         data=data;
%         else
        data=(data-repmat(mu,[length(time),1,1]))./repmat(sigma,[length(time),1,1,1,1]);
%         end
    case 'changepercent'
        data=(data-repmat(mean(data(index,:,:,:,:),1),[length(time),1,1,1,1]))./repmat(mean(data(index,:,:,:,:),1),[length(time),1,1,1,1]);      
    case 'fisherz'
         data=atanh(data);
    case 'normalized'
        data=(data-repmat(min(data(index,:,:,:,:),[],1),[length(time),1,1,1,1]))./(repmat(max(data(index,:,:,:,:),[],1),[length(time),1,1,1,1])-repmat(min(data(index,:,:,:,:),[],1),[length(time),1,1,1,1,1]));
    case 'normalized2'
        data=2*(data-repmat(min(data(index,:,:,:,:),[],1),[length(time),1,1,1,1]))./(repmat(max(data(index,:,:,:,:),[],1),[length(time),1,1,1,1])-repmat(min(data(index,:,:,:,:),[],1),[length(time),1,1,1,1,1]))-1;
        case 'normalized3'
        data=data./(repmat(max(data(index,:,:,:,:),[],1),[length(time),1,1,1,1])-repmat(min(data(index,:,:,:,:),[],1),[length(time),1,1,1,1,1]));
end
%     if sum(isnan(data))~=0||sum(isinf(data))~=0
%         disp('nan warning! basecorrect failure');
%         data=data;
%     end
else
    data=[];
end
end