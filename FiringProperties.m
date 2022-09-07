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
                    ProcessCellMetrics('session',session);
                    case 'Phy' % further corrected
                        session.spikeSorting{1}.format='Phy';
                        session.spikeSorting{1}.method='Phy';
                        session.spikeSorting{1}.manuallyCurated=1;
                        session.spikeSorting{1}.relativePath=strrep(objmatrix.SPKdata.Filename,basepath,'');
                        ProcessCellMetrics('session',session,'getWaveformsFromDat',true);
                end
               
                figobj=findobj('Type','Figure');
                index=arrayfun(@(x) isempty(x.Name),figobj,'UniformOutput',1);
                close(figobj(index));
                clear session
        end
    end
end