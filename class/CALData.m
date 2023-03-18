classdef CALData < BasicTag
    properties (Access='public')
        Filename=[];
        Samplerate=[];
        fileTag=[];   
    end
    methods (Access='public')
         function obj = fileappend(obj)
             % support the csv output from the inscopix software
             [calpath,path]=uigetfile('*.csv','Please select the Path of the Calsuim image file(s)','Multiselect','on');
             if ischar(calpath)
                 calpath={calpath};
             end
             for i=1:length(calpath)
                 tmp=CALData();
                 tmp.Filename=fullfile(path,calpath{i});
                 obj(i)=tmp;
             end
         end
         function obj = Taginfo(obj,Tagname,informationtype, information)
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
         function obj = initialize(obj,Samplerate)
            obj.Samplerate=Samplerate;
         end
    end
end