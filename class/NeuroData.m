classdef NeuroData < BasicTag & dynamicprops
    %% File management of the neuroview
    % all metadata are collected in a subject directory and management by a NeuroData object
    % To generate a the NeuroData object, using neuroview->Tag Define (neurodatatag) GUI.
    properties (Access='public')
        Datapath=[];
    end
    methods (Access='public')     
        function obj = fileappend(obj, filepath)
            obj.Datapath=filepath;     
        end
        function obj = Taginfo(obj, Tagname, informationtype, information)
            try
                addprop(obj,Tagname);
            end
            obj=Taginfo@BasicTag(obj,Tagname,informationtype, information);
        end
        function dataoutput=getTaginfo(obj,option,parent)
            dataoutput=getTaginfo@BasicTag(obj,option,parent);
        end
        function bool = Tagchoose(obj,informationtype,information)
           bool=Tagchoose@BasicTag(obj,'fileTag',informationtype,information)
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
        function choosematrix=choose(obj,varargin)
            % choose specific files with specific fileTag from NeuroData objects 
            % varargin contains the datatype (e.g., LFPdata, SPKdata, EVTdata, Videodata, CALdata)
            % and fileTag. 
            %->fileTag inputs
            % if ischar, choose the subject or Data object with unique file tag
            % if isnumeric choose the subject or Data object with numeric index
            % is iscell, choose the subject or Data object with muliple file tag intersect mode
            % the last cell of input is 'intersect' or 'union' to defined the interact or union from file tags.
            % example:
            % choosematrix=obj.choose('LFPdata','Preprocess:none','SPKdata','Preprocess:sorted','EVTdata','EVTtype:optostimulus');
            % choosematrix=obj.choose('LFPdata',{'Preprocess:none','Preprocess:filter','union'},'SPKdata',1,'EVTdata',1);
            p=inputParser;
            addOptional(p,'filetag',1:length(obj));
            addParameter(p,'LFPdata',[],@(x) ischar(x)||isnumeric(x)||iscell(x));
            addParameter(p,'SPKdata',[],@(x) ischar(x)||isnumeric(x)||iscell(x));
            addParameter(p,'EVTdata',[],@(x) ischar(x)||isnumeric(x)||iscell(x));
            addParameter(p,'Videodata',[],@(x) ischar(x)||isnumeric(x)||iscell(x));
            addParameter(p,'CALdata',[],@(x) ischar(x)||isnumeric(x)||iscell(x));
            parse(p,varargin{:});
            c=1;
            vartype={'LFPdata','SPKdata','EVTdata','Videodata','CALdata'};
            objnew=obj.Filechoose(p.Results.filetag);
            objinvalid=false(length(obj));
            choosematrix=[];valid=[];
            for s=1:length(objnew)
                varname=fieldnames(objnew(s));
                for i=1:length(varname)
                if ~contains(varname{i},vartype)
                        eval(['choosematrix(s).',varname{i},'=objnew(s).',varname{i},';']);
                end
                end
                for i=1:length(vartype)
                    try
                        eval(['tmp=objnew(s).',vartype{i},'.Filechoose(p.Results.',vartype{i},');']);
                        if ~isempty(tmp)
                            eval(['choosematrix(s).',vartype{i},'=tmp;']);
                            valid(c)=i;
                            c=c+1;
                        else
                            objinvalid(s)=true;
                        end
                    end
                end
            end
            try
                choosematrix=NeuroData(choosematrix);
            end
            choosematrix(objinvalid)=[];
        end                
        function neuroresult=ReadData(obj,varargin)
            % read the data from NeuroData object with single LFPdata,
            % SPKdata and EVTdata.
            if nargin<2
                neuroresult=NeuroResult();
            else
                neuroresult=varargin{1};
            end
            if isprop(obj,'LFPdata')
                assert(length(obj.LFPdata)==1);
            end
            if isprop(obj,'EVTdata')
                assert(length(obj.EVTdata)==1);
            end
            if isprop(obj,'SPKdata')
                assert(length(obj.SPKdata)==1);
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
        function Filelist=listfile(obj)
            % listall files in the neurodata object
            Filelist=[];
            subobject={'LFPdata','SPKdata','EVTdata','CALdata','Videodata'};
            for i=1:length(obj)
                for j=1:length(subobject)
                    try
                        eval(['Filelist=cat(1,Filelist,obj.',subobject{j},'.listfile());']);
                    end
                end
            end
        end
    end
       methods(Static)
          function obj=NeuroData(varargin)
             if nargin==1
             varname=fieldnames(varargin{1});
             data=varargin{1}; 
             subobjectname={'LFPData','SPKData','EVTData','VideoData','CALData'};
             for j=1:length(data)
                 obj(j)=NeuroData();
                for i=1:length(varname)
                   index=contains(subobjectname,varname{i},'IgnoreCase',true);
                   if ~isempty(eval(['data(j).',varname{i}]))
                   try
                       addprop(obj(j),varname{i});
                   end
                    try
                        eval(['obj(j).',varname{i},'=',subobjectname{index},'(data(j).',varname{i},');']);
                    catch
                        eval(['obj(j).',varname{i},'=data(j).',varname{i},';']);
                    end
                   end
                end
             end
          end
        end
    end
end
