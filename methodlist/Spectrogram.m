classdef Spectrogram < NeuroResult & NeuroPlot.NeuroPlot
    properties(Access='public')   
        Methodname='Spectrogram';
        Params
        Result
        Resultinfo
    end
    methods (Access='public')
        function obj=inherit(obj,neuroresult)
                     variablenames=fieldnames(neuroresult);
                for i=1:length(variablenames)
                    eval(['obj.',variablenames{i},'=neuroresult.',variablenames{i}]);
                end
         end
        function obj = getParams(obj)
             method=listdlg('PromptString','Spectrum method','ListString',{'Gabor','windowFFT','Multi-taper'});
                switch method
                    case 1
                        prompt={'fpass '};
                        title='input Params';
                        lines=1;
                        def={'0 100'};
                        x=inputdlg(prompt,title,lines,def,'on');
                        obj.Params.fpass=str2num(x{1});
                        obj.Params.methodname='Gabor';
                    case 2
                        prompt={'slide window size','fpass'};
                        title='input Params';
                        lines=2;
                        def={'0.1','0 100'};
                        x=inputdlg(prompt,title,lines,def,'on');
                        obj.Params.windowsize=str2num(x{1}); %%  signal length for FFT 
                        obj.Params.methodname='windowFFT';
                        obj.Params.fpass=str2num(x{2});
                        NeuroMethod.Checkpath('STEP');
                    case 3
                        prompt={'taper size','fpass','pad','slide window size and step'};
                        title='input Params';
                        lines=4;
                        def={'3 5','0 100','0','0.5 0.1'};
                        x=inputdlg(prompt,title,lines,def,'on');
                        obj.Params.methodname='Multi-taper';
                        obj.Params.windowsize=str2num(x{4});
                        obj.Params.fpass=str2num(x{2});
                        obj.Params.pad=str2num(x{3});
                        obj.Params.tapers=str2num(x{1});
                        obj.Params.err=0;
                        obj.Params.trialave=0;
                        NeuroMethod.Checkpath('chronux');                   
                end           
        end
        function obj = cal(obj,objmatrix,DetailsAnalysis) 
            if strcmp(class(objmatrix),'NeuroData')
                dataoutput=objmatrix.LoadData(DetailsAnalysis);
            else
                tmpdata=matfile(objmatrix.Datapath);
                dataoutput=eval(['NeuroResult(tmpdata.',DetailsAnalysis,')']);
            end
             obj=obj.inherit(dataoutput);
             obj.Params.Fs=dataoutput.LFPinfo.Fs;
             switch dataoutput.EVTinfo.timetype
                 case 'timeduration'
                     dataoutput=dataoutput.Split2Splice;
             end
            dataall=[];
            for i=1:length(dataoutput.LFPdata)
                dataall=cat(3,dataall,dataoutput.LFPdata{i});
            end
            data=dataall;
            % % % 
            multiWaitbar(['Caculating',objmatrix.Datapath],0);
            process=0;
            for i=1:size(data,2)
                for j=1:size(data,3)
                    switch obj.Params.methodname
                        case 'Gabor'
                             Spectro(:,:,i,j)=abs(awt_freqlist(data(:,i,j),obj.Params.Fs,obj.Params.fpass(1):obj.Params.fpass(2)));
                             obj.Resultinfo.f_lfp=obj.Params.fpass(1):obj.Params.fpass(2);
                             obj.Resultinfo.t_lfp=linspace(dataoutput.EVTinfo.timerange(1),dataoutput.EVTinfo.timerange(2),size(data,1));
                        case 'windowFFT'
                             [~,Spec_tmp] = sub_stft(data(:,i,j), obj.LFPinfo.time{1}, obj.LFPinfo.time{1}, obj.Params.fpass(1):obj.Params.fpass(2), obj.Params.Fs, obj.Params.windowsize);
                             Spectro(:,:,i,j)=permute(Spec_tmp,[2,1,3,4]);
                             obj.Resultinfo.f_lfp=obj.Params.fpass(1):obj.Params.fpass(2);
                             obj.Resultinfo.t_lfp=linspace(dataoutput.EVTinfo.timerange(1),dataoutput.EVTinfo.timerange(2),size(data,1));
                        case 'Multi-taper'
                             [Spec_tmp,t,f]=mtspecgramc(data(:,i,j),obj.Params.windowsize,obj.Params);
                            obj.Resultinfo.f_lfp=f;
                             obj.Resultinfo.t_lfp=t; % could be modified ~_~
                             Spectro(:,:,i,j)=Spec_tmp;    
                    end  
                    process=process+1/(size(data,2)*size(data,3));
                    multiWaitbar(['Caculating',objmatrix.Datapath],process);
                end
            end  
            obj.Result=Spectro;   
            multiWaitbar(['Caculating',objmatrix.Datapath],'close');
        end
         %% methods for NeuroPlot
        function obj=GenerateObjects(obj,filemat)
             import NeuroPlot.selectpanel NeuroPlot.commandcontrol
             global Chooseinfo Blacklist Eventpanel Channelpanel
             NeuroMethod.Checkpath('GUI Layout Toolbox');
             Chooseinfo=[]; Blacklist=[];
             for i=1:length(filemat)
                Chooseinfo(i).Channelindex=[];
                Blacklist(i).Channelindex=[];
                Chooseinfo(i).Eventindex=[];
                Blacklist(i).Eventindex=[];
            end
             obj=GenerateObjects@NeuroPlot.NeuroPlot(obj,filemat);       
             % baseline correct panel
             Figurecommand=uix.Panel('Parent',obj.FigurePanel,'Title','Baselinecorrect');
             FigurecommandPanel=uix.HBox('Parent',Figurecommand,'Tag','Basecorrect','Padding',5);
             set(obj.FigurePanel,'Heights',[-1,-7,-1,-7,-2]);
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Baselinebegin');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','-2','Tag','baselinebegin');
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Baselineend');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','0','Tag','baselineend');
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             addlistener(tmpobj,'Value','PreSet',@(~,~) obj.saveblacklist(Eventpanel,Channelpanel)); 
             tmpobj=findobj(obj.NP,'Tag','Plotresult');
             addlistener(tmpobj,'Value','PostSet',@(~,~) obj.saveblacklist(Eventpanel,Channelpanel));       
        end
        function obj=Loadresult(obj,filemat,option)
            variablenames=fieldnames(filemat);  
            switch option
                case 'info'
                    obj.Result=[];
                    index=contains(variablenames,'info');
                    variablenames=variablenames(index);
                case 'data'
                    index=contains(variablenames,{'Result','LFPdata'});
                    variablenames=variablenames(index);
            end  
            for i=1:length(variablenames)
                try
                eval(['obj.',variablenames{i},'=filemat.',variablenames{i}]);
                end
            end
        end
        function obj=Changefilemat(obj,filemat)
             % load the data mat file and define the callback  
             global Spec_t LFP_t Spec_f matvalue Blacklist Eventpanel Channelpanel currentmat
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             matvalue=tmpobj.Value;
             currentmat=filemat{matvalue};
             obj=obj.Loadresult(currentmat,'info');
             Eventdescription=getfield(obj.EVTinfo,'eventdescription');
             Channeldescription=getfield(obj.LFPinfo,'channeldescription');
             Spec_t=obj.Resultinfo.t_lfp;
             Spec_f=obj.Resultinfo.f_lfp;
             LFP_t=obj.LFPinfo.time{1};
             Eventlist=num2cell(obj.EVTinfo.eventselect);
             Channellist=num2cell(obj.LFPinfo.channelselect);
             Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
             Eventpanel=Eventpanel.assign('liststring',Eventlist,'listtag',{'EventIndex'},'typetag',{'Eventtype'},'typestring',Eventdescription,'blacklist',Blacklist(matvalue).Eventindex);
             Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
             Channelpanel=Channelpanel.assign('liststring',Channellist,'listtag',{'ChannelIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',Blacklist(matvalue).Channelindex);
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
        end
        function ResultSavefcn(obj,varargin)
            global Blacklist currentmat
            objnew=obj.ResultCalfcn();
            [path,name]=fileparts(currentmat.Properties.Source);
             if nargin>1
                 path=varargin{1};
             end
            savename=name;
            ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,objnew);
            ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,Blacklist(matvalue),'Blacklist');
        end
        function Msg(obj,msg,type)
            Msg@NeuroPlot.NeuroPlot(obj,msg,type);
        end
        function Averagealldata(obj,filemat)
            global Channelpanel Eventpanel
            multiWaitbar('Calculating...',0);
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            savepath=uigetdir('PromptString','Choose the save path');
            for i=1:length(tmpobj.String)
                tmpobj.Value=i; 
                obj.Changefilemat(filemat);
                tmpobj1=findobj(obj.NP,'Tag','Channeltype');
                channeltype=2:length(tmpobj1.String);
                tmpobj2=findobj(obj.NP,'Tag','Eventtype');
                eventtype=2:length(tmpobj2.String);
                for j=1:length(channeltype)
                    for k=1:length(eventtype)
                    Channelpanel.getValue({'Channeltype'},{'ChannelIndex'},channeltype(j));
                    Eventpanel.getValue({'Eventtype'},{'EventIndex'},eventtype(k));
                    try
                        obj.Resultplotfcn();
                        obj.ResultSavefcn(savepath);
                    catch
                        disp(['Error',tmpobj.String{i},'Skip']);
                    end
                    end
                end
                multiWaitbar('Calculating..',i/length(filemat));
            end
            multiWaitbar('Calculating','close');
        end
        function loadblacklist(obj,filemat)
            msg=loadblacklist@NeuroPlot.NeuroPlot();
            obj.Changefilemat(filemat);
            msgbox(['the blacklist of the files:',msg,' has been added.']);
        end
        function shortcut(obj,filemat)
            key=get(obj.NP,'currentcharacter');
            switch key
                case 'p'
                    obj.Resultplotfcn()
                case 's'
                    obj.ResultSavefcn(filemat)
                case 'u'
                    tmpobj=findobj(obj.NP,'Tag','Matfilename');
                    if tmpobj.Value<length(tmpobj.String)
                        tmpobj.Value=tmpobj.Value+1;
                        obj.Changefilemat(filemat);
                    end
                case 'd'
                    tmpobj=findobj(obj.NP,'Tag','Matfilename');
                    if tmpobj.Value>1
                        tmpobj.Value=tmpobj.Value-1;
                        obj.Changefilemat(filemat);
                    end
            end
        end  
        function Resultplotfcn(obj)
            global currentmat Spec_t LFP_t Spec_f Chooseinfo matvalue Channelpanel Eventpanel SpecFigure LFPFigure
            channelindex=Channelpanel.getIndex('ChannelIndex');
            Chooseinfo(matvalue).Channelindex=Channelpanel.listorigin(channelindex);
            eventindex=Eventpanel.getIndex('EventIndex');
            Chooseinfo(matvalue).Eventindex=Eventpanel.listorigin(eventindex);
            if isempty(obj.Result)
                h=msgbox('initial loading data');
                obj.Loadresult(currentmat,'data');
                 Resultorigin=[];
                for i=1:length(obj.LFPdata)
                    Resultorigin=cat(3,Resultorigin,obj.LFPdata{i});
                end
                obj.LFPdata=Resultorigin;
                close(h);
            end
            ResultSpec=obj.Result;
            Resultorigin=obj.LFPdata;
            basebegin=findobj(obj.NP,'Tag','baselinebegin');
            baseend=findobj(obj.NP,'Tag','baselineend');
            basemethod=findobj(obj.NP,'Tag','basecorrect_spec');
            tmpdata=basecorrect(ResultSpec(:,:,channelindex,eventindex),Spec_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
            tmpdata=squeeze(mean(mean(tmpdata,4),3));
            SpecFigure.plot(Spec_t,Spec_f,tmpdata');
            Resultorigintmp=Resultorigin(:,channelindex,eventindex);
            basemethod=findobj(obj.NP,'Tag','basecorrect_origin');
            tmpdata=basecorrect(Resultorigintmp,LFP_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
            LFPFigure.plot(LFP_t,tmpdata);
            tmpobj=findobj(obj.NP,'Tag','Savename');
            tmpobj1=findobj(obj.NP,'Tag','Eventtype');
            tmpobj2=findobj(obj.NP,'Tag','Channeltype');
            tmpobj.String=[tmpobj1.String{tmpobj1.Value},'_',tmpobj2.String{tmpobj2.Value}];
        end
        function objnew=ResultCalfcn(obj)
            global Chooseinfo matvalue Channelpanel Eventpanel
            channelindex=Channelpanel.getIndex('ChannelIndex');
            eventindex=Eventpanel.getIndex('EventIndex');
            Chooseinfo(matvalue).Channelindex=Channelpanel.listorigin(channelindex);
            Chooseinfo(matvalue).Eventindex=Eventpanel.listorigin(eventindex);
            obj.saveblacklist(Eventpanel,Channelpanel);
            %% save the current selected data as a new Spectrogram object.
            objnew=Spectrogram();
            objnew.Params=obj.Params;
            objnew.Result=obj.Result(:,:,channelindex,eventindex);
            objnew.Resultinfo=obj.Resultinfo;
            objnew.LFPdata=obj.LFPdata(:,channelindex,eventindex);
            objnew.LFPinfo=obj.LFPinfo;
            objnew.LFPinfo.channelselect=obj.LFPinfo.channelselect(channelindex);
            objnew.LFPinfo.channeldescription=obj.LFPinfo.channeldescription(channelindex);
            objnew.EVTinfo.eventselect=obj.EVTinfo.eventselect(eventindex);
            objnew.EVTinfo.eventdescription=obj.EVTinfo.eventdescription(eventindex);
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
        function saveblacklist(eventpanel,channelpanel)
                global Blacklist matvalue
                blacklist=findobj(eventpanel.parent,'Tag','blacklist');
                Blacklist(matvalue).Eventindex=blacklist.String;
                blacklist=findobj(channelpanel.parent,'Tag','blacklist');
                Blacklist(matvalue).Channelindex=blacklist.String;             
        end
        function SelectPanelcreate(ResultSelectPanel)
            global Eventpanel Channelpanel
           Eventtypepanel=uix.VBox('Parent',ResultSelectPanel,'Tag','Eventtypepanel');
             Eventpanel=NeuroPlot.selectpanel;
             Eventpanel=Eventpanel.create('Parent',Eventtypepanel,'listtitle',{'Eventnumber'},'listtag',{'EventIndex'},'typeTag',{'Eventtype'});
             Channeltypepanel=uix.VBox('Parent',ResultSelectPanel,'Tag','Channeltypepanel');
             Channelpanel=NeuroPlot.selectpanel;
             Channelpanel=Channelpanel.create('Parent',Channeltypepanel,'listtitle',{'Channelnumber'},'listtag',{'ChannelIndex'},'typeTag',{'Channeltype'});
        end
        function FigurePanelcreate(FigurePanel)
            global SpecFigure LFPFigure
                basetype={'None','Zscore','Subtract','ChangePercent'};
             % Figure Panel
             Figcontrol1=uix.HBox('Parent',FigurePanel,'Padding',0,'Tag','Figcontrol1');
             uicontrol('Style','popupmenu','Parent',Figcontrol1,'String',basetype,'Tag','basecorrect_spec');
             Figpanel1=uix.Panel('Parent',FigurePanel,'Title','Spectrogram','Tag','Figpanel1');
             SpecFigure=NeuroPlot.figurecontrol();
             SpecFigure=SpecFigure.create(Figpanel1,Figcontrol1,'imagesc');
             Figcontrol2=uix.HBox('Parent',FigurePanel,'Padding',0,'Tag','Figcontrol2');
             uicontrol('Style','popupmenu','Parent',Figcontrol2,'String',basetype,'Tag','basecorrect_origin');
             Figpanel2=uix.Panel('Parent',FigurePanel,'Title','Original LFPs','Tag','Figpanel2');
             LFPFigure=NeuroPlot.figurecontrol();
             LFPFigure=LFPFigure.create(Figpanel2,Figcontrol2,'plot');
        end
end

end