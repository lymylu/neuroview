classdef selectpanel < uix.VBox
    % select panel button group
    properties
        liststring=[];
        typestring=[];
        multiselect=[];
        mainpanel=[];
    end
    properties (SetObservable)
        blacklist 
        listpanel
        typepanel
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
             addParameter(p,'typestring',false);
             addParameter(p,'blacklist',NaN);
             addParameter(p,'multiselect','on');
             parse(p,varargin{:});
             varinput=fieldnames(p.Results);
             obj.Parent=parent;
             obj.Tag=tag;
           
             obj.liststring=liststring;  
             if size(liststring,2)>1
                 obj.liststring=obj.liststring';
             end
             for i = 1:length(varinput)
                eval(['obj.',varinput{i},'=p.Results.',varinput{i},';']);
             end
             sizelen=[];
             uicontrol('Parent',obj,'Style','Text','String',obj.Tag);
               sizelen=cat(1,sizelen,-1);
            if iscell(obj.typestring)
                if size(obj.typestring,2)>1
                    obj.typestring=obj.typestring';
                end
                obj.typepanel=uicontrol('Parent',obj,'Style','listbox','Tag',strcat('Type_',obj.Tag),'String',unique(obj.typestring),'Max',3,'Min',1);
                sizelen=cat(1,sizelen,-1);
                if ~isnan(p.Results.blacklist)
                    addblacklist=uicontrol('Parent',obj,'Style','pushbutton','String','invisible','Tag','add');
                    deleteblacklist=uicontrol('Parent',obj,'Style','pushbutton','String','visible','Tag','delete');
                    sizelen=cat(1,sizelen,[-1;-1]);
                end
                if isempty(p.Results.blacklist)
                    addblacklist=uicontrol('Parent',obj,'Style','pushbutton','String','invisible','Tag','add');
                    deleteblacklist=uicontrol('Parent',obj,'Style','pushbutton','String','visible','Tag','delete');
                    sizelen=cat(1,sizelen,[-1;-1]);
                end
            end
            switch obj.multiselect
            case 'on'
                obj.listpanel=uicontrol('Parent',obj,'Style','listbox','Tag',strcat('List_',obj.Tag),'String',obj.liststring,'Max',3,'Min',1);
            case 'off'
                obj.listpanel=uicontrol('Parent',obj,'Style','listbox','Tag',strcat('List_',obj.Tag),'String',obj.liststring,'Max',1,'Min',1);
            end
            sizelen=cat(1,sizelen,-8);
            obj.blacklist=false(size(obj.liststring));
            if ~isnan(p.Results.blacklist)
                obj.blacklist=p.Results.blacklist;
                set(addblacklist,'Callback',@(~,src) obj.add_blacklist(obj.listpanel));
                set(deleteblacklist,'Callback',@(~,src) obj.delete_blacklist());
            end
             if isempty(p.Results.blacklist)
                
                set(addblacklist,'Callback',@(~,src) obj.add_blacklist(obj.listpanel));
                set(deleteblacklist,'Callback',@(~,src) obj.delete_blacklist());
             end
            if iscell(obj.typestring)||obj.typestring
                addlistener(obj.typepanel,'Value','PostSet',@(~,src) obj.typeselect(obj.typepanel,obj.listpanel));
                set(obj.typepanel,'Value',1);
            end
            set(obj,'Heights',sizelen);
             try
                obj.typechangefcn();
             end
        end
        function getValue(obj,typetag,listtag,typevalue)
            for i=1:length(typetag)
                tmpobj=findobj(obj,'Tag',typetag);
                tmpobj.Value=typevalue(i);
                tmpobj=findobj(obj,'Tag',listtag);
                try
                  tmpobj.Value=1:length(tmpobj.String);
                catch
                  tmpobj.Value=1;
                end
            end
        end
        function typechangefcn(obj)
                  typeobj=findobj(obj,'Tag',['Type_',obj.Tag]);
                  value=typeobj.Value;
                  if value~=1
                    set(typeobj,'Value',1);
                    if numel(unique(obj.typestring))>1
                        set(typeobj,'Value',value);
                    end
                  else
                      set(typeobj,'Value',2);
                      set(typeobj,'Value',1);
                  end   
        end
        function obj=setdescription(obj,varargin)
            % modify the list and type description 
            % if typepanel is empty, only list is needed.
            newlist=varargin{1};
            if nargin>1
                newtype=varargin{2};
            end
            obj.liststring=newlist;
            set(obj.listpanel,'String',newlist);
            try
                obj.typestring=newtype;
                set(obj.typepanel,'String',unique(newtype));
            end
            obj.blacklist=false(size(obj.liststring));
            obj.typechangefcn();
        end
        function index=getIndex(obj)
                list=findobj(obj,'Tag',strcat('List_',obj.Tag));
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
            for i=1:length(obj.Tag)
                 tmpobj=findobj('Parent',obj,'Tag',['List_',obj.Tag]);
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
              for i=1:length(obj.Tag)
                   tmpobj=findobj('Parent',obj,'Tag',['List_',obj.Tag]);
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

