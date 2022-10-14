classdef BasicTag < dynamicprops
    % basic functions of the tagged data, including the tag add, tag choose and tag modified
    properties
    end
    methods(Access='public')
        function obj = Taginfo(obj, ParentTagname, informationtype, information)
           %  when informationtype&information is exist, add it.
           %  when information is empty, delete the informationtype.
           %  when informationtype&information are cells, add multiple.
           %  in this mode, there are only one element in the
           %  informationtype field.
            if iscell(informationtype) && ~isempty(information)
                for i=1:length(informationtype)
                    eval(['obj.',ParentTagname,'.',informationtype{i},'=information{i}']);
                end
            elseif ~isempty(information)
                eval(['obj.',ParentTagname,'.',informationtype,'=information']);
      
            elseif isempty(information)
                   try
                   eval(['obj.',ParentTagname,'=rmfield(obj.',ParentTagname,',informationtype)']);
                   end   
             end
        end
        function bool = Tagchoose(obj, ParentTagname, informationtype, information)
            if ~isempty(information)
            try
                if strcmp(eval(['obj.',ParentTagname,'.',informationtype]),information)
                    bool=1;
                else
                    bool=0;
                end
            catch
                bool =0;
            end
            else
                 x=fieldnames(['obj.',ParentTagname]);
                    if ismember(x,informationtype)
                        bool=1;
                    else
                        bool=0;
                    end
            end
        end
        function [informationtype, information] = Tagcontent(obj, ParentTagname, informationtype)
            % search the information type or information value
            if ~isempty(informationtype) % return the information type
                try
                information={eval(['obj.',ParentTagname,'.',informationtype])};
                catch
                informationtype=[];
                information=[];
                end
            else % return the information value from the given informationtype;
                try
                    informationtype=eval(['fieldnames(obj.',ParentTagname,')']);
                    for i=1:length(informationtype)
                        information{i}=eval(['obj.',ParentTagname,'.',informationtype{i}]);
                    end
                    information=information';
                catch
                    informationtype=[];
                    information=[];
                end
            end
        end
        function obj =Taglistinfo(obj,ParentTagname,informationtype,information,index)
            % in this mode, the obj.ParentTagname is used for the tags of an array, if add/remove the
            % informationtype in the ParentTagname, it must be add an array
            % to keep all the fieldnames in ParentTagname share same length.
            % delete the part of information could not delete the field
            % informationtype unless all the parts in the information type
            % were deleted.
            % this mode is used for spike class.
            if iscell(informationtype) && ~isempty(information)
                for i=1:length(informationtype)
                    if ~eval(['isfield(obj.',ParentTagname,',''',informationtype{i},''');'])
                        eval(['obj.',ParentTagname,'.',informationtype{i},'=repmat({''nan''},[length(index),1]);']);
                    end 
                    eval(['obj.',ParentTagname,'.',informationtype{i},'(index)=repmat(information(i),[sum(index),1]);']);
                end
            elseif ~isempty(information)
                if~eval(['isfield(obj.',ParentTagname,',''',informationtype,''');'])
                        eval(['obj.',ParentTagname,'.',informationtype,'=repmat({''nan''},[length(index),1]);']);
                end 
                eval(['obj.',ParentTagname,'.',informationtype,'(index)=repmat(information,[sum(index),1]);']);
            
            elseif isempty(information)
                    eval(['obj.',ParentTagname,'.',informationtype{:},'(index)=repmat({''nan''},[sum(index),1]);']);
                    if eval(['strcmp(''nan'',unique(obj.',ParentTagname,'.',informationtype{:},'))'])
                         eval(['obj.',ParentTagname,'=rmfield(obj.',ParentTagname,',''',informationtype{:},''');']);
                    end
                   
             end
        end
        function bool = Taglistchoose(obj,ParentTagname,informationtype,information)
        end
    end
end