function obj=cohgramc(neuroresult,params,obj)
% neuroview modification of cohgramc in chronux
% output: TimeVaringConnectivity obj
% input: NeuroResult obj, params (get from ChronuxFcn.getparams)
% See also cohgramc, TimeVaringConnectivity, ChronuxFcn.getparams
% function [C,phi,S12,S1,S2,t,f,confC,phistd,Cerr]=cohgramc(data1,data2,movingwin,params)
params.Fs=neuroresult.LFPinfo.Fs;
obj.Conn=cell(size(neuroresult.LFPdata));
obj.t_lfp=cell(size(neuroresult.LFPdata));
for j=1:length(neuroresult.LFPdata) % event
    for i=1:size(neuroresult.LFPdata{j},2) % from channel
        for k=1:size(neuroresult.LFPdata{j},2) % to channel
            [C,~,~,~,~,t,f]=cohgramc(neuroresult.LFPdata{j}(:,i),neuroresult.LFPdata{j}(:,k),params.movingwin,params);
            obj.Conn{j}(i,k,:,:,:)=C;
            obj.t_lfp{j}=t;
            obj.f_lfp=f;
        end
    end
end
