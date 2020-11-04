classdef Spectrogram < NeuroMethod & NeuroPlot
    %UNTITLED �˴���ʾ�йش����ժҪ
    %   �˴���ʾ��ϸ˵��
    properties
    end
    methods (Access='public')
        %% methods for NeuroMethod
        function obj = getParams(obj,timetype)
            switch timetype
                case 'timepoint'
                    msgbox('��ǰ�¼�Ϊʱ���ģʽ������ÿ��ʱ��ǰ��̶�ʱ��ν��м���');
                case 'duration'
                    msgbox('��ǰ�¼�Ϊʱ���ģʽ������ÿ��ʱ�����ƴ�Ϻ���м���!');
            end
            %  ������㷽���Ͳ���
             method=listdlg('PromptString','ѡ��Spectrum�ķ�������','ListString',{'Gabor','windowFFT','Multi-taper'});
                switch method
                    case 1
                        prompt={'fpass '};
                        title='�������';
                        lines=1;
                        def={'0 100'};
                        x=inputdlg(prompt,title,lines,def,'on');
                        obj.Params.fpass=str2num(x{1});
                        obj.Params.methodname='Gabor';
                    case 2
                        prompt={'slide window size','fpass'};
                        title='�������';
                        lines=2;
                        def={'0.1','0 100'};
                        x=inputdlg(prompt,title,lines,def,'on');
                        obj.Params.windowsize=str2num(x{1}); %%  signal length for FFT 
                        obj.Params.methodname='windowFFT';
                        obj.Params.fpass=str2num(x{2});
                        obj.Checkpath('STEP');
                    case 3
                        prompt={'taper size','fpass','pad','slide window size and step'};
                        title='�������';
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
            % load����
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
            spectime=linspace(timestart,timestop,size(data,1));
            % % % 
            %�����￪ʼ���㡣
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
             Chooseinfo=[]; Blacklist=[];
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
             obj.selectpanel('Parent',Eventtypepanel,'Tagstring','Eventnumber','Tag','EventIndex','command','create','typeTag','Eventtype','typelistener',@(~,src) obj.Eventtypefcn());
             Channeltypepanel=uix.VBox('Parent',ResultSelect_infoselect,'Tag','Channeltypepanel');
             obj.selectpanel('Parent',Channeltypepanel,'Tagstring','Channelnumber','Tag','ChannelIndex','command','create','typeTag','Channeltype','typelistener',@(~,src) obj.Channeltypefcn());
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
             set(obj.NP,'KeyPressFcn',@(~,varargin) obj.shortcut(filemat));
         end
       function obj=Changefilemat(obj,filemat,varargin)
             % load the data mat file and define the callback 
             % the filename is the matfile from the neurodataanalysis2. 
             global Resultorigin ResultSpec Eventdescription Spec_t origin_t f FilePath Channeldescription Resultorigintmp ResultSpectmp matvalue Blacklist Eventlist Channellist err
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             h=msgbox(['Loading data:',tmpobj.String(tmpobj.Value)]);  
             matvalue=tmpobj.Value;
             FilePath=filemat{matvalue};
             obj.Msg(['Loading Data..',tmpobj.String{matvalue}],'replace');
             Resultorigin=getfield(FilePath.Result,'origin');
             ResultSpec=getfield(FilePath.Result,'Spec');
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
             tmpevent=findobj(obj.NP,'Tag','Eventtypepanel');
             try 
                Eventlist=num2cell(getfield(FilePath.Description,'eventselect'));
                Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
             catch
                Eventlist=cellfun(@(x) num2str(x),num2cell(1:size(Resultorigin,3)),'UniformOutput',0);
             end
             obj.selectpanel('Parent',tmpevent,'Tag','EventIndex','command','assign','indexassign',Eventlist,'typeassign',Eventdescription,'blacklist',Blacklist(matvalue).Eventindex);
             tmpchannel=findobj(obj.NP,'Tag','Channeltypepanel');
             try
                 Channellist=num2cell(getfield(FilePath.Description,'channelselect'));
                 Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
             catch
                 Channellist=cellfun(@(x) num2str(x),num2cell(1:size(Resultorigin,2)),'UniformOutput',0);
             end
             obj.selectpanel('Parent',tmpchannel,'Tag','ChannelIndex','command','assign','indexassign',Channellist,'typeassign',Channeldescription,'blacklist',Blacklist(matvalue).Channelindex);
             tmpobj=findobj(obj.NP,'Tag','Holdonresult');
             if nargin>2
                 obj.Channeltypefcn(varargin{1});
                 if err==1
                     obj.Msg('no channeltype were found, show the ALL tag','replace');
                 end
                 obj.Eventtypefcn(varargin{2});
                 if err==1
                     obj.Msg('no Eventtype were found, show the ALL tag','replace');
                 end
             end
             if tmpobj.Value==1
                 obj.LoadInfo();
             end
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
             close(h);
        end
        function obj=Startupfcn(obj,filemat,varargin)
                obj.Changefilemat(filemat);
        end
        function ResultSavefcn(obj,filemat)
            global ResultSpectmp Resultorigintmp FilePath Chooseinfo Blacklist matvalue
            obj.Msg('Save the selected result...','replace');
            h=msgbox('Saving');
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            matvalue=tmpobj.Value;
            FilePath=filemat{matvalue};
            [path,name]=fileparts(FilePath.Properties.Source);
            savename=name;
            saveresult.Spec=ResultSpectmp;
            saveresult.origin=Resultorigintmp;
            saveresult.Chooseinfo=Chooseinfo(matvalue);
            ResultSavefcn@NeuroPlot(path,savename,saveresult);
            ResultSavefcn@NeuroPlot(path,savename,Blacklist(matvalue),'Blacklist');
            close(h)
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
        end
        function commandcontrol(obj,varargin)
            commandcontrol@NeuroPlot(obj,varargin{:})
          end
        function Msg(obj,msg,type)
            Msg@NeuroPlot(obj,msg,type);
        end
        function Averagealldata(obj,filemat)
            global err
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
                    if err==0
                        obj.Resultplotfcn()
                        obj.ResultSavefcn(filemat);
                    else
                        msgbox(['no chosen tag were found in,' tmpobj.String(tmpobj.Value),'. Skip.']);
                    end
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
        function shortcut(obj,filemat)
            key=get(gcf,'currentcharacter');
            switch key
                case 'p'
                    obj.Resultplotfcn()
                case 's'
                    obj.ResultSavefcn(filemat)
                case 'u'
                    tmpobj=findobj(gcf,'Tag','Matfilename');
                    if tmpobj.Value<length(tmpobj.String)
                        tmpobj.Value=tmpobj.Value+1;
                        obj.Changefilemat(filemat);
                    end
                case 'd'
                    tmpobj=findobj(gcf,'Tag','Matfilename');
                    if tmpobj.Value>1
                        tmpobj.Value=tmpobj.Value-1;
                        obj.Changefilemat(filemat);
                    end
            end
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
        function Channeltypefcn(varargin)
            global Channeldescription Channellist err
            tmpobj=findobj(gcf,'Tag','Channeltype');
            err=0;
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
             if nargin>0
                currentstring=varargin{1};
                tmpobj=findobj(gcf,'Tag','Channeltype');
                tmpvalue=find(strcmp(tmpobj.String,currentstring)==true);
                 if isempty(tmpvalue)
                     tmpobj.Value=1;
                     err=1;
                 else
                     tmpobj.Value=tmpvalue;
                 end
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
        function LoadInfo()
           global Chooseinfo matvalue
           tmpobj=findobj(gcf,'Tag','ChannelIndex');
           tmpobj.Value=1:length(tmpobj.String);
           Chooseinfo(matvalue).Channelindex=tmpobj.String;
           tmpobj=findobj(gcf,'Tag','EventIndex');
           tmpobj.Value=1:length(tmpobj.String);
           Chooseinfo(matvalue).Eventindex=tmpobj.String;
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

