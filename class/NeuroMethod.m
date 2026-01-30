classdef NeuroMethod < dynamicprops
    %NEUROMETHOD: some static functions to valid data and provide informations before Analysis
    properties
        Params=[];
    end
    methods (Access='public')
        function savematfile=writeData(obj,savematfile)
            varname=fieldnames(obj);
            for i=1:length(varname)
                eval(['savematfile.',varname{i},'=obj.',varname{i},';']);
            end
        end
    end
    methods(Static)
        function methodlist=List()
            % list current supported analysis method.
            methodnamelist=dir([fileparts(which('neuroview.m')),'/methodlist']);
            k=1;
            for i=3:length(methodnamelist)
            if ~methodnamelist(i).isdir
                methodlist{k}=methodnamelist(i).name(1:end-2);
                k=k+1;
            end
            end
        end
        function neuroresult=cal(params,objmatrix,resultname,methodname)
            if isa(objmatrix,'NeuroData')
                neuroresult=objmatrix.ReadData;
            else isa(objmatrix,'char') % path of the extract datamatrix
                neuroresult=NeuroResult(objmatrix);
            end
             neuroresult=eval([methodname,'.recal(params,neuroresult,resultname);']);
        end
        function Checkpath(option)
            % Check the toolbox is in the path
            workpath=path;
            if ~contains(lower(workpath),lower(option))
                error(['lack of the toolbox:',option,', please add the toolboxes to the workpath!']);
            end
        end
        function CheckValid(methodname)
            %% Check if the data for methodname is supported
            global NV
             if isempty(NV.choosematrix)
                button=questdlg('No selected NeuroData,using the epoched data directory?','choose epoched data','Yes','No','Yes');
                switch button
                    case 'Yes'
                        return
                    case 'No'
                        error('No selected NeuroData, please enter the button ''Select the NeuroData''.');
                end
             else
              if strcmp(methodname,'Spectrogram') || strcmp(methodname,'PowerSpectralDensity') || strcmp(methodname,'Connectivity') ||strcmp(methodname,'TimeVaringConnectivityAnalysis')
                    NV.choosematrix.CheckValid('LFPdata');
              elseif strcmp(methodname,'PerieventFiringHistogram')
                    NV.choosematrix.CheckValid('SPKdata');
              elseif strcmp(methodname,'PhaseLocking') || strcmp(methodname,'SpikeFieldConnectivity')
                  NV.choosematrix.CheckValid('LFPdata');
                  NV.choosematrix.CheckValid('SPKdata');
              try 
                  NV.choosematrix.CheckValid('EVTdata')
              catch
                  warndlg('no EVTdata was selected, using the whole file to analysis or the files with no event file will be ignored!')
              end
              end
             end
        end
        function choosematrix=getParams(choosematrix,varargin)
            % set the parameters to choose the channel (if exist) and event （if exist）
            % two types of inputs
            % choosematrix=getParams(choosematrix); open a GUI to select channel and or event informations
            % choosematrix=getParams(choosematrix, eventinfo, channeldescription)
            % See Also NEUROMETHOD.CHECKEVENTINPUT
            if nargin<2 % GUI choose
            parent=figure('menubar','none','numbertitle','off','name','Choose the eventtype and channeltype','DeleteFcn',@(~,~) NeuroMethod.Chooseparams(choosematrix));
            mainWindow=uix.HBoxFlex('Parent',parent);
            channelpanel=uix.VBox('Parent',mainWindow);
            uicontrol(channelpanel,'Style','Text','String','Choose the channel Tag(s)');
            channellist=uicontrol(channelpanel,'Style','listbox','Tag','Channeltype','min',0,'max',3);
            channellist.String=choosematrix.getTaginfo('Tagname','ChannelTag');
            uicontrol(channelpanel,'Style','pushbutton','String','Choose the event&channel info','Tag','Chooseinfo','Callback',@(~,~) NeuroMethod.Chooseparams(choosematrix));
            try
            choosematrix.CheckValid('EVTdata');
            NeuroMethod.Eventselect(mainWindow,choosematrix);
            set(mainWindow,'Width',[-1,-3]);
            catch
                disp('No EVTdata detected, using whole files to process');
            end
            uiwait;
            close(parent);
            else
                p=inputParser;
                validfcn=@NeuroMethod.CheckEventInput;
                addRequired(p,'eventinfo',@(x) validfcn(x));
                addParameter(p,'channel',[]);
                parse(p,varargin{:})
                eventinfo=p.Results.eventinfo;
                channel=p.Results.channel;
                for i=1:length(choosematrix)
                    try
                    choosematrix(i).addprop('selectchannel');
                    end
                    choosematrix(i).selectchannel=channel;
                    eventdata=choosematrix(i).EVTdata;
                    try
                        eventdata.addprop('selectevent');
                    end
                    eventdata.selectevent=eventinfo;
                end
            end
        end
        function bol=CheckEventInput(eventinfo)
            % the input format for eventinformation
            % eventinfo is a struct contains timetype (timepoint/timeduration)
            % for timepoint, eventinfo contains timestart(numeric), timestop(numeric),and selectdescription(cell),' ...
            % for timeduration, eventinfo contains timestart(cell) and timestop(cell)
            ErrDescription=['eventinfo is a struct contains timetype (timepoint/timeduration), for timepoint, eventinfo contains timestart(numeric), timestop(numeric),and selectdescription(cell),' ...
                'for timeduration, eventinfo contains timestart(cell) and timestop(cell)'];
            try
                switch eventinfo.timetype
                    case 'timepoint'
                        eventdescription=eventinfo.selectdescription;
                        timestart=eventinfo.timestart;
                        timestop=eventinfo.timestop;
                        valid=isnumeric(timestart)&&isnumeric(timestop)&&iscell(eventdescription);
                    case 'timeduration'
                        timestart=eventinfo.timestart;
                        timestop=eventinfo.timestop;
                        valid=iscell(timestart)&&iscell(timestop);
                end
            catch
                disp(ErrDescription);
                bol=false;
            end
            if ~valid
                disp(ErrDescription);
                bol=false;
            end
            bol=true;
        end
        function Chooseparams(choosematrix)
            % choose the given channel and event information for
            % NeuroData.ReadData()
            global eventinfo
            tmpobj=findobj(gcf,'Tag','Channeltype');
            channel=tmpobj.String(tmpobj.Value);
            try % if no event were select use all event time to analysis
                neurodataextract.eventchoosefcn;
            end
            for i=1:length(choosematrix)
                try
                choosematrix(i).addprop('selectchannel');
                end
                channeltag=choosematrix.getTaginfo('Tagname','ChannelTag');
                choosematrix(i).selectchannel=channeltag(ismember(channeltag,channel));
                if isprop(choosematrix(i),'EVTdata')
                    eventdata=choosematrix(i).EVTdata;
                    try
                        eventdata.addprop('selectevent');
                    end
                    eventdata.selectevent=eventinfo;
                end
            end
            clear eventinfo
            uiresume;
        end
        function [bol,output]=CheckAverageInput(input)
            % check the average input for LFP and SPK average
            reserveparams={'none','separate','all'};
            output=[];
            if ischar(input)
            if contains(input,reserveparams)
                bol=true;
                output=input;
            else
                try
                    output=eval(input);
                    bol=true;
                catch
                    bol=false;
                end
            end
            else
                bol=true;
                output=input;
            end
        end
        function Eventselect(parent,choosematrix)
            if isempty(parent)
                parent=figure('menubar','none','numbertitle','off','name','Choose the eventtype','DeleteFcn',@(~,~) neurodataextract.eventchoosefcn);
            end
            MainWindow=uix.HBox('Parent',parent);
            controlpanel=uix.VBox('Parent',MainWindow);
            infopanel=uix.CardPanel('Parent',MainWindow,'Tag','Eventinfo');
            uicontrol(controlpanel,'Style','pushbutton','String','Time points','Callback',@(~,~) neurodataextract.eventselectpanel(infopanel,1));
            uicontrol(controlpanel,'Style','pushbutton','String','Time duration','Callback',@(~,~) neurodataextract.eventselectpanel(infopanel,2));
            %uicontrol(controlpanel,'Style','pushbutton','String','Choose the Eventinfo','Tag','Chooseinfo','Callback',@(~,~) neurodataextract.eventchoosefcn);
            Timepointspanel=uix.HBox('Parent',infopanel,'Tag','Timepoints');
            Timeduration=uix.Grid('Parent',infopanel,'Tag','Timeduration');
            eventtype=[];
            for i=1:length(choosematrix)
                varname=fieldnames(choosematrix(i).EVTdata.EVTinfo);
                try
                    %eventtype=cat(1,eventtype,choosematrix(i).EVTdata.EVTtype);
                    warning('The EVTdata.EVTtype is not supported in this version, please re-intialize the EVTdata in the yaml file!');
                end
                for j=1:length(varname)
                    if ~isfield(eventtype,varname{j})
                        eval(['eventtype.',varname{j},'=[];']);
                    end
                        eval(['eventtype.',varname{j},'=cat(1,eventtype.',varname{j},',choosematrix(i).EVTdata.EVTinfo.',varname{j},');']);
                end
            end
            %varname=fieldnames(eventtype);
            Eventtype=[];Eventdescription=[];
            %for i=1:length(varname)
                %eval(['eventtype.',varname{i},'=unique(eventtype.',varname{i},');']);
                %tmp=eval(['eventtype.',varname{i}]);
                tmp=eventtype.description; % only description field can be choose.
                Eventtype=unique(cellstr(tmp));
                %Eventdescription=cat(1,Eventdescription,repmat(varname(i),[length(tmp),1]));
            %end
            % transfer eventtype to neuroplot.selectpanel
            eventtypepanel=NeuroPlot.selectpanel();
            eventtypepanel=eventtypepanel.create(Timepointspanel,'eventpoint',Eventtype,'multiselect','on');
            tmpgrid=uix.Grid('Parent',Timepointspanel);
            uicontrol(tmpgrid,'Style','text','String','begin time');
            uicontrol(tmpgrid,'Style','text','String','end time');
            uicontrol(tmpgrid,'Style','edit','String','-2','Tag','Begintime');
            uicontrol(tmpgrid,'Style','edit','String','2','Tag','Endtime');
            set(tmpgrid,'Heights',[-1,-1]);
            % Timedurationpanel

            eventtypebegin=NeuroPlot.selectpanel();
            eventtypebegin.create(Timeduration,'eventbegin',Eventtype,'multiselect','off');
            eventtypeend=NeuroPlot.selectpanel();
            eventtypeend.create(Timeduration,'eventend',Eventtype,'multiselect','off');
            eventdescription=uicontrol(Timeduration,"Style",'listbox','Tag','eventdescription','Max',3,'Min',1);
            addevent=uicontrol(Timeduration,"Style",'pushbutton','String','add timeduration','Callback',@(~,~) neurodataextract.addduration(Timeduration));
            deleteevent=uicontrol(Timeduration,"Style",'pushbutton','String','delete timeduration','Callback',@(~,~) neurodataextract.delduration(Timeduration));
            %set(Timeduration,'Heights',[-1,-3],'Width',[-1,-1]);
            %set(MainWindow,'Width',[-1,-2]);
        end
    end
end

        

