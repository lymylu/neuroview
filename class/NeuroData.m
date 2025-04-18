classdef NeuroData < BasicTag & dynamicprops
    %% File management of the neuroview
    % all metadata are collected in a subject directory and management by a NeuroData object
    % To generate a the NeuroData object, using neuroview->Tag Define (neurodatatag) GUI.
    properties (Access='public')
        Datapath=[];
        LFPdata=[];
        SPKdata=[];
        CALdata=[];
        EVTdata=[];
        Videodata=[];
        fileTag=[];
        ChannelTag=[];
        Neuroresult=[];
    end
    methods (Access='public')     
        function obj = fileappend(obj, filepath)
            obj.Datapath=filepath;     
        end
        function obj = Taginfo(obj, Tagname, informationtype, information)
            obj=Taginfo@BasicTag(obj,Tagname,informationtype, information);
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
        function choosematrix=choose(obj,subject,varargin)
            % choose specific files with specific fileTag from NeuroData objects 
            % varargin contains the datatype (e.g., LFPdata, SPKdata, EVTdata, Videodata, CALdata)
            % and fileTag. 
            % example:
            % choosematrix=obj.choose('LFPdata','Preprocess:none','SPKdata','Preprocess:sorted','EVTdata','EVTtype:leftstimulus');
            p=inputParser;
            addRequired(p,'Subject',@(x) ischar(x));
            addParameter(p,'LFPdata',[],@(x) ischar(x));
            addParameter(p,'SPKdata',[],@(x) ischar(x));
            addParameter(p,'EVTdata',[],@(x) ischar(x));
            addParameter(p,'Videodata',[],@(x) ischar(x));
            addParameter(p,'CALdata',[],@(x) ischar(x));
            parse(p,subject,varargin{:});
            c=1;
            for i=1:length(obj)
                tmp=regexpi([p.Results.Subject],':','split');
                if obj(i).Tagchoose('fileTag',tmp{1},tmp{2})
                    choosematrix(c)=obj(i);
                   if ~isempty(p.Results.LFPdata)
                      tmp=regexpi([p.Results.LFPdata],':','split');
                      choosematrix(c).LFPdata=obj(i).LFPdata(obj(i).LFPdata.Tagchoose('fileTag',tmp{1},tmp{2}));
                   else
                       choosematrix(c).LFPdata=[];
                   end
                   if ~isempty(p.Results.SPKdata)
                       tmp=regexpi([p.Results.SPKdata],':','split');
                      choosematrix(c).SPKdata=obj(i).SPKdata(obj(i).SPKdata.Tagchoose('fileTag',tmp{1},tmp{2}));
                   else
                       choosematrix(c).SPKdata=[];
                   end
                   if ~isempty(p.Results.EVTdata)
                       tmp=regexpi([p.Results.EVTdata],':','split');
                      choosematrix(c).EVTdata=obj(i).EVTdata(obj(i).EVTdata.Tagchoose('fileTag',tmp{1},tmp{2}));
                   else
                       choosematrix(c).EVTdata=[];
                   end
                    if ~isempty(p.Results.Videodata)
                       tmp=regexpi([p.Results.Videodata],':','split');
                      choosematrix(c).Videodata=obj(i).Videodata(obj(i).Videodata.Tagchoose('fileTag',tmp{1},tmp{2}));
                    else
                        choosematrix(c).Videodata=[];
                    end
                    if ~isempty(p.Results.CALdata)
                       tmp=regexpi([p.Results.CALdata],':','split');
                      choosematrix(c).CALdata=obj(i).CALdata(obj(i).CALdata.Tagchoose('fileTag',tmp{1},tmp{2}));
                    else
                        choosematrix(c).CALdata=[];
                    end
                   c=c+1;  
                end
            end
        end                
        function obj=ExtractData(obj,varargin)
            % Extract the single LFP or SPK data from the determined LFPdata, SPKdata
            % and EVTdata
            p=inputParser;
            addParameter(p,'LFPdata',1);
            addParameter(p,'SPKdata',1);
            addParameter(p,'EVTdata',1);
            parse(p,varargin{:});
            try
            obj.LFPdata=obj.LFPdata(p.Results.LFPdata);
            end
            try
            obj.EVTdata=obj.EVTdata(p.Results.EVTdata);
            end
            try
            obj.SPKdata=obj.SPKdata(p.Results.SPKdata);
            end
        end
        function neuroresult=ReadData(obj,varargin)
            % read the data from NeuroData object with single LFPdata,
            % SPKdata and EVTdata.
            if nargin<2
                neuroresult=NeuroResult();
            else
                neuroresult=varargin{1};
            end
            if length(obj.LFPdata)>1 || length(obj.EVTdata)>1 || length(obj.SPKdata)>1
                error('only support one file of LFPdata, SPKdata and EVTdata');
            end
            channeldescription=[];channelselect=[];
            try              
                Channel=obj.selectchannel;
            catch
                warning('no selected channel were detected, using all channel to load. To determine the channels, using NeuroMethod.getParams before load.');
                Channel=fieldnames(obj.ChannelTag);
            end
            for i=1:length(Channel)
                [channelselecttmp,channeldescriptiontmp]=obj.Channelchoose(Channel{i}); 
                channelselect=cat(2,channelselect,channelselecttmp);
                channeldescription=cat(1,channeldescription,channeldescriptiontmp);
            end
            try
                EVTinfo=obj.EVTdata.LoadEVT;
            catch
                warning('no selected event information were detected, using all time to load. To determine the event information, using NeuroMethod.getParams before load.');
                EVTinfo=[]; % no eventdata
            end
            try
                neuroresult=obj.LFPdata.Extractdata(neuroresult,channelselect,channeldescription,EVTinfo);
                [~,neuroresult.Subjectname]=fileparts(obj.Datapath);
            end
            try
                neuroresult=obj.SPKdata.Extractdata(neuroresult,channelselect,channeldescription,EVTinfo);
                [~,neuroresult.Subjectname]=fileparts(obj.Datapath);
                neuroresult=obj.ReadSPKproperties();
            end
            try  % not work yet
                neuroresult=neuroresult.Extractdata(neuroresult,obj.CALdata,EVTinfo);
                [~,neuroresult.Subjectname]=fileparts(obj.Datapath);
            end
            neuroresult.fileTag=obj.fileTag;% inherit the tag information of the subject
        end
    end
end
