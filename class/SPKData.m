classdef SPKData < BasicTag
     properties
        Filename=[];
        Samplerate=[];
        SPKcache=[];
        SPKchannel=[];
        SPKclass=[];
        fileTag=[];
    end
    methods (Access='public')
        function obj =  fileappend(obj, filename)
            obj.Filename=filename;
        end
        function obj = initialize(obj, Samplerate)
            obj.SPKchannel=SPKChannel(obj);
            obj.Samplerate=Samplerate;
        end
        function obj = Taginfo(obj, Tagname,informationtype, information)
            obj = Taginfo@BasicTag(obj,Tagname,informationtype,information);
        end
        function bool = Tagchoose(obj,Tagname, informationtype, information)
             bool = Tagchoose@BasicTag(obj,Tagname,informationtype,information);
         end          
       function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
             [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                  [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
       end    
        function Spikeoutput= ReadSPK(obj, channel,channeldescription,read_start, read_until,option)
            % read the Spike time or waveform in the given channel and event duration.
            switch option
                case 'time'
                    Spikeoutput=ReadSPKtime(obj,channel,channeldescription,read_start,read_until);
                case 'wave'
                    Spikeoutput=ReadSPKwave(obj,channel,channeldescription,read_start,read_until);
                case 'single'
                    Spikeoutput=ReadSPKsingle(obj,channel,channeldescription,read_start,read_until);
            end
        end
        function Spikeoutput=ReadSPKtime(obj,channel,channeldescription,read_start,read_until)
            Spikeoutput.timerange=[read_start,read_until];
            Spikeoutput.spiketime=cell(1,length(read_start));
            Spikeoutput.spikename=cell(1,length(read_start));
            Spikeoutput.channelname=cell(1,length(read_start));
            Spikeoutput.channeldescription=cell(1,length(read_start)); 
            for i=1:length(obj)
                if logical(sum(ismember(channel,obj(i).SPKchannel)))
                    obj(i)=obj(i).SPKloadcache('cluster');
                    obj(i)=obj(i).SPKloadcache('time');
                    Spikeoutput.Fs=obj(i).Samplerate;
                    clusternum=regexpi(obj(i).Filename,'.clu.','split');
                    clusternum=clusternum{end};
                    for j=1:length(read_start)
                        index=find(obj(i).SPKcache.cluster~=0&obj(i).SPKcache.cluster~=1&obj(i).SPKcache.time>=read_start(j)&obj(i).SPKcache.time<=read_until(j));  
                        Spikeoutput.spiketime{j}=cat(1,Spikeoutput.spiketime{j},obj(i).SPKcache.time(index));
                        Spikename=arrayfun(@(x) ['cluster',clusternum,'_',num2str(x)],obj(i).SPKcache.cluster(index),'UniformOutput',0);
                        Spikeoutput.channelname{j}=cat(1,Spikeoutput.channelname{j},repmat({obj(i).SPKchannel},[length(index),1]));
                        Spikeoutput.spikename{j}=cat(1,Spikeoutput.spikename{j},Spikename);
                        Channeldescription=unique(channeldescription(ismember(channel,obj(i).SPKchannel)));
                        Spikeoutput.channeldescription{j}=cat(1,Spikeoutput.channeldescription{j},repmat(Channeldescription,[length(index),1]));
                    end
                    obj(i).SPKdeletecache();
                end
            end
        end
        function Spikeoutput=ReadSPKsingle(obj,channel,channeldescription,read_start,read_until)    
            for i=1:length(obj)
                    if logical(sum(ismember(channel,obj(i).SPKchannel)))
                           obj(i)=obj(i).SPKloadcache('cluster');
                           obj(i)=obj(i).SPKloadcache('time');
                           Spikeoutput.Fs=obj(i).Samplerate;
                           clusternum=regexpi(obj(i).Filename,'.clu.','split');
                           clusternum=clusternum{end};
                           clustername=unique(obj(i).SPKcache.cluster);
                           clustername(clustername==0|clustername==1)=[];
                           for j=1:length(clustername)
                                tmpspikename=['cluster',num2str(clusternum),'_',num2str(clustername(j))];
                                tmpspike.channel=obj(i).SPKchannel;
                                tmpspike.channeldescription=unique(channeldescription(ismember(channel,obj(i).SPKchannel)));
                                tmpspike.spiketime=[];
                                 for k=1:length(read_start)
                                    index=obj(i).SPKcache.cluster==clustername(j)&obj(i).SPKcache.time>=read_start(k)&obj(i).SPKcache.time<=read_until(k);  
                                    tmpspike.spiketime{k}=obj(i).SPKcache.time(index);
                                 end
                                 tmpspike.timerange=[read_start,read_until];
                                 eval(['Spikeoutput.',tmpspikename,'=tmpspike;']);
                           end
                           obj(i).SPKdeletecache;
                    end
             end
        end                    
    end
    methods (Access='private')
        function SPKname = SPKName(obj)
             spk_clu=importdata(obj.Filename);%% load spike clusters
             spk_clu=spk_clu(2:end);
             spk_clu=unique(spk_clu);
             spk_clu(find(spk_clu==1|spk_clu==0))=[];
             SPKname=spk_clu;
        end
        function SPKchannel=SPKChannel(obj)
            SPKchannel=[];
            try
            clunumber=regexpi(obj.Filename,'.clu.','split');
            xmlfilename=[clunumber{1},'.xml'];
            xml=xml_read(xmlfilename);  
            SPKchannel=xml.spikeDetection.channelGroups.group(str2num(clunumber{2})).channels.channel;
            SPKchannel=cellfun(@(x) x+1,SPKchannel,'UniformOutput',1);
            catch
                SPKchannel=SPKchannel+1;
            end
        end
        function waveform=SPKWave(obj)
            waveform=LoadSpk(strrep(obj.Filename,'.clu.','.spk.'),length(obj.SPKchannel),length(obj.SPKcache.cluster));
        end
        function time=SPKTime(obj)
            time=importdata([strrep(obj.Filename,'.clu.','.res.')]);
            time=time/str2num(obj.Samplerate);
        end
        function cluster=SPKclu(obj)
            spk_clu=importdata(obj.Filename);%% load spike clusters
            cluster=spk_clu(2:end);
        end
        function obj=SPKloadcache(obj,option)
            switch option
                case 'wave'
                    obj.SPKcache.waveform = SPKWave(obj);
                case 'time'
                    obj.SPKcache.time = SPKTime(obj);
                case 'cluster'
                    obj.SPKcache.cluster = SPKclu(obj);
            end
        end
        function obj=SPKdeletecache(obj)
            try
                obj.SPKcache = rmfield(obj.SPKcache,'waveform');
            end
            try
                obj.SPKcache = rmfield(obj.SPKcache,'time');
            end
            try
                 obj.SPKcache = rmfield(obj.SPKcache,'cluster');
            end
        end 
    end
end