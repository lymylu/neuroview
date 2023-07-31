classdef Spectrogram < NeuroMethod & NeuroPlot.NeuroPlot
    properties(Access='public')   
        Spectro
        f_lfp
        t_lfp
        filename=[];
    end
    methods (Access='public')
        function obj=Spectrogram(varargin)
            if nargin==1
                obj.filename=varargin{1};
            end
        end
         %% methods for NeuroPlot
        function Figurepanel=createplot(obj,variablename)
            Figurepanel=NeuroPlot.figurecontrol;
            Figurepanel=Figurepanel.create(['imagesc-baseline'],0,obj);
            Figurepanel.figpanel.Title=variablename;
        end
        function plot(obj,Figurepanel,PanelManagement)
            LFPinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'LFPinfo'));
            EVTinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'EVTinfo'));
            if ~isempty(obj.filename) % save as h5file mode.
            [S_tmp,f_lfp,t_lfp]=obj.readh5(LFPinfo{:}.getIndex('ChannelIndex'),EVTinfo{:}.getIndex('EventIndex'));
            else
            for i=1:length(obj.Spectro)
                S_tmp(:,:,:,i)=obj.Spectro{i};
            end
            S_tmp=S_tmp(:,:,LFPinfo{:}.getIndex('ChannelIndex'),EVTinfo{:}.getIndex('EventIndex'));
            f_lfp=obj.f_lfp;
            if ~isnumeric(obj.t_lfp)
                t_lfp=obj.t_lfp{EVTinfo{:}.getIndex('EventIndex')};
            else
                t_lfp=obj.t_lfp;
            end
            end
            Figurepanel.plot(t_lfp,f_lfp,S_tmp);
        end
        function [S,f_lfp,t_lfp]=readh5(obj,ChannelIndex,EVTIndex)
            EVTatt=h5info(obj.filename,'/Spectro');
            f_lfp=h5read(obj.filename,'/f_lfp');
            try
            t_lfp=h5read(obj.filename,'/t_lfp');
            end
             c=1;d=1;
             for i=1:length(EVTatt.Datasets)
                 if EVTIndex(i)
                     datatmpsize=h5info(obj.filename,['/Spectro/',EVTatt.Datasets(i).Name]);
                     try 
                         t_lfp=h5read(obj.filename,['/t_lfp/',EVTatt.Datasets(i).Name]);
                     end
                     try
                         currenttime=findobj('Tag','currenttime');
                         currentrange=findobj('Tag','timerange');
                         currenttime=str2num(currenttime.String);
                         currentrange=str2num(currentrange.String);
                         [~,index1]=min(abs(t_lfp-(currenttime+currentrange(1))));
                         [~,index2]=min(abs(t_lfp-(currenttime+currentrange(2))));
                         t_lfp=t_lfp(index1:index2);
                         index2=index2-index1+1;
                     catch
                         index1=1;index2=datatmpsize.Dataspace.Size(1);
                     end
                     for j=1:length(ChannelIndex)
                         if ChannelIndex(j)
                            S(:,:,c,d)=h5read(obj.filename,['/Spectro/',EVTatt.Datasets(i).Name],[index1,1,j],[index2,datatmpsize.Dataspace.Size(2),1]);
                            c=c+1; 
                         end
                     end
                     d=d+1;
                 end
             end  
        end
        function saveh5(obj,filename)
            for i=1:length(obj.Spectro)
            h5create(filename,['/Spectro/',num2str(i)],size(obj.Spectro{i}));
            h5write(filename,['/Spectro/',num2str(i)],obj.Spectro{i});
            end
            h5writeatt(filename,'/','methodname','Spectrogram');
            h5create(filename,'/f_lfp',size(obj.f_lfp));
            h5write(filename,'/f_lfp',obj.f_lfp);
            if isnumeric(obj.t_lfp)
                h5create(filename,'/t_lfp',size(obj.t_lfp));
                h5write(filename,'/t_lfp',obj.t_lfp);
            else
                for i=1:length(obj.t_lfp)
                    h5create(filename,['/t_lfp/',num2str(i)],size(obj.t_lfp{i}));
                    h5write(filename,['/t_lfp/',num2str(i)],obj.t_lfp{i});
                end
            end
            variablenames=fieldnames(obj.Params);
            for i=1:length(variablenames)
                tmp=eval(['obj.Params.',variablenames{i},';']);
                if ischar(tmp)
                    Datatype='string';tmp={tmp};
                else
                    Datatype='double';
                end
                h5create(filename,['/Params/',variablenames{i}],size(tmp),'Datatype',Datatype);
                h5write(filename,['/Params/',variablenames{i}],tmp);
            end
        end
        %% methods for NeuroStat
        function obj=AverageEvent(obj)
            % average the trials level at each obj (Subjects)
            for i=1:length(obj)
                obj(i).Result=mean(obj(i).Result,4);
                obj(i).LFPdata=mean(obj(i).LFPdata,3);
            end
        end    
        function obj=AverageChannel(obj)
            for i=1:length(obj)
                obj(i).Result=mean(obj(i).Result,3);
                obj(i).LFPdata=mean(obj(i).LFPdata,2);
            end
        end    
        function statmatrix=CatAverageData(obj)
            for i=1:length(obj)
                try
                statmatrix.Result(:,:,:,:,i)=obj(i).Result;
                statmatrix.LFPdata(:,:,:,i)=obj(i).LFPdata;
                catch
                    error('the events or channels are different among Subjects, may be averaged first?');
                end
            end
        end
                
    end
    methods (Access='private')          
         function Resultplotfcn_CSD(obj)
            global Resultorigin ResultSpec Spec_t origin_t f Resultorigintmp ResultSpectmp Chooseinfo matvalue Channellist Eventlist 
            eventlist=findobj(obj.NP,'Tag','EventIndex');
            channellist=findobj(obj.NP,'Tag','ChannelIndex');
            channelindex=Channellist(ismember(Channellist,channellist.String(channellist.Value)));
            eventindex=Eventlist(ismember(Eventlist,eventlist.String(eventlist.Value)));
            Chooseinfo(matvalue).Channelindex=channelindex;
            Chooseinfo(matvalue).Eventindex=eventindex;
            ResultSpectmp=ResultSpec(:,:,ismember(Channellist,channellist.String(channellist.Value)),ismember(Eventlist,eventlist.String(eventlist.Value)));
            basebegin=findobj(obj.NP,'Tag','baselinebegin');
            baseend=findobj(obj.NP,'Tag','baselineend');
            basemethod=findobj(obj.NP,'Tag','basecorrect_spec');
% % csd          
            tmpdata=basecorrect(ResultSpectmp,origin_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
            tmpdata=obj.csd_cal(tmpdata,'grouplevel','timerange',[-2,4],'filter',[65,85],'type','spectral');
            tmpdata=squeeze(mean(tmpdata,4));
%             %
            tmpobj=findobj(obj.NP,'Tag','Figpanel1');
            delete(findobj(obj.NP,'Parent',tmpobj,'Type','axes'));
            figaxes=axes('Parent',tmpobj);
            obj.csd_plot(tmpdata,origin_t,[-1.2,1.2],[],[]);
            figaxes.XLim=[min(Spec_t),max(Spec_t)];
            figaxes.YDir='reverse';
            tmpparent=findobj(obj.NP,'Tag','Figcontrol1');
            NeuroPlot.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',tmpobj);
            tmpobj=findobj(obj.NP,'Tag','Figpanel2');
            delete(findobj(obj.NP,'Parent',tmpobj,'Type','axes'));
           
%             Resultorigintmp=FilePath.origin(:,channelindex,eventindex);
            basemethod=findobj(obj.NP,'Tag','basecorrect_origin');
            tmpdata=basecorrect(Resultorigin(:,channelindex,eventindex),origin_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
%             tmpdata=obj.csd_cal(tmpdata,'grouplevel','timerange',[-0.2,0.5],'filter',[75,85],'type','origin');
%             tmpdata=squeeze(mean(tmpdata,3));
            figaxes=axes('Parent',tmpobj);
%             Resultorigintmp=Resultorigin(:,ismember(Channellist,channellist.String(channellist.Value)),ismember(Eventlist,eventlist.String(eventlist.Value)));
%             basemethod=findobj(obj.NP,'Tag','basecorrect_origin');
%             tmpdata=basecorrect(Resultorigintmp,origin_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
            tmpparent=findobj(obj.NP,'Tag','Figcontrol2');
            tmpplot=findobj(tmpparent,'Tag','plotType');
             switch tmpplot.String{tmpplot.Value}
                 case 'average' 
                     tmpdata=squeeze(mean(mean(tmpdata,3),2));
                     plot(origin_t,tmpdata);
                 case 'overlapx'
                     tmpdata=squeeze(mean(tmpdata,2));
                     plot(origin_t,tmpdata);
                 case 'overlapy'
                     tmpdata=squeeze(mean(tmpdata,3));
                     plot(origin_t,tmpdata);
                 case 'separatex'
                     tmpdata=squeeze(mean(tmpdata,2));
                     lagging=max(abs(tmpdata));
                     lagging=cumsum(repmat(max(lagging),[1,size(tmpdata,2)]));
                     plot(origin_t,bsxfun(@minus,tmpdata,lagging));
                 case 'separatey'
                     tmpdata=squeeze(mean(tmpdata,3));
                     lagging=max(abs(tmpdata));
                     lagging=cumsum(repmat(max(lagging),[1,size(tmpdata,2)]));
                     plot(origin_t,bsxfun(@minus,tmpdata,lagging));
             end
            axis tight;
            figaxes.XLim=[min(origin_t),max(origin_t)];
           
            NeuroPlot.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',tmpobj);
            tmpobj=findobj(obj.NP,'Tag','Savename');
            tmpobj1=findobj(obj.NP,'Tag','Eventtype');
            tmpobj2=findobj(obj.NP,'Tag','Channeltype');
            tmpobj.String=[tmpobj1.String{tmpobj1.Value},'_',tmpobj2.String{tmpobj2.Value}];
         end
         function CSDoutput=csd_cal(obj,varargin)
        
p=inputParser;
addRequired(p,'data');
addRequired(p,'level');
addParameter(p,'timerange','',@(x) isnumeric(x));
addParameter(p,'type',[],@(x) ischar(x));
addParameter(p,'filter',[],@(x) isnumeric(x));
addParameter(p,'caxis',[],@(x) isnumeric(x));
parse(p,varargin{:});
t=linspace(-2,4,6001);
t2=t(find(t>=p.Results.timerange(1)&t<=p.Results.timerange(2)));
data=p.Results.data;
% if ~isempty(p.Results.filter)&& size(data,4)==1
%     for i=1:size(data,3)
%     datafilt(:,:,i)=eegfilt(data(:,:,i)',1000,p.Results.filter(1),p.Results.filter(2));
%     end
%     data=permute(datafilt,[2,1,3]);
% end

if ~isempty(p.Results.timerange)
    data=data(find(t>=p.Results.timerange(1)&t<=p.Results.timerange(2)),:,:,:);
end
switch p.Results.type        
    case 'amplitude'
      for i=1:size(data,3)
            data(:,:,i)=abs(hilbert(data(:,:,i)));
      end  
    case 'spectral'
        data=squeeze(mean(data(:,p.Results.filter(1):p.Results.filter(2),:,:),2));
end
switch p.Results.level
            case 'subjectlevel'
            for i=1:size(data,3)
                figure;
                CSDoutput(:,:,i)=CSD(data(:,:,i)./1E6,1000,1E-4,'unitsLength','mm','unitsCurrent','uA','timeaxis',p.Results.timerange,'inverse',1);
                close(gcf);
            end
            case 'grouplevel'
                data=nanmean(data,3);
                figure;
                CSDoutput=CSD(data./1E6,1000,1E-4,'unitsLength','mm','unitsCurrent','uA','timeaxis',p.Results.timerange,'inverse',1);
                close(gcf);
        end
   
end
         function csd_plot(obj,CSDoutput,t,cmap,timerange,pCSDoutput)
    [x,y]=meshgrid(1:size(CSDoutput,1),1:size(CSDoutput,2));
    [x2,y2]=meshgrid(1:size(CSDoutput,1),1:0.2:size(CSDoutput,2));
     CSDoutputsmooth=(interp2(x,y,CSDoutput',x2,y2))';
     f = fspecial('gaussian',[3 3],0.2);
     timerange=[];
    CSDoutputsmooth=imfilter(CSDoutputsmooth,f,'corr','full');
     if ~isempty(pCSDoutput)
         pCSDoutputsmooth=(interp2(x,y,pCSDoutput,x2,y2))';
     end
    imagesc(gca,t,y2(:,1),(CSDoutputsmooth')); colormap jet;
    try
        hold on;
        contour(gca,t,y2(:,1),(pCSDoutputsmooth'<0.05),[1,1],'black','LineWidth',1);
    end
%     set(gca,'ydir','reverse');   
    try caxis(cmap); end
%     separate=[2.6,6.8,8.8,12.8];
%     hold on;line(gca,[timerange(1),timerange(2)],[separate(1),separate(1)],'LineWidth',1); % separate layer I and II/III
%     line(gca,[timerange(1),timerange(2)],[separate(2),separate(2)],'LineWidth',1); % separate layer II/III and layer IV
%       line(gca,[timerange(1),timerange(2)],[separate(3),separate(3)],'LineWidth',1); % separate layer IV and layer V
%        line(gca,[timerange(1),timerange(2)],[separate(4),separate(4)],'LineWidth',1); % separate layer V and layer VI
%        set(gca,'YTick',[separate(1)/2,separate(1)+(separate(2)-separate(1))/2, separate(2)+(separate(3)-separate(2))/2,separate(3)+(separate(4)-separate(3))/2,separate(4)+(16-separate(4))/2]);
%        set(gca,'YTickLabel',{'Layer I','Layer II/III','Layer IV','Layer V','Layer VI'});
%        xlabel('Time(s)');
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
        function neuroresult = cal(params,objmatrix,DetailsAnalysis,resultname)
            neuroresult = cal@NeuroMethod(params,objmatrix,DetailsAnalysis,resultname,'Spectrogram');
        end
        function neuroresult = recal(params,neuroresult,resultname)
             obj=Spectrogram();
             params.Fs=neuroresult.LFPinfo.Fs;
             obj.Params=params;
            % % % 
            multiWaitbar(['Caculating',neuroresult.Subjectname],0);
            process=0;
            for j=1:size(neuroresult.LFPdata,2)
                for i=1:size(neuroresult.LFPdata{j},2) 
                    switch obj.Params.methodname
                        case 'Gabor'
                             obj.Spectro{j}(:,:,i)=abs(awt_freqlist(neuroresult.LFPdata{j}(:,i),obj.Params.Fs,obj.Params.fpass(1):obj.Params.fpass(2)));
                             obj.f_lfp=obj.Params.fpass(1):obj.Params.fpass(2);
                        case 'windowFFT'
                             time=linspace(neuroresult.EVTinfo.timerange(1),neuroresult.EVTinfo.timerange(2),size(neuroresult.LFPdata{j},1));
                             [~,Spec_tmp] = sub_stft(neuroresult.LFPdata{j}(:,i), time, time, obj.Params.fpass(1):obj.Params.fpass(2), obj.Params.Fs, obj.Params.windowsize);
                             obj.Spectro{j}(:,:,i)=permute(Spec_tmp,[2,1,3,4]);
                             obj.f_lfp=obj.Params.fpass(1):obj.Params.fpass(2);
                        case 'Multi-taper'
                             [Spec_tmp,~,f]=mtspecgramc(neuroresult.LFPdata{j}(:,i),obj.Params.windowsize,obj.Params);
                             obj.f_lfp=f;
                             obj.Spectro{j}(:,:,i)=Spec_tmp;    
                    end  
                    switch neuroresult.EVTinfo.timetype
                        case 'timepoint'
                            obj.t_lfp=linspace(neuroresult.EVTinfo.timerange(1),neuroresult.EVTinfo.timerange(2),size(obj.Spectro{j},1));
                        case 'timeduration'
                            obj.t_lfp{j}=linspace(neuroresult.EVTinfo.timestart(j),neuroresult.EVTinfo.timestop(j),size(obj.Spectro{j},1));
                    end
                    process=process+1/(size(neuroresult.LFPdata{j},2)*size(neuroresult.LFPdata{j},1));
                    multiWaitbar(['Caculating',neuroresult.Subjectname],process);
                end
            end  
            try
            neuroresult.addprop(resultname);
            end
            eval(['neuroresult.',resultname,'=obj;']);   
            multiWaitbar(['Caculating',neuroresult.Subjectname],'close');
        end
        function saveblacklist(eventpanel,channelpanel)
                global Blacklist matvalue
                blacklist=findobj(eventpanel.parent,'Tag','blacklist');
                Blacklist(matvalue).Eventindex=blacklist.String;
                blacklist=findobj(channelpanel.parent,'Tag','blacklist');
                Blacklist(matvalue).Channelindex=blacklist.String;             
        end
end

end