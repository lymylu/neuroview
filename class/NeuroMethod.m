classdef NeuroMethod < dynamicprops
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
          
            if strcmp(class(objmatrix),'NeuroData')
                neuroresult=objmatrix.LoadData;
            else strcmp(class(objmatrix),'char') % path of the extract datamatrix
                neuroresult=NeuroResult(objmatrix);
%             else
%                 tmpmat=matfile(objmatrix.Datapath);
%                 tmpmat=eval(['tmpmat.',DetailsAnalysis,';']);
%                 neuroresult=NeuroResult(tmpmat);
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
            global choosematrix
             if isempty(choosematrix)
                button=questdlg('No selected NeuroData,using the epoched data directory?','choose epoched data','Yes','No','Yes');
                switch button
                    case 'Yes'
                        return
                    case 'No'
                        error('No selected NeuroData, please enter the button ''Select the NeuroData''.');
                end
             else
              if strcmp(methodname,'Spectrogram') || strcmp(methodname,'PowerSpectralDensity') 
                    neurodataextract.CheckValid('LFPdata');
              elseif strcmp(methodname,'PerieventFiringHistogram')
                    neurodataextract.CheckValid('SPKdata');
              end
              try 
                  neurodataextract.CheckValid('EVTdata')
              catch
                  warndlg('no EVTdata was selected, using the whole file to analysis or the files with no event file will be ignored!')
              end
             end
        end
        function choosematrix=getParams(choosematrix,varargin)
            % usage
            % choosematrix=getParams(choosematrix,'ChannelTag','PL','Eventinfo',struct(eventtype,'timepoint','selecttype',{'left','right'},'eventparams',[-2,2]));
            % choosematrix=getParams(choosematrix,'ChannelTag',{'PL','IL'},'Eventinfo',struct('eventtype','timeduration',eventparams,{'begin','stop'}};
            p=inputParser;
            addParameter(p,'ChannelTag',[],@(x) ischar);
            addParameter(p,'Eventinfo',[],@(x) isstruct);
            parse(p,varargin{:});
            if isempty(p.Results.ChannelTag)||isempty(p.Results.Eventinfo)
            parent=figure('menubar','none','numbertitle','off','name','Choose the eventtype and channeltype','DeleteFcn',@(~,~) NeuroMethod.Chooseparams);
            mainWindow=uix.HBox('Parent',parent);
            channelpanel=uix.VBox('Parent',mainWindow);
            uicontrol(channelpanel,'Style','Text','String','Choose the channel Tag(s)');
            channellist=uicontrol(channelpanel,'Style','listbox','Tag','Channeltype','min',0,'max',3);
            channellist.String=neurodatatag.getTaginfo(choosematrix,'ChannelTag');
            uicontrol(channelpanel,'Style','pushbutton','String','Choose the event&channel info','Tag','Chooseinfo','Callback',@(~,~) NeuroMethod.Chooseparams);
            try
            neurodataextract.CheckValid('EVTdata');
            neurodataextract.Eventselect(mainWindow,choosematrix);
            set(mainWindow,'Width',[-1,-3]);
            catch
                disp('No EVTdata detected, using whole files to process');
            end
            uiwait;
            close(parent);
            else
                for i=1:length(choosematrix)
                    choosematrix(i)=choosematrix(i).addprop('selectchannel',p.Results.ChannelTag{:});
                    choosematrix(i).EVTdata=choosematrix(i).EVTdata.selectevent(p.Results.Eventinfo{:});
                end
            end

        end
        function Chooseparams
            global choosematrix eventinfo
            tmpobj=findobj(gcf,'Tag','Channeltype');
            channel=tmpobj.String(tmpobj.Value);
            neurodataextract.eventchoosefcn();
            for i=1:length(choosematrix)
                try
                choosematrix(i).addprop('selectchannel');
                end
                choosematrix(i).selectchannel=channel;
                choosematrix(i).EVTdata=choosematrix(i).EVTdata.selectevent(eventinfo);
            end
            uiresume;
        end
    end
end

        

