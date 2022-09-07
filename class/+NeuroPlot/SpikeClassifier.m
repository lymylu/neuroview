classdef SpikeClassifier
    % show the classfier panel from cell_metrics.cellinfo.mat by CellExplorer
    properties
        parent;
        Spikelist;
        Neuroresult;
        listener;
    end
    methods
        function obj=create(obj,parent)
            % create SpikeClasspanel
            global Datataglist
            Datataglist=[];
            obj.parent=parent;
            spikepanel=uix.VBox('Parent',parent,'Padding',5);
            descriptionpanel=uix.HBox('Parent',spikepanel,'Padding',5);
            uicontrol(descriptionpanel,'Style','listbox','Tag','descriptionlist','max',3,'min',1);
            uitable(descriptionpanel,'data',[],'Tag','descriptiontext');
            filterpanel=uix.HBox('Parent',spikepanel,'Padding',5);
            uitable(filterpanel,'data',[],'Tag','filtercondition');
            uicontrol(filterpanel,'Style','pushbutton','String','filter','Tag','filter');
            tagpanel=uix.VBox('Parent',spikepanel,'Padding',5);
            uicontrol(tagpanel,'Style','pushbutton','String','addnewtag','Tag','AddTag');
            uicontrol(tagpanel,'Style','pushbutton','String','deletenewtag','Tag','DeleteTag');
            obj.Spikelist=uicontrol(spikepanel,'Style','listbox','Tag','Spikelist','Visible','off'); 
        end
        function obj=assign(obj,Neuroresult)
            % include current SpikeClass (fieldnames in SPKinfo except Fs, name, datatype, channel)
            obj.Neuroresult=Neuroresult;
            descriptionlist=obj.getDescriptionlist;
            tmpobj1=findobj(obj.parent,'Tag','descriptionlist');
            set(tmpobj1,'String',descriptionlist,'Value',1);
            tmpobj2=findobj(obj.parent,'Tag','descriptiontext');
            tmpobj=findobj(obj.parent,'Tag','Spikelist');
            set(tmpobj,'String',Neuroresult.SPKinfo.name); 
            try 
               delete(obj.listener);
            end
            obj.listener=addlistener(obj.Spikelist,'Value','PostSet',@(~,src) obj.selectDescription(tmpobj1,tmpobj2));
            obj.selectDescription(tmpobj1,tmpobj2);
            set(tmpobj1,'Callback',@(~,~) obj.selectDescription(tmpobj1,tmpobj2));
            tmpobj=findobj(obj.parent,'Tag','AddTag');
            set(tmpobj,'Callback',@(~,~) obj.addSpikeTag);
             tmpobj=findobj(obj.parent,'Tag','DeleteTag');
             set(tmpobj,'Callback',@(~,~) obj.deleteSpikeTag);
            tmpobj=findobj(obj.parent,'Tag','filtercondition');
            set(tmpobj,'Data',cell(length(tmpobj1.String),1),'RowName',tmpobj1.String,'ColumnEditable',true,'ColumnName','condition');
        end
        function selectDescription(obj,descriptionlist,descriptiontext)
            global currentindex 
                fieldname=descriptionlist.String(descriptionlist.Value);
                for i=1:length(fieldname)
                    tmp=eval(['obj.Neuroresult.SPKinfo.',fieldname{i},'(currentindex);']);
                    if isnumeric(tmp)
                        tmp=num2cell(tmp);
                        tmp=cellfun(@(x) num2str(x),tmp,'UniformOutput',0);
                    end
                    description(i,:)=tmp;
                end
                set(descriptiontext,'Data',description','ColumnName',fieldname);
        end
        function addSpikeTag(obj)
            global currentindex Datataglist
            [informationtype, information, Datataglist]=Taginfoappend(Datataglist);
            obj.Neuroresult=obj.Neuroresult.Taglistinfo('SPKinfo',informationtype,information,currentindex);
            tmpobj1=findobj(obj.parent,'Tag','descriptionlist');
            tmpobj1.String=obj.getDescriptionlist;
            tmpobj2=findobj(obj.parent,'Tag','descriptiontext');
            obj.selectDescription(tmpobj1,tmpobj2);
            tmpobj=findobj(obj.parent,'Tag','filtercondition');
            set(tmpobj,'Data',cell(length(tmpobj1.String),1),'RowName',tmpobj1.String,'ColumnEditable',true,'ColumnName','condition');
        end
        function deleteSpikeTag(obj)
            global currentindex
            descriptionlist=obj.getDescriptionlist;
            chooseindex=listdlg('PromptString','delet a description','SelectionMode','single','ListString',descriptionlist);
            obj.Neuroresult=obj.Neuroresult.Taglistinfo('SPKinfo',descriptionlist(chooseindex),[],currentindex);
            tmpobj1=findobj(obj.parent,'Tag','descriptionlist');
            tmpobj1.String=obj.getDescriptionlist;
            tmpobj2=findobj(obj.parent,'Tag','descriptiontext');
            obj.selectDescription(tmpobj1,tmpobj2);
            tmpobj=findobj(obj.parent,'Tag','filtercondition');
            set(tmpobj,'Data',cell(length(tmpobj1.String),1),'RowName',tmpobj1.String,'ColumnEditable',true,'ColumnName','condition');
            
        end
        function getCurrentIndex(obj)
            global currentindex Spikepanel filterindex
            index=Spikepanel.getIndex('SpikeIndex');
            currentindex=zeros(length(filterindex),1);
            current=find(filterindex==1);
            current=current(index);
            currentindex(current)=1;
            currentindex=logical(currentindex);
            set(obj.Spikelist,'Value',currentindex);
        end
        function descriptionlist=getDescriptionlist(obj)
            descriptionlist=fieldnames(obj.Neuroresult.SPKinfo);
            index=ismember(descriptionlist,{'Fs','name','datatype','channel'});
            descriptionlist=descriptionlist(~index);
        end
        function filterSpike(obj)
            global filterindex 
            conditionfilter=findobj(obj.parent,'Tag','filtercondition');
            condition=conditionfilter.Data;         
            % not finished！
            for i=1:size(condition,1)
                     eval([conditionfilter.RowName{i},'=obj.Neuroresult.SPKinfo.',conditionfilter.RowName{i},';']);
                if ~isempty(condition{i})
                    conditionstr=strrep(condition{i},'$',conditionfilter.RowName{i});
                    eval(['index(:,i)=',conditionstr,';']);
                else
                    eval(['index(:,i)=ones(length(',conditionfilter.RowName{i},'),1);']);
                end
            end
            filterindex=logical(prod(index,2));
        end
        
end
end

