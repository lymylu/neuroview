classdef NeuroResult < BasicTag & dynamicprops
    % analysis results in the subjectlevel. could be managed by NeuroData
    properties
         Filename
         Subjectname
        
    end 
    properties(SetObservable,Access=protected)
         LFPdataplot
         t_lfpplot
         channelindexplot
         SPKdataplot
         t_spkplot
         spikeindexplot
    end
    events
        LFPdatachange
        SPKdatachange
    end
    methods
         function obj =  fileappend(obj)
            % support the .clu. file from KlustaKwik and .npy file from Phy
            ResultType={'HDF5','Matfile'};
            index=listdlg('PromptString','choose the format of the Result','ListString',ResultType);
            switch index
                case 1
                    Resultpath = uigetdir('Please select the Path of the result');
                case 2
                    [Resultfile,Resultpath] =uigetfile('*.mat','Please select the matfile');
                    Resultpath=fullfile(Resultpath,Resultfile);
            end
            obj.Filename = Resultpath;
         end
        function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
             [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                  [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
        end
        function obj = NeuroResult(varargin)
            if nargin==1 
                varname=fieldnames(varargin{1});
                data=varargin{1};
                if ~strcmp(class(data),'matlab.io.MatFile')
                for j=1:length(data)
                    obj(j)=NeuroResult();
                    for i=1:length(varname)
                        try
                            addprop(obj,varname{i});
                        end
                        
                        if ~ismember(varname{i},NeuroMethod.List())
                            try
                                eval(['obj(j).',varname{i},'=data(j).',varname{i},';']);
                            catch
                                warning([varname{i},'is not the default vars, ignored.']);
                            end
                        else
                            eval(['obj(j).',varname{i},'=',varname{i},'(data(j).',varname{i},');']);
                        end
                    end 
                end
                else % only for transfer one matfile
                     varname(ismember(varname,'Properties'))=[];% remove matFile properties
                    for i=1:length(varname)
                    try
                        addprop(obj,varname{i});
                    end
                    if ~ismember(varname{i},NeuroMethod.List())
                    eval(['obj.',varname{i},'=data.',varname{i},';']);
                    else
                        eval(['obj.',varname{i},'=',varname{i},'(data.',varname{i},');']);
                    end
                    end
                end 
            end
        end
        function obj = ReadCAL(obj,CALData,EVTinfo)
            %% not work well!
%             read_start=EVTinfo.timestart;
%             read_until=EVTinfo.timestop;
%             data=importdata(CALData.Filename);
%             cellname=regexpi(data.textdata{1,1},',','split');
%             validindex=ismember(data.colheaders,' accepted');
%             validindex=find(validindex==1);
%             obj.CALinfo.name=cellname(validindex);
%             timelist=data.data(:,1);
%             for i=1:length(validindex)
%                 for j=1:length(read_start)
%                     obj.CALdata{i,j}=data.data(timelist>=read_start(j)&timelist<=read_until(j),validindex(i));
%                 end
%             end
%             % using fast oopsi to get the spike time and save in SPKdata
%             V.dt=1/str2num(CALData.Samplerate);
%             for i=1:size(obj.CALdata,1)
%                 for j=1:size(obj.CALdata,2)
%                     V.T=length(obj.CALdata{i,j});
%                     try
%                     [~, obj.SPKdata{i,j}] = foopsi(obj.CALdata{i,j});
%                     catch
%                         a=1;
%                     end
%                     %obj.SPKdata{i,j}=fast_oopsi(obj.CALdata{i,j},V);
%                 end
%             end
%             obj.SPKinfo.name=obj.CALinfo.name;
%             obj.SPKinfo.channeldescription=repmat({'default'},[1,length(obj.CALinfo.name)]);
%             obj.SPKinfo.channel=repmat({1},[1,length(obj.CALinfo.name)]);
        end
        function SaveData(obj,savepath,savefilename,format)
            % clear the obj and save to the given file as HDF5 or mat formation
            % for matfile formation, save the obj in the memory as a matfile
            % for hdf5 formation necessary information (except SPKdata, LFPdata and [NeuroMethod] object) are saved as Datainfo.yaml file
            % save the LFPdata as LFPdata/[eventnumber]/time*channel and t_lfp/[eventnumber]/time;
            % save the SPKdata as /[spikenumber]/[eventnumber]/time;
            % for [NeuroMethods] objects, see [NeuroMethods].SaveData;
            % See also: NEURORESULT.SAVEMAT, NEURORESULT.SAVEH5
            variablenames=fieldnames(obj);
            switch format
                case 'matfile'
                    if exist(fullfile(savepath,strcat(savefilename,'.mat')))
                        warning(strcat('the result: ',fullfile(savepath,strcat(savefilename,'.mat')),'is exist, current result could not be saved'));
                    else
                        mkdir(fullfile(savepath));
                        savemat=matfile(fullfile(savepath,strcat(savefilename,'.mat')),'Writable',true);
                        obj.Savemat(savemat);% save the object variables in the matfile object.
                        obj.Filename=fullfile(savepath,strcat(savefilename,'.mat'));
                    end
                case 'hdf5'
                    if exist(fullfile(savepath,savefilename))
                        warning(strcat('the result: ',fullfile(savepath,savefilename),'is exist, current result could not be saved'));
                    else
                    mkdir(fullfile(savepath,savefilename));
                    if isprop(obj,'LFPdata') && ~isempty(obj.LFPdata)
                        LFPdatafile=fullfile(savepath,savefilename,'LFPdata');
                        obj.Saveh5(LFPdatafile,'LFPdata','/event/time*channel','');
                        obj.LFPdata=LFPdatafile;
                    end
                    if isprop(obj,'SPKdata') && ~isempty(obj.SPKdata)
                        SPKdatafile=fullfile(savepath,savefilename,'SPKdata');
                        obj.Saveh5(SPKdatafile,'SPKdata','/spike/event/time','');
                        obj.SPKdata=SPKdatafile;
                    end
                    obj.Filename=fullfile(savepath,savefilename);
                    for i=1:length(variablenames)
                        if eval(['ismember(class(obj.',variablenames{i},'),NeuroMethod.List)'])
                           eval(['obj.',variablenames{i},'=obj.',variablenames{i},'.Saveh5(fullfile(savepath,savefilename));']);
                        end
                        %eval(['Datafile.',variablenames{i},'=obj.',variablenames{i},';']);
                    end
                    yaml.dumpFile(fullfile(savepath,savefilename,'Datainfo.yaml'),obj.struct());
                    end
            end
                varname=fieldnames(obj);
                for i=1:length(varname)
                   if ismember(varname{i},NeuroMethod.List)
                        obj.Taginfo('fileTag',varname{i},savefilename);
                   end
                end
        end
        function Savemat(obj,savemat)
            variablenames=fieldnames(obj);
              for i=1:length(variablenames)
                 eval(['savemat.',variablenames{i},'=obj.',variablenames{i},';']);
              end
        end
        function data=Loadmat(obj,varname,Cellindex,Matrixindex)
            % load the variable from the matfile obj (which have been readed in the memory
            tmp=eval(['obj.',varname,';']);
            if ~isempty(Cellindex)
            numDimsCell=length(Cellindex);
            outputvar=[];
            for i=1:numDimsCell
                outputvar=strcat(outputvar,['a',num2str(i)],',');
                eval(['a',num2str(i),'=Cellindex{i};']);
            end
            eval(['tmp=tmp(',outputvar(1:end-1),');']);
            else
                tmp={tmp};
            end
            numDimsMatrix=length(Matrixindex);
            outputvar=[];
            for i=1:length(Matrixindex)
                if islogical(Matrixindex{i})
                    outputvar=strcat(outputvar,'Matrixindex{',num2str(i),'},');
                elseif Matrixindex{i}==-1
                    outputvar=strcat(outputvar,':,');
                end
            end
            data=eval(['cellfun(@(x) x(',outputvar(1:end-1),'),tmp,"UniformOutput",0);']);
            if isempty(Cellindex)
                data=data{:};
            end
            end
            function Saveh5(obj,savefile,varname,saveformat,parentnode)
            % save the var in the savefile by the saveformat
            % the savepath in h5file is /parentnode/.../.../a*b*c*...
            % parentnode define the parent contains the cellmatrix and could be empty
            % cellmatrix will be set in /1/1/a*b*c,/1/2/a*b*c,...,/2/1/a*b*c,.......
            % the matrix in the cell will be save as a*b*c..
            % example: for LFPdata {event}(time*channel) would be saved as Saveh5(obj,savefile,'LFPdata','/event/time*channel')
            % for SPKdata {spike,event}(time) would be saved as Saveh5(obj,savefile,'SPKdata','/spike/event/time')
            % See also: NEURORESULT.LOADH5
            tmp=eval(['obj.',varname,';']);
            if iscell(tmp)
                dims=size(tmp);
                %numDims=length(dims);
                %
                numDims=length(regexpi(saveformat,'/','match'))-1;
                if numDims==1 && size(tmp,1)==1
                    tmp=tmp';
                end
                outputvar=[];h5path=[];
                for i=1:numDims
                    outputvar=strcat(outputvar,['a',num2str(i)],',');
                end
                for i=1:numel(tmp)
                    eval(['[',outputvar(1:end-1),']=ind2sub(dims,i);']);
                    h5path=eval(['num2str([',outputvar(1:end-1),']);']);
                    h5path = regexprep(h5path, '\s+', '/');
                    
                    if ~isempty(tmp{i})
                        try
                        h5create(savefile,strcat(parentnode,'/',h5path),size(tmp{i}));
                        catch
                            aa=1;
                        end
                        h5write(savefile,strcat(parentnode,'/',h5path),tmp{i});
                    else
                        h5create(savefile,strcat(parentnode,'/',h5path),[inf,1],'ChunkSize',[1,1]);
                    end
                end
            else
                h5create(savefile,parentnode,size(tmp));
                h5write(savefile,parentnode,tmp);
            end
        end
        function data=Loadh5(obj,loadfile,loadformat,parentnode,Cellindex,Matrixindex)
        % load the hdf5 file(savefile) to obj.varname.parentnode by the loadformat
        % reverse function of NeuroResult.Saveh5
        % varargin defined the index of each dimensions
        % Cellindex{a,b,...} defined the index between /a/b/...
        % a,b,.. must be logical.
        % Matrixindex{a,b,...} defined the index within /.../.../a*b*c, note that a*b*c for all Datasets should be the same (timepoint read)
        % a,b,c are logical or -1 (read all data in this dimension).
        % See also NEURORESULT.SAVEH5, NEURORESULT.SLICE, NEURORESULT.LOAD
            % generate cellmatrix
            if ~isempty(Cellindex)
            numDimsCell=length(Cellindex);
            outputvar=[];
            validCellvar=[];
            for i=1:numDimsCell
                    outputvar=strcat(outputvar,['a',num2str(i)],',');
                    validCellvar=strcat(validCellvar,['b',num2str(i)],',');
                    eval(['b',num2str(i),'=find(Cellindex{i}==1);']);
                    eval(['datadim(i)=length(b',num2str(i),');']);
            end
            eval(['[',outputvar(1:end-1),']=ndgrid(',validCellvar(1:end-1),');']);
            % generate cellpath in h5info file
            for i=1:numDimsCell
                tmp(i,:)=eval(['a',num2str(i),'(:);']);
            end
            for i=1:size(tmp,2)
                v{i} = strjoin(arrayfun(@num2str, tmp(:,i), 'UniformOutput', false), '/');
                v{i}(end+1)='/';
            end
            else
                v={''};
            end
            %get Matrixdimension
            if ~strcmp(v{1},'')
                info=h5info(loadfile,strcat(parentnode,'/',v{1}));
            else
                info=h5info(loadfile,strcat(parentnode,'/'));
            end
            dimsMatrix=info.Dataspace.Size;
            % calculate the start and count for read the Datasets
            numDimsMatrix=length(Matrixindex);
            for i=1:length(Matrixindex)
                if islogical(Matrixindex{i})
                    start{i}=obj.segmentIndices(find(Matrixindex{i}));
                    seglens=cellfun(@length,start{i});
                    blocklength(i)=length(start{i});
                %start(i)=min(find(Matrixindex{i}==1));
                %count(i)=max(find(Matrixindex{i}==1))-min(find(Matrixindex{i}==1))+1;
                elseif Matrixindex{i}==-1
                    start{i}=[1,inf];  
                    seglens(i)=1;
                    blocklength(i)=1;
                end
            end
            % load the Datasets from MatrixIndices
            try
                data=cellfun(@(x) obj.ReadH5(loadfile,strcat(parentnode,'/',x),Matrixindex),v,'UniformOutput',0);
            catch
                data=obj.ReadH5(loadfile,strcat(parentnode,'/'),Matrixindex);
            end
            if isempty(Cellindex)
                data=data{:};
            elseif length(datadim)>1 && ~isempty(data)
                data=reshape(data,datadim);
            end
        end
        function result=ReadH5(obj,loadfile,path,Matrixindex)
            % modified by Deepseek
            info = h5info(loadfile, path);
            if isfield(info,'Dataspace')&&prod(info.Dataspace.Size)~=0
                dims = info.Dataspace.Size;          % 各维度大小，例如 [m n p ...]
                ndimsData = length(dims);
                % 验证每个逻辑索引长度
                for i = 1:length(Matrixindex)
                  if Matrixindex{i}==-1
                      Matrixindex{i}=true(1,dims(i));
                  end
                end   
                % 将每个逻辑索引转换为下标，并分段
               
                segs = cell(1, ndimsData);          % 每个维度存储分段后的单元数组
                numSegs = zeros(1, ndimsData);       % 每个维度的段数
                outSegStarts = cell(1, ndimsData);   % 每个维度存储每个段在输出中的起始索引
                outDims = zeros(1, ndimsData);       % 输出数组每个维度的大小
                
                for i = 1:ndimsData
                    idx = find(Matrixindex{i});
                    % 分段
                    seg_i = obj.segmentIndices(idx);
                    segs{i} = seg_i;
                    numSegs(i) = length(seg_i);
                    % 计算每个段在输出中的起始偏移
                    segLens = cellfun(@length, seg_i);
                    outDims(i) = sum(segLens);
                    % 起始偏移：累积和（1-based），第一个段起始为1
                    outSegStarts{i} = cumsum([1, segLens(1:end-1)]);
                end
                % 确定数据类型
                oneElem = h5read(loadfile,path, ones(1, ndimsData), ones(1, ndimsData));
                dataClass = class(oneElem);
                % 预分配结果数组
                result = zeros(outDims, dataClass);
                % 生成所有维度的段索引组合
                segVectors = arrayfun(@(n) 1:n, numSegs, 'UniformOutput', false);
                gridOut = cell(1, ndimsData);
                [gridOut{:}] = ndgrid(segVectors{:});
                % 将每个网格展开为向量，方便线性遍历
                for i = 1:ndimsData
                    gridOut{i} = gridOut{i}(:);
                end
                nBlocks = prod(numSegs);
                % 遍历所有组合
                for block = 1:nBlocks
                    % 当前组合每个维度的段索引
                    curSegIdx = zeros(1, ndimsData);
                    for i = 1:ndimsData
                        curSegIdx(i) = gridOut{i}(block);
                    end
                    % 提取该段的信息
                    start = zeros(1, ndimsData);
                    count = zeros(1, ndimsData);
                    outStart = zeros(1, ndimsData);   % 在输出中的起始坐标（1-based）
                    for i = 1:ndimsData
                        seg = segs{i}{curSegIdx(i)};
                        start(i) = seg(1);
                        count(i) = length(seg);
                        outStart(i) = outSegStarts{i}(curSegIdx(i));
                    end
                    % 读取数据块
                    blockData = h5read(loadfile, path, start, count);
                    % 将块数据放入结果数组的对应位置
                    idxOut = cell(1, ndimsData);
                    for i = 1:ndimsData
                        idxOut{i} = outStart(i) : outStart(i) + count(i) - 1;
                    end
                    result(idxOut{:}) = blockData;
                end
            else
                result=[];
            end
        end


        % function data=ReadH5(obj,loadfile,path,start,count)
        %     % check the start and count if the dataset is empty
        %     datasize=h5info(loadfile,path);
        %     if isfield(datasize,'Dataspace')&&prod(datasize.Dataspace.Size)~=0
        %         data=h5read(loadfile,path,start,count);
        %     else
        %         data=[];
        %     end
        % end
        function data=CollectVariables(obj,Variablenames,catdimensions,reservevar)
            % cat the defined Variablenames in multiple NeuroResult obj
            % according to the defined cat dimensions.
            % if the variablename is lack, using the nan with the size same
            % to the variablename 'reservevar'
            for i=1:length(Variablenames)
                eval(['data.',Variablenames{i},'=[];']);
            end
           % data.Subjectname=[];
            for i=1:numel(obj)
                for j=1:length(Variablenames)
                   try
                   eval(['data.',Variablenames{j},'=cat(catdimensions(j),data.',Variablenames{j},',obj(i).',Variablenames{j},');']);
                   catch
                       disp(strcat('error cat in the ',Variablenames{j},' of the ',obj(i).Subjectname{1},' replaced with NaNs'));
                       switch class(eval(['data.',Variablenames{j}]))
                           case 'double'
                            eval(['data.',Variablenames{j},'=cat(catdimensions(j),data.',Variablenames{j},',nan(size(obj(i).',reservevar,')));']); 
                           case 'cell'
                            eval(['data.',Variablenames{j},'=cat(catdimensions(j),data.',Variablenames{j},',cell(size(obj(i).',reservevar,')));']); 
                           
                       end
                   end
                end
               % data.Subjectname=cat(2,data.Subjectname,repmat({obj(i).Subjectname},[1,length(obj(i).SPKinfo.channeldescription)]));
            end
         end
        function obj=Split2Splice(obj)
            % from Splitting mode to Splicing mode, the epoches were spliced.
            % in this transformation , the trial number is 1.
            if isprop(obj,'LFPdata')&&strcmp(obj.LFPinfo.datatype,'splitting')
                LFPdatatmp=[];
                for i=1:length(obj.LFPdata) 
                    LFPdatatmp=cat(1,LFPdatatmp,obj.LFPdata{i});
                    obj.LFPinfo.spliceindex(i)=length(LFPdatatmp); % get the index of segments
                end
                obj.LFPdata={LFPdatatmp};
                obj.LFPinfo.datatype='splicing';
            end
            if isprop(obj,'SPKdata')&&strcmp(obj.SPKinfo.datatype,'splitting')
                SPKtimecorrection=cumsum(obj.EVTinfo.time(:,2)-obj.EVTinfo.time(:,1));
                SPKtimecorrection=[0;SPKtimecorrection];
                spkt=[];
                for j=1:size(obj.SPKdata,1)
                    SPKdatatmp{j,1}=[];
                    for i=1:size(obj.SPKdata,2)
                        SPKdatatmp{j,1}=cat(1,SPKdatatmp{j},obj.SPKdata{j,i}-obj.EVTinfo.time(i,1)+SPKtimecorrection(i));
                    end
                    spkt{j}=[min(SPKtimecorrection),max(SPKtimecorrection)];
                end
                obj.SPKinfo.datatype='splicing'; 
                obj.SPKdata=SPKdatatmp;
                obj.SPKinfo.spliceindex=SPKtimecorrection;
                obj.SPKinfo.spkt=spkt;
            end
        end
        function obj=Splice2Split(obj)
            % from Splicing mode to Splitting mode, the epoches were
            % splitted into cell
            if strcmp(obj.SPKinfo.datatype,'splicing')
                SPKtimecorrection=obj.SPKinfo.spliceindex;
                SPKdatatmp=cell(size(obj.SPKdata,1),size(obj.EVTinfo.time,1));spkt=[]; 
                for j=1:size(obj.SPKdata,1)
                    for i=1:length(obj.SPKinfo.spliceindex)-1
                        SPKdatatmp{j,i}=obj.SPKdata{j}(find(obj.SPKdata{j}>SPKtimecorrection(i)&obj.SPKdata{j}<SPKtimecorrection(i+1)))-SPKtimecorrection(i)+obj.EVTinfo.time(i,1);
                        spkt{j,i}=[obj.EVTinfo.time(i,1),obj.EVTinfo.time(i,2)];
                    end
                end
                obj.SPKinfo.datatype='splitting';
                obj.SPKdata=SPKdatatmp;
                obj.SPKinfo=rmfield(obj.SPKinfo,'spliceindex');
                obj.SPKinfo.spkt=spkt;
            end
        end
        function plotvariable=getPlotnames(obj)
            variablenames=fieldnames(obj);
            for i=1:length(variablenames)
                variableclass{i}=eval(['class(obj.',variablenames{i},');']);
                variablevalid(i)=eval(['~isempty(obj.',variablenames{i},');']);
            end
            plotvariable=table(variablenames(variablevalid),variableclass(variablevalid)');
        end
        function [Infopanel, DataPanel]=createplot(obj,variablename,varargin)
         import NeuroPlot.selectpanel NeuroPlot.figurecontrol
            % generate the panels to plot LFPdata, SPKdata,CALdata and EVTinfo
%             Infopanel=uix.Panel();DataPanel=uix.BoxPanel();
            switch variablename
               case 'LFPData'
                Infopanel=NeuroPlot.selectpanel;
                Channeldescription=getfield(obj.LFPinfo,'channeldescription');
                Channellist=num2cell(obj.LFPinfo.channelselect);
                Channellist=cellfun(@(x) num2str(x),Channellist,'UniformOutput',0);
                blacklist=obj.LFPinfo.blackchannel;
                Infopanel=Infopanel.create([],'ChannelIndex',Channellist,'typestring',Channeldescription,'blacklist',blacklist);
                addlistener(Infopanel,'blacklist','PostSet',@(~,~) obj.recordblacklist(Infopanel,'LFP'));
                DataPanel=NeuroPlot.figurecontrol();
                DataPanel=DataPanel.create([],'LFPdatapanel',strcat('plot',varargin{1}));
                DataPanel.figpanel.Title='Original LFPs';
               case 'SPKData'
                Infopanel=NeuroPlot.selectpanel;
                SPKChanneldescription=getfield(obj.SPKinfo,'channeldescription');
                SPKchannel=getfield(obj.SPKinfo,'channel');
                channeltype=unique(SPKChanneldescription);
                SPKnamelist=obj.SPKinfo.spikename;
                blacklist=obj.SPKinfo.blackspk;
                Infopanel= Infopanel.create([],'SpikeIndex',SPKnamelist,'typestring',SPKChanneldescription,'blacklist',blacklist);
                addlistener(Infopanel,'blacklist','PostSet',@(~,~) obj.recordblacklist(Infopanel,'SPK'));
                DataPanel=NeuroPlot.figurecontrol();
                DataPanel=DataPanel.create([],'SPKdatapanel',strcat('raster'));
                DataPanel.figpanel.Title='Raster Spikes';
               case 'EVTinfo'
                 Infopanel=NeuroPlot.selectpanel;
                blacklist=obj.EVTinfo.blackevt;
                 switch obj.EVTinfo.timetype
                     case 'timepoint'
                         Eventlist=num2cell(obj.EVTinfo.eventselect);
                         Eventlist=cellfun(@(x) num2str(x),Eventlist,'UniformOutput',0);
                         Eventdescription=obj.EVTinfo.description; % how to transfer different eventtypes??
                         Infopanel=Infopanel.create([],'EventIndex',Eventlist,'typestring',Eventdescription,'blacklist',blacklist);
                     case 'timeduration'
                         Eventlist=num2cell(obj.EVTinfo.eventselect);
                         Eventlist=cellfun(@(x,y) strcat(num2str(x),'_',num2str(y)),Eventlist(:,1),Eventlist(:,2),'UniformOutput',0);
                         for i=1:size(obj.EVTinfo.description,1)
                            Eventdescription{i}=cell2mat(obj.EVTinfo.description(i,:));
                         end
                         Infopanel=Infopanel.create([],'EventIndex',Eventlist,'typestring',Eventdescription,'blacklist',blacklist,'multiselect','off');
                 end
                addlistener(Infopanel,'blacklist','PostSet',@(~,~) obj.recordblacklist(Infopanel,'EVT'));
            end
        end
        function [LFPdatatmp,lfpt]=readlfp(obj,EVTindex,Channelindex)
            % read the data from NeuroResult object in given event index and channel index
            % LFPdatatmp is the cell {event}(time*channel)
            % lfpt is numeric for timepoint mode or cell for timeduration mode
            % defined the Timeindex for single Event in scroll plot
            try
                  currenttime=findobj('Tag','currenttime');
                  currentrange=findobj('Tag','timerange');
                  currenttime=str2num(currenttime.String);
                  currentrange=str2num(currentrange.String);
                  lfpt=linspace(obj.EVTinfo.time(EVTindex,1),obj.EVTinfo.time(EVTindex,2),round((obj.EVTinfo.time(EVTindex,2)-obj.EVTinfo.time(EVTindex,1))*obj.LFPinfo.Fs)+1);
                  [~,index1]=min(abs(lfpt-(currenttime+currentrange(1))));
                  [~,index2]=min(abs(lfpt-(currenttime+currentrange(2))));
                  Timeindex=false(size(lfpt));
                  Timeindex(index1:index2)=true;
            catch
                lfpt=[];
                timerange=obj.EVTinfo.time(EVTindex,:);
                Timeindex=-1;
                for i=1:size(timerange,1)
                    lfpt{i}=linspace(timerange(i,1),timerange(i,2),round((timerange(i,2)-timerange(i,1))*obj.LFPinfo.Fs+1));
                end
            end
            if strcmp(class(obj.LFPdata),'char')||strcmp(class(obj.LFPdata),'string') % for h5 file
                  LFPdatatmp=obj.Loadh5(obj.LFPdata,'/event/time*channel','',{EVTindex},{Timeindex,Channelindex});
            else % for matfile
                 LFPdatatmp=obj.Loadmat('LFPdata',{EVTindex},{Timeindex,Channelindex});
            end
            if strcmp(obj.EVTinfo.timetype,'timepoint')
                lfpt=linspace(obj.EVTinfo.timerange(1),obj.EVTinfo.timerange(2),(obj.EVTinfo.timerange(2)-obj.EVTinfo.timerange(1))*obj.LFPinfo.Fs+1);
            end
        end
        function [SPKdatatmp,spkt]=readspk(obj,EVTindex,Spikeindex)
            if strcmp(class(obj.SPKdata),'char')||strcmp(class(obj.SPKdata),'string') % for h5 file.
                SPKdatatmp=obj.Loadh5(obj.SPKdata,'/spike/event/time','',{Spikeindex,EVTindex},{-1,-1});
            else
                SPKdatatmp=obj.Loadmat('SPKdata',{Spikeindex,EVTindex},{-1,-1});
            end
            spkt=obj.EVTinfo.time(EVTindex,:);
            spkt=mat2cell(spkt,ones(size(spkt,1),1));
            if strcmp(obj.EVTinfo.timetype,'timepoint')
                for i=1:size(SPKdatatmp,1)
                    for j=1:size(SPKdatatmp,2)
                        try
                            SPKdatatmp{i,j}=SPKdatatmp{i,j}-spkt{j}(1)+obj.EVTinfo.timerange(1);
                        end
                        
                    end
                end
                spkt=spkt{1,1}-spkt{1,1}(1)+obj.EVTinfo.timerange(1);
            end
        end
        function plot(obj,typename,PanelManagement)
             % plot the LFPdata, SPKinfo and CALinfo
             EVTinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'EVTinfo'));
             EVTindex=EVTinfo.getIndex;
             switch typename
                 case 'LFPData'
                     LFPinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'LFPinfo'));
                     Channelindex=LFPinfo.getIndex;
                     [LFPdatatmp,lfpt]=obj.readlfp(EVTindex,Channelindex);
                     % for duration, only one event trial could be select
                     if iscell(lfpt)
                         lfpt=lfpt{1};
                         LFPdatatmp=LFPdatatmp{1};
                     end                     
                     % transfer LFPdata(cell) to matrix
                     if iscell(LFPdatatmp)
                        LFPdatatmp=reshape(cell2mat(LFPdatatmp),size(LFPdatatmp{1},1),size(LFPdatatmp{1},2),[]);
                     end
                     % for ERP need detrend before plot and average.
                     LFPdatatmp=detrend(LFPdatatmp);
                     obj.LFPdataplot=LFPdatatmp;
                     obj.t_lfpplot=lfpt; % set it observable;
                     obj.channelindexplot=Channelindex;
                     PanelManagement.Panel(ismember(PanelManagement.Type,'LFPData')).plot(lfpt,LFPdatatmp);
                 case 'SPKData'
                     SPKinfo=PanelManagement.Panel(ismember(PanelManagement.Type,'SPKinfo'));
                     SPKindex=SPKinfo.getIndex;
                     [SPKdatatmp,spkt]=obj.readspk(EVTindex,SPKindex);
                     obj.SPKdataplot=SPKdatatmp;% set it observable;
                     if iscell(spkt)
                         spkt=spkt{1};
                     end
                     obj.t_spkplot=spkt; % set it observable;
                     PanelManagement.Panel(ismember(PanelManagement.Type,'SPKData')).plot(spkt,SPKdatatmp,'black');
             end 
        end
        function obj=AverageSubject(obj,averagetype,averageparams)
            % select the given condition and average within subjects from each neuroresults
            % averagetype 
            dataoutput=NeuroResult();
            for i=1:numel(obj)
                for j=1:length(averagetype)
                if contains(averagetype{j}, {'LFPData'})
                    tic;
                        obj(i)=eval(['obj(i).Average',averagetype{j},'(averageparams{j});']);
                    toc;
                elseif contains(averagetype{j},NeuroMethod.List)
                        tmpdata=eval(['obj(i).',averagetype{j},';']);
                        tic;
                        eval(['obj(i).',averagetype{j},'=tmpdata.AverageSubject(obj(i),averageparams{j});']);
                        toc;
                end
                end
            end
        end
        function obj=AverageLFPData(obj,averageparams)
            % the LFPdata (ERP type) would be averaged according channel, event dimension for each subject.
               if ~isempty(obj.LFPinfo.blackchannel)
                    blackchannel=obj.LFPinfo.blackchannel;
                    if ~isequal(size(blackchannel),size(obj.LFPinfo.channeldescription))
                        blackchannel=blackchannel';
                    end
               else
                    blackchannel=false(size(obj.LFPinfo.channeldescription));
               end
                if ~isempty(obj.EVTinfo.blackevt) 
                      blackevt=obj.EVTinfo.blackevt;
                    if ~isequal(size(blackevt),size(obj.EVTinfo.description))
                        blackevt=blackevt';
                    end
                else
                    blackevt=false(size(obj.EVTinfo.description));
                end
                channelname=averageparams.Channel;
                eventname=averageparams.Event;
                baselinetime=averageparams.Baseline;
                baselinecorrectmode=averageparams.Correctmode;
                if ischar(obj.LFPdata)||isstring(obj.LFPdata)
                    [LFPdata,lfpt]=obj.readlfp(true(length(blackevt),1),true(length(blackchannel),1));
                else
                    LFPdata=obj.LFPdata;
                    lfpt=obj.LFPinfo.time;
                end
                obj.LFPinfo.averageparams=averageparams;
                % LFPdata is the {event}(time*channel).
                % note that for average subject, the dimension of each event
                % should be equal, thus transfer it to time*channel*event;
                LFPdata=reshape(cell2mat(LFPdata),size(LFPdata{1},1),size(LFPdata{1},2),[]);
                if averageparams.AverageBeforeCorrection
                if ~isempty(baselinetime)
                    LFPdata=basecorrect(LFPdata,lfpt,baselinetime(1),baselinetime(2),baselinecorrectmode);
                end
                end
                if ischar(eventname)&&strcmp(lower(eventname),'all')
                    LFPdata=mean(LFPdata(:,:,~blackevt),3);
                elseif ischar(eventname)&&strcmp(lower(eventname),'none')
                    LFPdata=LFPdata(:,:,~blackevt);
                else
                    if ischar(eventname)&&strcmp(lower(eventname),'separate')
                        eventname=unique(obj.EVTinfo.description);
                    end
                    tmpS=[];
                    for j=1:length(eventname)
                        if islogical(eventname{j})
                            assert(all(size(eventname{j})==size(blackevt)));
                            tmpS(:,:,j)=mean(LFPdata(:,:,eventname{j}&~blackevt),3);
                        else
                            tmpS(:,:,j)=mean(LFPdata(:,:,ismember(obj.EVTinfo.description,eventname{j})&~blackevt),3);
                        end
                    end
                    LFPdata=tmpS;
                end
                if ~averageparams.AverageBeforeCorrection
                if ~isempty(baselinetime)
                    LFPdata=basecorrect(LFPdata,lfpt,baselinetime(1),baselinetime(2),baselinecorrectmode);
                end
                end
                if ischar(channelname)&&strcmp(lower(channelname), 'all') 
                    LFPdata=mean(LFPdata(:,~blackchannel,:),2);
                elseif ischar(channelname)&&strcmp(lower(channelname),'none')
                    LFPdata=LFPdata(:,~blackchannel,:);
                else
                    if ischar(channelname)&&strcmp(lower(channelname),'separate')
                         channelname=unique(obj.LFPinfo.channeldescription);
                    end
                    tmpS=[];
                    for j=1:length(channelname)
                        if islogical(channelname{j})
                            assert(all(size(channelname{j})==size(blackchannel)));
                            tmpS(:,j,:)=mean(LFPdata(:,channelname{j}&~blackchannel,:),2);
                        else
                            tmpS(:,j,:)=mean(LFPdata(:,ismember(obj.LFPinfo.channeldescription,channelname{j})&~blackchannel,:),2);
                        end
                    end
                    LFPdata=tmpS;
                end
                
                obj.LFPdata=LFPdata;
            end
        function obj=AverageCALData(obj,averageparams)
            % on working
        end
        function bool = check(obj)
             bool=~isempty(obj.fileTag);
        end
         function obj=slice(obj,varargin)
             % Load the the selective NeuroResult with given channelindex, spkindex or eventindex of NeuroResult
             % after slice, the raw data from h5 format will also be read in the memory.
             p=inputParser();
             if isprop(obj,'LFPdata')
                 if size(obj.LFPinfo.blackchannel,2)>2
                     obj.LFPinfo.blackchannel=obj.LFPinfo.blackchannel';
                 end
                 addParameter(p,'Channelindex',~obj.LFPinfo.blackchannel,@islogical);
             end
             addParameter(p,'EVTindex',~obj.EVTinfo.blackevt,@islogical);
             %addParameter(p,'EVTindex',[]);
             addParameter(p,'Timeindex',[]);% only for time duration scroll
             if isprop(obj,'SPKdata')
                addParameter(p,'SPKindex',~obj.SPKinfo.blackspk,@islogical);
             end
             parse(p,varargin{:});
             
             if isprop(obj,'LFPdata')
                if isempty(p.Results.EVTindex) % for old version
                    EVTindex=~false(size(obj.EVTinfo.time,1),1);
                    obj.EVTinfo.blackevt=~EVTindex;

                else % some bug?
                    EVTindex=p.Results.EVTindex&~obj.EVTinfo.blackevt;
                    if size(p.Results.EVTindex,2)>1
                        obj.EVTinfo.blackevt=~p.Results.EVTindex(:,1);
                        EVTindex=EVTindex(:,1);
                    end
                end
                if isempty(p.Results.Channelindex)
                Channelindex=~false(size(obj.LFPinfo.channeldescription,1),1);
                obj.LFPinfo.blackchannel=~Channelindex;
                else
                    Channelindex=p.Results.Channelindex&~obj.LFPinfo.blackchannel;
                end
                 obj.LFPdata=obj.readlfp(EVTindex,Channelindex);
                 obj.LFPinfo.blackchannel=obj.LFPinfo.blackchannel(Channelindex);
                 obj.LFPinfo.channeldescription=obj.LFPinfo.channeldescription(Channelindex);
                 obj.LFPinfo.channelselect=obj.LFPinfo.channelselect(Channelindex);
             end
             if isprop(obj,'SPKdata')
                if isempty(p.Results.SPKindex)
                    SPKindex=~false(size(obj.SPKinfo.spikename,1),1);
                    obj.SPKinfo.blackspk=~SPKindex;
                else
                    SPKindex=p.Results.SPKindex;
                end
                 if isempty(p.Results.EVTindex) % for old version
                    EVTindex=~false(size(obj.EVTinfo.time,1),1);
                    obj.EVTinfo.blackevt=~EVTindex;
                 else
                     EVTindex=p.Results.EVTindex;
                 end
                 obj.SPKdata=obj.readspk(EVTindex,SPKindex);
                 obj.SPKinfo.blackspk=obj.SPKinfo.blackspk(SPKindex);
             end
             EVTinfo=obj.EVTinfo;
             %EVTinfo.time','EVTinfo.description','EVTinfo.eventselect',
             EVTinfo.time=EVTinfo.time(EVTindex,:);
             EVTinfo.description=EVTinfo.description(EVTindex,:);
             EVTinfo.eventselect=EVTinfo.eventselect(EVTindex,:);
             EVTinfo.blackevt=EVTinfo.blackevt(EVTindex);
             obj.EVTinfo=EVTinfo;
             methodlist=NeuroMethod.List();
             for i=1:length(methodlist)
                 if isprop(obj,methodlist{i})
                     eval(['obj.',methodlist{i},'=obj.',methodlist{i},'.slice(obj,varargin{:});']);
                 end
             end
         end
         function data=get(obj,varname)
             % get the protected properties
             data=eval(['obj.',varname,';']);
         end
    end         

    methods(Static)
        function obj = readNeuroResult(data)
            % generate the detail Result from the given path or file from .mat file name or file path for h5 formation.
            % the raw data would not be read in the memory if the path is h5 formation.
            % to read the raw data in the memory, add obj=slice(obj)
            if ischar(data)||isstring(data)
                    if isfolder(data)% h5file directory
                        %data=matfile(fullfile(data,'Datainfo.mat'),'Writable',true);
                        data=yaml.loadFile(fullfile(data,'Datainfo.yaml'),'ConvertToArray',true);
                    else % matfile format
                        data=matfile(data,'Writable',true);
                    end
            end
                    obj=NeuroResult(data);
        end
         function adjustNewPath(path)
             % change the data path variables within the Datainfo.mat for hdf5 format of NeuroResult object
             %Datainfo=matfile(fullfile(path,'Datainfo.mat'),'Writable',true);
             Datainfo=yaml.loadFile(fullfile(path,'Datainfo.yaml'),'ConvertToArray',true);
             varname=fieldnames(Datainfo);
             varlist={'LFPdata','SPKdata','CALdata'};
             vartype='Spectrogram';
             for i=1:length(varname)
                 try 
                     x=eval(['Datainfo.',varname{i}]);
                     if (isstring(x)||ischar(x))&& ismember(varname{i},varlist)
                         eval(['Datainfo.',varname{i},'=char(fullfile(path,"',varname{i},'.h5"));']);
                     elseif strcmp(class(x),vartype)
                         x.filename=fullfile(path,[varname{i},'.h5']);
                          eval(['Datainfo.',varname{i},'=x;']);
                     end
                 end
             end
             yaml.dumpFile(fullfile(path,'Datainfo.yaml'),Datainfo);
         end
        
end
    methods(Access=private)
        function obj=recordblacklist(obj,Infopanel,recordtype)
            global currentresult
            switch recordtype
                case 'EVT'
                    obj.EVTinfo.blackevt=Infopanel.blacklist;
                    currentresult.EVTinfo=obj.EVTinfo;
                case 'LFP'
                    obj.LFPinfo.blackchannel=Infopanel.blacklist;
                    currentresult.LFPinfo=obj.LFPinfo;
                case 'SPK'
                    obj.SPKinfo.blackspk=Infopanel.blacklist;
                    currentresult.SPKinfo=obj.SPKinfo;
            end
        end
        function segs = segmentIndices(obj,idx)
            % 将连续下标分组
            if isempty(idx)
                segs = {};
                return;
            end
            segs = {};
            start = idx(1);
            for i = 2:length(idx)
                if idx(i) ~= idx(i-1) + 1
                    segs{end+1} = start:idx(i-1);
                    start = idx(i);
                end
            end
            segs{end+1} = start:idx(end);
        end
    end
end
