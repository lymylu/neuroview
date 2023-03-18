function Spikeoutput=ReadSPK_KlustaKwik(obj,channel,channeldescription,read_start,read_until)
Spikeoutput.timerange=[read_start,read_until];
% Spikeoutput.channelname=cell(1,length(read_start));
% Spikeoutput.channeldescription=cell(1,length(read_start));
Spikeoutput.Fs=obj.Samplerate;
cd(obj.Filename);
clusterfile=dir('*.clu.*');
clusterfile=struct2table(clusterfile);
clusterfile=clusterfile.name;
if ischar(clusterfile)
    clusterfile1{1}=clusterfile;
    clusterfile=clusterfile1;
end
for i=1:length(clusterfile)
    clusterchannel=SPKchannel(clusterfile{i});
    if logical(sum(ismember(channel,clusterchannel)))
        spk_clu=importdata(clusterfile{i});
        spk_clu=spk_clu(2:end);
        spk_time=importdata([strrep(clusterfile{i},'.clu.','.res.')]);
        spk_time=spk_time/str2num(obj.Samplerate);
        clustername=unique(spk_clu);
        clustername(clustername==0|clustername==1)=[];
        clusternum=regexpi(clusterfile{i},'.clu.','split');
        clusternum=clusternum{end};
       for j=1:length(clustername)
            tmpspikename=['cluster',num2str(clusternum),'_',num2str(clustername(j))];
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
end
function clusterchannel=SPKchannel(clusterfile)
        clusterchannel=[];
        try
        clunumber=regexpi(clusterfile,'.clu.','split');
        xmlfilename=[clunumber{1},'.xml'];
        xml=xml_read(xmlfilename);  
        clusterchannel=xml.spikeDetection.channelGroups.group(str2num(clunumber{2})).channels.channel;
        clusterchannel=cellfun(@(x) x+1,clusterchannel,'UniformOutput',1);
        catch
            clusterchannel=clusterchannel+1;
        end
end
 