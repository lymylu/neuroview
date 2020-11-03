classdef TimeVaringConnectivityAnalysis < NeuroMethod & NeuroPlot
    % Calculate the LFP coherence between several signals 
    % Granger connectivity, Partial Directed coherence, Magnitude coherence, and so on.
    % using eMVAR toolbox, chronux toolbox and SIFT toolbox by EEGlab (support mvgc toolbox in future)
    properties
    end
    methods
         function obj = getParams(obj,timetype)
%             obj.Params.averagechannel=questdlg('当通道类型为多个时，是否将各类型通道内数据进行平均?');
            switch timetype
                case 'timepoint'
                    msgbox('当前事件为时间点模式，将对每个时间前后固定时间段进行计算');
                    methodlist={'Magnitude coherence','Partial Directed coherence','Generate EEG.set for SIFT toolbox'};
                case 'duration'
                    msgbox('当前事件为时间段模式，将对每段时间进行拼合后进行计算!');
                    methodlist={'Magnitude coherence','Partial Directed coherence'};
            end
            method=listdlg('PromptString','计算Connectivity的方法','ListString',methodlist);
            switch method
                 case 1
                       prompt={'taper size','fpass','pad','slide window size and step'};
                        title='输入参数';
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
                        PDCmode=listdlg('PromptString','选择想要计算的偏相关类型','ListString',PDClist,'Selectionmode','Multiple');
                        obj.Params.methodname='Partial Directed coherence';
                        prompt={'mvar estimation algorithm (see mvar.m)', 'max Model order', 'slide window size','fft points','fpass','downsampleratio'};
                        title='输入参数';
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
            end                   
         end
         function obj =cal(obj,objmatrix,DetailsAnalysis)
            % objmatrix is a NeuroData class;
            % the connectivity value is a 5-D channel*channel*t*f*event matrix 
            obj.methodname='TimeVaringConnectivityAnalysis';
            multiWaitbar(['Loading',objmatrix.Datapath],0);
            obj.Params.Fs=str2num(objmatrix.LFPdata.Samplerate);
            LFPoutput= objmatrix.loadData(DetailsAnalysis,'LFP');
            data=LFPoutput.LFPdata;
            dataall=[];
            % % %something wrong, wait for further correction (could not support duration mode)
            for i=1:length(data)
                dataall=cat(3,dataall,data{i});
            end
            data=dataall;
            timestart=cellfun(@(x) contains(x,'Timestart'),DetailsAnalysis,'UniformOutput',1);
            timestart=str2num(strrep(DetailsAnalysis{timestart},'Timestart:',''));
            timestop=cellfun(@(x) contains(x,'Timestop'),DetailsAnalysis,'UniformOutput',1);
            timestop=str2num(strrep(DetailsAnalysis{timestop},'Timestop:',''));
            spectime=linspace(timestart,timestop,size(data,1));
            obj.Description.eventdescription=LFPoutput.eventdescription;
            obj.Description.channeldescription=LFPoutput.channeldescription;    
            obj.Description.eventselect=LFPoutput.eventselect;
            obj.Description.channelselect=LFPoutput.channelselect;
            % % % 
            %从这里开始计算。
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
                    for i=1:size(data,2)
                          for j=1:size(data,2)
                             [obj.Result.MagC(i,j,:,:,:),~,~,~,~,t,f]=cohgramc(squeeze(data(:,i,:)),squeeze(data(:,j,:)),obj.Params.windowsize,obj.Params);
                             process=process+1/(size(data,2)*size(data,2));
                             multiWaitbar(['Caculating:',objmatrix.Datapath],process);
                          end
                    end
                    obj.Constant.MagC.f=f;
                    obj.Constant.MagC.t=t; % t should be corrected
                    obj.Description.MagC={'channel','channel','t','f','event'};
                case 'Partial Directed coherence'
                     data=downsample(data,obj.Params.downratio);
                     obj.Params.Fs=obj.Params.Fs/obj.Params.downratio;
                    [epochtime,t]=windowepoched(data,obj.Params.windowsize,timestart,timestop,obj.Params.Fs);
                    for i=1:size(epochtime,1)
                        for j=1:size(data,3)
                            Paic = mos_idMVAR(data(epochtime(:,i),:,j)',obj.Params.maxP,obj.Params.mvartype);
                            Paic=min(Paic);
                            if Paic==-Inf
                                warndlg('未找到合适的阶数，请修改拟合方法');
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
                                eval(['obj.Result.',obj.Params.PDCname{k},'(:,:,i,:,j)=',obj.Params.PDCname{k},';']);
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
                    eeglab;
                    data=permute(data,[2,1,3]);
                    EEG=pop_importdata('data',data,'dataformat','array','nbchan',size(data,1),'xmin',timestart,'pnts',size(data,2),'srate',obj.Params.Fs);
                    obj=addprop('EEG');
                    obj.EEG=EEG;
                    obj.Result.origin=mean(obj.Result.origin,3);
                    msgbox('the following analysis using SIFT in eeglab, in this method, the event trials are averaged.');
            end
         end        
         function savematfile=writeData(obj,savematfile)
            savematfile=writeData@NeuroMethod(obj,savematfile);
         end   
         %% methods for NeuroPlot
         function obj=GenerateObjects(obj,filemat)
             global Chooseinfo Blacklist
             for i=1:length(filemat)
                Chooseinfo(i).Channelindex=[];
                Blacklist(i).Channelindex=[];
                Chooseinfo(i).Eventindex=[];
                Blacklist(i).Eventindex=[];
            end
             obj = GenerateObjects@NeuroPlot(obj);
             % Result select panel
             ResultSelectBox=uix.VBox('Parent',obj.ResultSelectPanel,'Padding',0);
             ResultSelect_infoselect=uix.HBox('Parent',ResultSelectBox,'Padding',0);
             Eventtypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Eventtypepanel');
             obj.selectpanel('Parent',Eventtypepanel,'Tagstring','Eventnumber','Tag','EventIndex','command','create','typeTag','Eventtype','typelistener',@(~,src) obj.Eventtypefcn());
             Channelpanel=uix.Grid('Parent',ResultSelect_infoselect,'Tag','Channeltypepanel');
             obj.selectpanel('Parent',Channelpanel,'Tagstring',{'Channel From','Channel To'},'Tag',{'ChannelfromIndex','ChanneltoIndex'},'command','create','typeTag',{'Channelfromtype','Channeltotype'},'typelistener',{@(~,src) obj.Channeltypefcn('from'),@(~,src) obj.Channeltypefcn('to')});
             set(ResultSelect_infoselect,'Width',[-1,-2]);
             basetype={'None','Zscore','Subtract','ChangePercent'};
             % Figure Panel, support several Result type 
             uicontrol('Parent',obj.FigurePanel,'Style','popupmenu','Tag','Resulttype','Callback',@(~,src) obj.Resulttypefcn());
             Figcontrol1=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol1');
             uicontrol('Style','popupmenu','Parent',Figcontrol1,'String',basetype,'Tag','basecorrect_spec');
             Figpanel1=uix.TabPanel('Parent',obj.FigurePanel,'Tag','Figpanel1');
             set(Figpanel1,'SelectionChangedFcn',@(~,src) obj.ChangeLinkedCommand(Figcontrol1,Figpanel1));
             obj.commandcontrol('Parent',Figcontrol1,'Plottype','imagesc','Command','create');
             Figcontrol2=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol2');
             uicontrol('Style','popupmenu','Parent',Figcontrol2,'String',basetype,'Tag','basecorrect_origin');
             Figpanel2=uix.Panel('Parent',obj.FigurePanel,'Title','Original LFPs','Tag','Figpanel2');
             obj.commandcontrol('Parent',Figcontrol2,'Plottype','plot','Command','create','Linkedaxes',Figpanel2);
             % baseline correct panel
             Figurecommand=uix.Panel('Parent',obj.FigurePanel,'Title','Baselinecorrect');
             FigurecommandPanel=uix.HBox('Parent',Figurecommand,'Tag','Basecorrect','Padding',5);
             set(obj.FigurePanel,'Heights',[-1,-1,-7,-1,-7,-2]);
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Baselinebegin');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','-2','Tag','baselinebegin');
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Baselineend');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','0','Tag','baselineend');
             tmpobj=findobj(gcf,'Tag','Plotresult');
             set(tmpobj,'Callback',@(~,src) obj.Resultplotfcn());
             tmpobj=findobj(gcf,'Tag','Resultsave');
             set(tmpobj,'Callback',@(~,src) obj.ResultSavefcn(filemat));
             tmpobj=findobj(gcf,'Tag','Matfilename');
             set(tmpobj,'String',cellfun(@(x) x.Properties.Source(1:end-4),filemat,'UniformOutput',0),'Value',1,'Callback',@(~,~) obj.Changefilemat(filemat));
             addlistener(tmpobj,'Value','PreSet',@(~,~) obj.saveblacklist(Eventtypepanel,Channeltypepanel)); 
             tmpobj=findobj(gcf,'Tag','Averagealldata');
             set(tmpobj,'Callback',@(~,~) obj.Averagealldata(filemat));
             tmpobj=findobj(gcf,'Tag','Loadselectinfo');
             set(tmpobj,'Callback',@(~,~) obj.loadblacklist(filemat));
         end
        function obj=Changefilemat(obj,filemat,varargin)
             % load the data mat file and define the callback 
             % the filename is the matfile from the neurodataanalysis2. 
             global Resultorigin ResultCon Eventdescription FilePath Channeldescription matvalue Blacklist Channellist Eventlist err
             
             tmpobj=findobj(gcf,'Tag','Matfilename');
             h=msgbox(['Loading data:',tmpobj.String(tmpobj.Value)]);  
             matvalue=tmpobj.Value;
             FilePath=filemat{matvalue};
             obj.Msg(['Loading Data..',tmpobj.String(matvalue)],'replace');
             Resultorigin=getfield(FilePath.Result,'origin');
             close(h);
             resulttmp=obj.getResulttype(FilePath,'loading'); 
             ResultCon=resulttmp;
             Eventdescription=getfield(FilePath.Description,'eventdescription');
             Channeldescription=getfield(FilePath.Description,'channeldescription');
             tmpevent=findobj(gcf,'Tag','Eventtypepanel');
             Eventlist=num2cell(getfield(FilePath.Description,'eventselect'));
             Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
             obj.selectpanel('Parent',tmpevent,'Tag','EventIndex','command','assign','indexassign',Eventlist,'typeassign',Eventdescription,'blacklist',Blacklist(matvalue).Eventindex);
             Channellist=num2cell(getfield(FilePath.Description,'channelselect'));
             Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
             tmpchannel=findobj(gcf,'Tag','Channeltypepanel');
             obj.selectpanel('Parent',tmpchannel,'Tag','ChannelfromIndex','command','assign','indexassign',Channellist,'typeassign',Channeldescription,'blacklist',Blacklist(matvalue).Channelindex);
             obj.selectpanel('Parent',tmpchannel,'Tag','ChanneltoIndex','command','assign','indexassign',Channellist,'typeassign',Channeldescription,'blacklist',Blacklist(matvalue).Channelindex);
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
             tmpobj=findobj(gcf,'Tag','Matfilename');
             obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
             tmpobj=findobj(gcf,'Tag','Holdonresult');
             if tmpobj.Value==1
                 obj.LoadInfo();
             end
        end
        function obj=Startupfcn(obj,filemat,varargin)
                obj.Changefilemat(filemat);
        end
           
        function Resulttmp=getResulttype(obj,FilePath,option)
            switch option
                case 'loading'
                    Resultname=fieldnames(FilePath.Result);
                    TabFigure=findobj(gcf,'Parent',obj.FigurePanel,'Tag','Figpanel1');
                    Figcontrol1=findobj(gcf,'Tag','Figcontrol1');
                    TabTitle=[];
                    for i=1:length(Resultname)
                        if ~strcmp(Resultname{i},'origin')
                            uix.Panel('Parent',TabFigure,'Tag',Resultname{i});
                            TabTitle=cat(1,TabTitle,Resultname(i));
                        end
                    end
                    TabFigure.TabTitles=TabTitle;  
                    TabFigure.Selection=1;
                    obj.ChangeLinkedCommand(Figcontrol1,TabFigure);
                    Resulttmp=getfield(FilePath.Result,Resultname{i});
            end
        end
        function ChangeLinkedCommand(obj,control,panel)
            tmpobj=findobj(gcf,'Parent',panel);
            obj.commandcontrol('Parent',control,'Plottype','imagesc','Command','changelinkedaxes','Linkedaxes',tmpobj(panel.Selection));
            try
                obj.commandcontrol('Parent',control,'Plottype','imagesc','Command','assign','Linkedaxes',tmpobj(panel.Selection));
            end
        end
    end
    methods (Access='private')
         function Resultplotfcn(obj)
            global Resultorigin ResultCon tmp_t origin_t tmp_f Resultorigintmp ResultContmp Chooseinfo matvalue Blacklist Channellist Eventlist
            eventlist=findobj(gcf,'Tag','EventIndex');
            tmpchannel=findobj(gcf,'Tag','Channelfrompanel');
            channellistfrom=findobj(gcf,'Parent',tmpchannel,'Tag','ChannelIndex');
            tmpchannel=findobj(gcf,'Tag','Channeltopanel');
            channellistto=findobj(gcf,'Parent',tmpchannel,'Tag','ChannelIndex');
            Chooseinfo(matvalue).Channelindexfrom=channellistfrom.String(channellistfrom.Value);
            Chooseinfo(matvalue).Channelindexto=channellistto.String(channellistfrom.Value);
            Chooseinfo(matvalue).Eventindex=eventlist.String(eventlist.Value);
            ResultContmp=ResultCon(ismember(Channellist,channellistto.String(channellistto.Value)),ismember(Channellist,channellistfrom.String(channellistfrom.Value)),:,:,...
                ismember(Eventlist,eventlist.String(eventlist.Value)));
            basebegin=findobj(gcf,'Tag','baselinebegin');
            baseend=findobj(gcf,'Tag','baselineend');
            basemethod=findobj(gcf,'Tag','basecorrect_spec');
            tmpdata=basecorrect(ResultSpectmp,Spec_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
            tmpdata=squeeze(mean(mean(tmpdata,4),3));
             tmpevent=findobj(gcf,'Tag','Eventtypepanel');
            blacklist=findobj(gcf,'Parent',tmpevent,'Tag','blacklist');
            Blacklist(matvalue).Eventindex=blacklist.String;
            tmpchannel=findobj(gcf,'Tag','Channeltypepanel');
            blacklist=findobj(gcf,'Parent',tmpchannel,'Tag','blacklist');
            Blacklist(matvalue).Channelindex=blacklist.String;
            tmpobj=findobj(gcf,'Tag','Figpanel1');
            delete(findobj(gcf,'Parent',tmpobj,'Type','axes'));
            figaxes=axes('Parent',tmpobj);
            imagesc(Spec_t,f,tmpdata');
            figaxes.XLim=[min(Spec_t),max(Spec_t)];
            figaxes.YLim=[min(f),max(f)];
            figaxes.YDir='normal';
            tmpparent=findobj(gcf,'Tag','Figcontrol1');
            obj.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',tmpobj);
            Resultorigintmp=Resultorigin(:,ismember(Channellist,channellist.String(channellist.Value)),...
                ismember(Eventlist,eventlist.String(eventlist.Value)));
            basemethod=findobj(gcf,'Tag','basecorrect_origin');
            tmpdata=basecorrect(Resultorigintmp,origin_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
            tmpdata=squeeze(mean(mean(tmpdata,3),2));
            tmpobj=findobj(gcf,'Tag','Figpanel2');
            delete(findobj(gcf,'Parent',tmpobj,'Type','axes'));
            figaxes=axes('Parent',tmpobj);
            plot(origin_t,tmpdata);
            figaxes.XLim=[min(origin_t),max(origin_t)];
            tmpparent=findobj(gcf,'Tag','Figcontrol2');
            obj.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',tmpobj);
            tmpobj=findobj(gcf,'Tag','Savename');
            tmpobj1=findobj(gcf,'Tag','Eventtype');
            tmpobj2=findobj(gcf,'Tag','Channeltype');
            tmpobj.String=[tmpobj1.String{tmpobj1.Value},'_',tmpobj2.String{tmpobj2.Value}];
         end
    end
    methods(Static)
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

