classdef SpikeClassifier
    % show the classfier panel from cell_metrics.cellinfo.mat by CellExplorer
    properties
        parent;
    end
    methods
        function obj = create(obj,varargin)
             varinput={'parent'};
             default={[]};
               for i=1:length(varinput)
                   eval([varinput{i},'=default{i};']);
               end
             for i = 1:2:length(varargin)
                     varindex=find(ismember(varinput,lower(varargin{i}))==1);
                     eval([varinput{varindex},'=varargin{i+1};']);
             end
             obj.parent=parent;
             filterpanel=uix.VBox('Parent',obj.parent,'Tag','filterpanel');  
             uicontrol('Parent',filterpanel,'Style','text','Tag','Classpath');
             filtersubpanel1=uix.HBox('Parent',filterpanel);
             uicontrol('Parent',filtersubpanel1,'Style','text','String','putativeCelltype');
             celltype=uicontrol('Parent',filtersubpanel1,'Style','listbox','String',{'Unknown','Pyramidal Cell','Wide Interneuron','Narrow Interneuron'},'Tag','Celltype','min',1,'max',3,'Value',1:4);
             filtersubpanel2=uix.HBox('Parent',filterpanel);
             uicontrol('Parent',filtersubpanel2,'Style','text','String','firingRate range [min max]');
             firingrate=uicontrol('Parent',filtersubpanel2,'Style','edit','String','','Tag','firingrange','String','0 Inf');
             uix.Empty('Parent',filtersubpanel2);
             filtersubpanel3=uix.HBox('Parent',filterpanel);
               uicontrol('Parent',filtersubpanel3,'Style','text','String','putativeConnectionsType');
             connectiontype=uicontrol('Parent',filtersubpanel3,'Style','listbox','String',{'no','excitatory','inhibitory'},'Tag','Connectiontype','min',1,'max',3,'Value',1:3);
             filtersubpanel4=uix.HBox('Parent',filterpanel);
             uicontrol('Parent',filtersubpanel4,'Style','text','String','UpStreamRegion');
             upstream=uicontrol('Parent',filtersubpanel4,'Style','listbox','Tag','Upstreamchannel','min',1,'max',3);
             filtersubpanel5=uix.HBox('Parent',filterpanel);
             uicontrol('Parent',filtersubpanel5,'Style','text','String','DownStreamRegion');
             downstream=uicontrol('Parent',filtersubpanel5,'Style','listbox','Tag','Downstreamchannel','min',1,'max',3);
             controlpanel=uix.HBox('Parent',filterpanel);
             uicontrol('Parent',controlpanel,'Style','checkbox','String','hold on the filters','Tag','Appfilters','Value',1);
             uicontrol('Parent',controlpanel,'Style','pushbutton','String','Filter the spike according filters','Tag','FilterSpikes');            
        end
        function obj=assign(obj,classifierpath,channeldescription,spikepanel)
            tmpobj=findobj(gcf,'Tag','Classpath');
            set(tmpobj,'String',['Current Cellmatrix Path: ',classifierpath]);
            celltype=findobj(gcf,'Tag','Celltype');
            firingrange=findobj(gcf,'Tag','firingrange');
            connectiontype=findobj(gcf,'Tag','Connectiontype');
            upstream=findobj(gcf,'Tag','Upstreamchannel');
            downstream=findobj(gcf,'Tag','Downstreamchannel');
            set(upstream,'String',cat(1,{'Choose'},unique(channeldescription)),'Value',1:length(unique(channeldescription))+1);
            set(downstream,'String',cat(1,{'Choose'},unique(channeldescription)),'Value',1:length(unique(channeldescription))+1);
            tmpobj=findobj(gcf,'Tag','FilterSpikes');
            set(tmpobj,'Callback',@(~,~) obj.FilterSpikes(spikepanel,celltype,firingrange,connectiontype,upstream,downstream));   
        end
        
        function obj=FilterSpikes(obj,spikepanel,celltype,firingrate,connectiontype,upstream,downstream)
            %METHOD1 此处显示有关此方法的摘要
            %   此处显示详细说明
                tmpobj=findobj(gcf,'Tag','Classpath');
                classifierpath=strrep(tmpobj.String,'Current Cellmatrix Path: ','');
                 cellmatrics=matfile(classifierpath);
                 cellmatrics=cellmatrics.cell_metrics;
                 Namelist=arrayfun(@(x,y) ['cluster',num2str(x),'_',num2str(y)],cellmatrics.electrodeGroup,cellmatrics.cluID,'UniformOutput',0);
                 spikename=spikepanel.listorigin;
                 channeldescription=spikepanel.listdescription;
                 celltypeindex=ismember(cellmatrics.putativeCellType,celltype.String(celltype.Value));
                 blacklist(:,1)=~celltypeindex;
                 firingrange=str2num(firingrate.String);
                 firingindex=find(cellmatrics.firingRate>firingrange(1) & cellmatrics.firingRate<firingrange(2));
                 blacklist(:,2)=~firingindex;
                 connections=cellmatrics.putativeConnections;
                 connect=[];
                 if ismember(1,connectiontype.Value)
                     blacklist(:,3)=~logical(ones(length(Namelist),1));
                 else
                     if ismember(2,connectiontype.Value)
                     connect=cat(1,connect,cellfun(@(x) Namelist(x),num2cell(connections.excitatory),'UniformOutput',1));
                     end
                    if ismember(3,connectiontype.Value)
                     connect=cat(1,connect,cellfun(@(x) Namelist(x),num2cell(connections.inhibitory),'UniformOutput',1));
                     end
                    connectindex=cellfun(@(x) cellfun(@(y) ~isempty(regexpi(y,['\<',x,'\>'],'match')),reshape(connect,[],1),'UniformOutput',1),Namelist,'UniformOutput',0);
                    connectindex=logical(sum(cell2mat(connectindex),1));
                    blacklist(:,3)=~connectindex;
                     choosespikeindex=spikepanel.listorigin(ismember(spikepanel.listdescription,upstream.String(upstream.Value)));
                     chooseindexup=cellfun(@(x) cellfun(@(y) ~isempty(regexpi(y,['\<',x,'\>'],'match')),choosespikeindex,'UniformOutput',1),connect(:,1),'UniformOutput',0);
                     choosespikeindex=spikepanel.listorigin(ismember(spikepanel.listdescription,downstream.String(downstream.Value)));
                      chooseindexdown=cellfun(@(x) cellfun(@(y) ~isempty(regexpi(y,['\<',x,'\>'],'match')),choosespikeindex,'UniformOutput',1),connect(:,2),'UniformOutput',0);
                     chooseindex=cellfun(@(x,y) [sum(x),sum(y)],chooseindexup,chooseindexdown,'UniformOutput',0);
                     connectindex=logical(cellfun(@(x) x(1)*x(2),chooseindex,'UniformOutput',1)); 
                     choosename=[];
                     if ismember('Choose',upstream.String(upstream.Value))
                         choosename=cat(1,choosename,connect(connectindex,1));
                     end
                     if ismember('Choose',upstream.String(downstream.Value))
                         choosename=cat(1,choosename,connect(connectindex,2));
                     end
                     chooseindex=cellfun(@(x) cellfun(@(y) ~isempty(regexpi(y,['\<',x,'\>'],'match')),choosename,'UniformOutput',1),Namelist,'UniformOutput',0);
                     chooseindex=logical(sum(cell2mat(chooseindex),1));
                     blacklist(:,4)=~chooseindex;
                 end
                 blacklist=logical(sum(blacklist,2));
                 tmpobj=findobj(gcf,'parent',spikepanel.parent,'Tag','blacklist');
                blacklistindex=cellfun(@(x) cellfun(@(y) ~isempty(regexpi(y,['\<',x,'\>'],'match')),Namelist(blacklist),'UniformOutput',1),spikepanel.listorigin,'UniformOutput',0);
                blacklistindex=logical(sum(cell2mat(blacklistindex),2)); 
                tmpobj.String=spikepanel.listorigin(blacklistindex);
                spikepanel.typechangefcn();
        end
        function Filter=GetFilterValue(obj)
            checkbox=findobj(gcf,'Tag','Appfilters');
            Filter=[];
            try
             if checkbox.Value
                celltype=findobj(gcf,'Tag','Celltype');
                Filter{1}=celltype.Value;
                firingrange=findobj(gcf,'Tag','firingrange');
                Filter{2}=firingrange.String;
                connectiontype=findobj(gcf,'Tag','Connectiontype');
                Filter{3}=connectiontype.Value;
                upstream=findobj(gcf,'Tag','Upstreamchannel');
                Filter{4}=upstream.String(upstream.Value);
                downstream=findobj(gcf,'Tag','Downstreamchannel');
                Filter{5}=downstream.String(downstream.Value); 
             end
            catch
                Filter=[];
            end
        end
        function err=SetFilterValue(obj,Filter,spikepanel)
            err=true;
            if isempty(Filter)
                return;
            else
            celltype=findobj(gcf,'Tag','Celltype');
            celltype.Value=Filter{1};
            firingrange=findobj(gcf,'Tag','firingrange');
            firingrange.String=Filter{2};
            connectiontype=findobj(gcf,'Tag','Connectiontype');
            connectiontype.Value=Filter{3};
            upstream=findobj(gcf,'Tag','Upstreamchannel');
            err=~logical(prod(contains(Filter{4},upstream.String)));
            if err
                return;
            else
                upstream.Value=find(contains(upstream.String,Filter{4})==1);
                downstream=findobj(gcf,'Tag','Downstreamchannel');
                downstream.Value=find(contains(downstream.String,Filter{5})==1);
                obj.FilterSpikes(spikepanel,celltype,firingrange,connectiontype,upstream,downstream);
            end
            end 
        end
    end
end

