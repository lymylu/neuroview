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
                       obj.Checkpath('chronux');
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
                    obj.Constant.f=f;
                    obj.Constant.t=t; % t should be corrected
                    obj.Description.MagC={'channel','channel','t','f','event'};
                case 'Partial Directed coherence'
                     data=downsample(data,obj.Params.downratio);
                     obj.Params.Fs=obj.Params.Fs/obj.Params.downratio;
                    [epochtime,obj.Constant.t]=windowepoched(data,obj.Params.windowsize,timestart,timestop,obj.Params.Fs);
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
                    end
                case 'SIFT'
                    eeglab;
                    data=permute(data,[2,1,3]);
                    EEG=pop_importdata('data',data,'dataformat','array','nbchan',size(data,1),'xmin',timestart,'pnts',size(data,2),'srate',obj.Params.Fs);
                    obj=addprop('EEG');
                    obj.EEG=EEG;
                    obj.Result.origin=mean(obj.Result.origin,3);
                    msgbox('the following analysis using SIFT in eeglab when open the result by neurodataanalysis3.');
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
             ResultSelect_typeselect=uix.HBox('Parent',ResultSelectBox,'Padding',0);
             ResultSelect_infoselect=uix.HBox('Parent',ResultSelectBox,'Padding',0);
             set(ResultSelectBox,'Heights',[-1,-5]);
             Eventtypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Eventtypepanel');
             obj.selectpanel('Parent',Eventtypepanel,'Tag','EventIndex','command','create','typeTag','Eventtype','typelistener',@(~,src) obj.Eventtypefcn());
             Channelfrompanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Channelfrompanel');
             obj.selectpanel('Parent',Channelfrompanel,'Tag','ChannelfromIndex','command','create','typeTag','Channelfromtype','typelistener',@(~,src) obj.Channeltypefcn('from'));
             Channeltopanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Channeltopanel');
             obj.selectpanel('Parent',Channeltopanel,'Tag','ChanneltoIndex','command','create','typeTag','Channeltotype','typelistener',@(~,src) obj.Channeltypefcn('to'));
             basetype={'None','Zscore','Subtract','ChangePercent'};
             % Figure Panel, support several Result type 
             uicontrol('Parent',obj.FigurePanel,'Style','popupmenu','Tag','Resulttype','Callback',@(~,src) obj.Resulttypefcn());
             Figcontrol1=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol1');
             uicontrol('Style','popupmenu','Parent',Figcontrol1,'String',basetype,'Tag','basecorrect_spec');
             Figpanel1=uix.Panel('Parent',obj.FigurePanel,'Title','Spectrogram','Tag','Figpanel1');
             obj.commandcontrol('Parent',Figcontrol1,'Plottype','imagesc','Command','create','Linkedaxes',Figpanel1);
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
        function obj=Startupfcn(obj,filemat,varargin)
             % load the data mat file and define the callback 
             % the filename is the matfile from the neurodataanalysis2. 
             global Resultorigin ResultSpec Eventdescription t f FilePath Channeldescription Resultorigintmp ResultSpectmp matvalue Blacklist
             tmpobj=findobj(gcf,'Tag','Matfilename');
             h=msgbox(['Loading data:',tmpobj.String(tmpobj.Value)]);  
             matvalue=tmpobj.Value;
             FilePath=filemat{matvalue};
             obj.Msg(['Loading Data..',tmpobj.String(matvalue)],'replace');
             Resultorigin=getfield(FilePath.Result,'origin');
             Eventdescription=getfield(FilePath.Description,'eventdescription');
             Channeldescription=getfield(FilePath.Description,'channeldescription');
             t=getfield(FilePath.Constant,'t');
             f=getfield(FilePath.Constant,'f');
             close(h);
             tmpevent=findobj(gcf,'Tag','Eventtypepanel');
             Eventlist=cellfun(@(x) num2str(x),num2cell(1:size(Resultorigin,3)),'UniformOutput',0);
             obj.selectpanel('Parent',tmpevent,'Tag','EventIndex','command','assign','assign',Eventlist,'blacklist',Blacklist(matvalue).Eventindex);
             tmpchannel=findobj(gcf,'Tag','Channeltypepanel');
             Channellist=cellfun(@(x) num2str(x),num2cell(1:size(Resultorigin,2)),'UniformOutput',0);
             obj.selectpanel('Parent',tmpchannel,'Tag','ChannelIndex','command','assign','assign',Channellist,'blacklist',Blacklist(matvalue).Channelindex);
             tmpobj=findobj(gcf,'Tag','Channeltype');
             currentstring=tmpobj.String(tmpobj.Value);
             if nargin>3
                 currrentstring=varargin{2};
             end
             set(tmpobj,'String',cat(1,'All',unique(Channeldescription)));
             tmpvalue=find(strcmp(tmpobj.String,currentstring)==true);
             if isempty(tmpvalue) && nargin<3
                 msgbox('no channeltype were found, show the ALL tag');
                 tmpobj.Value=1;
             elseif nargin>3
                 obj.Err();
                 return;
             else
                 tmpobj.Value=tmpvalue;
             end
             tmpobj=findobj(gcf,'Tag','Eventtype');
             currentstring=tmpobj.String(tmpobj.Value);
             set(tmpobj,'String',cat(1,'All',unique(Eventdescription)));
              tmpvalue=find(strcmp(tmpobj.String,currentstring)==true);
              if isempty(tmpvalue) && nargin<3
                 msgbox('no eventtype were found, show the ALL tag');
                 tmpobj.Value=1;
              elseif nargin>3
                 obj.Err();
                 return;
              else
                 tmpobj.Value=tmpvalue;
              end
             ResultSpec=getfield(FilePath.Result,'Spec');
             Resultorigintmp=Resultorigin;
             ResultSpectmp=ResultSpec;
             tmpobj=findobj(gcf,'Tag','Matfilename');
             obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
        end
        function obj=Changefilemat(obj,filemat,varargin)
            if nargin>3
             obj.Startupfcn(filemat,varargin);
            else
                obj.Startupfcn(filemat);
            end
             tmpobj=findobj(gcf,'Tag','Holdonresult');
             if tmpobj.Value==1
                 obj.LoadInfo();
             end
        end
    end
    methods(Static)
         function Channeltypefcn(option)
            global Channeldescription Result
            switch option
                case 'from'
                    tmpobjtype=findobj(gcf,'Tag','Channelfromtype');
                    tmpobjindex=findobj(gcf,'Tag','ChannelfromIndex');
                case 'to'
                    tmpobjtype=findobj(gcf,'Tag','Channeltotype');
                    tmpobjindex=findobj(gcf,'Tag','ChanneltoIndex');
            end
            Channellist=cellfun(@(x) num2str(x),num2cell(1:size(Result,1)),'UniformOutput',0);
            if tmpobjtype.Value~=1
                value=tmpobjtype.Value;
                Channeltype=tmpobjtype.String;
                Channelindex=cellfun(@(x) regexpi(x,['\<',Channeltype{value},'\>'],'match'),Channeldescription,'UniformOutput',1);
                Channelindex=find(Channelindex==true);
                set(tmpobjindex,'String',Channellist(Channelindex),'Value',1);
            else
                set(tmpobjindex,'String',Channellist,'Value',1);
            end
         end
    end
end

