function Spikeoutput=ReadSPK_Phy(obj,channel,channeldescription,read_start,read_until)
% the Phy data are usally used for the silicon probes. Thus the Spikeoutput
% provide more informations, these information may get from CellExplorer
% for further.
Spikeoutput.timerange=[read_start,read_until];
Spikeoutput.channelname=cell(1,length(read_start));
Spikeoutput.channeldescription=cell(1,length(read_start));
Spikeoutput.Fs=obj.Samplerate;
cd(obj.Filename);
spk_clu=readNPY('spike_clusters.npy');
spk_time=readNPY('spike_times.npy');
channel_shanks=readNPY('channel_shanks.npy');
channel_map=readNPY('channel_map.npy');
[cluster_info,header,raw]=tsvread('cluster_info.tsv');
group_index=strcmp(header,'group');
shank_index=strcmp(header,'sh');
channel_index=strcmp(header,'ch');
id=strcmp(header,'id');
clusternumber=unique(channel_shanks);
for i=1:length(clusternumber)
    if ismember(channel,channel_map(channel_shanks==clusternumber(i))+1)
        clustername=cluster_info((cluster_info(:,shank_index)==clusternumber)&strcmp(raw(:,group_index),'good'),id);
        for j=1:length(clustername)
            tmpspikename=['cluster',num2str(clusternum),'_',num2str(clustername(j))];
            clusterchannel=cluster_info(cluster_info(:,id)==clustername(j),channel_index);
            tmpspike.channel=clusterchannel;
            tmpspike.channeldescription=unique(channeldescription(ismember(channel,clusterchannel)));
            tmpspike.spiketime=[];
             for k=1:length(read_start)
                index=spk_clu==clustername(j)&spk_time>=read_start(k)&spk_time<=read_until(k);  
                tmpspike.spiketime{k}=spk_time(index);
             end
             tmpspike.timerange=[read_start,read_until];
             eval(['Spikeoutput.',tmpspikename,'=tmpspike;']);
       end
    end
end