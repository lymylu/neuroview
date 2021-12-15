classdef selectpanel
   
    % select panel button group
    properties
        listdescription=[];
        listorigin=[];
        parent;
        typelistener;
        blacklistener;
        typepanel=[];
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
             obj.parent=parent;
             obj.typepanel=uix.Grid('Parent',obj.parent);
            for i=1:length(listtitle)     
                  uicontrol('Parent',obj.typepanel,'Style','Text','String',listtitle{i});
                  typeui=uicontrol('Parent',obj.typepanel,'Style','popupmenu','Tag',typetag{i});
                  addblacklist=uicontrol('Parent',obj.typepanel,'Style','pushbutton','String','invisible','Tag','add');
                  deleteblacklist=uicontrol('Parent',obj.typepanel,'Style','pushbutton','String','visible','Tag','delete');
                  tmpobj(i)=uicontrol('Parent',obj.typepanel,'Style','listbox','Tag',listtag{i},'Max',3,'Min',1);
                  set(obj.typepanel,'Heights',[-1,-1,-1,-1,-4]); 
                  set(typeui,'Value',1);
                  set(addblacklist,'Callback',@(~,src) obj.add_blacklist(tmpobj(i)));
                  set(deleteblacklist,'Callback',@(~,src) obj.delete_blacklist(tmpobj(i)));
            end
             tmpobj2=uicontrol('Parent',obj.parent,'Style','listbox','Tag','blacklist','String',[],'Visible','off');
              if ~isempty(blacklist)
                tmpobj2.String=blacklist;
              end
              set(obj.parent,'Heights',[-8,-1]);
          
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
              tmpobj2=findobj(obj.parent,'Tag','blacklist');
              for i=1:length(tmpobj2)
                  tmpobj2(i).String=blacklist;
              end
             
             try 
                 for i=1:length(obj.typelistener)
                    delete(obj.typelistener{i})
                 end
%                  delete(obj.blacklistener) 
             end
                for i=1:length(typetag)
                    tmptype=findobj(obj.parent,'Tag',typetag{i});
                    set(tmptype,'String',cat(1,{'All'},unique(typestring)),'Value',1);
                    obj.listdescription=typestring;
                    tmpobj(i)=findobj(obj.parent,'Tag',listtag{i});
                    set(tmpobj(i),'String',liststring,'Value',1);
                    obj.listorigin=liststring;
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
                tmpobj=findobj(obj.parent,'Tag',typetag{i});
                tmpobj.Value=typevalue(i);
                tmpobj=findobj(obj.parent,'Tag',listtag{i});
                try
                  tmpobj.Value=1:length(tmpobj.String);
                catch
                  tmpobj.Value=1;
                end
            end
        end
        function typechangefcn(obj)
              typeobj=findobj(obj.parent,'Style','popupmenu');
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
            obj.listdescription=description;
        end
    end
    methods (Access='private')
        function add_blacklist(obj,listobj)
            blacklistobj=findobj(obj.parent,'Tag','blacklist');
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
              blacklistobj=findobj(obj.parent,'Tag','blacklist');
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
            tmpobj=findobj('Parent',obj.typepanel,'Style','listbox');
         if ~isempty(tmpobj2.String)
            for i=1:length(tmpobj2.String)
                for j=1:length(tmpobj)
                    blackindex=cellfun(@(x) ~isempty(regexpi(x,['\<',tmpobj2.String{i},'\>'])),tmpobj(j).String,'UniformOutput',1);
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
              try
                obj.blacklistselect(varargin{3});
              end
        end
    end
end

