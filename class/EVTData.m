classdef EVTData< BasicTag 
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
                 tmp=NeuroFile.EVTFile();
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
         function EVTinfo=LoadEVT(obj,EVTparams)
              event=[];eventdescription=[];timerange=[];
             switch EVTparams.timetype
                 case 'timepoint'
                [eventdescription,event,eventselect]=obj.EVTType(EVTparams.EVTtype);
                timerange=[EVTparams.timestart,EVTparams.timestop];
                timestart=event+EVTparams.timestart;
                timestop=event+EVTparams.timestop;
                 case 'timeduration'
                [~,timestart,eventselect1]=obj.EVTType(EVTparams.timestart);
                [~,timestop,eventselect2]=obj.EVTType(EVTparams.timestop);
                if length(eventselect1)~=length(eventselect2)
                    error('different length between time begin events and time end events');
                else
                    eventselect=eventselect1;
                    eventdescription=repmat([EVTparams.timestart,'_',EVTparams.timestop],[length(eventselect),1]);
                    %timerange is empty;
                end
              end
            EVTinfo.timestart=timestart;
            EVTinfo.timestop=timestop;
            EVTinfo.eventdescription=eventdescription;
            EVTinfo.eventselect=eventselect;
            EVTinfo.timetype=EVTparams.timetype;
            EVTinfo.timerange=timerange;
         end
    end
    methods (Access='private')
        function [description, time,eventselect]=EVTType(obj,type)
            if exist(obj.Filename)
            time=[];
            events=LoadEvents_neurodata(obj.Filename);
            [~,index]=sort(events.time);
            events.time=events.time(index);
            events.description=events.description(index);
            SaveEvents_neurodata(obj.Filename,events,1);
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
