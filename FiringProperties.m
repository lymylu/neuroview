classdef FiringProperties < NeuroMethod
    %% calculate the firing properties using CellExplorer
    properties
    end
    methods(Static)
        function cal(objmatrix)
                basepath=objmatrix.Datapath;
                session = sessionTemplate(basepath);
                cellexplorermat=dir('*.cellinfo.mat');
                for i=1:length(cellexplorermat)
                    system(['rm ' cellexplorermat(i).name]);
                end
                switch objmatrix.SPKdata.SortingType
                    case 'KlustaKwik'    
                    % load the extracelluar information from the xml
                    xml=dir(fullfile(objmatrix.SPKdata.Filename,'*.xml'));
                    session = import_xml2session(fullfile(objmatrix.SPKdata.Filename,xml.name),session);
                    session.extracellular.electrodeGroups = session.extracellular.spikeGroups;
                    session.extracellular.nElectrodeGroups=session.extracellular.nSpikeGroups;
                    session.spikeSorting{1}.format='neurosuite';
                    session.spikeSorting{1}.method='klustakwik'; 
                    session.spikeSorting{1}.manuallyCurated=1;
                    session.spikeSorting{1}.relativePath='';
                    case 'Phy' % further corrected
                        session.spikeSorting{i}.format='SpyKING CIRCUS';
                        session.spikeSorting{i}.method='Phy';
                        session.spikeSorting{i}.manuallyCurated=1;
                        [~,subdir]=fileparts(objmatrix.SPKdata.Filename);
                        session.spikeSorting{1}.relativePath=subdir;
                end
                ProcessCellMetrics('session',session);
                figobj=findobj('Type','Figure');
                index=arrayfun(@(x) isempty(x.Name),figobj,'UniformOutput',1);
                close(figobj(index));
                clear session
        end
    end
end