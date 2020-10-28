classdef NeuroMethod < dynamicprops
    %PowerSpectralDensity PartialDirectedCoherence PerieventSpectrogram 
    %InstantaneousAmplitudeCrosscorrelations PhaseAmplitudeCoupling
    %FiringRate PerieventFiringHistogram
    %PhaseLockingValue SpikeTriggeredPotential
    %Cross-cohereohistogram
    properties
        methodname=[];
        Params=[];
        Result=[];
        Constant=[];
        Description=[];
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
                error(['lack of the toolbox',option,', please add the toolboxes to the workpath!']);
            end
        end
    end
end

        

