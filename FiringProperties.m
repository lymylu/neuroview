classdef FiringProperties < NeuroMethod
    %% calculate the firing properties using CellExplorer
    properties
    end
    methods(Static)
        function cal(objmatrix)
            % objmatrix (SPKData)
                basepath=objmatrix.SPKdata.Filename;
                if isempty(dir(fullfile(basepath,'*.cell_metrics.cellinfo.mat')))
                    if isfield(objmatrix.ChannelTag,'ChannelPosition') % prb format auto add the electrode mapping
                        session = sessionTemplate(char(basepath));
                        shankids=unique(objmatrix.ChannelTag.ChannelPosition(:,4));
                        shank=objmatrix.ChannelTag.ChannelPosition(:,4);
                        channelids=objmatrix.ChannelTag.ChannelPosition(:,1);
                        for i=1:length(shankids)
                            session.extracellular.electrodeGroups.channels{i}=channelids(shank==i)';
                        end
                        session.extracellular.nElectrodeGroups=length(shankids);
                        session.extracellular.nChannels=length(shank);
                        session = sessionTemplate(session,'showGUI',true);
                    else   
                        session = sessionTemplate(char(basepath),'showGUI',true);
                    end
                    cellexplorermat=dir('*.cellinfo.mat');
                    for i=1:length(cellexplorermat)
                        if ~ispc()
                        system(['rm ' cellexplorermat(i).name]);
                        else
                            system(['del ' cellexplorermat(i).name]);
                        end
                    end
                    try
                        ProcessCellMetrics('session',session,'getWaveformsFromDat',true);
                    figobj=findobj('Type','Figure');
                    index=arrayfun(@(x) isempty(x.Name),figobj,'UniformOutput',1);
                    close(figobj(index));
                    clear session
                    catch ME
                        disp(ME);
                    end
                end
        end
    end
end