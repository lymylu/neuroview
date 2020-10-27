classdef LFPData < BasicTag 
    properties (Access='public')
        Filename=[];
        Channelnum=[];
        Samplerate=[];
        fileTag=[];
        ADconvert=[];
    end
    methods (Access='public')
         function obj = fileappend(obj, filename)
            obj.Filename=filename;
         end
         function obj = initialize(obj,Channelnum,Samplerate,ADconvert)
            obj.Channelnum=Channelnum;
            obj.Samplerate=Samplerate;
            obj.ADconvert=ADconvert;
         end
         function obj = Taginfo(obj,Tagname,informationtype, information)
             obj = Taginfo@BasicTag(obj, Tagname,informationtype, information);
         end
         function bool = Tagchoose(obj, Tagname,informationtype, information)
             bool = Tagchoose@BasicTag(obj,Tagname,informationtype,information);
         end          
         function obj = SampleRate(obj, samplerate)
             obj.Samplerate=samplerate;
         end
         function dataoutput = ReadLFP(obj, chselect, read_start,read_until,precision,b_skip)
             timerange=[read_start, read_until];
             read_start=round(read_start.*str2num(obj.Samplerate));
              read_until=round(read_until.*str2num(obj.Samplerate));
             if nargin<6 %precision and skip 
                 precision='int16';
             end
             if nargin<7 %skip
                b_skip=0;
             end
             for i=1:length(read_start)
                data{i}=readmulti_frank(obj.Filename, str2num(obj.Channelnum), chselect, read_start(i), read_until(i), precision, b_skip);
                data{i}=data{i}.*str2num(obj.ADconvert);
             end
             dataoutput.LFPdata=data;
             dataoutput.timerange=timerange;
         end
         function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
             [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                  [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
        end
    end
end