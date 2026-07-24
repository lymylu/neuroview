classdef DatastoreHDF5 < matlab.io.Datastore & matlab.io.datastore.Partitionable
    % 将 ReadH5 方法包装成 Datastore
    % 支持从 HDF5 文件中按节点路径和维度索引懒加载数据
    
    properties
        Filename        % HDF5 文件名 (string)
        ParentNodes     % 节点路径
        Matrixindex % 每个节点的维度索引 cell 数组  
        totalTime 
        CurrentPos = 1  % 当前读取位置
        TotalNodes      % 节点总数
        PreviewData
    end
    
    methods
        function obj = DatastoreHDF5(filename, parentNodes, matrixindex)
            % 构造函数
            %
            % 输入:
            %   filename - HDF5 文件路径
            %   parentNodes - 节点路径，'1/'
            %   matrixindex - 维度索引 cell 数组，如 {-1, 1:64, -1}           
            obj.Filename = filename;
            obj.ParentNodes = parentNodes;
            obj.Matrixindex = matrixindex;
            obj.CurrentPos = 1;
               [~,previewdatasize]=obj.ReadH5(obj.ParentNodes,obj.Matrixindex,'lazy');
            obj.totalTime=previewdatasize(1); % only loading first timeindex
            obj.PreviewData = cell(obj.TotalNodes,1);
        end
        
        function [data, info] = read(obj)
            % 核心读取函数：每次返回一个节点的数据
            %
            % 输出:
            %   data - 当前节点的数据（普通数组）
            %   info - 元数据信息
             data = [];
             info = struct('NodePath', '', 'NodeIndex', 0, 'DataSize', [0, 0]);
            if ~obj.hasdata()
                error('No more data to read.');
            end
                data = obj.ReadH5(obj.ParentNodes,obj.Matrixindex);
                clear h5info;
                clear h5read;
               
                info = struct('DataSize', size(data));

               obj.CurrentPos=[];
        end

        function tf = hasdata(obj)
            % 检查是否还有数据可读
            tf = ~isempty(obj.CurrentPos);
        end
        
        function reset(obj)
            % 重置到起始位置
            obj.CurrentPos = 1;
        end
        function [previewdata,info]=preview(obj)
            [~,previewdatasize]=obj.ReadH5(obj.ParentNodes,obj.Matrixindex,'lazy');
            timeindex=previewdatasize(1); % only loading first timeindex
            Matrixindex=obj.Matrixindex;
            Matrixindex{1}=false(timeindex,1);
            Matrixindex{1}(1)=true;
            previewdata=obj.ReadH5(obj.ParentNodes,Matrixindex);
            info = struct('DataSize', previewdatasize);
        end
         function obj = partition(obj,numPartitions,index)
           %info=h5info(obj.Filename,obj.ParentNodes);
            fprintf('=== partition: index=%d, numPartitions=%d ===\n', index, numPartitions)
            
           %totalTime=info.Dataspace.Size(1);
           timeepoch=ceil(obj.totalTime/numPartitions);
           start=(index-1)*timeepoch+1;
            stop=min(index*timeepoch,obj.totalTime);
            if start>obj.totalTime
                obj.CurrentPos=[];
                return
            end
            timeindex=false(obj.totalTime,1);
            timeindex(start:stop)=true;

            obj.Matrixindex{1}=timeindex;
            obj.CurrentPos=1;
         end
        function [result, resultsize]=ReadH5(obj,nodePath,Matrixindex,option)
            % modified by Deepseek   
            info = h5info(obj.Filename,nodePath);
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
                oneElem = h5read(obj.Filename,nodePath, ones(1, ndimsData), ones(1, ndimsData));
                
                dataClass = class(oneElem);
                % 预分配结果数组
                result = zeros(outDims, dataClass);
                resultsize=size(result);
                if nargin==4 % for preview
                    result=oneElem;
                    return 
                end
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

                    blockData = h5read(obj.Filename, nodePath, start, count);

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
    methods(Access=protected)
        function n = maxpartitions(obj)
           %n=1;     
           n=min(obj.totalTime,8);
        end
    end
end