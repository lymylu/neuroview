classdef TimeVaringConnectivityAnalysis < NeuroMethod & NeuroPlot.NeuroPlot
    % Calculate the LFP coherence between several signals 
    % Granger connectivity, Partial Directed coherence, Magnitude coherence, and so on.
    % using eMVAR toolbox, chronux toolbox and SIFT toolbox by EEGlab (support mvgc toolbox in future)
    properties
        EEG=[];
    end
    methods
         function obj = getParams(obj)
            methodlist={'Magnitude coherence','Partial Directed coherence','Generate EEG.set for SIFT toolbox'};
            method=listdlg('PromptString','Select the Connectivity method','ListString',methodlist);
            switch method
                 case 1
                       prompt={'taper size','fpass','pad','slide window size and step'};
                        title='params';
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
                        obj.Params.methodname='Magnitude coherence';
                case 2
                        obj.Checkpath('emvar');
                        PDClist={'Normal','Generalized','Extended','Delayed'};
                        PDCname={'PDC','GPDC','EPDC','DPDC'};
                        PDCmode=listdlg('PromptString','PDC method','ListString',PDClist,'Selectionmode','Multiple');
                        obj.Params.methodname='Partial Directed coherence';
                        prompt={'mvar estimation algorithm (see mvar.m)', 'max Model order', 'slide window size','fft points','fpass','downsampleratio'};
                        title='params';
                        lines=6;
                        def={'10','20','0.5 0.1','512','0 100','1'};
                        x=inputdlg(prompt,title,lines,def,'on');
                        obj.Params.PDCtype=PDClist(PDCmode);
                        obj.Params.PDCname=PDCname(PDCmode);
                        obj.Params.mvartype=str2num(x{1});
                        obj.Params.maxP=str2num(x{2});
                        obj.Params.windowsize=str2num(x{3});
                        obj.Params.fftpoints=str2num(x{4});
                        obj.Params.fpass=str2num(x{5});
                        obj.Params.downratio=str2num(x{6});
                case 3
                        obj.Checkpath('eeglab');
                        obj.Params.methodname='SIFT';
                        X=questdlg('SIFT using all trials to cal connectivity, so the trials should be in one condition and the black trial should be excluded.','LoadingBlacklist','Loading','Skip','Loading');
                        if strcmp(X,'Loading')
                        [f,p]=uigetfile('blacklist.mat','load the blacklist');
                        obj.Params.blacklist=fullfile([p,f]);
                        end
            end                   
         end
         function obj =cal(obj,objmatrix,DetailsAnalysis)
            % objmatrix is a NeuroData class;
            % the connectivity value is a 5-D channel*channel*t*f*event matrix 
            obj.methodname='TimeVaringConnectivityAnalysis';
            if strcmp(class(objmatrix),'NeuroData')
            multiWaitbar(['Loading',objmatrix.Datapath],0);
            obj.Params.Fs=str2num(objmatrix.LFPdata.Samplerate);
            LFPoutput= objmatrix.loadData(DetailsAnalysis,'LFP');
            timestart=cellfun(@(x) contains(x,'Timestart'),DetailsAnalysis,'UniformOutput',1);
            timestart=str2num(strrep(DetailsAnalysis{timestart},'Timestart:',''));
            timestop=cellfun(@(x) contains(x,'Timestop'),DetailsAnalysis,'UniformOutput',1);
            timestop=str2num(strrep(DetailsAnalysis{timestop},'Timestop:',''));
            else
                tmpdata=matfile(objmatrix.Datapath);
                LFPoutput=eval(['tmpdata.',DetailsAnalysis]);
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
            obj.Description.eventdescription=LFPoutput.eventdescription;
            obj.Description.channeldescription=LFPoutput.channeldescription;    
            obj.Description.eventselect=LFPoutput.eventselect;
            obj.Description.channelselect=LFPoutput.channelselect;
            % % % 
            %
            process=0;
            multiWaitbar(['Loading',objmatrix.Datapath],'close');
            multiWaitbar(['Caculating:',objmatrix.Datapath],0);
            multiWaitbar(['Collect origin'],process);
            for i=1:size(data,2) % channel
                for j=1:size(data,3) % event
                    Origin(:,i,j)=data(:,i,j);
                    process=process+1/(size(data,2)*size(data,3));
                    multiWaitbar(['Collect origin'],process);
                end
            end
            obj.Description.origin={'t','channel','event'};
            obj.Result.origin=Origin;
            obj.Constant.origin.t=spectime;
            multiWaitbar(['Collect origin'],'close');
            process=0;
            switch obj.Params.methodname
                case 'Magnitude coherence'
                    obj.Result.MagC=[];
                    for i=1:size(data,2)
                          for j=1:size(data,2)
                              try
                             [obj.Result.MagC(i,j,:,:,:),~,~,~,~,t,f]=cohgramc(squeeze(data(:,i,:)),squeeze(data(:,j,:)),obj.Params.windowsize,obj.Params);
                              catch
                                  a=1;
                              end
                             process=process+1/(size(data,2)*size(data,2));
                             multiWaitbar(['Caculating:',objmatrix.Datapath],process);
                          end
                    end
                    obj.Constant.MagC.f=f;
                    obj.Constant.MagC.t=t+timestart; % t should be corrected
                    obj.Description.MagC={'channel','channel','t','f','event'};
                case 'Partial Directed coherence'
                     data=downsample(data,obj.Params.downratio);
                     obj.Params.Fs=obj.Params.Fs/obj.Params.downratio;
                    [epochtime,t]=windowepoched(data,obj.Params.windowsize,timestart,timestop,obj.Params.Fs);
                    for i=1:size(epochtime,2) % time
                        for j=1:size(data,3) % trial
                            [Paic,~,aic] = mos_idMVAR(data(epochtime(:,i),:,j)',obj.Params.maxP,obj.Params.mvartype);        
%                             [~,Paic]=min(diff(aic));
                            if Paic==-Inf
                                warndlg('bad MVAR order, please modified the parameters');
                                return
                            end
                            [Bm,B0,Sw,Am,Su,Up,Wp,percup,ki]=idMVAR0ng(data(epochtime(:,i),:,j)',Paic,obj.Params.mvartype);  
                            if contains('Extended',obj.Params.PDCtype) || contains('Delayed',obj.Params.PDCtype)
                                [~,~,EPDC,DPDC,~,~,~,~,~,f] = fdMVAR0(Bm,B0,Sw,obj.Params.fftpoints,obj.Params.Fs);
                                EPDC=abs(EPDC(:,:,find(f>obj.Params.fpass(1)&f<obj.Params.fpass(2))));
                                DPDC=abs(DPDC(:,:,find(f>obj.Params.fpass(1)&f<obj.Params.fpass(2))));
                                f=f(find(f>obj.Params.fpass(1)&f<obj.Params.fpass(2)));
                            end
                            if contains('Normal',obj.Params.PDCtype) || contains('Generalized',obj.Params.PDCtype)
                                [~,~,PDC,GPDC,~,~,~,~,~,~,f] = fdMVAR(Am,Su,obj.Params.fftpoints,obj.Params.Fs);
                                PDC=abs(PDC(:,:,find(f>obj.Params.fpass(1)&f<obj.Params.fpass(2))));
                                GPDC=abs(GPDC(:,:,find(f>obj.Params.fpass(1)&f<obj.Params.fpass(2))));
                                f=f(find(f>obj.Params.fpass(1)&f<obj.Params.fpass(2)));
                            end

                            for k=1:length(obj.Params.PDCtype)
                                try
                                eval(['obj.Result.',obj.Params.PDCname{k},'(:,:,i,:,j)=',obj.Params.PDCname{k},';']);
                                catch
                                    a=1;
                                end
                            end
                            process=process+1/(size(data,3)*size(epochtime,1));
                            multiWaitbar(['Caculating:',objmatrix.Datapath],process);
                        end
                    end
                    for k=1:length(obj.Params.PDCtype)
                     eval(['obj.Description.',obj.Params.PDCtype{k},'={''channel'',''channel'',''t'',''f'',''event''};']);
                     eval(['obj.Constant.',obj.Params.PDCtype{k},'.t=t;']);
                     eval(['obj.Constant.',obj.Params.PDCtype{k},'.f=f;']);
                    end
                case 'SIFT'
%                     eeglab;
                    data=permute(data,[2,1,3]);
                    try
                    blacklist=matfile(obj.Params.blacklist);
                    [~,subjectname]=fileparts(objmatrix.Datapath);
                    tmpblack=eval(['blacklist.',subjectname]);
                    invalid=cellfun(@(x) str2num(x),tmpblack.Eventindex,'UniformOutput',1);
                    invalidindex=ismember(LFPoutput.eventselect,invalid);
                    data(:,:,invalidindex)=[];
                    LFPoutput.eventdescription(invalidindex)=[];
                    end
                    eventtype=unique(LFPoutput.eventdescription);
                    for i=1:length(eventtype)
                        index=ismember(LFPoutput.eventdescription,eventtype{i});     
                        obj.EEG{i}=pop_importdata('data',data(:,:,index),'dataformat','array','nbchan',size(data,1),'xmin',timestart,'pnts',size(data,2),'srate',obj.Params.Fs);
                        obj.Description.EEGeventtype{i}=eventtype{i};
                    end
                        obj.Result.origin=mean(obj.Result.origin,3);
                    %msgbox('the following analysis using SIFT in eeglab, in this method, the event trials are averaged.');
            end
         end        
         function savematfile=writeData(obj,savematfile)
            savematfile=writeData@NeuroMethod(obj,savematfile);
            [filepath,filename]=fileparts(savematfile.Properties.Source(1:end-4));
            try
                Description=savematfile.Description;
                EEG=savematfile.EEG;
                for i=1:length(savematfile.EEG)    
                mkdir(fullfile(filepath,Description.EEGeventtype{i}));
                pop_saveset(EEG{i},'filename',filename,'filepath',fullfile(filepath,Description.EEGeventtype{i}));
                end
            end
         end   
         %% methods for NeuroPlot
         function obj=GenerateObjects(obj,filemat)
             import NeuroPlot.selectpanel NeuroPlot.commandcontrol
             global Chooseinfo Blacklist Eventpanel Channelpanel
             for i=1:length(filemat)
                Chooseinfo(i).Channelfromindex=[];
                Chooseinfo(i).Channeltoindex=[];
                Blacklist(i).Channelindex=[];
                Chooseinfo(i).Eventindex=[];
                Blacklist(i).Eventindex=[];
            end
             obj = GenerateObjects@NeuroPlot.NeuroPlot(obj);
             % Result select panel
             ResultSelectBox=uix.VBox('Parent',obj.ResultSelectPanel,'Padding',0);
             ResultSelect_infoselect=uix.HBox('Parent',ResultSelectBox,'Padding',0);
             Eventtypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Eventtypepanel');
             Eventpanel=selectpanel;
             Eventpanel=Eventpanel.create('Parent',Eventtypepanel,'listtitle',{'Eventnumber'},'listtag',{'EventIndex'},'typeTag',{'Eventtype'});
             Channeltypepanel=uix.Grid('Parent',ResultSelect_infoselect,'Tag','Channeltypepanel');
             Channelpanel=selectpanel;
             Channelpanel=Channelpanel.create('Parent',Channeltypepanel,'listtitle',{'ChannelFrom','Channel To'},'listtag',{'ChannelfromIndex','ChanneltoIndex'},'typeTag',{'Channelfromtype','Channeltotype'});
             set(ResultSelect_infoselect,'Width',[-1,-2]);
             basetype={'None','Zscore','Subtract','ChangePercent'};
             % Figure Panel, support several Result type 
             uicontrol('Parent',obj.FigurePanel,'Style','popupmenu','Tag','Resulttype','Callback',@(~,src) obj.Resulttypefcn());
             Figcontrol1=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol1');
             uicontrol('Style','popupmenu','Parent',Figcontrol1,'String',basetype,'Tag','basecorrect_spec');
             Figpanel1=uix.TabPanel('Parent',obj.FigurePanel,'Tag','Figpanel1');
             ConnFigure=NeuroPlot.figurecontrol();
             ConnFigure=ConnFigure.create(Figpanel1,Figcontrol1,'imagesc-multiple'); 
             set(Figpanel1,'SelectionChangedFcn',@(~,src) ConnFigure.ChangeLinked());
             obj.commandcontrol('Parent',Figcontrol1,'Plottype','imagesc','Command','create');
             Figcontrol2=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol2');
             uicontrol('Style','popupmenu','Parent',Figcontrol2,'String',basetype,'Tag','basecorrect_origin');
             Figpanel2=uix.Panel('Parent',obj.FigurePanel,'Title','Original LFPs','Tag','Figpanel2');
             LFPFigure=NeuroPlot.figurecontrol();
             LFPFigure=LFPFigure.create(Figpanel2,Figcontrol2,'plot');
             delete(findobj(LFPFigure.figpanel,'Tag','plottype'));
             % baseline correct panel
             set(obj.FigurePanel,'Heights',[-1,-1,-7,-1,-7,-2]);
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Baselinebegin');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','-2','Tag','baselinebegin');
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Baselineend');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','0','Tag','baselineend');
             tmpobj=findobj(obj.NP,'Tag','Plotresult');
             set(tmpobj,'Callback',@(~,src) obj.Resultplotfcn());
             tmpobj=findobj(obj.NP,'Tag','Resultsave');
             set(tmpobj,'Callback',@(~,src) obj.ResultSavefcn(filemat));
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             set(tmpobj,'String',cellfun(@(x) x.Properties.Source(1:end-4),filemat,'UniformOutput',0),'Value',1,'Callback',@(~,~) obj.Changefilemat(filemat));
             addlistener(tmpobj,'Value','PreSet',@(~,~) obj.saveblacklist(Eventtypepanel,Channeltypepanel)); 
             tmpobj=findobj(obj.NP,'Tag','Averagealldata');
             set(tmpobj,'Callback',@(~,~) obj.Averagealldata(filemat));
             tmpobj=findobj(obj.NP,'Tag','Loadselectinfo');
             set(tmpobj,'Callback',@(~,~) obj.loadblacklist(filemat));
         end
        function obj=Changefilemat(obj,filemat,varargin)
             % load the data mat file and define the callback 
             % the filename is the matfile from the neurodataanalysis2. 
             h=msgbox(['Loading data:',tmpobj.String(tmpobj.Value)]);  
             matvalue=tmpobj.Value;
             FilePath=filemat{matvalue};
             Resultorigin=getfield(FilePath.Result,'origin');
             close(h);
             resulttmp=TimeVaringConnectivityAnalysis.getResulttype(FilePath,'loading'); 
             ResultCon=resulttmp;
             Eventdescription=getfield(FilePath.Description,'eventdescription');
             Channeldescription=getfield(FilePath.Description,'channeldescription');
             Eventlist=num2cell(getfield(FilePath.Description,'eventselect'));
             Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
             Channellist=num2cell(getfield(FilePath.Description,'channelselect'));
             Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
             if nargin>2
                 obj.Channeltypefcn('from',varargin{1});
                 if err==1
                     obj.Msg('no channeltype were found, show the ALL tag','replace');
                 end
                 obj.Channeltypefcn('to',varargin{2});
                 if err==1
                     obj.Msg('no channeltype were found, show the ALL tag','replace');
                 end
                 obj.Eventtypefcn(varargin{3});
                 if err==1
                     obj.Msg('no Eventtype were found, show the ALL tag','replace');
                 end
             end
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
              obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
        end
        function obj=Startupfcn(obj,filemat,varargin)
                obj.Changefilemat(filemat);
        end          
        function ChangeLinkedCommand(obj,control,panel)
            try
                NeuroPlot.commandcontrol('Parent',control,'Plottype','imagesc','Command','assign','Linkedaxes',tmpobj(panel.Selection));
            end
        end
        function loadblacklist(obj,filemat)
            msg=loadblacklist@NeuroPlot.NeuroPlot();
            obj.Startupfcn(filemat);
            msgbox(['the blacklist of the files:',msg,' has been added.']);
        end
        function Averagealldata(obj,filemat)
            global Channelpanel Eventpanel
            multiWaitbar('calculating',0);
            tmpobj1=findobj(obj.NP,'Tag','Channelfromtype');
            channelfromtype=2:length(tmpobj1.String);
            tmpobj2=findobj(obj.NP,'Tag','Channeltotype');
            channeltotype=2:length(tmpobj2.String);
            tmpobj3=findobj(obj.NP,'Tag','Eventtype');
            eventtype=2:length(tmpobj3.String);
            multiWaitbar('Calculating...',0);
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            Spectrogram.saveblacklist(Eventpanel.parent,Channelpanel.parent);
            for i=1:length(tmpobj.String)
                tmpobj.Value=i; 
                obj.Changefilemat(filemat);
                for j=1:length(channelfromtype)
                    for l=1:length(channeltotype)
                        for k=1:length(eventtype)
                        Channelpanel.getValue({'Channelfromtype','Channeltotype'},{'ChannelfromIndex','ChanneltoIndex'},[channelfromtype(j),channeltotype(l)]);
                        Eventpanel.getValue({'Eventtype'},{'EventIndex'},eventtype(k));
                    try
                        obj.Resultplotfcn();
                        obj.ResultSavefcn(filemat);
                    catch
                        disp(['Error',tmpobj.String{i},'Skip']);
                    end
                    end
                    end
                end
                multiWaitbar('Calculating..',i/length(filemat));
            end
            multiWaitbar('Calculating','close');
        end
        function ResultSavefcn(obj,filemat)
            global ResultCon Resultorigin FilePath Chooseinfo Channellist Eventlist Blacklist matvalue Channelpanel Eventpanel  
            obj.Msg('Save the selected result...','replace');
            h=msgbox('Saving');
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            matvalue=tmpobj.Value;
            FilePath=filemat{matvalue};
            [path,name]=fileparts(FilePath.Properties.Source);
            savename=name;
            eventlist=findobj(obj.NP,'Tag','EventIndex');
            channellist=findobj(obj.NP,'Tag','ChannelfromIndex');
            channelfromindex=Channellist(ismember(Channellist,channellist.String(channellist.Value)));
            Chooseinfo(matvalue).Channelfromindex=channelfromindex;
            channelfromindex=find(ismember(Channellist,channellist.String(channellist.Value))==1);
            channellist=findobj(obj.NP,'Tag','ChanneltoIndex');
            channeltoindex=Channellist(ismember(Channellist,channellist.String(channellist.Value)));
            Chooseinfo(matvalue).Channeltoindex=channeltoindex;
            channeltoindex=find(ismember(Channellist,channellist.String(channellist.Value))==1);
            eventindex=Eventlist(ismember(Eventlist,eventlist.String(eventlist.Value)));
            Chooseinfo(matvalue).Eventindex=eventindex;
            eventindex=find(ismember(Eventlist,eventlist.String(eventlist.Value))==1);
            saveresult.Connectivity=ResultCon(channeltoindex,channelfromindex,:,:,eventindex);
            saveresult.Connectivity=permute(saveresult.Connectivity,[3,4,5,1,2]);
            saveresult.originfrom=Resultorigin(:,channelfromindex,eventindex);
            saveresult.originto=Resultorigin(:,channeltoindex,eventindex);
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
    end
    methods (Access='private')
         function Resultplotfcn(obj)
            global Resultorigin ResultCon tmp_t origin_t tmp_f Resultorigintmp ResultContmp Chooseinfo matvalue Blacklist Channellist Eventlist ConnFigure LFPFigure
            eventlist=findobj(obj.NP,'Tag','EventIndex');
            tmpchannel=findobj(obj.NP,'Tag','Channeltypepanel');
            channellistfrom=findobj(obj.NP,'Tag','ChannelfromIndex');
            channellistto=findobj(obj.NP,'Tag','ChanneltoIndex');
            Chooseinfo(matvalue).Channelindexfrom=channellistfrom.String(channellistfrom.Value);
            Chooseinfo(matvalue).Channelindexto=channellistto.String(channellistto.Value);
            Chooseinfo(matvalue).Eventindex=eventlist.String(eventlist.Value);
            ResultContmp=ResultCon(ismember(Channellist,channellistto.String(channellistto.Value)),ismember(Channellist,channellistfrom.String(channellistfrom.Value)),:,:,...
                ismember(Eventlist,eventlist.String(eventlist.Value)));
            basebegin=findobj(gcf,'Tag','baselinebegin');
            baseend=findobj(gcf,'Tag','baselineend');
            basemethod=findobj(gcf,'Tag','basecorrect_spec');
            ResultContmp=permute(ResultContmp,[3,4,5,1,2]);
            tmpdata=basecorrect(ResultContmp,tmp_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
            tmpdata=squeeze(mean(mean(mean(tmpdata,4),3),5));
             tmpevent=findobj(gcf,'Tag','Eventtypepanel');
            blacklist=findobj(gcf,'Parent',tmpevent,'Tag','blacklist');
            Blacklist(matvalue).Eventindex=blacklist.String;
            tmpchannel=findobj(gcf,'Tag','Channeltypepanel');
            blacklist=findobj(gcf,'Parent',tmpchannel,'Tag','blacklist');
            Blacklist(matvalue).Channelindex=blacklist.String;
            ConnFigure.plot(tmp_t,tmp_f,tmpdata');
            Resultorigintmp=Resultorigin(:,ismember(Channellist,channellist.String(channellist.Value)),...
                ismember(Eventlist,eventlist.String(eventlist.Value)));
            Resultoriginfrom=Resultorigin(:,ismember(Channellist,channellistfrom.String(channellistfrom.Value)),...
                ismember(Eventlist,eventlist.String(eventlist.Value)));
            Resultorigintmp=cat(2,Resultoriginto,Resultoriginfrom);
            basemethod=findobj(gcf,'Tag','basecorrect_origin');
            tmpdata1=basecorrect(Resultoriginto,origin_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
            tmpdata1=squeeze(mean(mean(tmpdata1,3),2));
            tmpdata2=basecorrect(Resultoriginfrom,origin_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
            tmpdata2=squeeze(mean(mean(tmpdata2,3),2));
            LFPFigure.plot(origin_t,tmpdata);
            tmpobj=findobj(gcf,'Tag','Savename');
            tmpobj1=findobj(gcf,'Tag','Eventtype');
            tmpobj2=findobj(gcf,'Tag','Channeltype');
            tmpobj.String=[tmpobj1.String{tmpobj1.Value},'_',tmpobj2.String{tmpobj2.Value}];
         end
      
    end
    methods(Static)
         function Resulttmp=getResulttype(FilePath,option)
            global ConnFigure
            switch option
                case 'loading'
                    Resultname=fieldnames(FilePath.Result);
                    TabTitle=[];
                    for i=1:length(Resultname)
                        if ~strcmp(Resultname{i},'origin')
                            uix.Panel('Parent',ConnFigure.figpanel_multiple,'Tag',Resultname{i});
                            TabTitle=cat(1,TabTitle,Resultname(i));
                        end
                    end
                    ConnFigure.figpanel_multiple.TabTitles=TabTitle;  
                    ConnFigure.figpanel_multiple.Selection=1;
                    ConnFigure.ChangeLinked();
                    Resulttmp=getfield(FilePath.Result,Resultname{i});
            end
        end
         function Channeltypefcn(option,varargin)
            global Channeldescription Channellist
            channelpanel=findobj(gcf,'Tag','Channeltypepanel');
            switch option
                case 'from'
                   tmpobjtype=findobj(gcf,'Parent',channelpanel,'Tag','Channelfromtype');
                   tmpobjindex=findobj(gcf,'Parent',channelpanel,'Tag','ChannelfromIndex');
                case 'to'
                   tmpobjtype=findobj(gcf,'Parent',channelpanel,'Tag','Channeltotype');
                   tmpobjindex=findobj(gcf,'Parent',channelpanel,'Tag','ChanneltoIndex');
            end
            if tmpobjtype.Value~=1
                value=tmpobjtype.Value;
                Channeltype=tmpobjtype.String;
                Channelindex=cellfun(@(x) ~isempty(regexpi(x,['\<',Channeltype{value},'\>'],'match')),Channeldescription,'UniformOutput',1);
                Channelindex=find(Channelindex==true);
                set(tmpobjindex,'String',Channellist(Channelindex),'Value',1);
            else
                set(tmpobjindex,'String',Channellist,'Value',1);
            end
         end
         function Eventtypefcn(varargin)
            global Eventdescription Eventlist err
            err=0;
            tmpobj=findobj(gcf,'Tag','Eventtype');
            if tmpobj.Value~=1
                 value=tmpobj.Value;
                 Eventtype=tmpobj.String;
                 Eventindex=cellfun(@(x) ~isempty(regexpi(x,['\<',Eventtype{value},'\>'],'match')),Eventdescription,'UniformOutput',1);
                 Eventindex=find(Eventindex==true);
                 tmpobj=findobj(gcf,'Tag','EventIndex');
                 set(tmpobj,'String',Eventlist(Eventindex),'Value',1);
            else
                tmpobj=findobj(gcf,'Tag','EventIndex');
                set(tmpobj,'String',Eventlist,'Value',1);
            end
             if nargin>0
                currentstring=varargin{1};
                tmpobj=findobj(gcf,'Tag','Eventtype');
                tmpvalue=find(strcmp(tmpobj.String,currentstring)==true);
                 if isempty(tmpvalue)
                     tmpobj.Value=1;
                     err=1;
                 else
                     tmpobj.Value=tmpvalue;
                 end
             end
        end   
    end
end

