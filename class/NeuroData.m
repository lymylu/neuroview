classdef NeuroData < BasicTag & dynamicprops
    %NEURODATA Subject level management of the neuroview
    % all metadata are collected in a subject directory and management by a NeuroData object
    % To generate a the NeuroData object, using neuroview->Tag Define (neurodatatag) GUI.
    % See also NEUROVIEW, NEURODATATAG, BASICTAG
    properties (Access='public')
        Datapath=[]; % subject data path
    end
    methods (Access='public')     
        function obj = fileappend(obj, filepath)
            % add subject path to neurodata object
            obj.Datapath=filepath;     
        end
        function obj = Taginfo(obj, Tagname, informationtype, information)
            try
                addprop(obj,Tagname);
            end
            obj=Taginfo@BasicTag(obj,Tagname,informationtype, information);
        end
        function datapath=getDatapath(obj)
            % list all Datapath from neurodata objects
            datapath=[];
            for i=1:length(obj)
                datapath=cat(1,{obj.Datapath});
            end
        end
        function dataoutput=getTaginfo(obj,option,parent)
            dataoutput=getTaginfo@BasicTag(obj,option,parent);
        end
        function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
             [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                  [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
          end
        %function [chselect, channeldescription] = Channelchoose(obj, informationtype)
             %chselect=eval(['obj.ChannelTag.',informationtype]);
             %chselect=str2num(chselect);
             %channeldescription=repmat({informationtype},[length(chselect),1]);
        %end
        function [choosematrix,index]=choose(obj,varargin)
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
            % See also BASICTAG.FILECHOOSE
            p=inputParser;
            addOptional(p,'filetag',1:length(obj));
            addParameter(p,'LFPdata',[],@(x) ischar(x)||isnumeric(x)||iscell(x));
            addParameter(p,'SPKdata',[],@(x) ischar(x)||isnumeric(x)||iscell(x));
            addParameter(p,'EVTdata',[],@(x) ischar(x)||isnumeric(x)||iscell(x));
            addParameter(p,'Videodata',[],@(x) ischar(x)||isnumeric(x)||iscell(x));
            addParameter(p,'CALdata',[],@(x) ischar(x)||isnumeric(x)||iscell(x));
            addParameter(p,'Neuroresult',[],@(x) ischar(x)||isnumeric(x)||iscell(x));
            parse(p,varargin{:});
            c=1;
            vartype={'LFPdata','SPKdata','EVTdata','Videodata','CALdata','Neuroresult'};
            [objnew,objvalid]=obj.Filechoose(p.Results.filetag);
            index=find(objvalid==1);
            objinvalid=false(length(find(objvalid==1)),1);
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
            index(objinvalid)=[];
            choosematrix(objinvalid)=[];
        end                
        function neuroresult=ReadData(obj,varargin)
            % read the data from NeuroData object
            % the neurodata object must contains only one LFPdata or SPKdata and EVTdata.
            % if neurodata.selectchannel is exist, select the corresponding regions (defined in ChannelTag), or use all channels.end
            % neurodata must contain a EVTData (function for neurodata without EVTdata is on working)
            % return NEURORESULT object
            % See also: NEURORESULT, NEURODATA.CHANNLCHOOSE, EVTDATA.LOADEVT, LFPDATA.EXTRACTDATA, SPKDATA.EXTRACTDATA, SPKDATA.READSPKPROPERTIES
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
                %[channelselecttmp,channeldescriptiontmp]=obj.Channelchoose(Channel{i});
                [channeldescriptiontmp,channelselecttmp]=obj.Tagcontent('ChannelTag',Channel{i});
                %channelselect=cat(2,channelselect,channelselecttmp);
                %channeldescription=cat(1,channeldescription,channeldescriptiontmp);
                try
                channeldescription=cat(1,channeldescription,repmat({channeldescriptiontmp},[length(str2num(channelselecttmp{:})),1]));
                catch
                    a=1;
                end
                channelselect=cat(2,channelselect,str2num(channelselecttmp{:}));
            end
            if isprop(obj,'EVTdata')
                obj.EVTdata=obj.EVTdata.LoadEVT;
            else % add the whole file length to generate the dummy EVTdata
                addprop(obj,'EVTdata')
                EVTData.EVTinfo.time=[0,inf];
                EVTData.EVTinfo.description={'filebegin','fileend'};
                EVTData.EVTinfo.timetype='timeduration';
                obj.EVTdata=EVTData;
            end
            if isprop(obj,'LFPdata')
                neuroresult=obj.LFPdata.Extractdata(neuroresult,channelselect,channeldescription,obj.EVTdata);
                [~,neuroresult.Subjectname]=fileparts(obj.Datapath);
            end
            if isprop(obj,'SPKdata')
                neuroresult=obj.SPKdata.Extractdata(neuroresult,channelselect,channeldescription,obj.EVTdata);
                try
                    neuroresult=obj.SPKdata.ReadSPKproperties(neuroresult);
                end
                [~,neuroresult.Subjectname]=fileparts(obj.Datapath); 
            end
            try  % not work yet
                neuroresult=obj.CALdata.Extractdata(neuroresult,obj.CALdata,EVTinfo);
                [~,neuroresult.Subjectname]=fileparts(obj.Datapath);
            end
            neuroresult.fileTag=obj.fileTag;% inherit the tag information of the subject
            neuroresult.Subjectname=obj.Datapath;
            try
                addprop(neuroresult,'ChannelTag');
            end
            neuroresult.ChannelTag=obj.ChannelTag;
        end  
        function Filelist=list(obj,varname)
            % listall file names in the neurodata object
            Filelist=[];
            subobject={'LFPdata','SPKdata','EVTdata','CALdata','Videodata','Neuroresult'};
            for i=1:length(obj)
                for j=1:length(subobject)
                    try
                        eval(['Filelist=cat(1,Filelist,obj(i).',subobject{j},'.list(varname));']);
                    end
                end
            end
        end
        function gui_plot(obj,parent)
            % gui_plot of NeuroData (origin, no epoch, timescroll plot)
            % find the object in NeuroData
            % (LFPdata,SPKdata,Videodata,CALdata,EVTdata to plot)
            % LFPdata,SPKdata,contains Channelselectpanel
            % EVTdata contains Eventselectpanel
            % Videodata contains videocontrol
            % LFPdata contains plot-scroll
            % SPKdata contains raster-scroll 
            % all timebar could be sychronized to each other.
            % Eventselectpanel could be sychronized to each other and the timebar.
            % Channelselectpanel could be sycrhonized to each other
            % See also: NEURODATA.GUI_PLOT_SINGLE
            Subject=obj.getDatapath;
            panel=uix.VBoxFlex('Parent',parent);
            subjectlist=uicontrol('Parent',panel,'Style','listbox','String',Subject,'Value',1,'Tag','subjectlist');
            panel_sub=uix.HBoxFlex('Parent',panel,'Tag','SingleSubjectPlot');
            set(subjectlist,'Callback',@(~,~) obj.gui_plot_single(subjectlist,panel_sub));
            obj.gui_plot_single(subjectlist,panel_sub);
            set(panel,'Height',[-1,-5]);
        end
        function gui_plot_single(obj,subjectlist,panel)
            % core function for general view single NeuroData object
            % See also:SPKDATA.GUI_PLOT, LFPDATA.GUI_PLOT, VIDEODATA.GUI_PLOT, NeuroPlot.SYNC
            index=subjectlist.Value;
            try
                tmpobj=findobj('Parent',panel);
                delete(tmpobj);
            end
             vartype={'Videodata','LFPdata','SPKdata','CALdata','EVTdata'};
            for i=1:length(vartype)
                if isprop(obj(index),vartype{i})
                    eval([vartype{i},'_panel=obj(index).',vartype{i},'.gui_plot([]);']);
                end
            end
            if exist('EVTdata_panel')
                %panel_sub=uix.HBoxFlex('Parent',panel,'Tag','Eventguiplot');
                EVTdata_panel.Parent=panel;
                % addlistener to all timebar when choose the given event data
            end
                mainpanel=uix.VBoxFlex('Parent',panel);
            for i=1:length(vartype)-1
                try
                    eval([vartype{i},'_panel.Parent=mainpanel;']);
                end
            end
            try
                set(panel,'Width',[-1,-8]);
            end
            %set(panel,'Height',[-1,-8]);
            %% add sync listener link EVT and timepanel
            if exist('EVTdata_panel')
                timepanel=findobj(panel,'-regexp','Tag','timerangepanel');
                for i=1:length(obj(index).EVTdata)
                    eventpanel=findobj(panel,'Tag',char(strcat(obj(index).EVTdata(i).Filename,'_eventpanel')));
                    for j=1:length(timepanel)
                        addlistener(eventpanel.listpanel,'Value','PostSet',@(~,~) NeuroPlot.Sync.SyncEvent_Time(eventpanel,timepanel(j))); 
                        addlistener(eventpanel,'type_list_change',@(~,~) NeuroPlot.Sync.SyncEvent_Time(eventpanel,timepanel(j)));
                    end
                end
            end
            % add sync listener link timepanel
            timepanel = findobj(panel,'-regexp','Tag','timerangepanel');
            for i=1:length(timepanel)
                for j=length(timepanel):-1:1
                    if i~=j
                        addlistener(timepanel(i),'currenttime','PostSet',@(~,~) NeuroPlot.Sync.SyncTime(timepanel(i),timepanel(j)));
                    end
                end
            end
        end
        function CheckValid(obj,option)
            % keep all neurodata object contains the [option] type of files
            for i=1:length(obj)
                if isempty(eval(['obj(i).',option]))
                    error(['No',option,'contains in the choosed data in',obj(i).Datapath]);
                end
            end
        end
    end
       methods(Static)
          function obj=NeuroData(varargin)
             % transfer neurodata object to a struct
             if nargin==1
             %varname=fieldnames(varargin{1});
             alldata=varargin{1}; 
             subobjectname={'LFPData','SPKData','EVTData','VideoData','CALData','NeuroResult'};
             for j=1:length(alldata)
                 obj(j)=NeuroData();
                 if iscell(alldata)
                     data=alldata{j};
                 elseif isstruct(alldata)
                     data=alldata(j);
                 end
                    varname=fieldnames(data);
                for i=1:length(varname)
                   index=contains(subobjectname,varname{i},'IgnoreCase',true);
                   if ~isempty(eval(['data.',varname{i}]))
                   try
                       addprop(obj(j),varname{i});
                   end
                    try
                        eval(['obj(j).',varname{i},'=',subobjectname{index},'(data.',varname{i},');']);
                    catch
                        eval(['obj(j).',varname{i},'=data.',varname{i},';']);
                    end
                   end
                end
             end
          end
        end
          
       end
end
