classdef BasicTag < dynamicprops
    %BASICTAG Core basic functions of the tagged data, including several tag operations
    % almost all class obj in neuroview are BasicTag and could be operated in similar ways.
    % See also: NeuroData, NeuroResult, EVTData, LFPData, SPKData, VideoData, functions in /methodlist
    properties
        fileTag % the field contains customized tags
    end
    methods(Access='public')
        function output=getTaginfo(obj,option,parent)
            % return the fileTags in the given field parent of multiple tagged object.
            % option: [Tagtype/ Tagtype:Tagvalue], return the list only tagname or tagname:tagvalue (if possible).
            % parent: the field name contains the fileTag
            % output = getTaginfo(neurodata,'Tagtype','fileTag') return all Tagtype name in the fileTag of neurodata objects.
            % output = getTaginfo(neurodata,'Tagtype:Tagvalue','SPKData.fileTag') return all Tagtype name and their Tagvalue in the fileTag of SPKData in the neurodata objects.
            output=[];
            switch option
                case 'Tagname'    
                    for i=1:length(obj)
                    tagtype=obj(i).Tagcontent(parent);
                        for j=1:length(tagtype)
                            output=vertcat(output,tagtype(j));
                        end
                    end
                case 'Tagname:Tagvalue'
                    for i=1:length(obj)
                        tagtype=obj(i).Tagcontent(parent);
                        if ~isempty(tagtype)
                            for j=1:length(tagtype)
                                 [tagtype{j},tagvalue]=obj(i).Tagcontent(parent,tagtype{j});
                                 try
                                    output=vertcat(output,{[char(tagtype{j}),':',char(tagvalue{:})]});
                                 catch
                                     disp(['field ',parent,'.',tagtype{j},' could not be presented by chars, please visit directly.']);
                                 end
                            end
                        end
                    end
                case 'Tagvalue'
                    for i=1:length(obj)
                        tagtype=obj(i).Tagcontent(parent);
                        if ~isempty(tagtype)
                            for j=1:length(tagtype)
                                 [tagtype{j},tagvalue]=obj(i).Tagcontent(parent,tagtype{j});
                                 try
                                    output=vertcat(output,{[char(tagvalue{:})]});
                                 catch
                                     disp(['field ',parent,'.',tagtype{j},' could not be presented by chars, please visit directly.']);
                                 end  
                            end
                        end
                    end
            end                     
           if ~isempty(output)
                    output=unique(output);
           end
        end
        function obj = Taginfo(obj, ParentTagname, informationtype, information)
           %  change the fieldnames ParentTagname in a BasicTag object
           %  when informationtype&information is exist, add informationtype:information as a new tag to obj.[ParentTagname].(ParentTagname is often 'fileTag')
           %  when information is empty, delete the informationtype.
           %  when informationtype&information are cells, add multiple of them
           %  obj = Taginfo(obj,'fileTag',informationtype,information)
           %  obj = Taginfo(obj,'fileTag',{informationtype1,informationtype2},{information1,information2})
            if iscell(informationtype) && ~isempty(information)
                for i=1:length(informationtype)
                    eval(['obj.',ParentTagname,'.',informationtype{i},'=information{i};']);
                end
            elseif ~isempty(information)
                eval(['obj.',ParentTagname,'.',informationtype,'=information;']);
            elseif isempty(information)
                try
                eval(['obj.',ParentTagname,'=rmfield(obj.',ParentTagname,',informationtype);']);  
                end
                try
                    if isempty(fieldnames(eval(['obj.',ParentTagname])))
                    eval(['obj.',ParentTagname,'=[];']);
                    end
                end
            end
        end
        function bool = Tagchoose(obj, ParentTagname, tagname, tagvalue)
            % return a list contains true/false if the Basic objects have the tagname:tagvalue.
            % if tagvalue is empty return true/false if the obj has the tagname
            % bool = Tagchoose(obj,'fileTag',tagname,tagvalue)
            % bool = Tagchoose(obj,'fileTag',tagname,[]);
            for i=1:length(obj)
            if ~isempty(tagvalue)
            try
                if strcmp(eval(['obj(i).',ParentTagname,'.',tagname]),tagvalue)
                    bool(i)=true;
                else
                    bool(i)=false;
                end
            catch
                bool(i) =false;
            end
            else
                 x=fieldnames(['obj(i).',ParentTagname]);
                    if ismember(x,tagname)
                        bool(i)=true;
                    else
                        bool(i)=false;
                    end
            end
            end
        end
        function [objnew, bool] = Filechoose(obj,filetag)
            % choose the sub objects which belonging to the given filetag
            %->fileTag inputs
            % if ischar, choose the subject or Data object with unique file tag
            % if isnumeric choose the subject or Data object with numeric index
            % is iscell, choose the subject or Data object with muliple file tag intersect mode
            % the last cell of input is 'intersect' or 'union' to defined the interact or union from file tags.
            % [objnew,bool]=Filechoose(obj,[1,2]); choose the first and second file in the object,
            % [objnew,bool]=Filechoose(obj,1);
            % See also:BASICTAG.TAGCHOOSE
            if ~isempty(filetag)
            if ischar(filetag)
                info=regexpi(filetag,':','split');
                bool=obj.Tagchoose('fileTag',info{1},info{2});
                objnew=obj(bool);
            elseif isnumeric(filetag)
                try
                    objnew=obj(filetag);
                    bool=filetag;
                catch
                    objnew=[];
                end
            elseif iscell(filetag)
                for i=1:length(filetag)-1
                    info=regexpi(filetag{i},':','split');
                    booltmp=obj.Tagchoose('fileTag',info{1},info{2});
                    if i==1
                        bool=booltmp;
                    else 
                        switch filetag{end}
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
        end
        function filelist = listfile(obj)
            % list all filename from obj
            filelist=[];
            for i=1:length(obj)
                filelist=cat(1,filelist,{obj(i).Filename});
            end
        end
        function [tagname, tagvalue] = Tagcontent(obj, ParentTagname, tagname)
            % search the information type or information value
            % return the given tagname/tagvalue
            % if tagname is empty, return all tagname/tagvalue in the obj.ParentTagname
            % [tagname, tagvalue]=Tagcontent(obj,ParentTagname,tagname)
            % [tagname, tagvalue]=Tagcontent(obj,ParentTagname,[])
            if ~isempty(tagname)
                try
                tagvalue={eval(['obj.',ParentTagname,'.',tagname])};
                catch
                tagname=[];
                tagvalue=[];
                end
            else % return all tagname/tagvalue;
                try
                    tagname=eval(['fieldnames(obj.',ParentTagname,')']);
                    for i=1:length(tagname)
                        tagvalue{i}=eval(['obj.',ParentTagname,'.',tagname{i}]);
                    end
                    tagvalue=tagvalue';
                catch
                    tagname=[];
                    tagvalue=[];
                end
            end
        end
        function obj =Taglistinfo(obj,ParentTagname,informationtype,information,index)
            % in this mode, the obj.ParentTagname is used for the tags of an array, the length(index) defines the array length
            % if add/remove the informationtype in the ParentTagname, it must be add an array
            % to keep all the fieldnames in ParentTagname share same length, other undefined (index==0) are nans.
            % delete the part of information could not delete the field
            % informationtype unless all the parts in the information type were deleted.
            % this mode is used for spike classification. (not optimized yet, may be replaced by table class)
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
        function bool = Taglistchoose(obj,ParentTagname,informationtype,information,index)
            % return a list contains true/false if the Basic objects have the tagname:tagvalue for Taglist mode (for spike classification).
            % not work yet
        end
        function data=struct(obj)
            % transfer obj to struct
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
        function data=clone(obj)
            % clone the obj to a new Basic Tag obj, thus the variable change in new object could not affect the original one.
            for i=1:length(obj)
                data(i)=eval([class(obj(i)),'()']);
                varname=fieldnames(obj(i));
                for j=1:length(varname)
                    try
                        addprop(data(i),varname{j});
                    end
                    try
                        eval(['data(i).',varname{j},'=obj(i).',varname{j},'.clone;']);
                    catch
                        eval(['data(i).',varname{j},'=obj(i).',varname{j},';']);
                    end
                end
            end
        end
        function objnew=slice(obj,index,varname,vardim)
            % select the index from choosen varname at the given dimension, generate a new BasicTag object
            objnew=obj.clone();
            for i=1:length(varname)
                tmp=eval(['objnew.',varname{i}]);
                dimop=repmat(':,',[1,ndims(tmp)]);
                startindex=regexpi(dimop,':');
                dimop=strcat(dimop(1:startindex(vardim(i))-1),'index',dimop(startindex(vardim(i))+1:end));
                try
                eval(['objnew.',varname{i},'=objnew.',varname{i},'(',dimop(1:end-1),');']);
                catch
                    error(['invalid index in ',varname{i},' at ',num2str(vardim(i))]);
                end
            end
        end
        
    end
    methods(Static)
        
    end
end