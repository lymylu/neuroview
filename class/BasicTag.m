classdef BasicTag < dynamicprops
    % basic functions of the tagged data, including the tag add, tag choose and tag modified
    properties
    end
    methods(Access='public')
        function obj = Taginfo(obj, ParentTagname, informationtype, information)
           %  when informationtype&information is exist, add it.
           %  when information is empty, delete the informationtype.
           %  when informationtype&information are cells, add multiple.
            if class(informationtype)=='cell'
                for i=1:length(informationtype);
                    eval(['obj.',ParentTagname,'.',informationtype{i},'=information{i}']);
                end
            else
                eval(['obj.',ParentTagname,'.',informationtype,'=information']);
            end
              if isempty(information)
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
                    for i=1:length(informationtype);
                        information{i}=eval(['obj.',ParentTagname,'.',informationtype{i}]);
                    end
                    information=information';
                catch
                    informationtype=[];
                    information=[];
                end
            end
        end
    end
end