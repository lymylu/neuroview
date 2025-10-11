classdef NeuroMethod < dynamicprops
    % parent object of multiple method
    %PowerSpectralDensity PartialDirectedCoherence PerieventSpectrogram 
    %InstantaneousAmplitudeCrosscorrelations PhaseAmplitudeCoupling
    %FiringRate PerieventFiringHistogram
    %PhaseLockingValue SpikeTriggeredPotential
    %Cross-cohereohistogram
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
            workpath=path;
            if ~contains(lower(workpath),lower(option))
                error(['lack of the toolbox:',option,', please add the toolboxes to the workpath!']);
            end
        end
        function CheckValid(methodname)
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
              if strcmp(methodname,'Spectrogram') || strcmp(methodname,'PowerSpectralDensity') 
                    NV.choosematrix.CheckValid('LFPdata');
              elseif strcmp(methodname,'PerieventFiringHistogram')
                    NV.choosematrix.CheckValid('SPKdata');
              end
              try 
                  NV.choosematrix.CheckValid('EVTdata')
              catch
                  warndlg('no EVTdata was selected, using the whole file to analysis or the files with no event file will be ignored!')
              end
             end
        end
        function choosematrix=getParams(choosematrix,varargin)
            % set the parameters to choose the channel (if exist) and event
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
            neurodataextract.Eventselect(mainWindow,choosematrix);
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
            neurodataextract.eventchoosefcn;
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
            clear eventinfo
            uiresume;
        end
    end
end

        

