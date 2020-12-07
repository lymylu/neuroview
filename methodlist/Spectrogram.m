classdef Spectrogram < NeuroMethod & NeuroPlot.NeuroPlot
    properties(Access='protected')
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
            % load data
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
             import NeuroPlot.selectpanel NeuroPlot.commandcontrol
             global Chooseinfo Blacklist Eventpanel Channelpanel
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
             NeuroPlot.commandcontrol('Parent',Figcontrol1,'Plottype','imagesc','Command','create','Linkedaxes',Figpanel1);
             Figcontrol2=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol2');
             uicontrol('Style','popupmenu','Parent',Figcontrol2,'String',basetype,'Tag','basecorrect_origin');
             Figpanel2=uix.Panel('Parent',obj.FigurePanel,'Title','Original LFPs','Tag','Figpanel2');
             NeuroPlot.commandcontrol('Parent',Figcontrol2,'Plottype','plot','Command','create','Linkedaxes',Figpanel2);
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
             global Resultorigin ResultSpec Spec_t origin_t f FilePath matvalue Blacklist Eventlist Channellist Eventpanel Channelpanel
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             h=msgbox('Loading data...');
             matvalue=tmpobj.Value;
             FilePath=filemat{matvalue};
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
            Eventlist=num2cell(getfield(FilePath.Description,'eventselect'));
            Channellist=num2cell(getfield(FilePath.Description,'channelselect'));
            close(h);
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
            ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,saveresult);
            ResultSavefcn@NeuroPlot.NeuroPlot(obj,path,savename,Blacklist(matvalue),'Blacklist');
            close(h)
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
        end
        function Msg(obj,msg,type)
            Msg@NeuroPlot.NeuroPlot(obj,msg,type);
        end
        function Averagealldata(obj,filemat)
            global Channelpanel Eventpanel
            multiWaitbar('calculating',0);
            tmpobj1=findobj(gcf,'Tag','Channeltype');
            channeltype=2:length(tmpobj1.String);
            tmpobj2=findobj(gcf,'Tag','Eventtype');
            eventtype=2:length(tmpobj2.String);
            multiWaitbar('Calculating...',0);
            tmpobj=findobj(gcf,'Tag','Matfilename');
            for i=1:length(tmpobj.String)
                tmpobj.Value=i; 
                obj.Changefilemat(filemat);
                for j=1:length(channeltype)
                    for k=1:length(eventtype)
                    Channelpanel.getValue({'Channeltype'},{'ChannelIndex'},channeltype(j));
                    Eventpanel.getValue({'Eventtype'},{'EventIndex'},eventtype(k));
                    try
                        obj.Resultplotfcn()
                        obj.ResultSavefcn(filemat);
                    end
                    end
                end
                multiWaitbar('Calculating..',i/length(filemat));
            end
            multiWaitbar('Calculating','close');
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
            channelindex=Channellist(ismember(Channellist,channellist.String(channellist.Value)));
            eventindex=Eventlist(ismember(Eventlist,eventlist.String(eventlist.Value)));
            Chooseinfo(matvalue).Channelindex=channelindex;
            Chooseinfo(matvalue).Eventindex=eventindex;
            ResultSpectmp=ResultSpec(:,:,channelindex,eventindex);
            basebegin=findobj(gcf,'Tag','baselinebegin');
            baseend=findobj(gcf,'Tag','baselineend');
            basemethod=findobj(gcf,'Tag','basecorrect_spec');
            tmpdata=basecorrect(ResultSpectmp,Spec_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
            tmpdata=squeeze(mean(mean(tmpdata,4),3));
            tmpobj=findobj(gcf,'Tag','Figpanel1');
            delete(findobj(gcf,'Parent',tmpobj,'Type','axes'));
            figaxes=axes('Parent',tmpobj);
            imagesc(Spec_t,f,tmpdata');
            figaxes.XLim=[min(Spec_t),max(Spec_t)];
            figaxes.YLim=[min(f),max(f)];
            figaxes.YDir='normal';
            tmpparent=findobj(gcf,'Tag','Figcontrol1');
            NeuroPlot.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',tmpobj);
            Resultorigintmp=Resultorigin(:,channelindex,eventindex);
            basemethod=findobj(gcf,'Tag','basecorrect_origin');
            tmpdata=basecorrect(Resultorigintmp,origin_t,str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
            tmpdata=squeeze(mean(mean(tmpdata,3),2));
            tmpobj=findobj(gcf,'Tag','Figpanel2');
            delete(findobj(gcf,'Parent',tmpobj,'Type','axes'));
            figaxes=axes('Parent',tmpobj);
            plot(origin_t,tmpdata);
            figaxes.XLim=[min(origin_t),max(origin_t)];
            tmpparent=findobj(gcf,'Tag','Figcontrol2');
            NeuroPlot.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',tmpobj);
            tmpobj=findobj(gcf,'Tag','Savename');
            tmpobj1=findobj(gcf,'Tag','Eventtype');
            tmpobj2=findobj(gcf,'Tag','Channeltype');
            tmpobj.String=[tmpobj1.String{tmpobj1.Value},'_',tmpobj2.String{tmpobj2.Value}];
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

