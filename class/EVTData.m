classdef EVTData< BasicTag & dynamicprops
    properties
        Filename=[];
        EVTinfo=[];
    end
    methods (Access='public')
        function objmatrix =  fileappend(obj, filename)
            [evtpath,path]=uigetfile('*.evt','Please select the Path of the evt file(s)','Multiselect','on');
             if ischar(evtpath)
                 evtpath={evtpath};
             end
             for i=1:length(evtpath)
                 tmp=EVTData();
                 tmp.Filename=fullfile(path,evtpath{i});
                 objmatrix(i)=tmp;
             end
        end
        function Filename=getFilename(obj)
            for i=1:length(obj)
                Filename{i}=obj(i).Filename;
            end
        end
        function obj = initialize(obj)
             try
                obj.EVTinfo=EVTType(obj);
             end
         end
         function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
                [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
         end
         function obj=LoadEVT(obj)
             % load event from EVTdata.selectevent
              event=[];eventdescription=[];timerange=[];
              events=LoadEvents_neurodata(obj.Filename);
             switch obj.selectevent.timetype
                 case 'timepoint'
                    timerange=[obj.selectevent.timestart,obj.selectevent.timestop];
                    %tmp=eval(['events.',obj.selectevent.selectdescription{:},';']);
                    tmp=events.description;
                    index=ismember(tmp,obj.selectevent.selectdescription);
                    timestart=events.time(index)+timerange(1);
                    timestop=events.time(index)+timerange(2);
                    varname=fieldnames(events);
                    for i=1:length(varname)
                        eval(['eventsnew.',varname{i},'=events.',varname{i},'(index);']);
                    end
                    eventsnew.time(:,1)=timestart;
                    eventsnew.time(:,2)=timestop;
                    eventsnew.eventselect=find(index==1);
                    eventsnew.timerange=timerange;
                 case 'timeduration'
                    tmpstart=obj.selectevent.timestart;
                    tmpstop=obj.selectevent.timestop;
                    tmp=events.description;
                    for j=1:length(tmpstart)
                    startindex=ismember(tmp,tmpstart{j});
                    stopindex=ismember(tmp,tmpstop{j});
                    varname=fieldnames(events);
                    for i=1:length(varname)
                        if j==1
                            eval(['eventsnew.',varname{i},'=[];']);
                            eventsnew.eventselect=[];
                        end
                       try
                       eval(['eventsnew.',varname{i},'=cat(1,eventsnew.',varname{i},',[events.',varname{i},'(startindex),events.',varname{i},'(stopindex)]);']);
                       catch 
                          error(['different number of timebegin: ',tmpstart{j},'and timeend: ',tmpstop{j},' in ',char(obj.Filename)]);
                       end
                    end
                     eventsnew.eventselect=cat(1,eventsnew.eventselect,[find(startindex==1),find(stopindex==1)]);
                    end
             end
            eventsnew.timetype=obj.selectevent.timetype;
            obj.EVTinfo=eventsnew;
            obj.EVTinfo.blackevt=[];
         end
         function bool = check(obj)
             bool=~isempty(obj.EVTType)&~isempty(obj.fileTag);
         end
         function panel=gui_plot(obj,parent)
            panel=uix.VBoxFlex('Parent',parent);
            Filename=obj.getFilename;
            filepanel=uix.TabPanel('Parent',panel,'Tag','EventTablePanel');
            %filelist=uicontrol('Parent',panel,'Style','listbox','String',Filename,'Value',1,'Tag','subjectlist');
            for i=1:length(obj) % for several events
                events=LoadEvents_neurodata(obj(i).Filename);
                eventlist=arrayfun(@(x) num2str(x),events.time,'UniformOutput',0);
                selectpanel(i)=NeuroPlot.selectpanel();
                selectpanel(i).create(filepanel,strcat(obj(i).Filename,'_eventpanel'),eventlist,'typestring',events.description,'multiselect','off');
            end
%             set(filelist,'Callback',@(~,~) obj.changefile(filelist,filepanel));
%             set(filelist,'Value',1);
%             obj.changefile(filelist,filepanel);
         end
    end
    methods (Access='private')
        function changefile(obj,filelist,filepanel)
            value=filelist.Value;
            filepanel.SelectedChild=value;
         end
        function [description, time,eventselect]=EVTType(obj)
            if exist(obj.Filename)
            time=[];
            events=LoadEvents_neurodata(obj.Filename);
            % for neurosuite format events contains time and description
            % for neuroview format, events contains time and several fields
            try
                [~,index]=sort(events.time);
                events.time=events.time(index);
                if prod(contains(fieldnames(events),{'time','description'}))
                    events.description=events.description(index);
                else
                    field=fieldnames(events);
                    for c=1:length(field)
                        eval(['events.',field{c},'=events.',field{c},'(index);']);
                    end
                end
                SaveEvents_neurodata(obj.Filename,events,1);
            end
            if prod(contains(fieldnames(events),{'time','description'}))
                description.description=unique(events.description);
            else
                field=fieldnames(events);
                for c=1:length(field)
                    eval(['description.',field{c},'=unique(events.',field{c},');']);
                end
                description=rmfield(description,'time');
            end 
            end
        end
    end
    methods(Static)
       function obj=EVTData(varargin)
             if nargin==1
             varname=fieldnames(varargin{1});
             data=varargin{1};
             for j=1:length(data)
                 obj(j)=EVTData();
             for i=1:length(varname)
                 try
                     addprop(obj(j),varname{i});
                 end
                 eval(['obj(j).',varname{i},'=data(j).',varname{i},';']);
             end
             end
             end
        end
        function obj=Clone(neurodata)
             obj=EVTData();
             obj.Filename=neurodata.Filename;
             obj.EVTtype=obj.EVTType();
        end
    end
end
