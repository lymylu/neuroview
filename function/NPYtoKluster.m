function NPYtoKluster
% transfer the NPY results to the Kluster .clu. files and .res.file used in
% NeuroData (no .fet. and .spk. files, therefore could not be open in Klusters)
% generate one clu files for each shank.
% only transfer the good template in spike_clusters.npy
spike_clusters=readNPY('spike_clusters.npy');
spike_template=readNPY('spike_templates.npy');
spike_times=readNPY('spike_times.npy');
channel_shanks=readNPY('channel_shanks.npy');
channel_positions=readNPY('channel_positions.npy');
channel_map=readNPY('channel_map.npy');
[cluster_info,header,raw]=tsvread('cluster_info.tsv');
group_index=strcmp(header,'group');
shank_index=strcmp(header,'sh');
id=strcmp(header,'id');
shanknumber=unique(channel_shanks);
for i=1:length(shanknumber)
    cluster_index=cluster_info((cluster_info(:,shank_index)==shanknumber)&strcmp(raw(:,group_index),'good'),id);
    clu_index=false(length(spike_clusters),1);
    for j=1:length(cluster_index)
        clu_index=clu_index|(spike_clusters==cluster_index(j));
    end
    spk_clu=spike_clusters(clu_index);
    spk_times=spike_times(clu_index);
    spike_clu=[length(cluster_index,spike_clu)];
    dlmwrite(['NPYtocluster.clu.',num2str(shanknumber)],spk_clu);
    dlmwrite(['NPYtocluster.res.',num2str(shanknumber)],spk_times);
end
end