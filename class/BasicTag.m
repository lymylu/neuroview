classdef BasicTag < dynamicprops
    % basic functions of the tagged data, including the tag add, tag choose and tag modified
    properties
        fileTag
    end
    methods(Access='public')
         function output=getTaginfo(Neurodata,option,parent)
            % return the fileTags in the given field parent of multiple neurodata object.
            % option [Tagtype/ Tagtype:Tagvalue], return the list only tagname or tagname:tagvalue.
            output=[];
            if ~isempty(parent) % get the subfield names of parent.
            switch option
                case 'Tagname'    
                    for i=1:length(Neurodata)
                    tagtype=Neurodata(i).Tagcontent(parent);
                        for j=1:length(tagtype)
                            output=vertcat(output,tagtype(j));
                        end
                    end
                case 'Tagname:Tagvalue'
                    for i=1:length(Neurodata)
                        tagtype=Neurodata(i).Tagcontent(parent);
                        if ~isempty(tagtype)
                            for j=1:length(tagtype)
                                 [tagtype{j},tagvalue]=Neurodata(i).Tagcontent('fileTag',tagtype{j});
                                 output=vertcat(output,{[char(tagtype{j}),':',char(tagvalue{:})]});
                            end
                        end
                    end
                case 'Tagvalue'
                    for i=1:length(Neurodata)
                        tagtype=Neurodata(i).Tagcontent(parent);
                        if ~isempty(tagtype)
                            for j=1:length(tagtype)
                                 [tagtype{j},tagvalue]=Neurodata(i).Tagcontent('fileTag',tagtype{j});
                                 output=vertcat(output,{[char(tagvalue{:})]});
                            end
                        end
                    end
            end
            else % get other field/values except Datapath Filename and non-str fields
                for i=1:length(NeuroData)
                    varname=fieldnames(NeuroData(i));
                    for j=1:length(varname)
                        tmp=NeuroData(i);
                    end
                end
            end
                     
           if ~isempty(output)
                    output=unique(output);
           end
        end
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
                try
                    if isempty(fieldnames(eval(['obj.',ParentTagname])))
                    eval(['obj.',ParentTagname,'=[];']);
                end
            end
            end
        end
        function bool = Tagchoose(obj, ParentTagname, informationtype, information)
            for i=1:length(obj)
            if ~isempty(information)
            try
                if strcmp(eval(['obj(i).',ParentTagname,'.',informationtype]),information)
                    bool(i)=true;
                else
                    bool(i)=false;
                end
            catch
                bool(i) =false;
            end
            else
                 x=fieldnames(['obj(i).',ParentTagname]);
                    if ismember(x,informationtype)
                        bool(i)=true;
                    else
                        bool(i)=false;
                    end
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
        function data=struct(obj)
            % transfer data to struct
            for i=1:length(obj)
                varname=fieldnames(obj(i));
                for j=1:length(varname)
                    if ~isempty(eval(['obj(i).',varname{j}]))
                    try
                    eval(['data(i).',varname{j},'=struct(obj(i).',varname{j},');']);
                    catch
                         eval(['data(i).',varname{j},'=obj(i).',varname{j},';']);
                    end
                    end
                end
            end
        end
    end
    methods(Static)
       
    end
end