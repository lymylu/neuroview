classdef NeuroMethod < dynamicprops
    %PowerSpectralDensity PartialDirectedCoherence PerieventSpectrogram 
    %InstantaneousAmplitudeCrosscorrelations PhaseAmplitudeCoupling
    %FiringRate PerieventFiringHistogram
    %PhaseLockingValue SpikeTriggeredPotential
    %Cross-cohereohistogram
    properties
        methodname=[];
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
        function Checkpath(option)
            workpath=path;
            if ~contains(lower(workpath),lower(option))
                error(['lack of the toolbox:',option,', please add the toolboxes to the workpath!']);
            end
        end
        function CheckValid(methodname)
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
        function getParams(choosematrix)
            parent=figure('menubar','none','numbertitle','off','name','Choose the eventtype and channeltype','DeleteFcn',@(~,~) NeuroMethod.Chooseparams);
            mainWindow=uix.HBox('Parent',parent);
            neurodataextract.Eventselect(mainWindow,choosematrix);
            channelpanel=uix.VBox('Parent',mainWindow);
            uicontrol(channelpanel,'Style','Text','String','Choose the channel Tag(s)');
            channellist=uicontrol(channelpanel,'Style','listbox','Tag','Channeltype','min',0,'max',3);
            channellist.String=neurodatatag.getTaginfo(choosematrix,'ChannelTag');
            tmpobj=findobj(parent,'Tag','Chooseinfo');
            set(tmpobj,'String','Choose the event&channel info','Callback',@(~,~) NeuroMethod.Chooseparams);
            set(mainWindow,'Width',[-3,-1]);
            uiwait;
        end
        function Chooseparams
            global DetailsAnalysis eventinfo
            tmpobj=findobj(gcf,'Tag','Channeltype');
            channel=tmpobj.String(tmpobj.Value);
            neurodataextract.eventchoosefcn();
            DetailsAnalysis.EVTinfo=eventinfo;
            DetailsAnalysis.channelchoose=channel;
            uiresume;
        end
    end
end

        

