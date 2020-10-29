classdef NeuroPlot <dynamicprops
    % generate the GUI for different NeuroMethod Obj
    % the Results could be selected and showed from different events and channels
    properties (Access='protected')
        Methodname % e.g. FiringRate PerieventHistogram Spectrogram, PowerSpectralDensity...
        NP=figure();% NeuroPlot Main Figure
        LeftPanel
        RightPanel
        ResultOutputPanel
        ResultSelectPanel
        FigurePanel
        ConditionPanel
    end
    methods (Access='public')
         function obj=GenerateObjects(obj)
            % create the command region and the figure region
            % the mainwindow contains several functional Panels, including
            % SaveFigurePanel, SaveResultPanel, ResultSelectPanel, FigurePanel, and ConditionPanel
            % SaveFigurePanel: Save the current plot Figure
            % SaveResultPanel: Save the current selected averaged Result & Save the multiple averaged Result
            % ResultSelectPanel: Select the Result from the given conditions (different method defined)
            % FigurePanel: Show the result figure from the given method (different method defined)
            % ConditionPanel: Show the current log of data, multidatacontroller ......
            gcf=figure();
            MainBox=uix.HBoxFlex('Parent',gcf,'Spacing',4); 
            obj.LeftPanel=uix.VBoxFlex('Parent',MainBox,'Padding',5);
            obj.RightPanel=uix.VBoxFlex('Parent',MainBox,'Padding',5);
            set(MainBox,'Width',[-1,-2]); 
            % SaveFigurePanel, SaveResultPanel, ResultSelectPanel are on the Left, FigurePanel and ConditionPanel are on the right.
            % Details of the command region.
            obj=obj.GenerateSaveFigurePanel();
            obj=obj.GenerateSaveResultPanel();
            obj=obj.GenerateConditionPanel(); 
            obj=obj.GenerateResultSelectPanel();
            obj=obj.GenerateFigurePanel();
            set(obj.LeftPanel,'Heights',[-1,-1,-3]);
            set(obj.RightPanel,'Heights',[-1,-9]);
         end
         % % % % % % % %
         function obj=GenerateSaveResultPanel(obj)
            obj.ResultOutputPanel=uix.Panel('Parent',obj.LeftPanel,'Padding',5,'Title','SaveResult');
            ResultOutputBox=uix.VBox('Parent',obj.ResultOutputPanel,'Padding',0);
            uicontrol('Style','pushbutton','Parent',ResultOutputBox,'String','Average and Plot result','Tag','Plotresult');
            uicontrol('Style','pushbutton','Parent',ResultOutputBox,'String','Save the selected averaged result','Tag','Resultsave');
            uicontrol('Style','edit','Parent',ResultOutputBox,'String','Save Name','Tag','Savename');
         end
         function obj=GenerateResultSelectPanel(obj)
              obj.ResultSelectPanel=uix.Panel('Parent',obj.LeftPanel,'Padding',5,'Title','SelectInfo');
              % different method defined
         end
         function obj=GenerateFigurePanel(obj)
              obj.FigurePanel=uix.VBox('Parent',obj.RightPanel,'Padding',0);
              % different method defined
         end
         function obj=GenerateSaveFigurePanel(obj)
            % define the FigureOutputPanel
            FigureOutputPanel=uix.Panel('Parent',obj.LeftPanel,'Padding',5,'Title','SaveFigure');
            FigureOutputBox=uix.VBox('Parent',FigureOutputPanel,'Padding',0);
            uicontrol('Style','pushbutton','Parent',FigureOutputBox,'String','Save current Figure','Tag','Savefig','Callback', @(~,~) obj.Savefigfcn);
            uicontrol('Style','pushbutton','Parent',FigureOutputBox,'String','Open the Figure in new window','Tag','Openfig', 'Callback', @(~,~) obj.Openfigfcn);
         end
         function obj=GenerateConditionPanel(obj)
             obj.ConditionPanel=uix.VBox('Parent',obj.RightPanel,'Padding',0);
              uicontrol('Parent',obj.ConditionPanel,'Style','text','Tag','Loginfo');
             % multiple select mode
             MultiplePanel=uix.HBox('Parent',obj.ConditionPanel,'Padding',0);
             uicontrol('Parent',MultiplePanel,'Style','popupmenu','Tag','Matfilename','Value',1);
             uicontrol('Parent',MultiplePanel,'Style','pushbutton','String','load Select info','Tag','Loadselectinfo');
             uicontrol('Parent',MultiplePanel,'Style','checkbox','String','hold on the select result','Tag','Holdonresult');
             uicontrol('Parent',MultiplePanel,'Style','pushbutton','String','averageAlldata','Tag','Averagealldata');
             set(obj.ConditionPanel,'Height',[-1,-1]);
         end
         function commandcontrol(obj,varargin)
             % create the control panel for different types of figure to
             % show the xlim ylim and clim for the figure
             plottype=[];
             parent=[];
             linkedaxes=[];
             command=[];
             for i = 1:2:length(varargin)
                 switch lower(varargin{i})
                     case 'plottype'
                         plottype=varargin{i+1};
                     case 'parent'
                         parent=varargin{i+1};
                     case 'linkedaxes'
                         linkedaxes=varargin{i+1};
                     case 'command'
                         command=varargin{i+1};
                 end
             end
            if strcmp(command,'create')
             switch plottype
                 case 'imagesc'
                     uicontrol('Style','text','Parent',parent,'String','XLim');
                     uicontrol('Style','edit','Parent',parent,'String',[],'Tag','XLim');
                     uicontrol('Style','text','Parent',parent,'String','YLim');
                     uicontrol('Style','edit','Parent',parent,'String',[],'Tag','YLim');
                     uicontrol('Style','text','Parent',parent,'String','CLim');
                     uicontrol('Style','edit','Parent',parent,'String',[],'Tag','CLim');
                 case 'plot'
                     uicontrol('Style','text','Parent',parent,'String','XLim');
                     uicontrol('Style','edit','Parent',parent,'String',[],'Tag','XLim');
                     uicontrol('Style','text','Parent',parent,'String','YLim');
                     uicontrol('Style','edit','Parent',parent,'String',[],'Tag','YLim');
                     uix.Empty('Parent',parent);
                     uix.Empty('Parent',parent);
                 case 'raster'
                     uicontrol('Style','text','Parent',parent,'String','XLim');
                     uicontrol('Style','edit','Parent',parent,'String',[],'Tag','XLim');
                     uix.Empty('Parent',parent);
                     uix.Empty('Parent',parent);
                     uix.Empty('Parent',parent);
                     uix.Empty('Parent',parent);
                     uix.Empty('Parent',parent);
             end    
                 tmpui=uicontrol('Style','pushbutton','Parent',parent,'String','Replot');
                 if ~isempty(linkedaxes)
                    set(tmpui,'Callback',@(~,varargin) obj.Replot(parent,linkedaxes))
                 end
             elseif strcmp(command,'assign')
                tmpobj=findobj(gcf,'Parent',parent,'Style','edit');
                figaxes=findobj(gcf,'Parent',linkedaxes);
                 for i=1:length(tmpobj)
                     tmpobj(i).String=[];
                    eval(['tmpobj(i).String=num2str(figaxes.',tmpobj(i).Tag,');']);
                 end
            elseif strcmp(command,'changelinkedaxes')
                tmpobj=findobj(gcf,'Parent',parent,'Style','pushbutton');
                set(tmpobj,'Callback',@(~,varargin) obj.Replot(parent,linkedaxes));
             end                      
         end
         function selectpanel(obj,varargin)
             % create the select panel for different result of NeuroMethod
             % such as event, channel, spike select information
             % include the type select and the content select
               tagstring=[];
               tag=[];
               parent=[];
               command=[];
               indexassign=[];
               typeassign=[];
               blacklist=[];
               typelistener=[];
               typeTag=[];        
             for i = 1:2:length(varargin)
                 switch lower(varargin{i})
                     case 'tag'
                         tag=varargin{i+1};
                     case 'tagstring'
                         tagstring=varargin{i+1};
                     case 'parent'
                         parent=varargin{i+1};
                     case 'command'
                         command=varargin{i+1};
                     case 'indexassign'
                         indexassign=varargin{i+1};
                     case 'blacklist'
                         blacklist=varargin{i+1};
                     case 'typelistener'
                         typelistener=varargin{i+1};
                     case 'typetag'
                         typeTag=varargin{i+1};
                     case 'typeassign'
                         typeassign=varargin{i+1};
                 end
              end
            switch command   
                case 'create'
                    if ~isempty(tagstring)
                        uicontrol('Parent',parent,'Style','text','String',tagstring);
                    else
                        uicontrol('Parent',parent,'Style','text','String',tag);
                    end
                  typeui=uicontrol('Parent',parent,'Style','popupmenu','Tag',typeTag,'String',{'All'});
                  addlistener(typeui,'Value','PostSet',typelistener);
                  uicontrol('Parent',parent,'Style','pushbutton','String','invisible','Tag','add','Callback',@(~,~) obj.selectpanel('Parent',parent,'Tag',tag,'command','add'));
                  uicontrol('Parent',parent,'Style','pushbutton','String','visible','Tag','delete','Callback',@(~,~) obj.selectpanel('Parent',parent,'Tag',tag,'command','delete'));
                  tmpobj=uicontrol('Parent',parent,'Style','listbox','Tag',tag,'Max',3,'Min',1);
                  tmpobj2=uicontrol('Parent',parent,'Style','listbox','Tag','blacklist','String',[],'Visible','off');
                  addlistener(tmpobj,'String','PostSet',@(~,src) obj.selectpanel('Tag',tag,'Parent',parent,'command','assign','indexassign',tmpobj.String,'blacklist',tmpobj2.String));  
                  set(parent,'Heights',[-1,-1,-1,-1,-4,-1]);
                case 'assign'
                  tmpobj=findobj(gcf,'Parent',parent,'Tag',tag);
                  tmpobj2=findobj(gcf,'Parent',parent,'Tag','blacklist');
                  if ~isempty(blacklist)
                    indextmp=cellfun(@(x) cellfun(@(y) ~isempty(regexpi(y,['\<',x,'\>'],'match')),indexassign,'UniformOutput',1),blacklist,'UniformOutput',0);
                    index=[];
                      for j=1:length(indextmp)
                           index=vertcat(index,find(indextmp{j}==1));
                      end
                      indexassign(index)=[];
                      tmpobj2.String=blacklist;
                  end
                  tmpobj.String=indexassign;
                  try 
                      tmpobj.Value=1;
                  end
                  if ~isempty(typeassign)
                      tmpobj3=findobj(gcf,'Parent',parent,'Style','popupmenu');
                      set(tmpobj3,'String',cat(1,'All',unique(typeassign)),'Value',1);
                  end
                case 'add'
                    tmpobj=findobj(gcf,'Parent',parent,'Tag',tag);
                    tmpobj2=findobj(gcf,'Parent',parent,'Tag','blacklist');
                    blacklist=tmpobj2.String;
                    tmpstring=tmpobj.String(tmpobj.Value);
                    if class(tmpstring)=='char'
                        tmpstring={tmpstring};
                    end
                    blacklist=cat(1,blacklist,tmpstring);
                    tmpobj2.String=blacklist;
                    obj.selectpanel('Parent',parent,'Tag',tag,'command','assign','indexassign',tmpobj.String,'blacklist',blacklist);
                case 'delete'
                    tmpobj2=findobj(gcf,'Parent',parent,'Tag','blacklist');
                    blacklist=tmpobj2.String;   
                    if class(blacklist)=='char';
                        blacklist={blacklist};
                    end
                    index=listdlg('PromptString','select the invisible info!','ListString',blacklist,'SelectionMode','multiple');
                    blacklist(index)=[];
                    tmpobj2.String=blacklist;
            end
         end
         function Msg(obj,msg,type)
             tmpobj=findobj('Tag','Loginfo');
             switch type
                 case 'replace'
                     tmpobj.String=msg;
                 case 'add'
                     tmpobj.String=[tmpobj.String,msg];
             end
         end
         function msg=loadblacklist(obj)
             global Blacklist 
             [f,p]=uigetfile('Blacklist.mat');
             blacklist=matfile([p,f]);
             tmpobj=findobj(gcf,'Tag','Matfilename');
             msg=[];
             for i=1:length(Blacklist)
                 [~,matname]=fileparts(tmpobj.String{i});           
                   try  
                     tmpblack=eval(['blacklist.',matname,';']);
                     namelist=intersect(fieldnames(tmpblack),fieldnames(Blacklist));
                     for j=1:length(namelist)
                        eval(['Blacklist(i).',namelist{j},'=tmpblack.',namelist{j},';']);
                     end
                     msg=[msg,' ',matname];
                     end
             end
         end 
         % % % % % % % % % % % %  % % % % % % % % % % % % % % % % 
    end
    methods(Static)
       % generate the Common methods used in different NeuroMethod plot. 
         function Replot(varargin)
            tmpobj=findobj('Parent',varargin{1},'Style','edit');
            figaxes=findobj('Parent',varargin{2});
            for i=1:length(tmpobj)
                eval(['figaxes.',tmpobj(i).Tag,'=[',tmpobj(i).String,'];']);
            end
         end
         function Savefigfcn()
             global h
             [f,p]=uiputfile('*.fig','save the figure!');
             Openfigfcn();
             savefig(h,[p,f]);
             delete(h);
         end
         function Openfigfcn()
             global h
             tmpobj=findobj(gcf,'Type','axes');
             h=figure();
             for i=1:length(tmpobj)
                 copies=copyobj(tmpobj(i),h);
                subplot(ceil(sqrt(length(tmpobj))),fix(sqrt(length(tmpobj))),i,copies);   
             end
         end
         function ResultSavefcn(varargin)
             path=varargin{1};
             savename=varargin{2};
             saveresult=varargin{3};
             if nargin<4
             tmpobj=findobj(gcf,'Tag','Savename');
             matname=tmpobj.String;
             else
                 matname=varargin{4};
             end
             if ispc
                 savemat=matfile([path,'\',matname,'.mat'],'Writable',true);
             else
                 savemat=matfile([path,'/',matname,'.mat'],'Writable',true);
             end
                eval(['savemat.',savename,'=saveresult']);
         end
         function LoadSpikeClassifier(inputoption)
             global FilePath ClassifierInfo ClassifierPath
             if length(inputoption) <2
                  if isempty(ClassifierPath)
                     ClassifierPath=uigetdir('please input the root dir of the ClassifierPath');
                  end
                 % config the Spike Classifier
                 Classlist={'firingRate','putativeCellType'};
                 index=listdlg('PromptString','Choose the Spike Class(es)','ListString',Classlist,'SelectionMode','Multiple');
                 tmpobj=findobj(gcf,'Parent',inputoption{1},'Style','text');
                 if isempty(index)
                     try
                        ClassifierInfo=rmfield(ClassifierInfo,'firingRate');
                     end
                     try
                        ClassifierInfo=rmfield(ClassifierInfo,'putativeCellType');
                     end
                     tmpobj.String=[];
                     return
                 end
                 Classlist=Classlist(index);tmpstring=[];
                 for i=1:length(Classlist)
                     switch Classlist{i}
                         case 'firingRate'
                             ClassifierInfo.firingRate=inputdlg({'min rate','max rate'},'input firing rate',2,{'1','10'});
                             tmpstring=[tmpstring,'firingRate_>',ClassifierInfo.firingRate{1},',<',ClassifierInfo.firingRate{2}];
                         case 'putativeCellType'
                             celltype={'Pyramidal Cell','Wide Interneuron','Narrow Interneuron'};
                             index=listdlg('PromptString','Choose the cell type','ListString',celltype,'SelectionMode','Multiple');
                             ClassifierInfo.putativeCellType=celltype(index);
                             tmpstring=[tmpstring,'putativeCellType_'];
                             for j=1:length(ClassifierInfo.putativeCellType)
                                 tmpstring=[tmpstring,ClassifierInfo.putativeCellType{j},','];
                             end
                     end
                     tmpstring=[tmpstring,' '];
                 end
                 tmpobj.String=tmpstring;
             else
                 % Classifier the Spike used the given Classifier
                tmpobj=findobj(gcf,'Parent',inputoption{1},'Style','text');
                if isempty(tmpobj.String)
                    return
                end
                 [path,name]=fileparts(FilePath.Properties.Source);
                 try
                     if ispc
                        cellmetrics=matfile([ClassifierPath,'\',name,'\',name,'.cell_metrics.cellinfo.mat']);
                     else
                        cellmetrics=matfile([ClassifierPath,'/',name,'/',name,'.cell_metrics.cellinfo.mat']);
                     end
                 catch
                     disp('No cellinfo found!');
                     ClassifierPath=[];
                     return
                 end
                 cellmetrics=cellmetrics.cell_metrics;
                 Namelist=arrayfun(@(x,y) ['cluster',num2str(x),'_',num2str(y)],cellmetrics.electrodeGroup,cellmetrics.cluID,'UniformOutput',0);
                 tmpobj=findobj(gcf,'Parent',inputoption{1},'Style','text');
                 Class=fieldnames(ClassifierInfo)
                 for i=1:length(Class)
                     switch Class{i}
                         case 'firingRate'
                             minfiring=ClassifierInfo.firingRate{1};
                             maxfiring=ClassifierInfo.firingRate{2};
                             indexmin=1:length(Namelist);indexmax=1:length(Namelist);
                             if ~isempty(minfiring)
                                 indexmin=find(cellmetrics.firingRate>str2num(minfiring))
                             end
                             if ~isempty(maxfiring)
                                 indexmax=find(cellmetrics.firingRate<str2num(maxfiring))
                             end
                             index{i}=intersect(indexmin,indexmax)
                         case 'putativeCellType'
                             index{i}=[];
                            for j=1:length(ClassifierInfo.putativeCellType)
                                tmpindex=contains(cellmetrics.putativeCellType,ClassifierInfo.putativeCellType{j});
                                index{i}=union(index{i},find(tmpindex==1));
                            end
                     end
                     inputoption{2}.String=intersect(Namelist(index{i}),inputoption{2}.String);
                     try
                     inputoption{2}.Value=1;
                     end
                 end
             end
         end
    end
end
            
        