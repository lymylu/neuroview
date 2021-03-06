classdef PowerSpectralDensity <NeuroMethod
    %   PSD方法 运算，参数设置，以及画图。
    properties 
    end
    methods (Access='public')
        function obj = getParams(obj)
            %  定义计算方法和参数
             method=listdlg('PromptString','选择PSD的分析方法','ListString',{'Multitaper','FastFFT'});
                switch method
                    case 1
                    prompt={'tapers ','fpass ','segwidth ','segave '};
                    title='输入参数';
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
                    title='输入参数';
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
        function obj = cal(obj,objmatrix,DetailsAnalysis)
            %% load数据
            obj.methodname='PowerSpectralDensity';
            obj.Params.Fs=str2num(objmatrix.LFPdata.Samplerate);
            [data,eventdescription,channeldescription] = obj.loadData(objmatrix,DetailsAnalysis);
            dataall=[];
            for i=1:length(data)
                dataall=cat(1,dataall,data{i});
            end
            data=dataall;
            %% 从这里开始计算。
            for i=1:size(data,2)
                for j=1:size(data,3)
                    switch obj.Params.methodname
                            case 'Multitaper'
                                 [S(:,:,i,j),f]=mtspectrumsegc(data(:,i,j),obj.Params.segwidth,obj.Params,obj.Params.segave);
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
                                 if obj.Params.segave==1;
                                    S(:,i,j)=mean(SS,2);
                                    S_PSD(:,i,j)=mean(SS_PSD,2);
                                 else
                                     S(:,:,i,j)=SS;
                                     S_PSD(:,:,i,j)=SS_PSD;
                                 end
                    end  
                end
            end
                     switch obj.Params.methodname
                         case 'Multitaper'
                             obj.Result.S=squeeze(S);
                             obj.Constant.f=f;
                         case 'FastFFT'
                             obj.Result.S=squeeze(S);
                             obj.Result.S_PSD=squeeze(S_PSD);
                             obj.Constant.f=f;
                             obj.Description.S_PSD={'f','channel'};
                     end
                     obj.Description.S={'f','channel'};
                     obj.Description.channeldescription=channeldescription;
                     obj.Description.eventdescription=eventdescription;
                     
        end
        function [data,eventdescription,channeldescription]=loadData(obj,objmatrix,DetailsAnalysis)
            [data, ~,eventdescription,channeldescription]=loadData@NeuroMethod(obj,objmatrix,DetailsAnalysis,'LFP');
        end
        function savematfile=writeData(obj,objmatrix,savematfile,option)
            savematfile=writeData@NeuroMethod(obj,objmatrix,savematfile,option);
        end   
    end
end