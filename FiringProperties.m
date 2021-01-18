classdef FiringProperties < NeuroMethod
    %% calculate the firing properties using CellExplorer
    properties
    end
    methods(Static)
        function cal(objmatrix)
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
                cellexplorermat=dir('*.cellinfo.mat');
                for i=1:length(cellexplorermat)
                    system(['rm ' cellexplorermat(i).name]);
                end
                % load the extracelluar information from the xml
                session = import_xml2session([],session);
                session.extracellular.electrodeGroups = session.extracellular.spikeGroups;
                session.extracellular.nElectrodeGroups=session.extracellular.nSpikeGroups;
                session.spikeSorting{1}.format='Neurosuite';
                session.spikeSorting{1}.method='Klustakwik';
                session.spikeSorting{1}.manuallyCurated=1;
                ProcessCellMetrics('session',session);
                figobj=findobj('Type','Figure');
                index=arrayfun(@(x) isempty(x.Name),figobj,'UniformOutput',1);
                close(figobj(index));
                clear session
        end
    end
end