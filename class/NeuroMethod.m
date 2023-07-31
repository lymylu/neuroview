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
        function neuroresult=cal(params,objmatrix,DetailsAnalysis,resultname,methodname)
          
            if strcmp(class(objmatrix),'NeuroData')
                neuroresult=objmatrix.LoadData(DetailsAnalysis);
            elseif isempty(DetailsAnalysis)
                neuroresult=NeuroResult(objmatrix.Datapath);
            else
                tmpmat=matfile(objmatrix.Datapath);
                tmpmat=eval(['tmpmat.',DetailsAnalysis,';']);
                neuroresult=NeuroResult(tmpmat);
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
        function getParams(choosematrix)
            global eventinfo
            parent=figure('menubar','none','numbertitle','off','name','Choose the eventtype and channeltype','DeleteFcn',@(~,~) NeuroMethod.Chooseparams);
            mainWindow=uix.HBox('Parent',parent);
            channelpanel=uix.VBox('Parent',mainWindow);
            uicontrol(channelpanel,'Style','Text','String','Choose the channel Tag(s)');
            channellist=uicontrol(channelpanel,'Style','listbox','Tag','Channeltype','min',0,'max',3);
            channellist.String=neurodatatag.getTaginfo(choosematrix,'ChannelTag');
            choosebutton=uicontrol(channelpanel,'Style','pushbutton','String','Choose the event&channel info','Tag','Chooseinfo','Callback',@(~,~) NeuroMethod.Chooseparams);
            %set(choosebutton,'String','Choose the event&channel info','Callback',@(~,~) NeuroMethod.Chooseparams);
            try
            neurodataextract.CheckValid('EVTdata');
            neurodataextract.Eventselect(mainWindow,choosematrix);
            set(mainWindow,'Width',[-1,-3]);
            catch
                disp('No EVTdata detected, using whole files to process');
                eventinfo=[];
            end
            uiwait;
            close(parent);
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

        

