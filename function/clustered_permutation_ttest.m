%以下为我编写的用于计算clustered_permutation correction的函数，基本思想在PPT中有说明，不必要纠结是如何实现的。
function [T_clustered, T_origin]=clustered_permutation_ttest(data,N_permutation)
% data为条件(2个)*被试个数*时间*频率的四维或者三维数组。时间和频率两者有一即可。在该代码中，会对时间或者频率进行点对点配对T检验。得到一个时频的统计图
% 根据clustered-based permutation的计算方法，找出时频点中，最具有显著差异的集群。
[~,N_subject,N_time,N_frequency]=size(data);
for i=1:N_time
    for j=1:N_frequency
[~,p_true(i,j),~,stat]=ttest(squeeze(data(1,:,i,j)),squeeze(data(2,:,i,j)));
T_origin(i,j)=stat.tstat;
    end
end
    %计算真实情况下的统计量
T_origin=T_origin.*(p_true<0.05); %找出T统计量中有差异的区域
rng('default');
for k=1:N_permutation
    rng(k);
    for j=1:N_subject
        permutationindex=randperm(2);
        data_permute(:,j,:,:)=squeeze(data([permutationindex(1),permutationindex(2)],j,:,:));
    end
    for i=1:N_time
    for j=1:N_frequency
[~,p_permute(i,j),~,stat]=ttest(squeeze(data_permute(1,:,i,j)),squeeze(data_permute(2,:,i,j)));
T_permute(i,j)=stat.tstat;
    end
    end
    T_permute=T_permute.*(p_permute<0.05);
    T_sum=clustered(T_permute); 
    T_clustered(k)=mean(abs(T_sum)); 
end
T_critcal=prctile(T_clustered,95);
[T_sum_true,clusterednum]=clustered(T_origin);
clusterednum=reshape(clusterednum,[],1);
clustered_crit=find(T_sum_true>T_critcal);
T_critindex=zeros(N_time,N_frequency);
for i=1:length(clustered_crit);
    T_critindex(clusterednum==clustered_crit(i))=1;
end
T_clustered=T_origin.*T_critindex;
end
%% 本示例中用到的子函数
function [T_sum,clusterednum]=clustered(T)
   clusterednum=bwlabel(T,4);
   [a,b]=size(clusterednum);
   clusterednum=reshape(clusterednum,[],1);
   T_sum=0;
   for i=1:max(clusterednum);
       if i>0;
           T_sum(i)=sum(sum(abs(T(find(clusterednum==i)))));
       end
   end
   clusterednum=reshape(clusterednum,a,b);
end
