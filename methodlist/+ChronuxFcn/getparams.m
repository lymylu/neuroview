function Params=getparams(option)
% get parameters from Chronux toolbox
% for magnitude coherence, psth, binspikes,multitaper spectrogram....
        NeuroMethod.Checkpath('chronux');
        switch option
            case 'cohgramc'
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
            case 'binspikes'
            case 'psth'
            case 'mtsepctrumgramc'
        end
end