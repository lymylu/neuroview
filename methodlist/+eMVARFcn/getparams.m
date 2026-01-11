function Params=getparams
        NeuroMethod.Checkpath('eMVAR');
        PDClist={'Normal','Generalized','Extended','Delayed'};
        PDCname={'PDC','GPDC','EPDC','DPDC'};
        PDCmode=listdlg('PromptString','PDC method','ListString',PDClist,'Selectionmode','Multiple');
        obj.Params.methodname='Partial Directed coherence';
        prompt={'mvar estimation algorithm (see mvar.m)', 'max Model order', 'slide window size','fft points','fpass','downsampleratio'};
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
end