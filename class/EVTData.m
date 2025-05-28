classdef EVTData< BasicTag & dynamicprops
    properties
        Filename=[];
        EVTtype=[];
        EVTinfo=[];
    end
    methods (Access='public')
        function objmatrix =  fileappend(obj, filename)
            [evtpath,path]=uigetfile('*.evt','Please select the Path of the evt file(s)','Multiselect','on');
             if ischar(evtpath)
                 evtpath={evtpath};
             end
             for i=1:length(evtpath)
                 tmp=EVTData();
                 tmp.Filename=fullfile(path,evtpath{i});
                 objmatrix(i)=tmp;
             end
        end
        function Filename=getFilename(obj)
            for i=1:length(obj)
                Filename{i}=obj(i).Filename;
            end
        end
        function obj = initialize(obj)
             try
                obj.EVTtype=EVTType(obj);
             end
         end
         function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
                [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
         end
         function EVTinfo=LoadEVT(obj)
              event=[];eventdescription=[];timerange=[];
             switch obj.EVTinfo.timetype
                 case 'timepoint'
                [eventdescription,event,eventselect]=obj.EVTType(obj.EVTinfo.selecttype);
                timerange=[obj.EVTinfo.timestart,obj.EVTinfo.timestop];
                timestart=event+obj.EVTinfo.timestart;
                timestop=event+obj.EVTinfo.timestop;
                 case 'timeduration'
                [~,timestart,eventselect1]=obj.EVTType(obj.EVTinfo.timestart);
                [~,timestop,eventselect2]=obj.EVTType(obj.EVTinfo.timestop);
                if length(eventselect1)~=length(eventselect2)
                    error('different length between time begin events and time end events');
                else
                    eventselect=eventselect1;
                    eventdescription=repmat([obj.EVTinfo.timestart,'_',obj.EVTinfo.timestop],[length(eventselect),1]);
                    %timerange is empty;
                end
             end
            EVTinfo=obj.EVTinfo;
            EVTinfo.timestart=timestart;
            EVTinfo.timestop=timestop;
            EVTinfo.eventdescription=eventdescription;
            EVTinfo.eventselect=eventselect;
            EVTinfo.timerange=timerange;
            EVTinfo.blackevt=[];
         end
         function obj=selectevent(obj,eventinfo)
             % add the event selection in EVTdata object
             try
                 obj.addprop('timetype');
                 obj.addprop('timestart');
                 obj.addprop('selecttype');
                 obj.addprop('timestop');
             end
             obj.timetype=eventinfo.timetype;
             switch eventinfo.timetype
                 case 'timepoint'
                     obj.timestart=eventinfo.timestart;
                     obj.timestop=eventinfo.timestop;
                     obj.selecttype=eventinfo.selecttype;
                 case 'timeduration'
                     obj.timestart=eventinfo.timestart;
                     obj.timestop=eventinfo.timestop;
             end
         end
         function bool = check(obj)
             bool=~isempty(obj.EVTType)&~isempty(obj.fileTag);
         end
         function panel=gui_plot(obj,parent)
            panel=uix.VBoxFlex('Parent',parent);
            Filename=obj.getFilename;
            filepanel=uix.TabPanel('Parent',panel,'Tag','EventTablePanel');
            %filelist=uicontrol('Parent',panel,'Style','listbox','String',Filename,'Value',1,'Tag','subjectlist');
            for i=1:length(obj) % for several events
                events=LoadEvents_neurodata(obj(i).Filename);
                eventlist=arrayfun(@(x) num2str(x),events.time,'UniformOutput',0);
                selectpanel(i)=NeuroPlot.selectpanel();
                selectpanel(i).create(filepanel,strcat(obj(i).Filename,'_eventpanel'),eventlist,'typestring',events.description,'multiselect','off');
            end
%             set(filelist,'Callback',@(~,~) obj.changefile(filelist,filepanel));
%             set(filelist,'Value',1);
%             obj.changefile(filelist,filepanel);
         end
    end
    methods (Access='private')
        function changefile(obj,filelist,filepanel)
            value=filelist.Value;
            filepanel.SelectedChild=value;
         end
        function [description, time,eventselect]=EVTType(obj,type)
            if exist(obj.Filename)
            time=[];
            events=LoadEvents_neurodata(obj.Filename);
            try
                [~,index]=sort(events.time);
                events.time=events.time(index);
                events.description=events.description(index);
                SaveEvents_neurodata(obj.Filename,events,1);
            end
            if nargin<2 % get the description of the event.
                  description=unique(events.description);
            else
                 time=events.time(ismember(events.description,type));
                 description=events.description(ismember(events.description,type));
                 eventselect=find(ismember(events.description,type)==1);
            end
            else
                error(['no file were found in',])
        end
        end
    end
    methods(Static)
       function obj=EVTData(varargin)
             if nargin==1
             varname=fieldnames(varargin{1});
             data=varargin{1};
             for j=1:length(data)
                 obj(j)=EVTData();
             for i=1:length(varname)
                 eval(['obj(j).',varname{i},'=data(j).',varname{i},';']);
             end
             end
             end
        end
        function obj=Clone(neurodata)
             obj=EVTData();
             obj.Filename=neurodata.Filename;
             obj.EVTtype=obj.EVTType();
        end
    end
end
