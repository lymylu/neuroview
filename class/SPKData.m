classdef SPKData < BasicTag
     properties
        Filename=[];
        Samplerate=[];
        SPKcache=[];
        SPKchannel=[];
        fileTag=[];
    end
    methods (Access='public')
        function obj =  fileappend(obj, filename)
            obj.Filename=filename;
        end
        function obj = initialize(obj, Samplerate)
%             try
%             spk_fet=importdata([strrep(obj.Filename,'.clu.','.fet.')]);%%load features
%             featurenumber=spk_fet(1);
%             if featurenumber<=5
%                 obj.Recordtype=1;
%             elseif featurenumber==9
%                 obj.Recordtype=2;
%             elseif featurenumber==13
%                 obj.Recordtype=4;
%             end
%             end%%single =4, tetrode=13;
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
            Spikeoutput.timerange=[read_start,read_until];
            Spikeoutput.spiketime=cell(1,length(read_start));
            Spikeoutput.spikename=cell(1,length(read_start));
            Spikeoutput.spikewaveform=cell(1,length(read_start));
            Spikeoutput.channelname=cell(1,length(read_start));
            Spikeoutput.channeldescription=cell(1,length(read_start));
            for i=1:length(obj)
                if logical(sum(ismember(channel,obj(i).SPKchannel)))
                    obj(i)=obj(i).SPKloadcache('cluster');
                    obj(i)=obj(i).SPKloadcache('time');
                    Spikeoutput.Fs=obj(i).Samplerate;
                    if strcmp(option,'wave')
                        obj(i)=obj(i).SPKloadcache('wave');
                    end
                    clusternum=regexpi(obj(i).Filename,'.clu.','split');
                    clusternum=clusternum{end};
                    for j=1:length(read_start)
                        index=find(obj(i).SPKcache.cluster~=0&obj(i).SPKcache.cluster~=1&obj(i).SPKcache.time>=read_start(j)&obj(i).SPKcache.time<=read_until(j));  
                        try
                            Spikeoutput.spikewaveform{j}=cat(3,Spikeoutput.spikewaveform{j},obj(i).SPKcache.waveform(:,:,index));
                        end
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