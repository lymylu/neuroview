classdef EVTData < BasicTag 
    properties
        Filename=[];
        EVTtype=[];
        fileTag=[];
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
         function [timestart, timestop,eventdescription,eventselect]=LoadEVT(obj, DetailsAnalysis)
              timetype=cellfun(@(x) contains(x,'Timetype:timepoint'),DetailsAnalysis,'UniformOutput',1);% ѡ��ʱ�䡣
              event=[];eventdescription=[];
              if sum(timetype)==1 %  time points
                timestart1=cellfun(@(x) contains(x,'Timestart:'),DetailsAnalysis,'UniformOutput',1);
                timestart1=str2num(strrep(DetailsAnalysis{timestart1},'Timestart:',''));
                timestop1=cellfun(@(x) contains(x,'Timestop:'),DetailsAnalysis,'UniformOutput',1);
                timestop1=str2num(strrep(DetailsAnalysis{timestop1},'Timestop:',''));
                eventtype=strrep(DetailsAnalysis{timetype},'Timetype:timepoint:EVTtype:','');
                eventtype=regexpi(eventtype,',','split');
                [eventdescription,event,eventselect]=obj.EVTType(eventtype);
                timestart=event+timestart1;
                timestop=event+timestop1;
            else % time duration
                timestart=cellfun(@(x) contains(x,'Timestart:EVTtype:'),DetailsAnalysis,'UniformOutput',1);
                timestart=strrep(DetailsAnalysis{timestart},'Timestart:EVTtype:','');
                timestop=cellfun(@(x) contains(x,'Timestop:EVTtype:'),DetailsAnalysis,'UniformOutput',1);
                timestop=strrep(DetailsAnalysis{timestop},'Timestop:EVTtype:','');
                [~,timestart,eventselect1]=obj.EVTType(timestart);
                [~,timestop,eventselect2]=obj.EVTType(timestop);
                if length(eventselect1)~=length(eventselect2)
                    error('�¼���ʼ�ͽ�β�ĳ��Ȳ�һ���޷���ȡ����');
                else
                    eventselect=eventselect1;
                end
            end
         end
    end
    methods (Access='private')
        function [description, time,eventselect]=EVTType(obj,type)
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
        end
    end
end
