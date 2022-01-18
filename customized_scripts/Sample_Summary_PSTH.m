%% Sample of summarizing the PSTH data using the PerieventFiringHistogram.Averagealldata
function [Data,Subjectindex]=Sample_Summary_PSTH(datamat)
        namelist=fieldnames(datamat);
        index=cellfun(@(x) ~strcmp(x,'Properties'),namelist,'UniformOutput',1);
        subjectnamelist=namelist(index);
        for i=1:length(subjectnamelist)
            tmp=eval(['datamat.',subjectnamelist{i}]);
            output=Loaddata(tmp,'binneddata',[]); % for different load type see function Loaddata below;
            output.dataoutput=basecorrect(output.dataoutput,output.spkt,-0.5,0,'Zscore');
            Subjectindextmp=cellfun(@(x,y) [x,'.',y],output.spikesubject,output.spikename,'UniformOutput',0);
            Subjectindex=cat(1,Subjectindex,Subjectindextmp);
            Data=cat(2,Data,output.dataoutput); % could be modified according to the load type (dataoutput maybe a cell)
        end
end
function output=Loaddata(tmp,propname,prop)
dataoutput=[];spikename=[];spikesubject=[];
switch propname
    case 'rawtobin'
        try
        data=getfield(tmp,'rawdata');
        chooseinfo=getfield(tmp,'Chooseinfo');% get the spikename
        for i=1:length(data)
        [binoutput,t]=cellfun(@(x) binspikes(x,1/prop,[-2,4]),data{i},'UniformOutput',0);
        dataoutput=cat(1,dataoutput,{mean(cell2mat(binoutput),2)});
        spikename=cat(1,spikename,chooseinfo.spikename(i));
        spikesubject=cat(1,spikesubject,{name});
        output.spkt=t{1};
        end   
        catch
            dataoutput=cat(1,dataoutput,{});
                spikename=cat(1,spikename,{});
                spikesubject=cat(1,spikesubject,{});
        end
    case 'rawtobin-noaverage'
        try
        data=getfield(tmp,'rawdata');
        chooseinfo=getfield(tmp,'Chooseinfo');% get the spikename
        for i=1:length(data)
        [binoutput,t]=cellfun(@(x) binspikes(x,1/prop,[-2,4]),data{i},'UniformOutput',0);
        dataoutput=cat(1,dataoutput,{cell2mat(binoutput)});
        spikename=cat(1,spikename,chooseinfo.spikename(i));
        spikesubject=cat(1,spikesubject,{name});
        output.spkt=t{1};
        end   
        catch
            dataoutput=cat(1,dataoutput,{});
            spikename=cat(1,spikename,{});
            spikesubject=cat(1,spikesubject,{});
        end
    case 'rawtopsth'
         try
        data=getfield(tmp,'rawdata');
        chooseinfo=getfield(tmp,'Chooseinfo');% get the spikename
        for i=1:length(data)
        [binoutput,spkt]=cal_psth(data{i},prop,'n',[-2,4],1);
            if isempty(binoutput)
            binoutput=nan(1,length(spkt));
            end
            binoutput=binoutput';
            output.spkt=spkt;
        dataoutput=cat(1,dataoutput,{binoutput});
        spikename=cat(1,spikename,chooseinfo.spikename(i));
        spikesubject=cat(1,spikesubject,{name});
        end   
        catch
            dataoutput=cat(1,dataoutput,{});
                spikename=cat(1,spikename,{});
                spikesubject=cat(1,spikesubject,{});
         end
    case 'rawtopsth-noaverage'
        try
        data=getfield(tmp,'rawdata');
        chooseinfo=getfield(tmp,'Chooseinfo');% get the spikename
        for i=1:length(data)
            binoutputall=[];binoutput=[];
            for j=1:size(data{i},2)      
        [binoutputtmp,spkt]=cal_psth(data{i}(j),prop,'n',[-2,4],1);
            if isempty(binoutputtmp)
            binoutputtmp=zeros(1,length(spkt));
            end
            binoutput(:,j)=binoutputtmp';
            end
            binoutputall=binoutput;
            output.spkt=spkt;
        dataoutput=cat(1,dataoutput,{binoutputall});
        spikename=cat(1,spikename,chooseinfo.spikename(i));
        spikesubject=cat(1,spikesubject,{name});
        end   
        catch
            dataoutput=cat(1,dataoutput,{});
                spikename=cat(1,spikename,{});
                spikesubject=cat(1,spikesubject,{});
         end
    case 'binneddata'
          try
            data=getfield(tmp,'binneddata');
            chooseinfo=getfield(tmp,'Chooseinfo');% get the spikename
            for i=1:length(data)
                dataoutput=cat(1,dataoutput,{mean(data{i},2)});
                spikename=cat(1,spikename,chooseinfo.spikename(i));
                spikesubject=cat(1,spikesubject,{name});
            end
          catch
                dataoutput=cat(3,dataoutput,{});
                spikename=cat(1,spikename,{});
                spikesubject=cat(1,spikesubject,{});
          end
          data=single(data);
    case 'rawraster'
        try
        data=getfield(tmp,'rasterdata');
        chooseinfo=getfield(tmp,'Chooseinfo');% get the spikename
        dataoutput=cat(2,dataoutput,cellfun(@(x) sparse(x),data,'UniformOutput',0));
        output.spkt=linspace(-2,4,240001);
        spikename=cat(1,spikename,chooseinfo.spikename(i));
        spikesubject=cat(1,spikesubject,{name}); 
        catch
            dataoutput=cat(1,dataoutput,{});
                spikename=cat(1,spikename,{});
                spikesubject=cat(1,spikesubject,{});
        end
         dataoutput=dataoutput';
    end
        output.dataoutput=dataoutput;
        output.spikename=spikename;
        output.spikesubject=spikesubject;

end