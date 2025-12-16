classdef LFPData < BasicTag
    %LFPDATA Continuous data management in NEURODATA object
    % it contains the binary file(s)
    % The marix is channel*timepoint if using fread() and used the transposed formation timepoint*channel in the object
    % the Properties Channelnum(channel number), AD convert coeff (ADconvert), sample rate (Samplerate), precision (Precision) must be defined by LFPData.initialize
    % The channel map information were defined in neurodata object
    % See also: NEURODATA, BASICTAG
    properties (Access='public') % for LFPdata file
        Filename=[];
        Channelnum=[];
        Samplerate=[];
        ADconvert=[];
        Precision='int16';
        ChannelTag=[]; % Group Position ChannelIndex
    end
    methods (Access='public')
         function obj = fileappend(obj)
             [lfppath,path]=uigetfile('*.*','Please select the Path of the Continuous file(s)','Multiselect','on');
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
             bool=~isempty(obj.Channelnum)&~isempty(obj.Samplerate)&~isempty(obj.fileTag)&~isempty(obj.ADconvert)&~isempty(obj.Precision);
         end
         function neuroresult = Extractdata(obj,neuroresult,chselect,channeldescription,EVTdata)
            % extract LFP data from LFPData object using the EVTdata.LoadEVT, return NeuroResult object
            % neuroresult= Extractdata(obj, neuroresult, chselect, channeldescription, EVTdata)
            % neuroresult= Extractdata(obj,[],chselect,channeldescription,[])
            % See also: readmulti_frank
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
             read_start=round(EVTdata.EVTinfo.time(:,1).*str2num(obj.Samplerate));
             read_until=round(EVTdata.EVTinfo.time(:,2).*str2num(obj.Samplerate));
            if isempty(chselect) % load all channel
                chselect=1:str2num(obj.Channelnum);
            end
             for i=1:length(read_start)
                Data{i}=readmulti_frank(obj.Filename, str2num(obj.Channelnum), chselect, read_start(i), read_until(i),obj.Precision);
                Data{i}=Data{i}.*str2num(obj.ADconvert);
             end
             if isinf(EVTdata.EVTinfo.time(1,2)) % load the whole file, calculate the file time;
                 EVTdata.EVTinfo.time(1,2)=size(Data{1},1)/str2num(obj.Samplerate);
             end
             neuroresult.LFPdata=Data;
            if ~isempty(EVTdata)
             switch EVTdata.selectevent.timetype
                 case 'timepoint'
                  LFPinfo.time=linspace(EVTdata.EVTinfo.timerange(1),EVTdata.EVTinfo.timerange(2),size(neuroresult.LFPdata{1},1)); % for plot, time(:,i)=linspace(read_start(i),read_until(i),length(Data{1}));
                 case 'duration'
                     for i=1:length(read_start)
                        LFPinfo.time{i}=linspace(EVTdata.EVTinfo.time(i,1),EVTdata.EVTinfo.time(i,2),size(neuroresult.LFPdata{i},1));
                     end
             end
              LFPinfo.datatype='splitting';
              neuroresult.EVTinfo=EVTdata.EVTinfo;
            end
              LFPinfo.channelselect=chselect';
              LFPinfo.channeldescription=channeldescription';
              LFPinfo.Fs=str2num(obj.Samplerate);
              LFPinfo.blackchannel=false(size(channeldescription))';
              neuroresult.LFPinfo=LFPinfo;
         end
         function hbox=gui_plot(obj,parent)
             % generate gui plot of LFPdata files in a BoxPanel
             % plot from NeuroData instead of NeuroResult
             % contains the channelselectpanel and LFP plot panel with timebar
             % See also: NEURODATA.GUI_PLOT
                hbox = uix.VBox( 'Parent', parent );
                for i=1:length(obj) % for multiple lfp files within the subject
                % Add three box panels.
                boxPanels(i) = uix.BoxPanel( 'Parent', hbox,'UserData',i,'Title',obj(i).Filename);
                tmppanel1=uix.HBoxFlex('Parent',boxPanels(i)); % left is the channellist, right is the figure axes and timebar      
                channelpanel(i)=NeuroPlot.selectpanel();
                Channellist=arrayfun(@(x) num2str(x),1:str2num(obj(i).Channelnum),'UniformOutput',0);
                channelpanel(i).create(tmppanel1,strcat(obj(i).Filename,'_channelpanel'),Channellist);
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
             channelindex=channelpanel.getIndex;
%              timestart=timestart+relativetime;
%              timestop=timestop+relativetime;
             data=LFPData.readdata(obj.Filename,str2num(obj.Channelnum),channelindex,round(timestart*str2num(obj.Samplerate)),round(timestop*str2num(obj.Samplerate)),obj.Precision);
             time=linspace(timestart,timestop,length(data));
             figcontrolpanel.plot(time,data');
             currenttime=figcontrolpanel.timerangepanel.getcurrenttime;
             currentaxes=findobj(figcontrolpanel,'Type','Axes');
             yrange=get(gca,'YLim');
             hold on;
             h=plot(currentaxes,[currenttime,currenttime],[yrange(1),yrange(2)],'Color','r');
             h.Tag='currenttimeline';
             set(currentaxes,'ButtonDownFcn',@(~,~) obj.changecurrenttimeline(figcontrolpanel));
         end
         function changecurrenttimeline(obj,figcontrolpanel)
             currenttimeline=findobj(figcontrolpanel,'Tag','currenttimeline');
             ax=findobj(figcontrolpanel,'Type','Axes'); 
             coord = get(ax, 'CurrentPoint');
             x = coord(1,1);
             delete(currenttimeline);
             yrange=get(ax,'YLim');
             h=plot(ax,[x,x],[yrange(1),yrange(2)],'Color','r');
             h.Tag='currenttimeline';
             timerange=findobj(figcontrolpanel,'Tag','timerange');
             currenttimerange=ax.XLim;
             timerange.String=num2str([currenttimerange(1)-x,currenttimerange(2)-x]);
             relativetime=findobj(figcontrolpanel.timerangepanel,'Tag','relativetime');
             set(relativetime,'String',num2str(x));
             figcontrolpanel.timerangepanel.settimebar('timerelative');
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
            % read data for gui_plot
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
        function averageparams=getAverageparams(varargin)
            % input the average condition names (including eventname and channelname) to average data
            % the reserve names are 'all','separate',and 'none'
            % all means average all channels or events
            % separate means average each channels or events conditions
            % none means do not average.
            % See also: NeuroResult.AverageSubject
            p=inputParser;
            addParameter(p,'Channel','none',@NeuroMethod.CheckAverageInput);
            addParameter(p,'Event','separate',@NeuroMethod.CheckAverageInput);
            addParameter(p,'Baseline',[-1,0],@isnumeric);
            addParameter(p,'Correctmode','zscore',@ischar);
            addParameter(p,'AverageBeforeCorrection',false,@islogical);
            if nargin>1
                parse(p,varargin{:});
                averageparams=p.Results;
            else
            title='LFP average params';
            prompt={'channel average mode','event average mode','baselinecorrect','baselinecorrect mode','Average Before Correction'};
            lines=4;
            def={'none','separate','-1,0','subtract','0'};  
            output=inputdlg(prompt,title,lines,def,'on');  
            averageparams.Channel=NeuroMethod.valid(output{1});
            averageparams.Event=NeuroMethod.valid(output{2});
            averageparams.Baseline=str2num(output{3});
            averageparams.Correctmode=output{4};
            averageparams.AverageBeforeCorrection=logical(str2num(output{5}));
            end
    end
    end
end
