classdef Connectivity < NeuroMethod & NeuroPlot.NeuroPlot
    % Calculate the LFP coherence between several signals 
    % Granger connectivity, Partial Directed coherence, Magnitude coherence, and so on.
    % using eMVAR toolbox, chronux toolbox and SIFT toolbox by EEGlab (support mvgc toolbox in future)
    properties
        S
        f_lfp
        filename=[];
    end

    methods
        function obj=Connectivity(varargin)
            if nargin==1
                obj.filename=varargin{1};
            end
        end
    end
    methods(Static)
        function Params=getParams()
            methodlist={'Magnitude coherence','Partial Directed coherence','Granger Causaulity'};
            method=listdlg('PromptString','Select the Connectivity method','ListString',methodlist);
            switch method
                 case 1
                    NeuroMethod.Checkpath('chronux');
                    prompt={'taper size','fpass','pad','slide window size and step'};
                    title='params';
                    lines=4;
                    def={'3 5','0 100','0','0.5 0.1'};
                    x=inputdlg(prompt,title,lines,def,'on');
                    Params.windowsize=str2num(x{4});
                    Params.fpass=str2num(x{2});
                    Params.pad=str2num(x{3});
                    Params.tapers=str2num(x{1});
                    Params.err=0;
                    Params.trialave=0;
                    Params.methodname='Magnitude coherence';
                case 2
                    NeuroMethod.Checkpath('eMVAR');
                    PDClist={'Normal','Generalized','Extended','Delayed'};
                    PDCname={'PDC','GPDC','EPDC','DPDC'};
                    PDCmode=listdlg('PromptString','PDC method','ListString',PDClist,'Selectionmode','Multiple');
                    Params.methodname='Partial Directed coherence';
                    prompt={'mvar estimation algorithm (see mvar.m)', 'max Model order', 'epoched window size','fft points','fpass','downsampleratio'};
                    title='params';
                    lines=6;
                    def={'10','20','0.5 0.1','512','0 100','1'};
                    x=inputdlg(prompt,title,lines,def,'on');
                    Params.PDCtype=PDClist(PDCmode);
                    Params.PDCname=PDCname(PDCmode);
                    Params.mvartype=str2num(x{1});
                    Params.maxP=str2num(x{2});
                    Params.windowsize=str2num(x{3});
                    Params.fftpoints=str2num(x{4});
                    Params.fpass=str2num(x{5});
                    Params.downratio=str2num(x{6});
                case 3
                    NeuroMethod.Checkpath('mvgc')
                    

                    end                   
        end
    end
end