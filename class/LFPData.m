classdef LFPData < BasicTag 
    properties (Access='public')
        Filename=[];
        Channelnum=[];
        Samplerate=[];
        fileTag=[];
        ADconvert=[];
        Precision='int16';
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
         function obj = Taginfo(obj,Tagname,informationtype, information)
             obj = Taginfo@BasicTag(obj, Tagname,informationtype, information);
         end
         function bool = Tagchoose(obj, Tagname,informationtype, information)
             bool = Tagchoose@BasicTag(obj,Tagname,informationtype,information);
         end          
         function obj = SampleRate(obj, samplerate)
             obj.Samplerate=samplerate;
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
         function gui_plot(obj,parent)
             % generate gui plot of LFPdata files in a BoxPanel 
             % plot from NeuroData instead of NeuroResult
             if ~isempty(parent)
                 parent=figure();
             end
                hbox = uix.HBox( 'Parent', parent );
                for i=1:length(obj)
                % Add three box panels.
                boxPanels(i) = uix.BoxPanel( 'Parent', hbox, 'Title',obj(i).Filename,'UserData',i);
                tmppanel1=uix.HBoxFlex('Parent',boxPanels(i));
                Channelcontrol(i)=uicontrol('Parent',tmppanel1,'Style','listbox','String',num2cell(1:str2num(obj.Channelnum)),'Min',1,'Max',3);
                tmppanel2=uix.VBoxFlex('Parent',tmppanel1);
                LFPshow(i)=uiaxes('Parent',tmppanel2);
                tmppanel3=uix.HBox('Parent',tmppanel2);
                uicontrol('Parent',tmppanel3,'Style','text','String','Timerange');
                Timecontrol(i).timerange=uicontrol('Parent',tmppanel3,'Style','edit','String','1000'); % 1000ms per show, could be change.
                fid(i)=fopen(obj(i).Filename,'r');
                fseek(fid(i),0,'eof');
                fsize=ftell(fid(i));
                switch obj(i).Precision
                    case 'int16'
                        fsize=fsize/(2*str2num(obj.Channelnum));
                    case 'int32'
                        fsize=fsize/(4*str2num(obj.Channelnum));
                end
                try 
                    addprop(obj(i),'fsize');
                    obj(i).fsize=fize;
                end
                Sliderstep=1/(fsize/obj(i).Samplerate*str2num(Timecontrol(i).timerange));
                Timecontrol(i).slider=uicontrol('Parent',tmppanel3,'Style','slider','Min',0,'Max',1,'SliderStep',[SliderStep/5,SliderStep],'Value',1);
                Timecontrol(i).timedisplay=uicontrol('Parent',tmppanel3,'Style','text');
                set(tmppanel1,'Width',[-1,-5]);
                set(tmppanel2,'Height',[-5,-1]);
                addlistener(Channelcontrol.Value,'PostSet',@(~,~) obj(i).ShowLFP(Channelcontrol(i),Timecontrol(i),LFPshow(i)));
                addlistener(Timecontrol(i).slider.Value,'PostSet',@(~,~) obj(i).ShowLFP(Channelcontrol(i),Timecontrol(i),LFPshow(i)));
                addlistener(Timecontrol(i).timerange.Value,'PostSet',@(~,~) obj(i).ShowLFP(Channelcontrol(i),Timecontrol(i),LFPshow(i)));
                end
         end
         function ShowLFP(obj,Channelcontrolpanel,Timecontrolpanel,LFPshowpanel)
             % gui read the LFPdata from binary files and show 
             timestart=Timecontrolpanel.slider/obj.fize*num2str(obj.Samplerate)*1000;
             timestop=timestart+str2num(Timecontrolpanel.timerange.String);
             Channelselect=Channelcontrolpanel.Value;
             data=readmulti_frank(obj.Filename,num2str(obj.Channelnum),Channelselect,timestart,timestop,obj.Precision);
             time=linspace(timestart,timestop,length(data));
             plot(LFPshowpanel,time,data');
         end

    end
    methods(Static)
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
