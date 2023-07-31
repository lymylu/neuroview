classdef PowerSpectralDensity < NeuroMethod & NeuroPlot.NeuroPlot
    %   PSD analysis finished
    properties 
        S
        f_lfp
        S_PSD
        filename=[];
    end
    methods (Access='public')
        function obj=PowerSpectralDesity(varargin)
            if nargin==1
                obj.filename=varargin{1};
            end
        end
        function [tmpPSD]=getAverage(obj,neuroresult,channelname,eventname,freqband)
            % generate the averaged PSD from given channelname, eventname or frequency band range.
            % 'All' means average all data ,'none': no average,
            % cell(string) means average among each string type.
            % generate averaged channel data
            if strcmp(channelname, 'All')
                    for i=1:length(obj.S)
                        obj.S{i}=mean(obj.S{i},2);
                    end
            elseif strcmp(channelname,'none')
                obj.S=obj.S;
            else
                tmpS=[];
                for i=1:length(obj.S)
                for j=1:length(channelname)
                    tmpS{i}(:,j)=mean(obj.S{i}(:,ismember(neuroresult.LFPinfo.channeldescription,channelname{j})),2);
                end
                end
                obj.S=tmpS;
            end
            if strcmp(eventname,'All')
                tmpS=[];
                eventlength=length(obj.S);
                tmpS{1}=cell2mat(obj.S);
                tmpS{1}=reshape(obj.S,length(obj.f_lfp),[],eventlegnth);
                tmpS{1}=squeeze(mean(tmpS{1},3));
                obj.S=tmpS;
            elseif strcmp(eventname,'none')
                obj.S=obj.S;
            else
                tmpS=[];
                for i=1:length(eventname)
                    eventlength=sum(ismember(neuroresult.EVTinfo.eventdescription,eventname{i}));
                    tmpS{i}=cell2mat(obj.S(ismember(neuroresult.EVTinfo.eventdescription,eventname{i})));
                    tmpS{i}=reshape(tmpS{i},length(obj.f_lfp),[],eventlength);
                    tmpS{i}=squeeze(mean(tmpS{i},3));
                end
                obj.S=tmpS;
            end
            if strcmp(freqband,'All')
                obj.S=cellfun(@(x) mean(x,1),'UniformOutput',0);
            elseif strcmp(freqband,'none')
                obj.S=obj.S;
            else
                tmpS=[];
                for i=1:length(obj.S)
                    for j=1:length(freqband)
                        tmpS{i}(j,:)=mean(obj.S{i}(obj.f_lfp>=freqband{j}(1)&obj.f_lfp<=freqband{j}(2),:),1);
                    end
                end
                obj.S=tmpS;
            end
            tmpPSD=obj.S;
        end
        function Figurepanel=createplot(obj,variablename,plottype)
            % for timepoint or timeduration PSD plot are the same.
            Figurepanel=NeuroPlot.figurecontrol;
            Figurepanel=Figurepanel.create('plot',0);
            Figurepanel.figpanel.Title=variablename;
        end
        function plot(obj,Figurepanel,PanelManagement)
            LFPinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'LFPinfo'));
            EVTinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'EVTinfo'));
            if ~isempty(obj.filename) % save as h5file mode.
            [S_tmp,f_lfp]=obj.readh5(LFPinfo{:}.getIndex('ChannelIndex'),EVTinfo{:}.getIndex('EventIndex'));
            else
            for i=1:length(obj.S)
                S_tmp(:,:,i)=obj.S{i};
            end
            S_tmp=S_tmp(:,LFPinfo{:}.getIndex('ChannelIndex'),EVTinfo{:}.getIndex('EventIndex'));
            f_lfp=obj.f_lfp;
            end
            Figurepanel.plot(f_lfp,S_tmp);
        end
        function [S,f_lfp]=readh5(obj,ChannelIndex,EVTIndex)
            EVTatt=h5readatt(filename,'/S');
            EVTatt=EVTatt(EVTIndex);
            for i=1:length(EVTatt)
                S(:,:,i)=h5read(obj.filename,['/S/',EVTatt{i}],[ChannelIndex,Inf]);
            end
            f_lfp=h5read(obj.filename,'/f_lfp');
        end
        function saveh5(obj,filename)
            for i=1:length(obj.S)
            h5create(filename,['/S/',num2str(i)],size(obj.S{i}));
            h5write(filename,['/S/',num2str(i)],obj.S{i});
            if ~isempty(obj.S_PSD)
            h5create(filename,'/S_PSD/',num2str(i)',size(obj.S_PSD{i}));
            h5write(filename,'/S_PSD/',num2str(i)',obj.S_PSD{i});
            end
            end
            h5writeatt(filename,'/','methodname','PowerSpectralDensity');
            h5create(filename,'/f_lfp',size(obj.f_lfp));
            h5write(filename,'/f_lfp',obj.f_lfp);
            variablenames=fieldnames(obj.Params);
            for i=1:length(variablenames)
                tmp=eval(['obj.Params.',variablenames{i},';']);
                 if ischar(tmp)
                    Datatype='string';tmp={tmp};
                else
                    Datatype='double';
                end
                h5create(filename,['/Params/',variablenames{i}],size(tmp),'Datatype',Datatype)
                h5write(filename,['/Params/',variablenames{i}],tmp);
            end
        end
        function neuroresult=AverageSubject(obj,neuroresult,resultname,functionname)
            % generate the result in the subject level for further
            % statistic analysis.
            % it will redirect to custom scripts
            % neuoresult=[functionname](obj,neuroresult,resultname);
            % neuroresult provide the data information, resultname is the
            % output save variable name in NeuroResult.
            neuroresult=eval([functioname,'(obj,neuroresult,resultname);']);
        end

    end
    methods(Static)
        function Params = getParams
            % 
             method=listdlg('PromptString','Select the PSD method','ListString',{'Multitaper','FastFFT'});
                switch method
                    case 1
                    prompt={'tapers ','fpass ','segwidth ','segave '};
                    title='MultiTaper PSD using chronux';
                    lines=4;
                    def={'3 5','0 100','2','1'};
                    x=inputdlg(prompt,title,lines,def,'on');
                    Params.tapers=str2num(x{1});
                    Params.pad=0;
                    Params.err=0;
                    Params.trialave=1;
                    Params.fpass=str2num(x{2});
                    Params.segwidth=str2num(x{3});
                    Params.segave=str2num(x{4});
                    Params.methodname='Multitaper';
                    case 2
                    prompt={'fft signal length','fpass','segwidth','segave'};
                    title='FFT PSD';
                    lines=4;
                    def={'1000','0 100','2','1'};
                    x=inputdlg(prompt,title,lines,def,'on');
                    Params.L=str2num(x{1}); %%  signal length for FFT 
                    Params.methodname='FastFFT';
                    Params.fpass=str2num(x{2});
                    Params.segwidth=str2num(x{3});
                    Params.segave=str2num(x{4});
                end           
        end
        function neuroresult= cal(params,objmatrix,DetailsAnalysis,resultname)
            % cal PSD and save the result as a resultname variable (class PSD) in
            % NeuroResult
             neuroresult = cal@NeuroMethod(params,objmatrix,DetailsAnalysis,resultname,'PowerSpectralDensity');
        end
        function neuroresult = recal(params,neuroresult,resultname)
             obj=PowerSpectralDensity();
             params.Fs=neuroresult.LFPinfo.Fs;
             obj.Params=params;
             switch neuroresult.EVTinfo.timetype
                 case 'timeduration'
                     neuroresult=neuroresult.Split2Splice;
             end
            %% cal PSD
            for j=1:size(neuroresult.LFPdata,2) % for each trial
                for i=1:size(neuroresult.LFPdata{j},2) % for each channel
                    neuroresult.LFPdata{j}(:,i)=detrend(neuroresult.LFPdata{j}(:,i));
                    neuroresult.LFPdata{j}(:,i)=neuroresult.LFPdata{j}(:,i)-mean(neuroresult.LFPdata{j}(:,i),1);
                    switch obj.Params.methodname
                            case 'Multitaper'
                                 [S{j}(:,i,:),f]=mtspectrumsegc(neuroresult.LFPdata{j}(:,i),obj.Params.segwidth,obj.Params,obj.Params.segave);
                            case 'FastFFT'
                                 segnum=fix(size(neuroresult.LFPdata{j}(:,i),1)/(obj.Params.segwidth*obj.Params.Fs));
                                 T=1/obj.Params.Fs;
                                 t=(0:obj.Params.L-1)*T;
                                 NFFT=2^nextpow2(obj.Params.L);
                                 f=obj.Params.Fs/2*linspace(0,1,NFFT/2+1);
                                 f_idx=find(f>obj.Params.fpass(1)&f<obj.Params.fpass(2)); 
                                 f=f(f_idx); %% region of interest
                                 for k=1:segnum
                                 temp=fft(neuroresult.LFPdata{j}(1+obj.Params.segwidth*obj.Params.Fs*(k-1):obj.Params.segwidth*obj.Params.Fs*k,i),NFFT)/obj.Params.L;
                                 Stmp=2*abs(temp(1:NFFT/2+1)); 
                                 SS(:,k)=Stmp(f_idx);% fft results, in amplitude
                                 S_PSDtmp=2*(abs(temp(1:NFFT/2+1))).^2;
                                 SS_PSD(:,k)=S_PSDtmp(f_idx);%fft result, in power
                                 end 
                                 if obj.Params.segave==1
                                    S{j}(:,i,:)=mean(SS,2);
                                    S_PSD{j}(:,i,:)=mean(SS_PSD,2);
                                 else
                                     S{j}(:,i,:)=SS;
                                     S_PSD{j}(:,i,:)=SS_PSD;
                                 end
                    end
                end
            end
                     switch obj.Params.methodname
                         case 'Multitaper'
                             obj.S=S;
                             obj.f_lfp=f;
                         case 'FastFFT'
                             obj.S=S;
                             obj.S_PSD=S_PSD;
                             obj.f_lfp=f;
                     end        
            try
            neuroresult.addprop(resultname);
            end
            eval(['neuroresult.',resultname,'=obj;']);
        end   
        
    end
end