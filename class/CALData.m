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
         function objnew = Tagchoose(obj,filetag)
            %->fileTag inputs
            % if ischar, choose the subject or Data object with unique file tag
            % if isnumeric choose the subject or Data object with numeric index
            % is iscell, choose the subject or Data object with muliple file tag intersect mode
            % the last cell of input is 'intersect' or 'union' to defined the interact or union from file tags.
            if ischar(filetag)
                info=regexpi(filetag,':','split');
                bool=Tagchoose@BasicTag(obj,'fileTag',info{1},info{2});
                objnew=obj(bool);
            elseif isnumeric(filetag)
                objnew=obj(filetag);
            elseif iscell(filetag)
                for i=1:length(filetag)-1
                    info=regexpi(filetag{i},':','split');
                    booltmp=Tagchoose@BasicTag(obj,'fileTag',info{1},info{2});
                    if i==1
                        bool=booltmp;
                    else 
                        switch p.Results.filetag{3}
                            case 'intersect'
                                bool=booltmp&bool;
                            case 'union'
                                bool=booltmp|bool;
                        end
                    end
                end
                objnew=obj(bool);
            else
                objnew=obj;
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