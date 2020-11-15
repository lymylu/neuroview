classdef SpikeClassfier
    % show the classfier panel from cell_metrics.cellinfo.mat by CellExplorer
    properties
        cellmatrix;
        parent;
    end
    methods
        function obj = create(obj,varargin)
             varinput={'parent','classifierpath','channeldescription','spikepanel'};
             default={[],[]};
               for i=1:length(varinput)
                   eval([varinput{i},'=default{i};']);
               end
             for i = 1:2:length(varargin)
                     varindex=find(ismember(varinput,lower(varargin{i}))==1);
                     eval([varinput{varindex},'=varargin{i+1};']);
             end
             obj.parent=parent;
             uicontrol('Parent',parent,'Style','text','String','Current Cellmatrix Path ',classifierpath);
             filterpanel=uix.VBox('Parent',parent);
             filtersubpanel1=uix.HBox('Parent',filterpanel);
             uicontrol('Parent',filtersubpanel1,'Style','text','String','putativeCelltype');
             celltype=uicontrol('Parent',filtersubpanel1,'Style','listbox','String',{'Unknown','Pyramidal Cell','Wide Interneuron','Narrow Interneuron'},'Tag','Celltype','min',1,'max',2,'Value',1:4);
             filtersubpanel2=uix.HBox('Parent',filterpanel);
             uicontrol('Parent',filtersubpanel2,'Style','text','String','firingRate range [min max]');
             firingrate=uicontrol('Parent',filtersubpanel2,'Style','edit','String','','Tag','firingrate range');
             uix.Empty('Parent',filtersubpanel2);
             filtersubpanel3=uix.HBox('Parent',filterpanel);
               uicontrol('Parent',filtersubpanel3,'Style','text','String','putativeConnectionsType');
             connectiontype=uicontrol('Parent',filtersubpanel3,'Style','listbox','String',{'no','excitatory','inhibitory'},'Tag','Connectiontype','Value',1:3);
             filtersubpanel4=uix.HBox('Parent',filterpanel);
             uicontrol('Parent',filtersubpanel4,'Style','text','UpStreamRegion');
             upstream=uicontrol('Parent',filtersubpanel4,'Style','listbox','String',channeldescription,'Tag','Upstreamchannel','min',1,'max',2,'Value',1:length(channeldescription));
             filtersubpanel5=uix.HBox('Parent',filterpanel);
             uicontrol('Parent',filtersubpanel5,'Style','text','DownStreamRegion');
             downstream=uicontrol('Parent',filtersubpanel5,'Style','listbox','String',channeldescription,'Tag','Downstreamchannel','min',1,'max',2,'Value',1:length(channeldescription));
             obj.cellmatrix=matfile(classifierpath);
             controlpanel=uix.HBox('Parent',filterpanel);
             uicontrol('Parent',controlpanel,'Style','checkbox','String','hold on the filters','Tag','Appfilters');
             uicontrol('Parent',controlpanel,'Style','pushbutton','String','Filter the spike according filters','Callback',obj.FilterSpikes(spikepanel,celltype,firingrate,connectiontype,upstream,downstream));            
        end
        
        function obj=obj.FilterSpikes(obj,spikepanel,celltype,firingrate,connectiontype,upstream,downstream)
            %METHOD1 此处显示有关此方法的摘要
            %   此处显示详细说明
                 cellmatrics=obj.cellmatrix.cell_metrics;
                 Namelist=arrayfun(@(x,y) ['cluster',num2str(x),'_',num2str(y)],cellmatrics.electrodeGroup,cellmatrics.cluID,'UniformOutput',0);
                 spikename=spikepanel.listorigin;
                 channeldescription=spikepanel.listdescription;
                 celltypeindex=ismember(cellmatrics.putativeCellType,celltype.String(celltype.Value));
                 blacklist(:,1)=Namelist(~celltypeindex);
                 firingrange=str2num(firingrate.String);
                 firingindex=find(cellmatrics.firingRate>firingrate(1) & cellmatrics.firingRate<firingrate(2));
                 blacklist(:,2)=Namelist(~firingindex);
                 connections=cellmatrics.putativeConnections;
                 connect=[];
                 if ismember(connectiontype,1)
                     blacklist(:,3)=Namelist(~logical(ones(length(Namelist),1)));
                 else
                     if ismember(connectiontype,2)
                     connect=cat(1,connect,cellfun(@(x) Namelist(x),num2cell(connections.excitatory),'UniformOutput',1));
                    elseif ismember(connectiontype,3)
                     connect=cat(1,connect,cellfun(@(x) Namelist(x),num2cell(connections.inhibitory),'UniformOutput',1));
                     end
                    connect=cellfun(@(x) cellfun(@(y) ~isempty(regexpi(y,['\<',x,'\>'],'match')),reshape(connect,[],1),'UniformOutput',1),Namelist,'UniformOutput',0);
                    connect=logical(sum(cell2mat(connectindex),1));
                    blacklist(:,3)=Namelist(~connectindex);
                 end
                 choosespikeindex=spikepanel.listorigin(ismember(spikepanel.listdescription,upstream.String(upstream.Value)));
                 chooseindex=cellfun(@(x) cellfun(@(y) ~isempty(regexpi(y,['\<',x,'\>'],'match')),choosespikeindex,'UniformOutput',1),Namelist,'UniformOutput',0);
                 chooseindex=logical(sum(cell2mat(chooseindex),1);
                 blacklist(:,4)=Namelist(~chooseindex);
                 choosespikeindex=spikepanel.listorigin(ismember(spikepanel.listdescription,downstream.String(downstream.Value)));
                 chooseindex=cellfun(@(x) cellfun(@(y) ~isempty(regexpi(y,['\<',x,'\>'],'match')),choosespikeindex,'UniformOutput',1),Namelist,'UniformOutput',0);
                 chooseindex=logical(sum(cell2mat(chooseindex),1);
                 blacklist(:,5)=Namelist(~chooseindex);
                 blacklist=logical(sum(blacklist,2));
                 tmpobj=findobj(gcf,'parent',spikepanel.parent,'Tag','blacklist');
                 tmpobj.String=Namelist(blacklist);
                 spikepanel.typechangefcn();
        end
    end
end

