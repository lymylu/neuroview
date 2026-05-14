classdef Spectrogram < NeuroMethod & NeuroPlot.NeuroPlot & NeuroResult
    %SPECTROGRAM：object for calculate and plot Spectrogram for timepoint and timeduration NeuroResult.end
    %Spectro: {event}(time*frequency*channel)
    %f_lfp:numeric (1*frequency)
    %t_lfp:{1*event}(1*time) for timeduration; time*1 for timepoint
    % Filename: if ischar (matfile formation) or isdir(hdf5 formation), other field could be empty
    % using Spectrogram.slice() to load all data to the memory
    %See also: NeuroResult, NeuroPlot.NeuroPlot
    properties(Access='public')   
        Spectro
        f_lfp
        t_lfp
        averageParams
    end
    properties(SetObservable,Access=private)
        Specdataplot
        f_lfpplot;
    end
    methods (Access='public')
        function obj=Spectrogram(varargin)
            if nargin==1
                data=varargin{1};
                for i=1:length(data)
                    varname=fieldnames(data(i));
                    for j=1:length(varname)
                        try
                            eval(['obj(i).',varname{j},'=data(i).',varname{j},';']);
                        catch
                            warning([varname{j},'is not the default vars in Spectrogram object.']);
                        end
                    end
                end
            end
        end
        % method for Basic Tag
        function obj = Taginfo(obj, Tagname, informationtype, information)
            try
                addprop(obj,Tagname);
            end
            obj=Taginfo@BasicTag(obj,Tagname,informationtype, information);
        end
        function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
             [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                  [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
        end
         % methods for NeuroPlot
         function Figurepanel=createplot(obj,variablename,varargin)
            Figurepanel=NeuroPlot.figurecontrol;
            Figurepanel=Figurepanel.create([],'Spectrogram',strcat('imagesc',varargin{1}));
            Figurepanel.figpanel.Title=variablename;
        end
        function [S_tmp,t_lfp,f_lfp]=load(obj,channelindex,eventindex)
            % load the data from Spectrogram object for given channel and event
           if ~isempty(obj.Filename) % load from h5file mode.
            [S_tmp,f_lfp,t_lfp]=obj.Loadh5(channelindex,eventindex);
           else
                S_tmp=obj.Loadmat('Spectro',{eventindex},{-1,-1,channelindex});
                t_lfp=obj.Loadmat('t_lfp',{eventindex},{-1});
                f_lfp=obj.Loadmat('f_lfp',[],{-1});
           end
        end
        function plot(obj,Figurepanel,PanelManagement)
            % plot function for NeuroPlot.figurecontrol
            % See also:NEUROPLOT.FIGURECONTROL
            LFPinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'LFPinfo'));
            EVTinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'EVTinfo'));
            eventindex=EVTinfo.getIndex;
            channelindex=LFPinfo.getIndex;
            [S_tmp,t_lfp,f_lfp]=obj.load(channelindex,eventindex);
            % for duration only supports one event epoch 
            % for timepoint, each t_lfp{} is equal.
            if iscell(t_lfp)
                t_lfp=t_lfp{1};
            end
            % transfer S_tmp to matrix
            S_tmp=reshape(cell2mat(S_tmp),size(S_tmp{1},1),size(S_tmp{1},2),[],size(S_tmp{1},3));
            S_tmp=permute(S_tmp,[1,2,4,3]);
            obj.Specdataplot=S_tmp;
            obj.t_lfpplot=t_lfp;
            obj.f_lfpplot=f_lfp;
            obj.channelindexplot=channelindex;
            Figurepanel.plot(t_lfp,f_lfp,S_tmp);
        end
        function [Spectro,f_lfp,t_lfp]=Loadh5(obj,ChannelIndex,EVTIndex,TimeIndex,FrequencyIndex)
            % See also: NEURORESULT.LOADH5
            if nargin<4
                FrequencyIndex=-1;
            end
            if nargin<3
                TimeIndex=-1;
            end
            t_lfp=Loadh5@NeuroResult(obj,obj.Filename,'/event/time','/t_lfp',{EVTIndex},{-1,-1});
            try
                 currenttime=findobj('Tag','currenttime');
                 currentrange=findobj('Tag','timerange');
                 currenttime=str2num(currenttime.String);
                 currentrange=str2num(currentrange.String);
                 t_lfp=obj.t_lfp{:};
                 [~,index1]=min(abs(t_lfp-(currenttime+currentrange(1))));
                 [~,index2]=min(abs(t_lfp-(currenttime+currentrange(2))));
                 TimeIndex=false(size(t_lfp));
                 TimeIndex(index1:index2)=true;
             catch
                 TimeIndex=-1;
             end
            Spectro=Loadh5@NeuroResult(obj,obj.Filename,'/event/time*frequency*channel','/Spectro',{EVTIndex},{TimeIndex,FrequencyIndex,ChannelIndex});
            f_lfp=Loadh5@NeuroResult(obj,obj.Filename,'/event/frequency','/f_lfp',[],{-1,FrequencyIndex});
            t_lfp=Loadh5@NeuroResult(obj,obj.Filename,'/event/time','/t_lfp',{EVTIndex},{-1,TimeIndex});
        end
        function info=Saveh5(obj,dirname)
            % transfer Spectrogram objects to the h5 file according to each
            % fileTag.Name.
            name=obj.getTaginfo('Tagvalue','fileTag');
            for c=1:length(obj)
                savefilename=fullfile(dirname,name{c});
                info(c)=Spectrogram();
                info(c).fileTag=obj(c).fileTag;
                info(c).Filename=savefilename;
                Saveh5@NeuroResult(obj,savefilename,'Spectro','/event/time*frequency*channel','/Spectro');
                Saveh5@NeuroResult(obj,savefilename,'t_lfp','/event/time','/t_lfp');
                Saveh5@NeuroResult(obj,savefilename,'f_lfp','frequency','/f_lfp');
                variablenames=fieldnames(obj(c).Params);
                for i=1:length(variablenames)
                    tmp=eval(['obj(c).Params.',variablenames{i},';']);
                    eval(['info(c).Params.',variablenames{i},'=tmp;']);
                end
            end
        end
        function obj=slice(obj,neuroresult,varargin)
            p= inputParser();
            addParameter(p,'Channelindex',~neuroresult.LFPinfo.blackchannel,@islogical);
            addParameter(p,'EVTindex',~neuroresult.EVTinfo.blackevt,@islogical);
            parse(p,varargin{:});
            [obj.Spectro,obj.t_lfp,obj.f_lfp]=obj.load(p.Results.Channelindex,p.Results.EVTindex);
        end
        function obj=AverageSubject(obj,neuroresult,averageparams)
            % generate the averaged Spectral from given channelname, eventname or frequency band range.
            % 'All' means average all data ,'none': no average,
            % cell(string) means average among each string type.
            % generate averaged channel data
            if ~isempty(neuroresult.LFPinfo.blackchannel)
                 blackchannel=neuroresult.LFPinfo.blackchannel;
            else
                 blackchannel=false(size(neuroresult.LFPinfo.channeldescription));
            end
            if ~isempty(neuroresult.EVTinfo.blackevt)
                  blackevt=neuroresult.EVTinfo.blackevt;
            else
                blackevt=false(size(neuroresult.EVTinfo.description));
            end
            channelname=averageparams.Channel;
            eventname=averageparams.Event;
            freqband=averageparams.Frequency;
            baselinetime=averageparams.Baseline;
            baselinecorrectmode=averageparams.Correctmode;
            [Spectro,t_lfp,f_lfp]=obj.load(true(length(blackchannel),1),true(length(blackevt),1));
            % Spectro is the matrix {event}(time*frequency*channel)
            % note that for averagesubject, the dimension of each event
            % should be equal, thus transfer it to time*frequency*channel*event;
            if iscell(t_lfp)
                t_lfp=t_lfp{1};
            end
            obj.t_lfp=t_lfp;
            
            Spectro=reshape(cell2mat(Spectro),size(Spectro{1},1),size(Spectro{1},2),[],size(Spectro{3},3));
            Spectro=permute(Spectro,[1,2,4,3]);
           
            if averageparams.AverageBeforeCorrection
            if ~isempty(baselinetime)
               Spectro=basecorrect(Spectro,t_lfp,baselinetime(1),baselinetime(2),baselinecorrectmode);
            end
            end
            if ischar(eventname)&&strcmp(lower(eventname),'all')
                Spectro=mean(Spectro(:,:,:,~blackevt),4);
            elseif ischar(eventname)&&strcmp(lower(eventname),'none')
                Spectro=Spectro(:,:,:,~blackevt);
            else
                if ischar(eventname)&&strcmp(lower(eventname),'separate')
                    eventname=unique(neuroresult.EVTinfo.description);
                end
                tmpS=[];
                for j=1:length(eventname)
                   if islogical(eventname{j})
                       assert(all(size(eventname{j})==size(blackevt)));
                       tmpS(:,:,:,j)=mean(Spectro(:,:,:,eventname{j}&~blackevt),4);
                   else
                       tmpS(:,:,:,j)=mean(Spectro(:,:,:,ismember(neuroresult.EVTinfo.description,eventname{j})&~blackevt),4);
                   end
                end
                Spectro=tmpS;
                averageparams.Event=eventname;
            end
            if ~averageparams.AverageBeforeCorrection
            if ~isempty(baselinetime)
               Spectro=basecorrect(Spectro,t_lfp,baselinetime(1),baselinetime(2),baselinecorrectmode);
            end
            end
            if ischar(channelname)&&strcmp(lower(channelname), 'all')
               Spectro=mean(Spectro(:,:,~blackchannel,:),3);
            elseif ischar(channelname)&&strcmp(lower(channelname),'none')
               Spectro=Spectro(:,:,~blackchannel,:);
            else
                if ischar(channelname)&&strcmp(lower(channelname),'separate')
                     channelname=unique(neuroresult.LFPinfo.channeldescription);
                end
                tmpS=[];
                for j=1:length(channelname)
                    if islogical(channelname{j})
                       assert(all(size(channelname{j})==size(blackchannel)));
                       tmpS(:,:,j,:)=mean(Spectro(:,:,channelname{j}&~blackchannel,:),3);
                    else
                        tmpS(:,:,j,:)=mean(Spectro(:,:,ismember(neuroresult.LFPinfo.channeldescription,channelname{j})&~blackchannel,:),3);
                    end
                end
                Spectro=tmpS;
                averageparams.Channel=channelname;
            end  
            if ischar(freqband)&&strcmp(lower(freqband),'none')
                Spectro=Spectro;
            else
                tmpS=[];
                    for j=1:length(freqband)
                        tmpS(:,j,:,:)=mean(Spectro(:,f_lfp>=freqband{j}(1)&f_lfp<=freqband{j}(2),:,:),2);
                    end
                Spectro=tmpS;
                % obj.f_lfp=1:length(freqband);
        end
            obj.Spectro=Spectro;
            obj.t_lfp=t_lfp;
            obj.f_lfp=f_lfp;
            obj.averageParams=averageparams;
        end
         function data=get(obj,varname)
             % get the protected properties
             data=eval(['obj.',varname,';']);
         end
        end
    methods(Static)
        function Params = getParams
             method=listdlg('PromptString','Spectrum method','ListString',{'Gabor','windowFFT','Multi-taper'});
                switch method
                    case 1
                        prompt={'fpass '};
                        title='input Params';
                        lines=1;
                        def={'0 100'};
                        x=inputdlg(prompt,title,lines,def,'on');
                        Params.fpass=str2num(x{1});
                        Params.methodname='Gabor';
                    case 2
                        prompt={'slide window size','fpass'};
                        title='input Params';
                        lines=2;
                        def={'0.1','0 100'};
                        x=inputdlg(prompt,title,lines,def,'on');
                        Params.windowsize=str2num(x{1}); %%  signal length for FFT 
                        Params.methodname='windowFFT';
                        Params.fpass=str2num(x{2});
                        NeuroMethod.Checkpath('STEP');
                    case 3
                        prompt={'taper size','fpass','pad','slide window size and step'};
                        title='input Params';
                        lines=4;
                        def={'3 5','0 100','0','0.5 0.1'};
                        x=inputdlg(prompt,title,lines,def,'on');
                        Params.methodname='Multi-taper';
                        Params.windowsize=str2num(x{4});
                        Params.fpass=str2num(x{2});
                        Params.pad=str2num(x{3});
                        Params.tapers=str2num(x{1});
                        Params.err=0;
                        Params.trialave=0;
                        NeuroMethod.Checkpath('chronux');                   
                end           
        end
        function neuroresult = cal(params,objmatrix,resultname)
            neuroresult = cal@NeuroMethod(params,objmatrix,resultname,'Spectrogram');
        end
        function neuroresult = recal(params,neuroresult,resultname)
            % neuroresult.Spectrogram: {event}(time*frequency*channel);
            % neuroresult.t_lfp:{event}(time,1);
            % neuroresult.f_lfp:(1,freq);
            if isprop(neuroresult,'Spectrogram')
                currentname=neuroresult.Spectrogram.getTaginfo('Tagvalue','fileTag');
                if contains(resultname,currentname)
                    warning([resultname,'is in the current result, skip.']);
                    return;
                end
            end
            % return neuroresult subject
             obj=Spectrogram();
             params.Fs=neuroresult.LFPinfo.Fs;
             obj.Params=params;
            % % % 
            multiWaitbar(['Calculating',char(neuroresult.Subjectname)],0);
            process=0;
            for j=1:length(neuroresult.LFPdata)
            switch neuroresult.EVTinfo.timetype
                case 'timepoint'
                     time{j}=linspace(neuroresult.EVTinfo.timerange(1),neuroresult.EVTinfo.timerange(2),size(neuroresult.LFPdata{j},1));
                case 'timeduration'
                     time{j}=linspace(neuroresult.EVTinfo.time(j,1),neuroresult.EVTinfo.time(j,2),size(neuroresult.LFPdata{j},1));
                end
            end                
            for j=1:length(neuroresult.LFPdata)
                for i=1:size(neuroresult.LFPdata{j},2) 
                    switch obj.Params.methodname
                        case 'Gabor'
                             obj.Spectro{j}(:,:,i)=abs(awt_freqlist(neuroresult.LFPdata{j}(:,i),obj.Params.Fs,obj.Params.fpass(1):obj.Params.fpass(2)));
                             obj.f_lfp=obj.Params.fpass(1):obj.Params.fpass(2);
                        case 'windowFFT'
                             [~,Spec_tmp] = sub_stft(neuroresult.LFPdata{j}(:,i), time{j}, time{j}, obj.Params.fpass(1):obj.Params.fpass(2), obj.Params.Fs, obj.Params.windowsize);
                             obj.Spectro{j}(:,:,i)=permute(Spec_tmp,[2,1,3,4]);
                             obj.f_lfp=obj.Params.fpass(1):obj.Params.fpass(2);
                        case 'Multi-taper'
                             [Spec_tmp,~,f]=mtspecgramc(neuroresult.LFPdata{j}(:,i),obj.Params.windowsize,obj.Params);
                             obj.f_lfp=f;
                             obj.Spectro{j}(:,:,i)=Spec_tmp;
                    end  
                end
                    process=process+1/(size(neuroresult.LFPdata,2));
                    multiWaitbar(['Calculating',char(neuroresult.Subjectname)],process);
                    switch neuroresult.EVTinfo.timetype
                        case 'timepoint' % relative time
                            obj.t_lfp{j}=linspace(neuroresult.EVTinfo.timerange(1),neuroresult.EVTinfo.timerange(2),size(obj.Spectro{j},1));
                        case 'timeduration' % absolute time
                            obj.t_lfp{j}=linspace(neuroresult.EVTinfo.time(j,1),neuroresult.EVTinfo.time(j,2),size(obj.Spectro{j},1));
                    end
            end
            obj.Taginfo('fileTag','Name',resultname);
            obj.t_lfp=cellfun(@(x) x',obj.t_lfp,'UniformOutput',0); % keep the t_lfp time*1 numeric.
            try
                neuroresult.addprop('Spectrogram');
                neuroresult.Spectrogram=obj;
            catch
                neuroresult.Spectrogram=cat(1,neuroresult.Spectrogram,obj);
            end
            %multiWaitbar(['Calculating',char(neuroresult.Subjectname)],'close');
        end
        function averageparams=getAverageparams(varargin)
            p=inputParser;
            addParameter(p,'Channel','none');
            addParameter(p,'Event','separate',@NeuroMethod.CheckAverageInput);
            addParameter(p,'Baseline',[-1,0],@isnumeric);
            addParameter(p,'Correctmode','zscore',@ischar);
            addParameter(p,'Frequency','none',@NeuroMethod.CheckAverageInput);
            addParameter(p,'AverageBeforeCorrection',false,@islogical);
            if nargin>1
                parse(p,varargin{:});
                averageparams=p.Results;
            else
                title='Spectrogram average params';
                prompt={'channel average mode','event average mode','frequency average mode','baselinecorrect','baselinecorrect mode','average before correct'};
                lines=6;
                def={'separate','separate','none','-1,0','subtract','0'};  
                output=inputdlg(prompt,title,lines,def,'on');
                [~,averageparams.Channel]=NeuroMethod.CheckAverageInput(output{1});
                [~,averageparams.Event]=NeuroMethod.CheckAverageInput(output{2});
                [~,averageparams.Frequency]=NeuroMethod.CheckAverageInput(output{3});
                averageparams.Baseline=str2num(output{4});
                averageparams.Correctmode=output{5};
                averageparams.AverageBeforeCorrection=logical(str2num(output{4}));
            end
        end
    end

end