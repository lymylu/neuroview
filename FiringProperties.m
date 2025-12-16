classdef FiringProperties < NeuroMethod
    %% calculate the firing properties using CellExplorer
    properties
    end
    methods(Static)
        function cal(objmatrix)
            % objmatrix (SPKData)
                basepath=objmatrix.SPKdata.Filename;
                if isempty(dir(fullfile(basepath,'*.cell_metrics.cellinfo.mat')))
                    session = sessionTemplate(char(basepath),'showGUI',true);
                    cellexplorermat=dir('*.cellinfo.mat');
                    for i=1:length(cellexplorermat)
                        if ~ispc()
                        system(['rm ' cellexplorermat(i).name]);
                        else
                            system(['del ' cellexplorermat(i).name]);
                        end
                    end
                    ProcessCellMetrics('session',session,'getWaveformsFromDat',true);
                    figobj=findobj('Type','Figure');
                    index=arrayfun(@(x) isempty(x.Name),figobj,'UniformOutput',1);
                    close(figobj(index));
                    clear session
                end
        end
    end
end