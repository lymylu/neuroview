classdef BasicTag < dynamicprops
    %% 标签化数据的一些基本功能，包括添加子标签，根据标签名返回符合值和内容。
    properties
    end
    methods(Access='public')
        function obj = Taginfo(obj, ParentTagname, informationtype, information)
            % 当标签：值对应的时候，为添加，当标签值为空时，删除该标签。标签和值为cell数组时，一次添加多个。
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