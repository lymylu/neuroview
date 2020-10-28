classdef Spectrogram < NeuroMethod & NeuroPlot
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    properties
    end
    methods (Access='public')
        %% methods for NeuroMethod
        function obj = getParams(obj,timetype)
            switch timetype
                case 'timepoint'
                    msgbox('当前事件为时间点模式，将对每个时间前后固定时间段进行计算');
                case 'duration'
                    msgbox('当前事件为时间段模式，将对每段时间进行拼合后进行计算!');
            end
            %  定义计算方法和参数
             method=listdlg('PromptString','选择Spectrum的分析方法','ListString',{'Gabor','windowFFT','Multi-taper'});
                switch method
                    case 1
                        prompt={'fpass '};
                        title='输入参数';
                        lines=1;
                        def={'0 100'};
                        x=inputdlg(prompt,title,lines,def,'on');
                        obj.Params.fpass=str2num(x{1});
                        obj.Params.methodname='Gabor';
                    case 2
                        prompt={'slide window size','fpass'};
                        title='输入参数';
                        lines=2;
                        def={'0.1','0 100'};
                        x=inputdlg(prompt,title,lines,def,'on');
                        obj.Params.windowsize=str2num(x{1}); %%  signal length for FFT 
                        obj.Params.methodname='windowFFT';
                        obj.Params.fpass=str2num(x{2});
                        obj.Checkpath('STEP');
                    case 3
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
                        obj.Checkpath('chronux');                   
                end           
        end
        function obj = cal(obj,objmatrix,DetailsAnalysis) 
            % objmatrix is a NeuroData class;
            obj.methodname='Spectrogram';
            % load数据
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
            % % % 
            %从这里开始计算。
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
                             obj.Contant.Spec.t=spectime;
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
             global Chooseinfo Blacklist
             for i=1:length(filemat)
                Chooseinfo(i).Channelindex=[];
                Blacklist(i).Channelindex=[];
                Chooseinfo(i).Eventindex=[];
                Blacklist(i).Eventindex=[];
            end
             obj = GenerateObjects@NeuroPlot(obj);
             % Result select panel
             obj.Checkpath('GUI Layout Toolbox');
             ResultSelectBox=uix.VBox('Parent',obj.ResultSelectPanel,'Padding',0);
             ResultSelect_infoselect=uix.HBox('Parent',ResultSelectBox,'Padding',0);
             Eventtypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Eventtypepanel');
             obj.selectpanel('Parent',Eventtypepanel,'Tag','EventIndex','command','create','typeTag','Eventtype','typelistener',@(~,src) obj.Eventtypefcn());
             Channeltypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Channeltypepanel');
             obj.selectpanel('Parent',Channeltypepanel,'Tag','ChannelIndex','command','create','typeTag','Channeltype','typelistener',@(~,src) obj.Channeltypefcn());
             basetype={'None','Zscore','Subtract','ChangePercent'};
             % Figure Panel
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
             set(obj.FigurePanel,'Heights',[-1,-7,-1,-7,-2]);
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
             global Resultorigin ResultSpec Eventdescription Spec_t origin_t f FilePath Channeldescription Resultorigintmp ResultSpectmp matvalue Blacklist Eventlist Channellist
             tmpobj=findobj(gcf,'Tag','Matfilename');
             h=msgbox(['Loading data:',tmpobj.String(tmpobj.Value)]);  
             matvalue=tmpobj.Value;
             FilePath=filemat{matvalue};
             obj.Msg(['Loading Data..',tmpobj.String(matvalue)],'replace');
             Resultorigin=getfield(FilePath.Result,'origin');
             Eventdescription=getfield(FilePath.Description,'eventdescription');
             Channeldescription=getfield(FilePath.Description,'channeldescription');
             try
                tmp=getfield(FilePath.Constant,'Spec');
                Spec_t=tmp.t; f=tmp.f;
                tmp=getfield(FilePath.Constant,'origin');
                origin_t=tmp.t;
             catch
                 Spec_t=getfield(FilePath.Constant,'t');
                 origin_t=getfield(FilePath.Constant,'t');
                 f=getfield(FilePath.Constant,'f');
             end  
             close(h);
             tmpevent=findobj(gcf,'Tag','Eventtypepanel');
             try 
                Eventlist=num2cell(getfield(FilePath.Description,'eventselect'));
                Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
             catch
                Eventlist=cellfun(@(x) num2str(x),num2cell(1:size(Resultorigin,3)),'UniformOutput',0);
             end
             obj.selectpanel('Parent',tmpevent,'Tag','EventIndex','command','assign','assign',Eventlist,'blacklist',Blacklist(matvalue).Eventindex);
             tmpchannel=findobj(gcf,'Tag','Channeltypepanel');
             try
                 Channellist=num2cell(getfield(FilePath.Description,'channelselect'));
                 Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
             catch
                 Channellist=cellfun(@(x) num2str(x),num2cell(1:size(Resultorigin,2)),'UniformOutput',0);
             end
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
        function ResultSavefcn(obj,filemat)
            global ResultSpectmp Resultorigintmp FilePath Chooseinfo Blacklist matvalue
            obj.Msg('Save the selected result...','replace');
            tmpobj=findobj(gcf,'Tag','Matfilename');
            matvalue=tmpobj.Value;
            FilePath=filemat{matvalue};
            [path,name]=fileparts(FilePath.Properties.Source);
            savename=name;
            saveresult.Spec=ResultSpectmp;
            saveresult.origin=Resultorigintmp;
            saveresult.Chooseinfo=Chooseinfo(matvalue);
            ResultSavefcn@NeuroPlot(path,savename,saveresult);
            ResultSavefcn@NeuroPlot(path,savename,Blacklist(matvalue),'Blacklist');
            obj.Msg('Save done!','replace');
        end
        function commandcontrol(obj,varargin)
            commandcontrol@NeuroPlot(obj,varargin{:})
          end
        function Msg(obj,msg,type)
            Msg@NeuroPlot(obj,msg,type);
        end
        function Averagealldata(obj,filemat)
            multiWaitbar('calculating',0);
            tmpobj1=findobj(gcf,'Tag','Channeltype');
            channeltype=tmpobj1.String(tmpobj1.Value);
            tmpobj2=findobj(gcf,'Tag','Eventtype');
            eventtype=tmpobj2.String(tmpobj2.Value);
            multiWaitbar('Calculating...',0);
            tmpobj=findobj(gcf,'Tag','Matfilename');
            for i=1:length(tmpobj.String)
                tmpobj.Value=i;
                    obj.Changefilemat(filemat,channeltype,eventtype);
                    obj.Resultplotfcn()
                    obj.ResultSavefcn(filemat)

                     multiWaitbar('Calculating..',i/1);
            end
            multiWaitbar('Calculating','close');
        end
        function selectpanel(obj,varargin)
            selectpanel@NeuroPlot(obj,varargin{:});
        end
        function loadblacklist(obj,filemat)
            msg=loadblacklist@NeuroPlot(obj);
            obj.Startupfcn(filemat);
            msgbox(['the blacklist of the files:',msg,' has been added.']);
        end
    end
    methods (Access='private')     
         function Resultplotfcn(obj)
            global Resultorigin ResultSpec Spec_t origin_t f Resultorigintmp ResultSpectmp Chooseinfo matvalue Blacklist Channellist Eventlist
            eventlist=findobj(gcf,'Tag','EventIndex');
            channellist=findobj(gcf,'Tag','ChannelIndex');
            Chooseinfo(matvalue).Channelindex=channellist.String(channellist.Value);
            Chooseinfo(matvalue).Eventindex=eventlist.String(eventlist.Value);
            ResultSpectmp=ResultSpec(:,:,ismember(Channellist,channellist.String(channellist.Value)),...
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
        function Channeltypefcn()
            global Channeldescription Channellist
            tmpobj=findobj(gcf,'Tag','Channeltype');
            if tmpobj.Value~=1
              value=tmpobj.Value;
              Channeltype=tmpobj.String;
             Channelindex=cellfun(@(x) ~isempty(regexpi(x,['\<',Channeltype{value},'\>'],'match')),Channeldescription,'UniformOutput',1);
             Channelindex=find(Channelindex==true);
              tmpobj=findobj(gcf,'Tag','ChannelIndex');
              set(tmpobj,'String',Channellist(Channelindex),'Value',1);
            else
              tmpobj=findobj(gcf,'Tag','ChannelIndex');
              set(tmpobj,'String',Channellist,'Value',1);
            end
        end
        function Eventtypefcn()
            global Eventdescription Eventlist
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
        end   
        function LoadInfo()
           global Chooseinfo matvalue
           tmpobj=findobj(gcf,'Tag','ChannelIndex');
           tmpobj.Value=1:length(tmpobj.String);
           Chooseinfo(matvalue).Channelindex=tmpobj.String;
           tmpobj=findobj(gcf,'Tag','EventIndex');
           Chooseinfo(matvalue).Eventindex=tmpobj.String;
         end
        function Err
             error('Error, no such tag');
        end
        function saveblacklist(eventpanel,channelpanel)
                global Blacklist matvalue
                blacklist=findobj(gcf,'Parent',eventpanel,'Tag','blacklist');
                Blacklist(matvalue).Eventindex=blacklist.String;
                blacklist=findobj(gcf,'Parent',channelpanel,'Tag','blacklist');
                Blacklist(matvalue).Channelindex=blacklist.String;
        end
    end
end

