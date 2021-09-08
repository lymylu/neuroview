classdef NeuroData < BasicTag
    %% 
    properties (Access='public')
        Datapath=[];
        LFPdata=[];
%         Videodata
        SPKdata=[];
        EVTdata=[];
        Videodata=[];
        fileTag=[];
        ChannelTag=[];
    end
    methods (Access='public')
        function obj = fileappend(obj, filepath)
            obj.Datapath=filepath;     
        end
        function obj = Taginfo(obj, Tagname, informationtype, information)
            obj=Taginfo@BasicTag(obj,Tagname,informationtype,information);
        end
        function bool = Tagchoose(obj,Tagname,informationtype, information)
            bool=Tagchoose@BasicTag(obj,Tagname,informationtype,information);
        end
        function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
             [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                  [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
          end
        function [chselect, channeldescription] = Channelchoose(obj, informationtype)
             chselect=eval(['obj.ChannelTag.',informationtype]);
             chselect=str2num(chselect);
             channeldescription=repmat({informationtype},[length(chselect),1]);
         end
        function dataoutput=loadData(obj,DetailsAnalysis,DataType)
            %% load the LFP or SPK data from the determined events
            Channel=cellfun(@(x) contains(x,'ChannelTag:'),DetailsAnalysis,'UniformOutput',1);
            Channel=strrep(DetailsAnalysis{Channel},'ChannelTag:','');
            Channel=regexpi(Channel,',','split');
            channeldescription=[];channelselect=[];
            for i=1:length(Channel)
                [channelselecttmp,channeldescriptiontmp]=obj.Channelchoose(Channel{i}); 
                channelselect=cat(2,channelselect,channelselecttmp);
                channeldescription=cat(1,channeldescription,channeldescriptiontmp);
            end
            [timestart, timestop,eventdescription,eventselect,relativetime]=obj.EVTdata.LoadEVT(DetailsAnalysis);
            switch DataType
                case 'LFP' 
                    dataoutput=obj.LFPdata.ReadLFP(channelselect,timestart,timestop);
                    dataoutput.channeldescription=channeldescription;
                    dataoutput.channelselect=channelselect;
                    dataoutput.Fs=obj.LFPdata.Samplerate;
                    dataoutput.relativetime=relativetime;
                case 'SPK'    
                    dataoutput=obj.SPKdata.ReadSPK(channelselect,channeldescription,timestart,timestop);
            end
             dataoutput.eventdescription=eventdescription;
             dataoutput.eventselect=eventselect;
        end
    end
end
