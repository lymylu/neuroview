classdef EVTData< BasicTag & dynamicprops
    properties
        Filename=[];
        EVTtype=[];
        fileTag=[];
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
         function obj = initialize(obj)
             try
                obj.EVTtype=EVTType(obj);
             end
         end
         function obj = Taginfo(obj, Tagname,informationtype, information)
             obj = Taginfo@BasicTag(obj, Tagname,informationtype, information);
         end
         function bool = Tagchoose(obj, Tagname,informationtype, information)
             bool = Tagchoose@BasicTag(obj,Tagname,informationtype,information);
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
             switch obj.timetype
                 case 'timepoint'
                [eventdescription,event,eventselect]=obj.EVTType(obj.selecttype);
                timerange=[obj.timestart,obj.timestop];
                timestart=event+obj.timestart;
                timestop=event+obj.timestop;
                 case 'timeduration'
                [~,timestart,eventselect1]=obj.EVTType(obj.timestart);
                [~,timestop,eventselect2]=obj.EVTType(obj.timestop);
                if length(eventselect1)~=length(eventselect2)
                    error('different length between time begin events and time end events');
                else
                    eventselect=eventselect1;
                    eventdescription=repmat([obj.timestart,'_',obj.timestop],[length(eventselect),1]);
                    %timerange is empty;
                end
              end
            EVTinfo.timestart=timestart;
            EVTinfo.timestop=timestop;
            EVTinfo.eventdescription=eventdescription;
            EVTinfo.eventselect=eventselect;
            EVTinfo.timetype=obj.timetype;
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
    end
    methods (Access='private')
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
        function obj=Clone(neurodata)
             obj=EVTData();
             obj.Filename=neurodata.Filename;
             obj.EVTtype=obj.EVTType();
        end
    end
end
