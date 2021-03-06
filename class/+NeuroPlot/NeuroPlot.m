classdef NeuroPlot <dynamicprops
    % generate the GUI for different NeuroMethod Obj
    % the Results could be selected and showed from different events and channels
    properties (Access='protected')
        Methodname % e.g. FiringRate PerieventHistogram Spectrogram, PowerSpectralDensity...
        NP=figure();% NeuroPlot Main Figure
        MainBox
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
            obj.NP=figure();
            obj.MainBox=uix.HBoxFlex('Parent',obj.NP,'Spacing',4); 
            obj.LeftPanel=uix.VBoxFlex('Parent',obj.MainBox,'Padding',5);
            obj.RightPanel=uix.VBoxFlex('Parent',obj.MainBox,'Padding',5);
            set(obj.MainBox,'Width',[-1,-2]); 
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
            uicontrol('Style','pushbutton','Parent',ResultOutputBox,'String','Average and Plot result (P)','Tag','Plotresult');
            uicontrol('Style','pushbutton','Parent',ResultOutputBox,'String','Save the selected averaged result (S)','Tag','Resultsave');
            uicontrol('Style','edit','Parent',ResultOutputBox,'String','Save Name','Tag','Savename');
         end
         function obj=GenerateResultSelectPanel(obj,varargin)
              Panel=uix.Panel('Parent',obj.LeftPanel,'Padding',5,'Title','SelectInfo');
              obj.ResultSelectPanel=uix.HBox('Parent',Panel);
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
             uicontrol('Parent',MultiplePanel,'Style','pushbutton','String','averageAlldata','Tag','Averagealldata');
             set(obj.ConditionPanel,'Height',[-1,-1]);
         end
        function Msg(obj,msg,type)
             tmpobj=findobj(obj.NP,'Tag','Loginfo');
             switch type
                 case 'replace'
                     tmpobj.String=msg;
                 case 'add'
                     tmpobj.String=[tmpobj.String,msg];
             end
        end 
        function ResultSavefcn(obj,varargin)
             path=varargin{1};
             savename=varargin{2};
             saveresult=varargin{3};
             if nargin<5
             tmpobj=findobj(obj.NP,'Tag','Savename');
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
         % % % % % % % % % % % %  % % % % % % % % % % % % % % % % 
    end
    methods(Static)
       % generate the Common methods used in different NeuroMethod plot. 
       function Savefigfcn()
             global h
             [f,p]=uiputfile('*.fig','save the figure!');
             Openfigfcn();
             savefig(h,[p,f]);
             delete(h);
         end
         function Openfigfcn()
             global h
             tmpobj=findobj(obj.NP,'Type','axes');
             h=figure();
             for i=1:length(tmpobj)
                 copies=copyobj(tmpobj(i),h);
                subplot(ceil(sqrt(length(tmpobj))),fix(sqrt(length(tmpobj))),i,copies);   
             end
         end
      
         function msg=loadblacklist()
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
    end
end
            
        