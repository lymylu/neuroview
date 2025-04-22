classdef CALData < BasicTag
    properties (Access='public')
        Filename=[];
        Samplerate=[]; 
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
          function bool = check(obj)
             bool=~isempty(obj.Samplerate)&~isempty(obj.fileTag);
         end
    end
    methods(Static)
          function obj=CALData(varargin)
  if nargin==1
             varname=fieldnames(varargin{1});
             data=varargin{1};
             for j=1:length(data)
                 obj(j)=CALData();
             for i=1:length(varname)
                 eval(['obj(j).',varname{i},'=data(j).',varname{i},';']);
             end
             end
             end
        end
    end
end