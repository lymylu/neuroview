function data=basecorrect(data,time,timebegin,timeend,option,varargin)
% the basecorrect to the first dimension (time) of data
% the dimension of data is variable
% varargin is the dimension where time is (not the first)
if nargin==6
    timedim=varargin{1};
else
    timedim=1;
end
dimnum=ndims(data);
    if timedim>1
        data=permute(data,[timedim,1:timedim-1,timedim+1:dimnum]);
        data=basecorrect_cal(data,time,timebegin,timeend,option);
        data=permute(data,[2:timedim,1,timedim+1:dimnum]);
    else
        data=basecorrect_cal(data,time,timebegin,timeend,option);
    end
end
function data=basecorrect_cal(data,time,timebegin,timeend,option)
if ~isempty(data)
index=find(time<=timeend&time>=timebegin);
dimnum=ndims(data);
basedata=eval(['data(index',repmat(',:',[1,dimnum-1]),');']);
repmatrix=strcat('[length(time)',repmat(',1',[1,dimnum-1]),']');
switch lower(option)
    case 'subtract'
        data=data-repmat(mean(basedata,1),eval(repmatrix));
    case 'zscore'
        [~,mu,sigma]=zscore(basedata);
%         if mu==0 && sigma==0 % % no spike in the given interval;
%         data=data;
%         else
        data=(data-repmat(mu,eval(repmatrix)))./repmat(sigma,eval(repmatrix));
%         end
    case 'changepercent'
        data=(data-repmat(mean(basedata,1),eval(repmatrix)))./repmat(mean(basedata,1),eval(repmatrix));      
    case 'fisherz'
         data=atanh(data);
    case 'normalized'
        data=(data-repmat(min(basedata,[],1),eval(repmatrix)))./(repmat(max(basedata,[],1),eval(repmatrix))-repmat(min(basedata,[],1),eval(repmatrix)));
    case 'normalized2'
        data=2*(data-repmat(min(basedata,[],1),eval(repmatrix)))./(repmat(max(basedata,[],1),eval(repmatrix))-repmat(min(basedata,[],1),eval(repmatrix)))-1;
    case 'normalized3'
        data=data./(repmat(max(basedata,[],1),eval(repmatrix))-repmat(min(basedata,[],1),eval(repmatrix)));
    case 'relativepower'
        data=data./repmat(sum(basedata,1),eval(repmatrix));
end
%     if sum(isnan(data))~=0||sum(isinf(data))~=0
%         disp('nan warning! basecorrect failure');
%         data=data;
%     end
else
    data=[];
end
end