classdef PhaseLocking < NeuroMethod & NeuroPlot.NeuroPlot
    % Calculate the spike phase locking value to local field potential
    % using the hilbert transfrom to get the phase information
   
    properties
    end
    
    methods
        function obj = getParams(obj)
        end     
         function obj = cal(obj,objmatrix,DetailsAnalysis)
            obj.methodname='PhaseLocking';
            % % get the LFP data
            obj.Params.Fs_lfp=str2num(objmatrix.LFPdata.Samplerate);
            LFPoutput = objmatrix.loadData(DetailsAnalysis,'LFP');
            % %  get the SPKdata
            obj.Params.Fs_spk=str2num(objmatrix.SPKdata.Samplerate);
            Spikeoutput = objmatrix.loadData(DetailsAnalysis,'SPK');
            Timetype=cellfun(@(x) contains(x,'Timetype:'),DetailsAnalysis,'UniformOutput',1);
            Timetype=regexpi(DetailsAnalysis{Timetype},':','split');
            
            dataall=[];
            % % %something wrong, wait for further correction (could not support duration mode)
            for i=1:length(LFPoutput.LFPdata)
                dataall=cat(3,dataall,LFPoutput.LFPdata{i});
            end
            obj.Result.LFP=dataall;
             timestart=cellfun(@(x) contains(x,'Timestart'),DetailsAnalysis,'UniformOutput',1);
             timestart=str2num(strrep(DetailsAnalysis{timestart},'Timestart:',''));
             timestop=cellfun(@(x) contains(x,'Timestop'),DetailsAnalysis,'UniformOutput',1);
             timestop=str2num(strrep(DetailsAnalysis{timestop},'Timestop:',''));
            spectime=linspace(timestart,timestop,size(dataall,1));
            spikename=fieldnames(Spikeoutput);
            timerange=Spikeoutput.timerange;
            for j=1:length(spikename)
                if strfind(spikename{j},'cluster')
                    data=eval(['Spikeoutput.',spikename{j},'.spiketime']);
                switch Timetype{2}
                    case 'timeduration' % % %  wait for further correction
                        duration=timerange(:,2)-timerange(:,1);
                        duration=cumsum(duration);
                        obj.Constant.t=duration(end);
                        duration=[0;duration(1:end-1)];
                        for i=1:length(duration)
                            data{i}=data{i}-timerange(i,1)+duration(i)
                        end
                    case 'timepoint'
                        timestart=cellfun(@(x) contains(x,'Timestart'),DetailsAnalysis,'UniformOutput',1);
                        timestart=str2num(strrep(DetailsAnalysis{timestart},'Timestart:',''));
                        timestop=cellfun(@(x) contains(x,'Timestop'),DetailsAnalysis,'UniformOutput',1);
                        timestop=str2num(strrep(DetailsAnalysis{timestop},'Timestop:',''));
                        for i=1:length(data)
                            data{i}=data{i}-timerange(i,1)+timestart;
                        end
                end
                    eval(['Spikeoutput.',spikename{j},'.spiketime=data']);
                    eval(['obj.Result.',spikename{j},'=Spikeoutput.',spikename{j},';']);
                end    
            end
            obj.Description.eventdescription=LFPoutput.eventdescription;
            obj.Description.eventselect=LFPoutput.eventselect;
            obj.Description.channeldescription=LFPoutput.channeldescription;
            obj.Description.channelselect=LFPoutput.channelselect;
            obj.Constant.t_spk=[timestart, timestop];
            obj.Constant.t_lfp=spectime;
         end
        %% method for NeuroPlot
          function obj=GenerateObjects(obj,filemat)
             import NeuroPlot.selectpanel NeuroPlot.commandcontrol NeuroPlot.LoadSpikeClassifier
             global Chooseinfo Blacklist Channelpanel Eventpanel Spikepanel Classpath FilterLFP
             for i=1:length(filemat)
                Chooseinfo(i).Channelindex=[];
                Blacklist(i).Channelindex=[];
                Chooseinfo(i).Eventindex=[];
                Blacklist(i).Eventindex=[];
                Chooseinfo(i).spikename=[];
                Blacklist(i).spikename=[];
                FilterLFP(i).LFP=[];
                FilterLFP(i).Filterband=[];
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
             Channelpanel=Channelpanel.create('Parent',Channeltypepanel,'listtitle',{'Channel:LFP'},'listtag',{'ChannelIndex'},'typeTag',{'Channeltype'});
             Spiketypepanel=uix.Grid('Parent',ResultSelect_infoselect,'Tag','Spiketypepanel'); 
             Spikepanel=selectpanel;
             Spikepanel=Spikepanel.create('Parent',Spiketypepanel,'listtitle',{'Channel:SPK'},'listtag',{'SpikeIndex'},'typeTag',{'Channeltype'});
             set(ResultSelect_infoselect,'Width',[-1,-1,-1]);
             % Figure Panel, support several Result type 
             Figcontrol1=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol1');
             Figpanel1=uix.Panel('Parent',obj.FigurePanel,'Title','Filtered LFP','Tag','FilterLFPpanel');
             NeuroPlot.commandcontrol('Parent',Figcontrol1,'Plottype','imagesc','Command','create','Linkedaxes',Figpanel1);
             Figcontrol2=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol2');
             Figpanel2=uix.Panel('Parent',obj.FigurePanel,'Title','Raster Plot','Tag','Rasterpanel');
             NeuroPlot.commandcontrol('Parent',Figcontrol2,'Plottype','raster','Command','create','Linkedaxes',Figpanel2);
             Figcontrol3=uix.HBox('Parent',obj.FigurePanel,'Padding',0,'Tag','Figcontrol3');
             Figpanel3=uix.Panel('Parent',obj.FigurePanel,'Title','Phase Locking','Tag','PhaseLockingpanel');
             NeuroPlot.commandcontrol('Parent',Figcontrol3,'Plottype','roseplot','Command','create','Linkedaxes',Figpanel3);
             Figurecommand=uix.Panel('Parent',obj.FigurePanel,'Title','Params option');
             FigurecommandPanel=uix.HBox('Parent',Figurecommand,'Tag','Params','Padding',5);
             set(obj.FigurePanel,'Heights',[-1,-3,-1,-3,-1,-4,-2]);
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Filter band');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','4 8','Tag','Filterband');
             uicontrol('Style','text','Parent',FigurecommandPanel,'String','Spike tolerancenumber number');
             uicontrol('Style','edit','Parent',FigurecommandPanel,'String','40','Tag','tolerancenumber');
             Classpath=uigetdir('','Choose the root dir which contains the SpikeClass information');
            if Classpath ~=0
                spikeclasspanel=uix.Panel('parent',obj.MainBox,'Tag','SpikeClassPanel','Title','SpikeProperties');
                set(obj.MainBox,'Width',[-1,-3,-1]);
                obj.LoadSpikeClassifier(spikeclasspanel);
            end
             tmpobj=findobj(obj.NP,'Tag','Plotresult');
             set(tmpobj,'Callback',@(~,src) obj.Resultplotfcn);
             tmpobj=findobj(obj.NP,'Tag','Resultsave');
             set(tmpobj,'Callback',@(~,src) obj.ResultSavefcn(filemat));
             tmpobj=findobj(obj.NP,'Tag','Matfilename');
             set(tmpobj,'String',cellfun(@(x) x.Properties.Source(1:end-4),filemat,'UniformOutput',0),'Value',1,'Callback',@(~,~) obj.Changefilemat(filemat));
             addlistener(tmpobj,'Value','PreSet',@(~,~) obj.saveblacklist(Eventtypepanel,Channeltypepanel,Spiketypepanel)); 
             tmpobj=findobj(obj.NP,'Tag','Averagealldata');
             set(tmpobj,'Callback',@(~,~) obj.Averagealldata(filemat));
             tmpobj=findobj(obj.NP,'Tag','Loadselectinfo');
             set(tmpobj,'Callback',@(~,~) obj.loadblacklist(filemat));
          end
          function obj=Changefilemat(obj,filemat,varargin)
            global Result Eventdescription Channeldescription SPKdescription Channelpanel t_lfp FilePath Fs_lfp t_spk Fs_spk matvalue Blacklist Eventpanel Spikepanel Classpath Channellist Eventlist Spikelist
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
            h=msgbox('Loading data...');
            matvalue=tmpobj.Value;
            FilePath=filemat{matvalue};
            Result=getfield(FilePath,'Result');
            Fs_lfp=getfield(FilePath.Params,'Fs_lfp');
            Fs_spk=getfield(FilePath.Params,'Fs_spk');
            % event information
            Eventdescription=getfield(FilePath.Description,'eventdescription');
            Eventlist=num2cell(getfield(FilePath.Description,'eventselect'));
            Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
            Eventpanel=Eventpanel.assign('liststring',Eventlist,'listtag',{'EventIndex'},'typetag',{'Eventtype'},'typestring',Eventdescription,'blacklist',Blacklist(matvalue).Eventindex);
            % lfp information
            Channeldescription=getfield(FilePath.Description,'channeldescription');
            Channellist=num2cell(getfield(FilePath.Description,'channelselect'));
            Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
            Channelpanel=Channelpanel.assign('liststring',Channellist,'listtag',{'ChannelIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',Blacklist(matvalue).Channelindex);
            % spk information
            Spikelist=fieldnames(Result);
            Spikelist(strcmp(Spikelist,'LFP'))=[];
            SPKdescription=[];
            for i=1:length(Spikelist)
                tmp=eval(['Result.',Spikelist{i}]);
                SPKdescription=cat(1,SPKdescription,tmp.channeldescription);
            end
            Spikepanel=Spikepanel.assign('liststring',Spikelist,'listtag',{'SpikeIndex'},'typetag',{'Channeltype'},'typestring',Channeldescription,'blacklist',Blacklist(matvalue).spikename);
            tmpobj=findobj(obj.NP,'Tag','Matfilename');
             obj.Msg(['Current Data: ',tmpobj.String(matvalue)],'replace');
             if nargin>2
                 Channelpanel.getValue({'Channeltype'},{'ChannelIndex'},varargin{1});
                 Spikepanel.getValue({'Channeltype'},{'SpikeIndex'},varargin{2});
                 Eventpanel.getValue({'Eventtype'},{'EventIndex'},varargin{3});
             end
             if Classpath~=0
                 Filter=[];
                 Filter=obj.GetFilterValue;
                 [~,filename]=fileparts(tmpobj.String{tmpobj.Value});
                 obj.AssignSpikeClassifier(fullfile(Classpath,filename,[filename,'.cell_metrics.cellinfo.mat']));
                 err=obj.SetFilterValue(Filter);
                 obj.setSpikeProperties();
             end
          end
          function obj=Startupfcn(obj,filemat,varargin)
                obj.Changefilemat(filemat);
          end
          function loadblacklist(obj,filemat)
            msg=loadblacklist@NeuroPlot.NeuroPlot();
            obj.Startupfcn(filemat);
            msgbox(['the blacklist of the files:',msg,' has been added.']);
          end
          function Msg(obj,msg,type)
            Msg@NeuroPlot.NeuroPlot(obj,msg,type);
          end
    end
    methods(Access='private')
        function Resultplotfcn(obj)
                global  t Fs Spikepanel Eventpanel Channelpanel FilterLFP
                obj.saveblacklist(Channelpanel.parent,Spikepanel.parent,Eventpanel.parent);
                [Resultoutput, binnedraster, binnedspike]= obj.GetPhaseLocking;
                figpanel=findobj(obj.NP,'Tag','Rasterpanel');  
                delete(findobj(obj.NP,'Parent',figpanel,'Type','axes'));
                figaxes=axes('Parent',figpanel);
                figaxes.YLim=[0,size(Resultoutput,2)];
                [~,xpoints,ypoints]=plotSpikeRaster(logical(binnedraster),'PlotType','vertline2','TimePerBin',1/Fs);
                basebegin=findobj(obj.NP,'Tag','baselinebegin');
                baseend=findobj(obj.NP,'Tag','baselineend');
                basemethod=findobj(obj.NP,'Tag','basecorrect');
                tmpdata=basecorrect(mean(binnedspike,1)',linspace(t(1),t(2),size(binnedspike,2)),str2num(basebegin.String),str2num(baseend.String),basemethod.String{basemethod.Value});
                smoothwidth=findobj(obj.NP,'Tag','smooth');
                if str2num(smoothwidth.String)~=0
                    tmpdata=smooth(tmpdata,str2num(smoothwidth.String));
                end
                tmpparent=findobj(obj.NP,'Tag','Figcontrol1');
                NeuroPlot.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',figpanel);
                figpanel=findobj(obj.NP,'Tag','Histogrampanel');
                delete(findobj(obj.NP,'Parent',figpanel,'Type','axes'));
                figaxes=axes('Parent',figpanel);
                bar(linspace(t(1),t(2),size(binnedspike,2)),tmpdata);
                tmpobj=findobj(obj.NP,'Tag','Savename');
                tmpobj1=findobj(obj.NP,'Tag','Eventtype');
                tmpobj2=findobj(obj.NP,'Tag','Channeltype');
                tmpobj.String=[tmpobj1.String{tmpobj1.Value},'_',tmpobj2.String{tmpobj2.Value}];
                 tmpparent=findobj(obj.NP,'Tag','Figcontrol2');
                NeuroPlot.commandcontrol('Parent',tmpparent,'Command','assign','linkedaxes',figpanel);  
        end
        function  [Resultoutput, binnedraster, binnedspike]=GetPhaseLocking(obj)
            global Channellist Spikelist Eventlist Result FilterLFP matvalue Fs_lfp t_lfp Fs_spk t_spk Chooseinfo
            params=findobj(obj.NP,'Tag','Filterband');
            filterband=str2num(params.String);
            tolerancenum=findobj(obj.NP,'Tag','tolerancenumber');
            tolerancenumber=str2num(params.String);
            if isempty(FilterLFP(matvalue).LFP) || sum(FilterLFP(matvalue).Filterband ~=filterband)~=0
                FilterLFP(matvalue).Filterband=filterband;
                for i=1:size(Result.LFP,3)
                    tmp=eegfilt(Result.LFP(:,:,i)',Fs_lfp,filterband(1),filterband(2));
                    FilterLFP(matvalue).LFP(:,:,i)=hilbert(tmp');
                end
            end
            eventlist=findobj(obj.NP,'Tag','EventIndex');
            Chooseinfo(matvalue).EventIndex=eventlist.String(eventlist.Value);
            eventindex=ismember(Eventlist,eventlist.String(eventlist.Value));
            channellist=findobj(obj.NP,'Tag','ChannelIndex');
            Chooseinfo(matvalue).ChannelIndex=channellist.String(channellist.Value);
            channelindex=ismember(Channellist,channellist.String(channellist.Value));
            phaseLFP=atan2(imag(FilterLFP(matvalue).LFP(:,channelindex,eventindex)),real(FilterLFP(matvalue).LFP(:,channelindex,eventindex)));
            phaseLFP=squeeze(mean(phaseLFP,2));    
            spikelist=findobj(obj.NP,'Tag','SpikeIndex');
            Chooseinfo(matvalue).SpikeIndex=spikelist.String(spikelist.Value);
            Spikename=spikelist.String(spikelist.Value);
            for i=1:length(Spikename)
                tmp=eval(['Result.',Spikename{i}]);
                spikephase{i}=PhaseLocking.getSpikephase(phaseLFP,tmp.spiketime(eventindex));
            end
        end
    end
    methods(Static)
        function Spikephase=getSpikephase(FilterLFP,spiketime)
            for i=1:length(spiketime)
                Spikephase{i}=restrict(FilterLFP(:,i),spiketime{i});
            end
            Spikephase=cell2mat(Spikephase);
        end
            function LoadSpikeClassifier(parent)
                global spikeclass 
                import NeuroPlot.SpikeClassifier
                spikeclass=SpikeClassifier();
                spikeclass=spikeclass.create('Parent',parent);
            end
            function setSpikeProperties
                global spikeclass Spikepanel
                    tmpobj=findobj(Spikepanel.parent,'Tag','SpikeIndex');
                    addlistener(tmpobj,'Value','PostSet',@(~,~) spikeclass.SetSpikeProperties(tmpobj));           
            end
            function [firingrate,neurotype]=getSpikeProperties
                global spikeclass Spikepanel
                    tmpobj=findobj(Spikepanel.parent,'Tag','SpikeIndex');
                    [firingrate,neurotype]=spikeclass.GetSpikeProperties(tmpobj);
            end
            function AssignSpikeClassifier(classifierpath)
            % varargin{1} is the Type Classifier, varargin{2} is the Spikeindex
                import NeuroPlot.SpikeClassifier
                global Channeldescription spikeclass Spikepanel
                spikeclass=spikeclass.assign(classifierpath,Channeldescription,Spikepanel);
            end
            function Filter=GetFilterValue()
                global spikeclass
                   Filter=spikeclass.GetFilterValue();
            end
            function err=SetFilterValue(Filter)
                global spikeclass Spikepanel
                err=spikeclass.SetFilterValue(Filter,Spikepanel);
            end
            function saveblacklist(lfppanel,spikepanel,eventpanel)
                global Blacklist matvalue
                blacklist=findobj(eventpanel,'Tag','blacklist');
                Blacklist(matvalue).Eventindex=blacklist.String;
                blacklist=findobj(spikepanel,'Tag','blacklist');
                Blacklist(matvalue).spikename=blacklist.String;
                blacklist=findobj(lfppanel,'Tag','blacklist');
                Blacklist(matvalue).Channelindex=blacklist.String;
            end         
    end
end

