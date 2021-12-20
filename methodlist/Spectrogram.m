classdef Spectrogram < NeuroMethod & NeuroPlot.NeuroPlot
    properties(Access='public')
    end
    methods (Access='public')
        %% methods for NeuroMethod
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
                        obj.Checkpath('STEP');
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
                        obj.Checkpath('chronux');                   
                end           
        end
        function obj = cal(obj,objmatrix,DetailsAnalysis) 
            % objmatrix is a NeuroData class;
            obj.methodname='Spectrogram';
            if strcmp(class(objmatrix),'NeuroData')
            % load data 
            multiWaitbar(['Loading',objmatrix.Datapath],0);
            obj.Params.Fs=str2num(objmatrix.LFPdata.Samplerate);
            LFPoutput= objmatrix.loadData(DetailsAnalysis,'LFP');
            timestart=cellfun(@(x) contains(x,'Timestart'),DetailsAnalysis,'UniformOutput',1);
             timestart=str2num(strrep(DetailsAnalysis{timestart},'Timestart:',''));
             timestop=cellfun(@(x) contains(x,'Timestop'),DetailsAnalysis,'UniformOutput',1);
             timestop=str2num(strrep(DetailsAnalysis{timestop},'Timestop:',''));
            % % %something wrong, wait for further correction (could not support duration mode)
            else
                tmpdata=matfile(objmatrix.Datapath);
                LFPoutput=eval(['tmpdata.',DetailsAnalysis{:}]);
                obj.Params.Fs=str2num(LFPoutput.Fs);
              timestart=min(LFPoutput.relativetime);
              timestop=max(LFPoutput.relativetime);
            end
            data=LFPoutput.LFPdata;
            dataall=[];
            for i=1:length(data)
                dataall=cat(3,dataall,data{i});
            end
            data=dataall;
            spectime=linspace(timestart,timestop,size(data,1));
            % % % 
            %cal
            process=0;
            multiWaitbar(['Loading',objmatrix.Datapath],'close');
            multiWaitbar(['Caculating',objmatrix.Datapath],process);
            for i=1:size(data,2)
                for j=1:size(data,3)
                    Origin(:,i,j)=data(:,i,j);
                    switch obj.Params.methodname
                        case 'Gabor'
                             Spectro(:,:,i,j)=abs(awt_freqlist(data(:,i,j),obj.Params.Fs,obj.Params.fpass(1):obj.Params.fpass(2)));
                             obj.Constant.Spec.f=obj.Params.fpass(1):obj.Params.fpass(2);
                             obj.Constant.Spec.t=spectime;
                        case 'windowFFT'
                             [~,Spec_tmp] = sub_stft(data(:,i,j), spectime, spectime, obj.Params.fpass(1):obj.Params.fpass(2), obj.Params.Fs, obj.Params.windowsize);
                             Spectro(:,:,i,j)=permute(Spec_tmp,[2,1,3,4]);
                             obj.Constant.Spec.f=obj.Params.fpass(1):obj.Params.fpass(2);
                             obj.Constant.Spec.t=spectime;   
                        case 'Multi-taper'
                             [Spec_tmp,t,f]=mtspecgramc(data(:,i,j),obj.Params.windowsize,obj.Params);
                             obj.Constant.Spec.f=f;
                             obj.Constant.Spec.t=t+timestart;
                             Spectro(:,:,i,j)=Spec_tmp;    
                    end  
                    process=process+1/(size(data,2)*size(data,3));
                    multiWaitbar(['Caculating',objmatrix.Datapath],process);
                end
            end  
            obj.Constant.origin.t=spectime;
            obj.Description.Spec={'t','f','channel','event'};
            obj.Description.origin={'t','channel','event'};
            obj.Description.eventdescription=LFPoutput.eventdescription;
            obj.Description.eventselect=LFPoutput.eventselect;
            obj.Description.channeldescription=LFPoutput.channeldescription;
            obj.Description.channelselect=LFPoutput.channelselect;
            obj.Result.Spec=Spectro;   
            obj.Result.origin=Origin;
            multiWaitbar(['Caculating',objmatrix.Datapath],'close');
        end
        function savematfile=writeData(obj,savematfile)
            savematfile=writeData@NeuroMethod(obj,savematfile);
         end    
         %% methods for NeuroPlot
        function obj=GenerateObjects(obj,filemat)
             import NeuroPlot.selectpanel NeuroPlot.commandcontrol
             global Chooseinfo Blacklist Eventpanel Channelpanel SpecFigure LFPFigure
             obj.Checkpath('GUI Layout Toolbox');
             Chooseinfo=[]; Blacklist=[];
             for i=1:length(filemat)
                Chooseinfo(i).Channelindex=[];
                Blacklist(i).Channelindex=[];
                Chooseinfo(i).Eventindex=[];
                Blacklist(i).Eventindex=[];
            end
             obj=GenerateObjects@NeuroPlot.NeuroPlot(obj);
             % Result select panel
             Eventtypepanel=uix.VBox('Parent',obj.ResultSelectPanel,'Tag','Eventtypepanel');
             Eventpanel=selectpanel;
             Eventpanel=Eventpanel.create('Parent',Eventtypepanel,'listtitle',{'Eventnumber'},'listtag',{'EventIndex'},'typeTag',{'Eventtype'});
             Channeltypepanel=uix.VBox('Parent',obj.ResultSelectPanel,'Tag','Channeltypepanel');
             Channelpanel=selectpanel;
             Channelpanel=Channelpanel.create('Parent',Channeltypepanel,'listtitle',{'Channelnumber'},'listtag',{'ChannelIndex'},'typeTag',{'Channeltype'});
             basetype={'None','Zscore','Subtract','ChangePercent'};
             % Figure Panel
             Figcontrol1=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol1');
             uicontrol('Style','popupmenu','Parent',Figcontrol1,'String',basetype,'Tag','basecorrect_spec');
             Figpanel1=uix.Panel('Parent',obj.FigurePanel,'Title','Spectrogram','Tag','Figpanel1');
             SpecFigure=NeuroPlot.figurecontrol();
             SpecFigure=SpecFigure.create(Figpanel1,Figcontrol1,'imagesc');
             Figcontrol2=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol2');
             uicontrol('Style','popupmenu','Parent',Figcontrol2,'String',basetype,'Tag','basecorrect_origin');
             Figpanel2=uix.Panel('Parent',obj.FigurePanel,'Title','Original LFPs','Tag','Figpanel2');
             LFPFigure=NeuroPlot.figurecontrol();
             LFPFigure=LFPFigure.create(Figpanel2,Figcontrol2,'plot');
             % baseline correct panel
             Figurecommand=uix.Panel('Parent',obj.FigurePanel,'Title','Baselinecorrect');
             FigurecommandPanel=uix.HBox('Parent',Figurecommand,'Tag','Basecorrect','Padding',5);
             set(obj.FigurePanel,'Heights',[-1,-7,-1,-7,-2]);
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Baselinebegin');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','-2','Tag','baselinebegin');
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Baselineend');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','0','Tag','baselineend');
             tmpobj=findobj(obj.NP,'Tag','Plotresult');
             set(tmpobj,'Callback',@(~,src) obj.Resultplotfcn);
             tmpobj=findobj(obj.NP,'Tag','Resultsave');
             set(tmpobj,'Callback',@(~,src) obj.ResultSavefcn(filemat));
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             set(tmpobj,'String',cellfun(@(x) x.Properties.Source(1:end-4),filemat,'UniformOutput',0),'Value',1,'Callback',@(~,~) obj.Changefilemat(filemat));
             addlistener(tmpobj,'Value','PreSet',@(~,~) obj.saveblacklist(Eventtypepanel,Channeltypepanel)); 
             tmpobj=findobj(obj.NP,'Tag','Averagealldata');
             set(tmpobj,'Callback',@(~,~) obj.Averagealldata(filemat));
             tmpobj=findobj(obj.NP,'Tag','Loadselectinfo');
             set(tmpobj,'Callback',@(~,~) obj.loadblacklist(filemat));
%              set(obj.NP,'KeyPressFcn',@(~,varargin) obj.shortcut(filemat));
        end
        function obj=Changefilemat(obj,filemat,varargin)
             % load the data mat file and define the callback 
             % the filename is the matfile from the neurodataanalysis2. 
             global Spec_t origin_t f FilePath ResultSpec Resultorigin matvalue Blacklist Eventlist Channellist Eventpanel Channelpanel
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
%              h=msgbox('Loading data...');
             matvalue=tmpobj.Value;
             FilePath=filemat{matvalue};
%              Resultorigin=getfield(FilePath.Result,'origin');
%              ResultSpec=getfield(FilePath.Result,'Spec');
             ResultSpec=[];
             Resultorigin=[];
             Eventdescription=getfield(FilePath.Description,'eventdescription');
             Channeldescription=getfield(FilePath.Description,'channeldescription');
            tmp=getfield(FilePath.Constant,'Spec');
            Spec_t=tmp.t; f=tmp.f;
            tmp=getfield(FilePath.Constant,'origin');
            origin_t=tmp.t; 
            Eventlist=num2cell(getfield(FilePath.Description,'eventselect'));
            Channellist=num2cell(getfield(FilePath.Description,'channelselect'));
%             close(h);
            Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
            Eventpanel=Eventpanel.assign('liststring',Eventlist,'listtag',{'EventIndex'},'typetag',{'Eventtype'},'typestring',Eventdescription,'blacklist',Blacklist(matvalue).Eventindex);
            Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
            Channelpanel=Channelpanel.assign('liststring',Channellist,'listtag',{'ChannelIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',Blacklist(matvalue).Channelindex);
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
             if nargin>2
                 Channelpanel.getValue({'Channeltype'},{'ChannelIndex'},varargin{1});
                 Eventpanel.getValue({'Eventtype'},{'EventIndex'},varargin{2});
             end
        end
        function obj=Startupfcn(obj,filemat,varargin)
                obj.Changefilemat(filemat);
        end
        function ResultSavefcn(obj,filemat)
            global ResultSpec Resultorigin FilePath Chooseinfo Channellist Eventlist Blacklist matvalue Channelpanel Eventpanel  
            obj.Msg('Save the selected result...','replace');
            h=msgbox('Saving');
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            matvalue=tmpobj.Value;
            FilePath=filemat{matvalue};
            [path,name]=fileparts(FilePath.Properties.Source);
            savename=name;
            eventlist=findobj(obj.NP,'Tag','EventIndex');
            channellist=findobj(obj.NP,'Tag','ChannelIndex');
            channelindex=Channellist(ismember(Channellist,channellist.String(channellist.Value)));
            eventindex=Eventlist(ismember(Eventlist,eventlist.String(eventlist.Value)));
            Chooseinfo(matvalue).Channelindex=channelindex;
            Chooseinfo(matvalue).Eventindex=eventindex;
            channelindex=find(ismember(Channellist,channellist.String(channellist.Value))==1);
            eventindex=find(ismember(Eventlist,eventlist.String(eventlist.Value))==1);
            saveresult.Spec=ResultSpec(:,:,channelindex,eventindex);
            saveresult.origin=Resultorigin(:,channelindex,eventindex);
            saveresult.Chooseinfo=Chooseinfo(matvalue);
            ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,saveresult);
            close(h);
            Spectrogram.saveblacklist(Eventpanel.parent,Channelpanel.parent);
            ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,Blacklist(matvalue),'Blacklist');  
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
        end
        function Msg(obj,msg,type)
            Msg@NeuroPlot.NeuroPlot(obj,msg,type);
        end
        function Averagealldata(obj,filemat)
            global Channelpanel Eventpanel
            multiWaitbar('calculating',0);
            tmpobj1=findobj(obj.NP,'Tag','Channeltype');
            channeltype=2:length(tmpobj1.String);
            tmpobj2=findobj(obj.NP,'Tag','Eventtype');
            eventtype=2:length(tmpobj2.String);
            multiWaitbar('Calculating...',0);
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            Spectrogram.saveblacklist(Eventpanel.parent,Channelpanel.parent);
            for i=1:length(tmpobj.String)
                tmpobj.Value=i; 
                obj.Changefilemat(filemat);
                for j=1:length(channeltype)
                    for k=1:length(eventtype)
                    Channelpanel.getValue({'Channeltype'},{'ChannelIndex'},channeltype(j));
                    Eventpanel.getValue({'Eventtype'},{'EventIndex'},eventtype(k));
                    try
                        obj.Resultplotfcn();
                        obj.ResultSavefcn(filemat);
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
            obj.Startupfcn(filemat);
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
    end
    methods (Access='private')     
         function Resultplotfcn(obj)
            global FilePath Spec_t origin_t f Resultorigin ResultSpec Chooseinfo matvalue Channellist Eventlist 
            eventlist=findobj(obj.NP,'Tag','EventIndex');
            channellist=findobj(obj.NP,'Tag','ChannelIndex');
            channelindex=Channellist(ismember(Channellist,channellist.String(channellist.Value)));
            eventindex=Eventlist(ismember(Eventlist,eventlist.String(eventlist.Value)));
            Chooseinfo(matvalue).Channelindex=channelindex;
            Chooseinfo(matvalue).Eventindex=eventindex;
            channelindex=find(ismember(Channellist,channellist.String(channellist.Value))==1);
            eventindex=find(ismember(Eventlist,eventlist.String(eventlist.Value))==1);
            if isempty(Resultorigin)
                h=msgbox('initial loading origin data');
                Resultorigin=getfield(FilePath.Result,'origin');
                close(h);
            end
            if isempty(ResultSpec)
                h=msgbox('initial loading Spec data');
                ResultSpec=getfield(FilePath.Result,'Spec');
                close(h);
            end
                
%             ResultSpectmp=FilePath.Spec(:,:,channelindex,eventindex);
            basebegin=findobj(obj.NP,'Tag','baselinebegin');
            baseend=findobj(obj.NP,'Tag','baselineend');
            basemethod=findobj(obj.NP,'Tag','basecorrect_spec');
            tmpdata=basecorrect(ResultSpec(:,:,channelindex,eventindex),Spec_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
            tmpdata=squeeze(mean(mean(tmpdata,4),3));
%         tmpdata=ResultSpectmp;
% % csd          
%               Resultorigintmp=Resultorigin(:,ismember(Channellist,channellist.String(channellist.Value)),ismember(Eventlist,eventlist.String(eventlist.Value)));
%             basemethod=findobj(obj.NP,'Tag','basecorrect_origin');
%             tmpdata=basecorrect(Resultorigintmp,origin_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
%             tmpdata=obj.csd_cal(tmpdata,'grouplevel','timerange',[-2,4],'filter',[65,85],'type','spectral');
%             tmpdata=squeeze(mean(tmpdata,3));
%             %
           SpecFigure.plot(Spec_t,f,tmpdata');
%             obj.csd_plot(tmpdata,origin_t,[-1.2,1.2],[],[]);        
%           tmpdata=detrend(tmpdata);
%              tmpdata=medfilt1(tmpdata,2);
            Resultorigintmp=Resultorigin(:,ismember(Channellist,channellist.String(channellist.Value)),ismember(Eventlist,eventlist.String(eventlist.Value)));
            basemethod=findobj(obj.NP,'Tag','basecorrect_origin');
            tmpdata=basecorrect(Resultorigintmp,origin_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
%             tmpdata=obj.csd_cal(tmpdata,'grouplevel','timerange',[-0.2,0.5],'filter',[75,85],'type','origin');
%             tmpdata=squeeze(mean(tmpdata,3));
%             Resultorigintmp=Resultorigin(:,ismember(Channellist,channellist.String(channellist.Value)),ismember(Eventlist,eventlist.String(eventlist.Value)));
%             basemethod=findobj(obj.NP,'Tag','basecorrect_origin');
%             tmpdata=basecorrect(Resultorigintmp,origin_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
           LFPFigure.plot(origin_t,tmpdata);
            tmpobj=findobj(obj.NP,'Tag','Savename');
            tmpobj1=findobj(obj.NP,'Tag','Eventtype');
            tmpobj2=findobj(obj.NP,'Tag','Channeltype');
            tmpobj.String=[tmpobj1.String{tmpobj1.Value},'_',tmpobj2.String{tmpobj2.Value}];
         end
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
%             imagesc(Spec_t,f,tmpdata');axis xy;
            figaxes.XLim=[min(Spec_t),max(Spec_t)];
%             figaxes.YLim=[min(f),max(f)];
            figaxes.YDir='reverse';
%             figaxes.YDir='normal';
            tmpparent=findobj(obj.NP,'Tag','Figcontrol1');
            NeuroPlot.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',tmpobj);
                
%           tmpdata=detrend(tmpdata);
%              tmpdata=medfilt1(tmpdata,2);

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
         function Resultplotfcn_CSD(obj)
            global FilePath Spec_t origin_t f Resultorigintmp ResultSpectmp Chooseinfo matvalue Channellist Eventlist 
            eventlist=findobj(obj.NP,'Tag','EventIndex');
            channellist=findobj(obj.NP,'Tag','ChannelIndex');
            channelindex=Channellist(ismember(Channellist,channellist.String(channellist.Value)));
            eventindex=Eventlist(ismember(Eventlist,eventlist.String(eventlist.Value)));
            Chooseinfo(matvalue).Channelindex=channelindex;
            Chooseinfo(matvalue).Eventindex=eventindex;
            ResultSpectmp=FilePath.Spec(:,:,ismember(Channellist,channellist.String(channellist.Value)),ismember(Eventlist,eventlist.String(eventlist.Value)));
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
%             imagesc(Spec_t,f,tmpdata');axis xy;
            figaxes.XLim=[min(Spec_t),max(Spec_t)];
%             figaxes.YLim=[min(f),max(f)];
            figaxes.YDir='reverse';
%             figaxes.YDir='normal';
            tmpparent=findobj(obj.NP,'Tag','Figcontrol1');
            NeuroPlot.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',tmpobj);
                
%           tmpdata=detrend(tmpdata);
%              tmpdata=medfilt1(tmpdata,2);

            tmpobj=findobj(obj.NP,'Tag','Figpanel2');
            delete(findobj(obj.NP,'Parent',tmpobj,'Type','axes'));
          
%             tmpdata=obj.csd_cal(tmpdata,'grouplevel','timerange',[-0.2,0.5],'filter',[75,85],'type','origin');
%             tmpdata=squeeze(mean(tmpdata,3));
            figaxes=axes('Parent',tmpobj);
%             Resultorigintmp=FilePath(matvalue).origin(:,ismember(Channellist,channellist.String(channellist.Value)),ismember(Eventlist,eventlist.String(eventlist.Value)));
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
                blacklist=findobj(gcf,'Parent',eventpanel,'Tag','blacklist');
                Blacklist(matvalue).Eventindex=blacklist.String;
                blacklist=findobj(gcf,'Parent',channelpanel,'Tag','blacklist');
                Blacklist(matvalue).Channelindex=blacklist.String;             
        end
    end
end

