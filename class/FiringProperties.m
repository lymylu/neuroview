classdef FiringProperties < NeuroMethod
    %% caculate the firing properties using CellExplorer
    properties
    end
    methods
        function obj=getParams(obj)
            % calculate the event epoch or all time (default all time)
            obj.Checkpath('Cellexplorer');
        end
        function obj=cal(obj,objmatrix,DetailsAnalysis)
%             if contains(obj.Params.methodname,'Waveform')
%                  Spikedata=objmatrix.loadData(DetailsAnalysis,'SPKwave');
%                  waveform=Spikedata.spikewaveform;
%                  obj.Result.spikewaveform=waveform;
%             else
%                 Spikedata=objmatrix.loadData(DetailsAnalysis,'SPKtime');
                % Automatic Cellexplorer session initialized 
                %
                basepath=objmatrix.Datapath;
                session = sessionTemplate(basepath);
                % load the extracelluar information from the xml
                session = import_xml2session([],session);
                session.extracellular.electrodeGroups = session.extracellular.spikeGroups;
                session.extracellular.nElectrodeGroups=session.extracellular.nSpikeGroups;
                session.spikeSorting{1}.format='Neurosuite';
                session.spikeSorting{1}.method='Klustakwik';
                session.spikeSorting{1}.manuallyCurated=1;
                ProcessCellMetrics('session',session);
                clear session;
        end
    end
end