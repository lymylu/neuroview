classdef LFPData < BasicTag 
    properties (Access='public')
        Filename=[];
        Channelnum=[];
        Samplerate=[];
        ADconvert=[];
        Precision='int16';
        ChannelTag=[]; % Group Position ChannelIndex
    end
    methods (Access='public')
         function obj = fileappend(obj)
             [lfppath,path]=uigetfile('*.lfp','Please select the Path of the LFP file(s)','Multiselect','on');
             if ischar(lfppath)
                 lfppath={lfppath};
             end
             for i=1:length(lfppath)
                 tmp=LFPData();
                 tmp.Filename=fullfile(path,lfppath{i});
                 obj(i)=tmp;
             end
         end
         function obj = initialize(obj,Channelnum,Samplerate,ADconvert,Precision)
             % initialize the binary LFP file.
            obj.Channelnum=Channelnum;
            obj.Samplerate=Samplerate;
            obj.ADconvert=ADconvert;
            obj.Precision=Precision;
         end
         function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
             [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                  [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
         end
         function bool = check(obj)
             bool=~isempty(obj.Channelnum)&~isempty(obj.Samplerate)&~isempty(obj.fileTag)&~isempty(obj.ADconvert);
         end
         function neuroresult = Extractdata(obj,neuroresult,chselect,channeldescription,EVTinfo)
            % extract LFP data from LFPData object, return NeuroResult object
            if ~isempty(neuroresult)
                neuroresult=NeuroResult();
            end
            propvars={'LFPdata','EVTinfo','LFPinfo'};
            if isempty(obj.Precision)
                obj.Precision='int16';
            end
            for i=1:length(propvars)
                try
                eval(['addprop(neuroresult,''',propvars{i},''');']);
                end
            end
            if isempty(EVTinfo) % loading entire file!
             read_start=0; read_until=inf;
            else
             read_start=round(EVTinfo.timestart.*str2num(obj.Samplerate));
             read_until=round(EVTinfo.timestop.*str2num(obj.Samplerate));
            end
            if isempty(chselect) % load all channel
                chselect=1:str2num(obj.Channelnum);
            end
             for i=1:length(read_start)
                Data{i}=readmulti_frank(obj.Filename, str2num(obj.Channelnum), chselect, read_start(i), read_until(i),obj.Precision);
                Data{i}=Data{i}.*str2num(obj.ADconvert);
             end
             neuroresult.LFPdata=Data;
            if ~isempty(EVTinfo)
             switch EVTinfo.timetype
                 case 'timepoint'
                  %obj.LFPinfo.time{1}=linspace(EVTinfo.timerange(1),EVTinfo.timerange(2),size(obj.LFPdata{1},1)); % for plot, time(:,i)=linspace(read_start(i),read_until(i),length(Data{1}));
                  LFPinfo.datatype='splitting';
                 case 'duration'
                     LFPinfo.datatype='splitting';
                     for i=1:length(read_start)
                        %obj.LFPinfo.time{i}=linspace(EVTinfo.timestart(i),EVTinfo.timestop(i),size(obj.LFPdata{i},1));
                     end
             end
              neuroresult.EVTinfo=EVTinfo;
            end
              LFPinfo.channelselect=chselect;
              LFPinfo.channeldescription=channeldescription;
              LFPinfo.Fs=str2num(obj.Samplerate);
              LFPinfo.blackchannel=[];
              neuroresult.LFPinfo=LFPinfo;
         end
         function [Infopanel,Datapanel]=createplot(obj)
         end
         function hbox=gui_plot(obj,parent)
             % generate gui plot of LFPdata files in a BoxPanel 
             % plot from NeuroData instead of NeuroResult
             % contains the channelselectpanel and LFP plot panel with timebar
                hbox = uix.VBox( 'Parent', parent );
                for i=1:length(obj) % for multiple lfp files within the subject
                % Add three box panels.
                boxPanels(i) = uix.BoxPanel( 'Parent', hbox,'UserData',i,'Title',obj(i).Filename);
                tmppanel1=uix.HBoxFlex('Parent',boxPanels(i)); % left is the channellist, right is the figure axes and timebar      
                channelpanel(i)=NeuroPlot.selectpanel();
                Channellist=arrayfun(@(x) num2str(x),1:str2num(obj(i).Channelnum),'UniformOutput',0);
                channelpanel(i).create(tmppanel1,strcat('channelpanel_',obj(i).Filename),Channellist);
                finfo=dir(obj(i).Filename);
                switch obj(i).Precision
                    case 'int16'
                        fsize=finfo.bytes/(2*str2num(obj(i).Channelnum));
                    case 'int32'
                        fsize=finfo.bytes/(4*str2num(obj(i).Channelnum));
                end
                timerange=fsize;
                timestamps=linspace(0,timerange,timerange)/str2num(obj(i).Samplerate);
                figurecontrol(i)=NeuroPlot.figurecontrol();
                figurecontrol(i)=figurecontrol(i).create(tmppanel1,strcat('figurepanel_',obj(i).Filename),'plot-scroll','timestamp',timestamps);
                set(tmppanel1,'Width',[-1,-5]);
                %addlistener(channelpanel(i).listpanel,'Value','PostSet',@(~,~) obj(i).ShowLFP(channelpanel(i),figurecontrol(i)));
                addlistener(figurecontrol(i).timerangepanel,'currenttime','PostSet',@(~,~) obj(i).ShowLFP(channelpanel(i),figurecontrol(i)));
                end
         end
         function ShowLFP(obj,channelpanel,figcontrolpanel)
             % gui read the LFPdata from binary files and show 
             [timestart,timestop]=figcontrolpanel.timerangepanel.gettimerange;
             %currenttime=figcontrolpanel.timerangepanel.getrelativetime;
             channelindex=channelpanel.getIndex(strcat('List_',channelpanel.Tag));
%              timestart=timestart+relativetime;
%              timestop=timestop+relativetime;
             data=LFPData.readdata(obj.Filename,str2num(obj.Channelnum),channelindex,round(timestart*str2num(obj.Samplerate)),round(timestop*str2num(obj.Samplerate)),obj.Precision);
             time=linspace(timestart,timestop,length(data));
             figcontrolpanel.plot(time,data');
             currenttime=figcontrolpanel.timerangepanel.getcurrenttime;
             yrange=get(gca,'YLim');
             hold on;
             plot(gca,[currenttime,currenttime],[yrange(1),yrange(2)],'Color','r');
         end

    end
    methods(Static)
         function obj=LFPData(varargin)
             % struct to LFPData
             if nargin==1
             varname=fieldnames(varargin{1});
             data=varargin{1};
             for j=1:length(data)
                 obj(j)=LFPData();
             for i=1:length(varname)
                 eval(['obj(j).',varname{i},'=data(j).',varname{i},';']);
             end
             end
             end
        end
        function data=readdata(filename,channelnum,channelselect,timestart,timestop,precision)
            fid=fopen(filename,'r');
            switch precision
                case 'int16'
                    readlen=timestop-timestart;
                    timestart=timestart*2*channelnum;
                case 'int32'
                    timestart=timestart*4*channelnum;
            end
            data=zeros(channelnum,readlen);
            fseek(fid,timestart,'bof');
            datatmp=fread(fid,[channelnum,readlen],precision);
            data(:,1:size(datatmp,2))=datatmp;
            data=data(channelselect,:);
            fclose(fid);
        end
                    
        function obj=Clone(neurodata)
             obj=LFPData();
             obj.Filename=neurodata.Filename;
             obj.Channelnum=neurodata.Channelnum;
             obj.Samplerate=neurodata.Samplerate;
             obj.fileTag=neurodata.fileTag;
             obj.ADconvert=neurodata.ADconvert;
        end
        function averageparams=getAverageparams
            % input the average condition names (including eventname and channelname) to average data
            % the reserve names are 'all','separate',and 'none'
            % all means average all channels or events
            % separate means average each channels or events conditions
            % none means do not average.
            title='LFP average params';
            prompt={'channel average mode','event average mode','baselinecorrect','baselinecorrect mode'};
            lines=4;
            def={'separate','separate','-1,0','subtract'};  
            output=inputdlg(prompt,title,lines,def,'on');
            averageparams.Channel=output{1};
            averageparams.Event=output{2};
            averageparams.Baseline=str2num(output{3});
            averageparams.Correctmode=output{4};
    end
    end
end
