classdef FiringProperties < NeuroMethod
    %% calculate the firing properties using CellExplorer
    properties
    end
    methods(Static)
        function cal(objmatrix)
            % objmatrix (SPKData)
                basepath=objmatrix.SPKdata.Filename;
                session = sessionTemplate(char(basepath),'showGUI',true);
                cellexplorermat=dir('*.cellinfo.mat');
                for i=1:length(cellexplorermat)
                    system(['rm ' cellexplorermat(i).name]);
                end
                ProcessCellMetrics('session',session,'getWaveformsFromDat',true);
                figobj=findobj('Type','Figure');
                index=arrayfun(@(x) isempty(x.Name),figobj,'UniformOutput',1);
                close(figobj(index));
                clear session
        end
    end
end