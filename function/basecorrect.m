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
% add tall compatible
if ~isempty(data)
isTall=isa(data,'tall');

%index=find(time<=timeend&time>=timebegin);
dimnum=ndims(data);
    if isTall
        dimnum=gather(dimnum);
    end
        baseidx = (time <= timeend) & (time >= timebegin);

    idx_cell = cell(1, dimnum);
    idx_cell{1} = baseidx;
    for i = 2:dimnum
        idx_cell{i} = ':';
    end
    S.type='()';
    S.subs=idx_cell;
    basedata=subsref(data,S);
%basedata=eval(['data(index',repmat(',:',[1,dimnum-1]),');']);
%repmatrix=strcat('[length(time)',repmat(',1',[1,dimnum-1]),']');
switch lower(option)
    case 'subtract'
       % data=data-repmat(mean(basedata,1),eval(repmatrix));
       data=data-mean(basedata,1);
    case 'zscore'
        [~,mu,sigma]=zscore(basedata);

        %data=(data-repmat(mu,eval(repmatrix)))./repmat(sigma,eval(repmatrix));
        data=(data-mu)./sigma;
    case 'changepercent'

       % data=(data-repmat(mean(basedata,1),eval(repmatrix)))./repmat(mean(basedata,1),eval(repmatrix));      
        data=(data-mean(basedata,1))./mean(basedata,1);
    case 'fisherz'
         data=atanh(data);
    case 'normalized'
         min_val = min(basedata, [], 1);
         max_val = max(basedata, [], 1);
         data = (data - min_val) ./ (max_val - min_val); 
        %data=(data-repmat(min(basedata,[],1),eval(repmatrix)))./(repmat(max(basedata,[],1),eval(repmatrix))-repmat(min(basedata,[],1),eval(repmatrix)));
    case 'normalized2'
         min_val = min(basedata, [], 1);
            max_val = max(basedata, [], 1);
            data = 2 * (data - min_val) ./ (max_val - min_val) - 1; 
        %data=2*(data-repmat(min(basedata,[],1),eval(repmatrix)))./(repmat(max(basedata,[],1),eval(repmatrix))-repmat(min(basedata,[],1),eval(repmatrix)))-1;
    case 'normalized3'
         min_val = min(basedata, [], 1);
            max_val = max(basedata, [], 1);
            data = data ./ (max_val - min_val);
        %data=data./(repmat(max(basedata,[],1),eval(repmatrix))-repmat(min(basedata,[],1),eval(repmatrix)));
    case 'relativepower'
          sum_val = sum(basedata, 1);
          data = data ./ sum_val; 
        %data=data./repmat(sum(basedata,1),eval(repmatrix));
end
%     if sum(isnan(data))~=0||sum(isinf(data))~=0
%         disp('nan warning! basecorrect failure');
%         data=data;
%     end
else
    data=[];
end
end