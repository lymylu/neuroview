classdef selectpanel < handle
    % select panel button group
    properties
        tag=[];
        liststring=[];
        typestring=[];
        multiselect=[];
        parent=[];
        mainpanel=[];
    end
    properties (SetObservable)
        blacklist 
        listpanel
        typepanel
        synctag; % could sync several selectpanel to control different data (if these data share same typestring and/or liststring);
    end
    methods
        function obj=create(obj,parent,tag,liststring,varargin)
             % create the select panel for different result of NeuroMethod
             % such as event, channel, spike select information
             % include the type select, the relative content listbox and the blacklist
             % support multiple contentlistboxes shared the same blacklist
             % % varagin:
             % 'parent': the select panel (uipanel)
             % 'tag': the tag of content listbox(es) (cell matrix with str)
             % 'typestring': the name of type select popupmenu (s) (cell matrix with str)    
             % listtitle & liststring: the name of selectpanel and the content in listbox string (required)
             % blacklist: the blacklist of the content listbox (string);
             p=inputParser;
             % if more than one tag, that means there are several listpanel share same type management.
             addParameter(p,'typestring',[]);
             addParameter(p,'blacklist',[]);
             addParameter(p,'multiselect','on');
             parse(p,varargin{:});
             varinput=fieldnames(p.Results);
             obj.parent=parent;
             obj.tag=tag;
             obj.liststring=liststring;
             for i = 1:length(varinput)
                eval(['obj.',varinput{i},'=p.Results.',varinput{i},';']);
             end
             if ~isempty(obj.parent)
                obj.mainpanel=uix.Grid('Parent',obj.parent);
             else
                 obj.mainpanel=uix.Grid();
             end         
             for i=1:length(obj.tag)
                   uicontrol('Parent',obj.mainpanel,'Style','Text','String',obj.tag{i});
                if ~isempty(obj.typestring)
                    obj.typepanel{i}=uicontrol('Parent',obj.mainpanel,'Style','listbox','Tag',['Type_',obj.tag{i}],'String',unique(obj.typestring),'Max',3,'Min',1);
                    if ~isempty(p.Results.blacklist)
                        addblacklist=uicontrol('Parent',obj.mainpanel,'Style','pushbutton','String','invisible','Tag','add');
                        deleteblacklist=uicontrol('Parent',obj.mainpanel,'Style','pushbutton','String','visible','Tag','delete');
                    end
                end
                switch obj.multiselect
                case 'on'
                    obj.listpanel{i}=uicontrol('Parent',obj.mainpanel,'Style','listbox','Tag',['List_',obj.tag{i}],'String',obj.liststring,'Max',3,'Min',1);
                case 'off'
                    obj.listpanel{i}=uicontrol('Parent',obj.mainpanel,'Style','listbox','Tag',['List_',obj.tag{i}],'String',obj.liststring,'Max',1,'Min',1);
                end
                obj.blacklist=false(size(obj.liststring));
                if ~isempty(p.Results.blacklist)
                    set(addblacklist,'Callback',@(~,src) obj.add_blacklist(obj.listpanel{i}));
                    set(deleteblacklist,'Callback',@(~,src) obj.delete_blacklist());
                end
                if ~isempty(obj.typestring)
                    set(obj.typepanel{i},'Callback',@(~,src) obj.typeselect(obj.typepanel{i},obj.listpanel{i}));
                    set(obj.typepanel{i},'Value',1);
                end
             end
             if ~isempty(p.Results.typestring)&&~isempty(p.Results.blacklist)
                set(obj.mainpanel,'Heights',[-1,-1,-1,-1,-8]);
             elseif ~isempty(p.Results.blacklist)
                 set(obj.mainpanel,'Heights',[-1,-1,-1,-8]);
             elseif ~isempty(p.Results.typestring)
                 set(obj.mainpanel,'Heights',[-1,-1,-8]);
             else
                 set(obj.mainpanel,'Heights',[-1,-8]);
             end
                set(obj.mainpanel,'Widths',-1*ones(length(obj.tag),1));
            obj.typechangefcn();
        end
        function getValue(obj,typetag,listtag,typevalue)
            for i=1:length(typetag)
                tmpobj=findobj(obj.mainpanel,'Tag',typetag{i});
                tmpobj.Value=typevalue(i);
                tmpobj=findobj(obj.mainpanel,'Tag',listtag{i});
                try
                  tmpobj.Value=1:length(tmpobj.String);
                catch
                  tmpobj.Value=1;
                end
            end
        end
        function typechangefcn(obj)
              for i=1:length(obj.tag)
                  typeobj=findobj(obj.mainpanel,'Tag',['Type_',obj.tag{i}]);
                  value=typeobj.Value;
                  if value~=1
                    set(typeobj,'Value',1);
                    set(typeobj,'Value',value);
                  else
                      set(typeobj,'Value',2);
                      set(typeobj,'Value',1);
                  end
              end     
        end
        function obj=setdescription(obj,varargin)
            % modify the list and type description 
            % if typepanel is empty, only list is needed.
            newlist=varargin{1};
            if nargin>1
                newtype=varargin{2};
            end  
            for i=1:length(obj.tag)
                obj.liststring=newlist;
                set(obj.listpanel{i},'String',newlist);
                try
                    obj.typestring=newtype;
                    set(obj.typepanel{i},'String',unique(newtype));
                end
            end
            obj.blacklist=false(size(obj.liststring));
            obj.typechangefcn();
        end
        function index=getIndex(obj,listtag)
                list=findobj(obj.mainpanel,'Tag',listtag);
                indexstring=list.String(list.Value);
                for i=1:length(indexstring)
                    index(i,:)=cellfun(@(x) ~isempty(regexpi(x,['\<',indexstring{i},'\>'],'match')),obj.liststring,'UniformOutput',1);
                end
                index=logical(sum(index,1));
        end
    end
    methods (Access='private')
        function add_blacklist(obj,listpanel)
            blacktrial=listpanel.String(listpanel.Value);
            for i=1:length(blacktrial)
                blackindex=cellfun(@(x) ~isempty(regexpi(x,['\<',blacktrial{i},'\>'])),obj.liststring,'UniformOutput',1);
                obj.blacklist=obj.blacklist|blackindex; 
            end
            for i=1:length(obj.tag)
                 tmpobj=findobj('Parent',obj.mainpanel,'Tag',['List_',obj.tag{i}]);
                 tmpobj.String=obj.liststring(~obj.blacklist);
            end
            obj.typechangefcn();
        end
        function delete_blacklist(obj)
              index=listdlg('PromptString','select the invisible info!','ListString',obj.liststring(obj.blacklist),'SelectionMode','multiple');
              tmpblack=obj.liststring(obj.blacklist);
              reversetrial=tmpblack(index);
              for i=1:length(reversetrial)
                   reverseindex=cellfun(@(x) ~isempty(regexpi(x,['\<',reversetrial{i},'\>'])),obj.liststring,'UniformOutput',1);
                   obj.blacklist(reverseindex)=false;
              end
              for i=1:length(obj.tag)
                   tmpobj=findobj('Parent',obj.mainpanel,'Tag',['List_',obj.tag{i}]);
                   tmpobj.String=obj.liststring(~obj.blacklist);
              end
              obj.typechangefcn();
        end
        function typeselect(obj,typepanel,listpanel)
              value=typepanel.Value;  
              if size(obj.blacklist,2)>1
                  obj.blacklist=obj.blacklist';
              end
              type=typepanel.String;
              tmpstring=type(value);
              index=false(size(obj.liststring));
              if size(index,2)>1
                  index=index';
              end
              for c=1:length(tmpstring)
                  special={'+'};
                  for i=1:length(special)
                      substring=strrep(tmpstring{c},special{i},['\',special{i}]);
                  end
                  index=index|cellfun(@(x) ~isempty(regexpi(x,['\<',substring,'\>'],'match')),obj.typestring,'UniformOutput',1);
              end
                set(listpanel,'String',obj.liststring(index&~obj.blacklist),'Value',1);
        end
    end
end

