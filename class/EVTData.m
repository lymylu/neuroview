classdef EVTData < BasicTag 
    properties
        Filename=[];
        EVTtype=[];
        fileTag=[];
    end
    methods (Access='public')
        function obj =  fileappend(obj, filename)
            obj.Filename=filename;
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
         function time=Timechoose(obj, eventtype)
             [~,time]=EVTType(obj,eventtype);
         end
         function [timestart, timestop,eventdescription]=LoadEVT(obj, DetailsAnalysis)
              timetype=cellfun(@(x) contains(x,'Timetype:timepoint'),DetailsAnalysis,'UniformOutput',1);% Ñ¡ÔñÊ±¼ä¡£
            if sum(timetype)==1 %  time points
                timestart1=cellfun(@(x) contains(x,'Timestart:'),DetailsAnalysis,'UniformOutput',1);
                timestart1=str2num(strrep(DetailsAnalysis{timestart1},'Timestart:',''));
                timestop1=cellfun(@(x) contains(x,'Timestop:'),DetailsAnalysis,'UniformOutput',1);
                timestop1=str2num(strrep(DetailsAnalysis{timestop1},'Timestop:',''));
                eventtype=strrep(DetailsAnalysis{timetype},'Timetype:timepoint:EVTtype:','');
                eventtype=regexpi(eventtype,',','split');
                event=[];eventdescription=[];
                for i=1:length(eventtype)
                    eventtmp=obj.Timechoose(eventtype{i});
                    eventdescriptiontmp=repmat(eventtype(i),[length(eventtmp),1]);
                    event=cat(1,event,eventtmp);
                    eventdescription=cat(1,eventdescription,eventdescriptiontmp);
                end
                timestart=event+timestart1;
                timestop=event+timestop1;
            else % time duration
                timestart=cellfun(@(x) contains(x,'Timestart:EVTtype:'),DetailsAnalysis,'UniformOutput',1);
                timestart=strrep(DetailsAnalysis{timestart},'Timestart:EVTtype:','');
                timestop=cellfun(@(x) contains(x,'Timestop:EVTtype:'),DetailsAnalysis,'UniformOutput',1);
                timestop=strrep(DetailsAnalysis{timestop},'Timestop:EVTtype:','');
                timestart=obj.Timechoose(timestart);
                timestop=obj.Timechoose(timestop);
            end
         end
    end
    methods (Access='private')
        function [typeout, time]=EVTType(obj,type)
            time=[];
            events=LoadEvents_neurodata(obj.Filename);
            [~,index]=sort(events.time);
            events.time=events.time(index);
            events.description=events.description(index);
            SaveEvents_neurodata(obj.Filename,events,1);
            if nargin<2
                  typeout=unique(events.description);
            else
                 time=events.time(ismember(events.description,type));
                 typeout=unique(events.description);
            end          
        end
    end
end
