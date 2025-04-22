classdef NeuroPlot <dynamicprops
    % generate the GUI for a NeuroResult class to plot NeuroResult objects.
    properties (Access='protected')
        NP% NeuroPlot Main Figure
        MainBox
        LeftPanel
        RightPanel
        ResultOutputPanel
        ResultSelectPanel
        FigurePanel
        ConditionPanel
        PanelManagement 
    end
    methods (Access='public')
        function obj=Plot(obj,figparent,Resultfile)
            % initialized the NeuroPlot, Resultfile is the file(directory) lists of each subject or NeuroResults
              clearvars -global currentvalue currentresult
              obj.setParent(figparent);
              obj.GenerateObjects(Resultfile);
              obj.Changefilemat(Resultfile);
        end
        function obj=CreatePlot(obj,neuroresult)
            % generate the mainwindow of NeuroPlot from a neuroresult file
            plotvariable = neuroresult.getPlotnames;% check the data to plot(LFP,SPK,and analysis results)
            obj.PanelManagement.Panel=cell(0,0);
            obj.PanelManagement.Type=cell(0,0);
            obj.PanelManagement.Data=cell(0,0);
            %% create UI from NeuroResult Class
            plottype=[];
            switch neuroresult.EVTinfo.timetype
                case 'timeduration'
                    plottype='-scroll';
            end
            try
            [SPKinfopanel,SPKdatapanel]=neuroresult.createplot('SPKData');
            obj.PanelManagement.Panel=cat(1,obj.PanelManagement.Panel,{SPKdatapanel});
            obj.PanelManagement.Type=cat(1,obj.PanelManagement.Type,'SPKData');
            obj.PanelManagement.Data=cat(1,obj.PanelManagement.Data,{neuroresult.SPKdata});
            obj.PanelManagement.Panel=cat(1,obj.PanelManagement.Panel,{SPKinfopanel});
            obj.PanelManagement.Type=cat(1,obj.PanelManagement.Type,'SPKinfo');
            obj.PanelManagement.Data=cat(1,obj.PanelManagement.Data,{[]});
            end
            try
            [LFPinfopanel,LFPdatapanel]=neuroresult.createplot('LFPData');
            obj.PanelManagement.Panel=cat(1,obj.PanelManagement.Panel,{LFPdatapanel});
            obj.PanelManagement.Type=cat(1,obj.PanelManagement.Type,'LFPData'); 
            obj.PanelManagement.Data=cat(1,obj.PanelManagement.Data,{neuroresult.LFPdata});
            obj.PanelManagement.Panel=cat(1,obj.PanelManagement.Panel,{LFPinfopanel});
            obj.PanelManagement.Type=cat(1,obj.PanelManagement.Type,'LFPinfo');
            obj.PanelManagement.Data=cat(1,obj.PanelManagement.Data,{[]});
            end
            try
            [CALinfopanel,CALdatapanel]=neuroresult.createplot('CALData');
            obj.PanelManagement.Panel=cat(1,obj.PanelManagement.Panel,{CALdatapanel});
            obj.PanelManagement.Type=cat(1,obj.PanelManagement.Panel,'CALData');
             obj.PanelManagement.Data=cat(1,obj.PanelManagement.Data,{neuroresult.CALdata});
            obj.PanelManagement.Panel=cat(1,obj.PanelManagement.Panel,{CALinfopanel});
            obj.PanelManagement.Type=cat(1,obj.PanelManagement.Panel,'CALinfo');
            obj.PanelManagement.Data=cat(1,obj.PanelManagement.Data,{[]});
            end
            try
            EVTpanel=neuroresult.createplot('EVTinfo');
            obj.PanelManagement.Panel=cat(1,obj.PanelManagement.Panel,{EVTpanel});
            obj.PanelManagement.Type=cat(1,obj.PanelManagement.Type,'EVTinfo');
            obj.PanelManagement.Data=cat(1,obj.PanelManagement.Data,{neuroresult.EVTinfo});
%             catch
%                 obj=Plot_origin(obj,parent,neuroresult); % no eventextract, plot the result from origin data?
%                 return;
            end
           if strcmp(neuroresult.EVTinfo.timetype,'timeduration') % add scroll panel for time
               Timepanel.mainpanel=uix.VBox();
               Slider=uicontrol('parent',Timepanel.mainpanel,'Style','slider','Tag','timeslider');
               Time=uicontrol('parent',Timepanel.mainpanel,'Style','edit','String',[],'Tag','currenttime');
               uicontrol('Parent',Timepanel.mainpanel,'Style','text','String','currenttime');
               Timeshow=uicontrol('Parent',Timepanel.mainpanel,'Style','edit','String','-10 10','Tag','timerange');
               uicontrol('Parent',Timepanel.mainpanel,'Style','text','String','timerange');
               eventlist=findobj(EVTpanel.mainpanel,'Tag','EventIndex');
               obj.PanelManagement.Panel=cat(1,obj.PanelManagement.Panel,{Timepanel});
               obj.PanelManagement.Type=cat(1,obj.PanelManagement.Type,'Timeinfo');
               obj.PanelManagement.Data=cat(1,obj.PanelManagement.Data,{[]}); % change in the future;
               addlistener(eventlist,'Value','PostSet',@(~,~) obj.setSlider(neuroresult));
               obj.setSlider(neuroresult);
               addlistener(Slider,'Value','PostSet',@(~,~) obj.getSliderTime(neuroresult));
           end
            % Create UI from NeuroMethod Class
            for i=1:length(plotvariable{:,2})
                for j=1:length(NeuroMethod.List)
                    if strcmp(plotvariable{:,2}{i},NeuroMethod.List{j})
                        tmpdata=eval(['neuroresult.',plotvariable{:,1}{i},';']);
                        for k=1:length(tmpdata)
                            tmppanel=eval(['neuroresult.',plotvariable{:,1}{i},'(k).createplot(plotvariable{:,1}{i});']);
                            obj.PanelManagement.Panel=cat(1,obj.PanelManagement.Panel,{tmppanel});
                            obj.PanelManagement.Type=cat(1,obj.PanelManagement.Type,eval(['class(',plotvariable{:,2}{i},');']));
                            obj.PanelManagement.Data=cat(1,obj.PanelManagement.Data,{tmpdata(k)});
                        end
                    end
                end
            end
        end
        function obj=setSlider(obj,neuroresult)
            EVTpanel=obj.PanelManagement.Panel(ismember(obj.PanelManagement.Type,'EVTinfo'));
            Timepanel=obj.PanelManagement.Panel(ismember(obj.PanelManagement.Type,'Timeinfo'));
            index=EVTpanel{:}.getIndex('EventIndex');
            Slider=findobj(Timepanel{:}.mainpanel,'Tag','timeslider');
            timerange=findobj(Timepanel{:}.mainpanel,'Tag','timerange');
            timerange=str2num(timerange.String);
            largestep=(timerange(2)-timerange(1))/(neuroresult.EVTinfo.timestop(index)-timerange(2)-neuroresult.EVTinfo.timestart(index)+timerange(1));
            smallstep=largestep/10;
            set(Slider,'min',0,'max',1,'Value',0,'SliderStep',[smallstep,largestep]);
        end
        function obj=getSliderTime(obj,neuroresult)
             EVTpanel=obj.PanelManagement.Panel(ismember(obj.PanelManagement.Type,'EVTinfo'));
             Timepanel=obj.PanelManagement.Panel(ismember(obj.PanelManagement.Type,'Timeinfo'));
             index=EVTpanel{:}.getIndex('EventIndex');
             Slider=findobj(Timepanel{:}.mainpanel,'Tag','timeslider');
             timerange=findobj(Timepanel{:}.mainpanel,'Tag','timerange');
             timerange=str2num(timerange.String);
             currenttime=findobj(Timepanel{:}.mainpanel,'Tag','currenttime');
             timeall=neuroresult.EVTinfo.timestop(index)-timerange(2)-neuroresult.EVTinfo.timestart(index)+timerange(1);
             time=neuroresult.EVTinfo.timestart(index)+Slider.Value*timeall-timerange(1);
             set(currenttime,'String',num2str(time));
             obj.Resultplotfcn(neuroresult);
        end
        function obj=setParent(obj,parent)
            obj.NP=parent;
        end
        function obj=GenerateObjects(obj,filemat)
            % create the command region and the figure region
            % the mainwindow contains several functional Panels, including
            % SaveFigurePanel, SaveResultPanel, ResultSelectPanel, FigurePanel, and ConditionPanel
            % SaveFigurePanel: Save the current plot Figure
            % SaveResultPanel: Save the current selected averaged Result & Save the multiple averaged Result
            % ResultSelectPanel: Select the Result from the given conditions (different method defined)
            % FigurePanel: Show the result figure from the given method (different method defined)
            % ConditionPanel: Show the current log of data, multidatacontroller ......
            if isempty(obj.NP)
                obj.NP=figure();
            end
            obj.MainBox=uix.HBoxFlex('Parent',obj.NP,'Spacing',4); 
            obj.LeftPanel=uix.VBoxFlex('Parent',obj.MainBox,'Padding',5);
            obj.RightPanel=uix.VBoxFlex('Parent',obj.MainBox,'Padding',5);
            set(obj.MainBox,'Width',[-1,-2]); 
            % SaveFigurePanel, SaveResultPanel, ResultSelectPanel are on the Left, FigurePanel and ConditionPanel are on the right.
            % Details of the command region.
            obj=obj.GenerateSaveFigurePanel;
            obj=obj.GenerateSaveResultPanel;
            obj=obj.GenerateConditionPanel(filemat); 
         end
        function obj=Changefilemat(obj,filemat)
            % change according to the filemat
            global currentresult currentvalue
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            matvalue=tmpobj.Value;
            try
                obj.saveblacklist(filemat);
            end
            currentvalue=matvalue;
            currentresult=NeuroResult(filemat{matvalue});
            try
                deletedobj=findobj('Tag','SelectInfo');
                delete(deletedobj);
                delete(obj.FigurePanel);
            end
            obj.PanelManagement=[];
            obj=obj.CreatePlot(currentresult);
            obj=obj.GenerateResultSelectPanel;
            obj=obj.GenerateFigurePanel();
            Plotbutton=findobj('Tag','Plotresult');
            set(Plotbutton,'Callback',@(~,~) obj.Resultplotfcn(currentresult));
            set(obj.LeftPanel,'Heights',[-1,-1,-3]);
            set(obj.RightPanel,'Heights',[-1,-9]);
         end
         function Resultplotfcn(obj,neuroresult)
             for i=1:length(obj.PanelManagement.Type)
                 if ismember(obj.PanelManagement.Type{i},{'LFPData','SPKData','CALData'})
                     neuroresult.plot(obj.PanelManagement.Type{i},obj.PanelManagement);
                 end
             end
             for i=1:length(obj.PanelManagement.Panel)
                 if ismember(obj.PanelManagement.Type{i},NeuroMethod.List)
                     obj.PanelManagement.Data{i}.plot(obj.PanelManagement.Panel{i},obj.PanelManagement);
                 end
             end
            
         end
         % % % % % % % %
         function obj=GenerateSaveResultPanel(obj)
            obj.ResultOutputPanel=uix.Panel('Parent',obj.LeftPanel,'Padding',5,'Title','SaveResult');
            ResultOutputBox=uix.VBox('Parent',obj.ResultOutputPanel,'Padding',0);
            uicontrol('Style','pushbutton','Parent',ResultOutputBox,'String','Average and Plot result (P)','Tag','Plotresult');
            uicontrol('Style','pushbutton','Parent',ResultOutputBox,'String','Save the selected averaged result (S)','Tag','Resultsave','Callback',@(~,~) obj.ResultSavefcn());
            uicontrol('Style','edit','Parent',ResultOutputBox,'String','Save Name','Tag','Savename');
         end
         function obj=GenerateResultSelectPanel(obj)
              Panel=uix.Panel('Parent',obj.LeftPanel,'Padding',5,'Title','SelectInfo','Tag','SelectInfo');
              obj.ResultSelectPanel=uix.HBox('Parent',Panel);
              for i=1:length(obj.PanelManagement.Panel)
                  if ismember(obj.PanelManagement.Type{i},{'EVTinfo','LFPinfo','SPKinfo','CALinfo','Timeinfo'})
                      obj.PanelManagement.Panel{i}.mainpanel.Parent=obj.ResultSelectPanel;
                  end
              end
         end
         function obj=GenerateFigurePanel(obj)
              obj.FigurePanel=uix.VBoxFlex('Parent',obj.RightPanel,'Padding',0);
              for i=1:length(obj.PanelManagement.Panel)
                  if ismember(obj.PanelManagement.Type{i},[NeuroMethod.List,'SPKData','LFPData','CALData'])
                      obj.PanelManagement.Panel{i}.mainpanel.Parent=obj.FigurePanel;
                  end
              end
         end
         function obj=GenerateSaveFigurePanel(obj)
            % define the FigureOutputPanel
            FigureOutputPanel=uix.Panel('Parent',obj.LeftPanel,'Padding',5,'Title','SaveFigure');
            FigureOutputBox=uix.VBox('Parent',FigureOutputPanel,'Padding',0);
            uicontrol('Style','pushbutton','Parent',FigureOutputBox,'String','Save current Figure','Tag','Savefig','Callback', @(~,~) obj.Savefigfcn);
            uicontrol('Style','pushbutton','Parent',FigureOutputBox,'String','Open the Figure in new window','Tag','Openfig', 'Callback', @(~,~) obj.Openfigfcn);
            try
               obj.CreateSaveFigurePanel(FigureOutputBox); %% some unique options in Spike associate plot (SUA or MUA)
            end
         end
         function obj=GenerateConditionPanel(obj,filemat)
             obj.ConditionPanel=uix.VBox('Parent',obj.RightPanel,'Padding',0);
              uicontrol('Parent',obj.ConditionPanel,'Style','text','Tag','Loginfo');
             % multiple select mode
             MultiplePanel=uix.HBox('Parent',obj.ConditionPanel,'Padding',0);
             tmpmat=uicontrol('Parent',MultiplePanel,'Style','popupmenu','Tag','Matfilename','String',filemat,'Value',1,'Callback',@(~,~) obj.Changefilemat(filemat));
             uicontrol('Parent',MultiplePanel,'Style','pushbutton','String','load Select info','Tag','Loadselectinfo','Callback',@(~,~,src) obj.loadblacklist(filemat));
             uicontrol('Parent',MultiplePanel,'Style','pushbutton','String','averageAlldata','Tag','Averagealldata','Callback',@(~,~) obj.Averagealldata(filemat));
             %addlistener(tmpmat,'Value','PreSet',@(~,~) obj.saveblacklist(filemat));
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
        function neuroresult_all=Averagealldata(obj,filemat)
            % not work well yet!
            NeuroPlot.NeuroPlot.saveblacklist(filemat);
            savedir=uigetdir('Select the Save path');
             % save all data from the subjectlevel
             for i=1:length(obj.PanelManagement.Type)
                 if ismember(obj.PanelManagement.Type{i},NeuroMethod.List)
                    averageparams_method{i}=eval([obj.PanelManagement.Type{i},'.getAverageparams']);
                 elseif ismember(obj.PanelManagement.Type{i},{'LFPData','SPKData','CALData'})
                     averageparams{i}=eval([obj.PanelManagement.Type{i},'.getAverageparams']);
                 end
             end
            for j=1:length(filemat)
                neuroresult=NeuroResult(filemat{j});
                for i=1:length(obj.PanelManagement.Type)
                     if ismember(obj.PanelManagement.Type{i},{'LFPData','SPKData','CALData'})
                         neuroresult=neuroresult.AverageSubject(obj.PanelManagement.Type{i},averageparams{i});
                     end
                end                       
                for i=1:length(obj.PanelManagement.Panel)
                     if ismember(obj.PanelManagement.Type{i},NeuroMethod.List)
                         eval(['neuroresult.',obj.PanelManagement.Panel{i}.figpanel.Title,'=neuroresult.',obj.PanelManagement.Panel{i}.figpanel.Title,'.AverageSubject(neuroresult,averageparams_method{i});']);
                     end
                end
                neuroresult.SaveData(savedir,neuroresult.Subjectname,'matfile',[]);
            end
         end
         % % % % % % % % % % % %  % % % % % % % % % % % % % % % % 
    end
    methods(Static)
       % generate the Common methods used in different NeuroMethod plot. 
       function Savefigfcn()
             global h
             [f,p]=uiputfile('*.fig','save the figure!');
             NeuroPlot.NeuroPlot.Openfigfcn();
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
       function msg=loadblacklist()
             global Blacklist 
             [f,p]=uigetfile('Blacklist.mat');
             blacklist=matfile([p,f]);
             tmpobj=findobj(gcf,'Tag','Matfilename');
             msg=[];
             for i=1:length(Blacklist)
                 try  
                    [~,matname]=fileparts(tmpobj.String{i});           
                     tmpblack=eval(['blacklist.',matname,';']);
                     namelist=intersect(fieldnames(tmpblack),fieldnames(Blacklist));
                     for j=1:length(namelist)
                        eval(['Blacklist(i).',namelist{j},'=tmpblack.',namelist{j},';']);
                     end
                        msg=[msg,' ',matname];
                     end
             end
         end 
         function saveblacklist(filemat)
             global currentresult currentvalue
             savemat=filemat{currentvalue};
             try
             savemat=matfile(savemat,'Writable',true);
             catch
                 savemat=matfile(fullfile(savemat,'Datainfo.mat'),'Writable',true);
             end
             savemat.LFPinfo=currentresult.LFPinfo;
             savemat.SPKinfo=currentresult.SPKinfo;
             savemat.EVTinfo=currentresult.EVTinfo;
         end
    end
end
            
        