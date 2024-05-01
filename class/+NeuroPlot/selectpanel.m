classdef selectpanel
   
    % select panel button group
    properties
        listtitle=[];
        listtag=[];
        liststring=[];
        typetag=[];
        typestring=[];
        blacklist=[];
        typelistener;
        blacklistener;
        multiselect=[];
        mainpanel=[];% mainpanel
    end
    methods
        function obj=create(obj,varargin)
             % create the select panel for different result of NeuroMethod
             % such as event, channel, spike select information
             % include the type select, the relative content listbox and the blacklist
             % support multiple contentlistboxes shared the same blacklist
             % % varagin:
             % 'parent': the select panel (uipanel)
             % 'tag': the tag of content listbox(es) (cell matrix with str)
             % 'typestring': the name of type select popupmenu (s) (cell matrix with str)    
             % Content: the content listbox string 
             % blacklist: the blacklist of the content listbox (string);
             p=inputParser;
               varinput={'listtitle','listtag','liststring','blacklist','typelistener','typetag','typestring','multiselect'};
               default={[],[],[],[],[],[],[],'on'};
               for i=1:length(varinput)
                   addParameter(p,varinput{i},default{i});
               end
               parse(p,varargin{:});
             for i = 1:length(varinput)
                eval(['obj.',varinput{i},'=p.Results.',varinput{i},';']);
             end
             obj.mainpanel=uix.Grid();
          uicontrol('Parent',obj.mainpanel,'Style','Text','String',obj.listtitle{1});
          typeui=uicontrol('Parent',obj.mainpanel,'Style','popupmenu','Tag',obj.typetag{1});
          addblacklist=uicontrol('Parent',obj.mainpanel,'Style','pushbutton','String','invisible','Tag','add');
          deleteblacklist=uicontrol('Parent',obj.mainpanel,'Style','pushbutton','String','visible','Tag','delete');
          switch obj.multiselect
              case 'on'
                tmpobj1=uicontrol('Parent',obj.mainpanel,'Style','listbox','Tag',obj.listtag{1},'Max',3,'Min',1);
              case 'off'
                tmpobj1=uicontrol('Parent',obj.mainpanel,'Style','listbox','Tag',obj.listtag{1},'Max',1,'Min',1);
          end
          set(typeui,'Value',1);
          set(addblacklist,'Callback',@(~,src) obj.add_blacklist(tmpobj1));
          set(deleteblacklist,'Callback',@(~,src) obj.delete_blacklist(tmpobj1));
             tmpobj2=uicontrol('Parent',obj.mainpanel,'Style','listbox','Tag','blacklist','String',[],'Visible','off');
              set(obj.mainpanel,'Heights',[-1,-1,-1,-1,-4,-1]); 
             if ~isempty(obj.blacklist)
                tmpobj2.String=obj.blacklist;
             end
          
        end
        function obj=assign(obj,varargin)
              p = inputParser;
              varinput={'listtag','liststring','blacklist','typetag','typestring'};
              default={obj.listtag,obj.liststring,obj.blacklist,obj.typetag,obj.typestring};
               for i=1:length(varinput)
                   addParameter(p,varinput{i},default{i});
               end
               parse(p,varargin{:});
               for i=1:length(varinput)
                   eval(['obj.',varinput{i},'=p.Results.',varinput{i},';']);
               end
             try
              tmpobj2=findobj(obj.mainpanel,'Tag','blacklist');
              for i=1:length(tmpobj2)
                  tmpobj2(i).String=obj.blacklist;
              end
             end
             
             try 
                 for i=1:length(obj.typelistener)
                    delete(obj.typelistener{i})
                 end
%                  delete(obj.blacklistener) 
             end
                for i=1:length(obj.typetag)
                    tmptype=findobj(obj.mainpanel,'Tag',obj.typetag{i});
                    set(tmptype,'String',cat(1,{'All'},unique(obj.typestring)),'Value',1);
                    tmpobj(i)=findobj(obj.mainpanel,'Tag',obj.listtag{i});
                    set(tmpobj(i),'String',obj.liststring,'Value',1);
                    try
                        delete(obj.typelistener{i});
                    end
                    obj.typelistener{i}=addlistener(tmptype,'Value','PostSet',@(~,src) obj.typeselect(tmptype,tmpobj(i),tmpobj2));
                end
                if isempty(obj.blacklistener)
                    obj.blacklistener=addlistener(tmpobj,'String','PostSet',@(~,src) obj.blacklistselect(tmpobj2));
                end
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
              typeobj=findobj(obj.mainpanel,'Style','popupmenu');
              for i=1:length(typeobj)
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
        function obj=setdescription(obj,description)
            obj.typestring=description;
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
        function add_blacklist(obj,listobj)
            blacklistobj=findobj(obj.mainpanel,'Tag','blacklist');
            for i=1:length(listobj)
                if isempty(blacklistobj.String)
                    blacklistobj.String=listobj(i).String(listobj(i).Value);
                else
                    blacklistobj.String=cat(1,blacklistobj.String,listobj(i).String(listobj(i).Value));
                end
            end
            obj.blacklistselect(blacklistobj);
        end
        function delete_blacklist(obj,listobj)
              blacklistobj=findobj(obj.mainpanel,'Tag','blacklist');
              blacklist=blacklistobj.String;
               if class(blacklist)=='char'
                       blacklist={blacklist};
               end
              index=listdlg('PromptString','select the invisible info!','ListString',blacklist,'SelectionMode','multiple');
              blacklist(index)=[];
              for i=1:length(listobj)
                   blacklistobj.String=blacklist;
                   if size(blacklistobj.String,2)==0
                       blacklistobj.String=[];
                   end
              end
              obj.typechangefcn();
        end
       
        function blacklistselect(obj,tmpobj2)
            tmpobj=findobj('Parent',obj.mainpanel,'Style','listbox');
         if ~isempty(tmpobj2.String)
            for i=1:length(tmpobj2.String)
                for j=1:length(tmpobj)
                    if ~strcmp(tmpobj(j).Tag,'blacklist')
                    blackindex=cellfun(@(x) ~isempty(regexpi(x,['\<',tmpobj2.String{i},'\>'])),tmpobj(j).String,'UniformOutput',1);
                    tmpobj(j).String(blackindex)=[];
                    end
                end
            end
         end
        end
        function typeselect(obj,varargin)
              value=varargin{1}.Value;
              if value~=1
              type=varargin{1}.String;
              tmpstring=type{value};
              special={'+'};
              for i=1:length(special)
                  tmpstring=strrep(tmpstring,special{i},['\',special{i}]);
              end
              index=cellfun(@(x) ~isempty(regexpi(x,['\<',tmpstring,'\>'],'match')),obj.typestring,'UniformOutput',1);
              index=find(index==true);
              set(varargin{2},'String',obj.liststring(index),'Value',1);
              else
                  set(varargin{2},'String',obj.liststring,'Value',1);
              end
              try
                obj.blacklistselect(varargin{3});
              end
        end
    end
end

