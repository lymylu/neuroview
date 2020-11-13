classdef selectpanel 
    % select panel button group
    properties
        listdescription=[];
        listorigin=[];
        parent;
        typelistener;
        blacklistener;
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
               varinput={'listtitle','listtag','liststring','parent','blacklist','typelistener','typetag','typestring'};
               default={[],[],[],[],[],[],[],[],[]};
               for i=1:length(varinput)
                   eval([varinput{i},'=default{i};']);
               end
             for i = 1:2:length(varargin)
                     varindex=find(ismember(varinput,lower(varargin{i}))==1);
                     eval([varinput{varindex},'=varargin{i+1};']);
             end
            for i=1:length(listtitle)
                  obj.parent=parent;
                  uicontrol('Parent',obj.parent,'Style','Text','String',listtitle{i});
                  typeui=uicontrol('Parent',obj.parent,'Style','popupmenu','Tag',typetag{i});
                  addblacklist=uicontrol('Parent',obj.parent,'Style','pushbutton','String','invisible','Tag','add');
                  deleteblacklist=uicontrol('Parent',obj.parent,'Style','pushbutton','String','visible','Tag','delete');
                  tmpobj(i)=uicontrol('Parent',obj.parent,'Style','listbox','Tag',listtag{i},'Max',3,'Min',1);
                  tmpobj2=uicontrol('Parent',obj.parent,'Style','listbox','Tag','blacklist','String',[],'Visible','off');
                  if ~isempty(blacklist)
                      tmpobj2.String=blacklist;
                  end
                  set(obj.parent,'Heights',[-1,-1,-1,-1,-4,-1]); 
                  set(typeui,'Value',1);
            end
            set(addblacklist,'Callback',@(~,src) obj.add_blacklist(tmpobj));
            set(deleteblacklist,'Callback',@(~,src) obj.delete_blacklist(tmpobj));
        end
        function obj=assign(obj,varargin)
              varinput={'listtag','liststring','blacklist','typetag','typestring'};
              default={[],[],[],[],[]};
               for i=1:length(varinput)
                   eval([varinput{i},'=default{i};']);
               end
             for i = 1:2:length(varargin)
                     varindex=find(ismember(varinput,lower(varargin{i}))==1);
                     eval([varinput{varindex},'=varargin{i+1};']);
             end
              tmpobj2=findobj(gcf,'Parent',obj.parent,'Tag','blacklist');
              for i=1:length(tmpobj2)
                  tmpobj2(i).String=blacklist;
              end
             try 
                 for i=1:length(obj.typelistener)
                    delete(obj.typelistener{i})
                 end
                 delete(obj.blacklistener) 
             end
                for i=1:length(typetag)
                    tmptype=findobj(gcf,'Parent',obj.parent,'Tag',typetag{i});
                    set(tmptype,'String',cat(1,{'All'},unique(typestring)));
                    obj.listdescription=typestring;
                    tmpobj(i)=findobj(gcf,'Parent',obj.parent,'Tag',listtag{i});
                    set(tmpobj(i),'String',liststring);
                    obj.listorigin=liststring;
                    obj.typelistener{i}=addlistener(tmptype,'Value','PostSet',@(~,src) obj.typeselect(tmptype,tmpobj(i)));
                end
                obj.blacklistener=addlistener(tmpobj,'String','PostSet',@(~,src) obj.blacklistselect(tmpobj,tmpobj2)); 
                obj.typechangefcn();
        end
    end
    methods (Access='private')
        function add_blacklist(obj,listobj)
            blacklistobj=findobj(gcf,'Parent',obj.parent,'Tag','blacklist');
            for i=1:length(blacklistobj)
                if isempty(blacklistobj(i).String)
                    blacklistobj(i).String=listobj(i).String(listobj(i).Value);
                else
                    blacklistobj(i).String=cat(1,blacklistobj(i).String,listobj.String(listobj(i).Value));
                end
            end
            obj.blacklistselect(listobj,blacklistobj(1));
        end
        function delete_blacklist(obj,listobj)
              blacklistobj=findobj(gcf,'Parent',obj.parent,'Tag','blacklist');
              blacklist=blacklistobj(1).String;
               if class(blacklist)=='char'
                       blacklist={blacklist};
               end
              index=listdlg('PromptString','select the invisible info!','ListString',blacklist,'SelectionMode','multiple');
              blacklist(index)=[];
              for i=1:length(blacklistobj)
                   blacklistobj(i).String=blacklist;
                   if size(blacklistobj(i).String,2)==0
                       blacklistobj(i).String=[];
                   end
              end
              obj.typechangefcn();
        end
        function typechangefcn(obj)
              typeobj=findobj(gcf,'Parent',obj.parent,'Style','popupmenu');
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
        function blacklistselect(obj,tmpobj,tmpobj2)
         if ~isempty(tmpobj2.String)
            for i=1:length(tmpobj2.String)
                for j=1:length(tmpobj)
                    blackindex=cellfun(@(x) ~isempty(regexpi(x,['\<',tmpobj2.String{i},'\>'])),tmpobj.String,'UniformOutput',1);
                    tmpobj(j).String(blackindex)=[];
                end
            end
         end
        end
        function typeselect(obj,varargin)
              value=varargin{1}.Value;
              if value~=1
              type=varargin{1}.String;
              index=cellfun(@(x) ~isempty(regexpi(x,['\<',type{value},'\>'],'match')),obj.listdescription,'UniformOutput',1);
              index=find(index==true);
              set(varargin{2},'String',obj.listorigin(index),'Value',1);
              else
                  set(varargin{2},'String',obj.listorigin,'Value',1);
              end
        end
    end
end

