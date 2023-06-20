classdef NeuroData < BasicTag
    %% 
    properties (Access='public')
        Datapath=[];
        LFPdata=[];
        SPKdata=[];
        CALdata=[];
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
        function dataoutput=LoadData(obj,DetailsAnalysis)
            % load the LFP or SPK data from the determined events
            channeldescription=[];channelselect=[];
            Channel=DetailsAnalysis.channelchoose;
            for i=1:length(Channel)
                [channelselecttmp,channeldescriptiontmp]=obj.Channelchoose(Channel{i}); 
                channelselect=cat(2,channelselect,channelselecttmp);
                channeldescription=cat(1,channeldescription,channeldescriptiontmp);
            end
            try
            EVTinfo=obj.EVTdata.LoadEVT(DetailsAnalysis.EVTinfo);
            catch
                EVTinfo=[]; % no eventdata
            end
            dataoutput=NeuroResult();
            try
                dataoutput=dataoutput.ReadLFP(obj.LFPdata,channelselect,channeldescription,EVTinfo);
                [~,dataoutput.Subjectname]=fileparts(obj.Datapath);
            end
            try
                dataoutput=dataoutput.ReadSPK(obj.SPKdata,channelselect,channeldescription,EVTinfo);
                [~,dataoutput.Subjectname]=fileparts(obj.Datapath);
                dataoutput=dataoutput.ReadSPKproperties(obj.Datapath);
            end
            try 
                dataoutput=dataoutput.ReadCAL(obj.CALdata,EVTinfo);
                [~,dataoutput.Subjectname]=fileparts(obj.Datapath);
            end
            dataoutput.fileTag=obj.fileTag;% inherit the tag information of the subject
        end
    end
end
