classdef PowerSpectralDensity < NeuroResult & NeuroPlot.NeuroPlot
    %   PSD analysis Not finished
    properties 
        Methodname='PowerSpectralDensity';
        Params
        Result
    end
    methods (Access='public')
        function obj = getParams(obj)
            % 
             method=listdlg('PromptString','Select the PSD method','ListString',{'Multitaper','FastFFT'});
                switch method
                    case 1
                    prompt={'tapers ','fpass ','segwidth ','segave '};
                    title='MultiTaper PSD using chronux';
                    lines=4;
                    def={'3 5','0 100','2','1'};
                    x=inputdlg(prompt,title,lines,def,'on');
                    obj.Params.tapers=str2num(x{1});
                    obj.Params.pad=0;
                    obj.Params.err=0;
                    obj.Params.trialave=1;
                    obj.Params.fpass=str2num(x{2});
                    obj.Params.segwidth=str2num(x{3});
                    obj.Params.segave=str2num(x{4});
                    obj.Params.methodname='Multitaper';
                    case 2
                    prompt={'fft signal length','fpass','segwidth','segave'};
                    title='FFT PSD';
                    lines=4;
                    def={'1000','0 100','2','1'};
                    x=inputdlg(prompt,title,lines,def,'on');
                    obj.Params.L=str2num(x{1}); %%  signal length for FFT 
                    obj.Params.methodname='FastFFT';
                    obj.Params.fpass=str2num(x{2});
                    obj.Params.segwidth=str2num(x{3});
                    obj.Params.segave=str2num(x{4});
                end           
        end
        function obj=inherit(obj,neuroresult)
                     variablenames=fieldnames(neuroresult);
                for i=1:length(variablenames)
                    eval(['obj.',variablenames{i},'=neuroresult.',variablenames{i}]);
                end
        end
        function obj = cal(obj,objmatrix,DetailsAnalysis)
            %% load data
            if strcmp(class(objmatrix),'NeuroData')
                dataoutput=objmatrix.LoadData(DetailsAnalysis);
            else
                tmpdata=matfile(objmatrix.Datapath);
                dataoutput=eval(['NeuroResult(tmpdata.',DetailsAnalysis,')']);
            end
             obj=obj.inherit(dataoutput);
             obj.Params.Fs=dataoutput.LFPinfo.Fs;
            for i=1:length(dataoutput.LFPdata)
                dataall=cat(1,dataall,dataoutput.LFPdata{i});
            end
            dataoutput=dataoutput.Split2Splice;
            %% cal PSD
            for i=1:size(data,2) % for each channel
                    switch obj.Params.methodname
                            case 'Multitaper'
                                 [S(:,:,i),f]=mtspectrumsegc(dataoutput.LFPdata(:,i),obj.Params.segwidth,obj.Params,obj.Params.segave);
                            case 'FastFFT'
                                 segnum=fix(size(data,1)/(obj.Params.segwidth*obj.Params.Fs));
                                 T=1/obj.Params.Fs;
                                 t=(0:obj.Params.L-1)*T;
                                 NFFT=2^nextpow2(obj.Params.L);
                                 f=obj.Params.Fs/2*linspace(0,1,NFFT/2+1);
                                 f_idx=find(f>obj.Params.fpass(1)&f<obj.Params.fpass(2)); 
                                 f=f(f_idx); %% region of interest
                                 for k=1:segnum
                                 temp=fft(data(1+obj.Params.segwidth*obj.Params.Fs*(k-1):obj.Params.segwidth*obj.Params.Fs*k,i,j),NFFT)/obj.Params.L;
                                 Stmp=2*abs(temp(1:NFFT/2+1)); 
                                 SS(:,k)=Stmp(f_idx);% fft results, in amplitude
                                 S_PSDtmp=2*(abs(temp(1:NFFT/2+1))).^2;
                                 SS_PSD(:,k)=S_PSDtmp(f_idx);%fft result, in power
                                 end 
                                 if obj.Params.segave==1
                                    S(:,:,i)=mean(SS,2);
                                    S_PSD(:,:,i)=mean(SS_PSD,2);
                                 else
                                     S(:,:,i)=SS;
                                     S_PSD(:,:,i)=SS_PSD;
                                 end
                end
            end
                     switch obj.Params.methodname
                         case 'Multitaper'
                             obj.Result.S=squeeze(S);
                             obj.Result.f_lfp=f;
                         case 'FastFFT'
                             obj.Result.S=squeeze(S);
                             obj.Result.S_PSD=squeeze(S_PSD);
                             obj.Result.f_lfp=f;
                     end        
        end
        %%% plot function
        
    end
end