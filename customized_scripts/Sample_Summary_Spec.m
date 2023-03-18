%% Sample of summarizing the Spec data using the Spectrogram.Averagealldata
function [Data,Subjectindex]=Sample_Summary_Spec(datamat) 
%the varargin and varagout are fixed, Data is a matrix of  data * subjects (timepoints * frequency *subjects for Spectrogram)
        lfpt=linspace(-2,4,6001);
        lfpf=linspace(0,100,101);
        namelist=fieldnames(datamat);
        index=cellfun(@(x) ~strcmp(x,'Properties'),namelist,'UniformOutput',1);
        subjectnamelist=namelist(index);
        for i=1:length(subjectnamelist)
            try
            tmp=eval(['datamat.',subjectnamelist{i}]);
            data=getfield(tmp,'Spec'); % the data is a time*channel* event matrix.
            data= basecorrect(data,lfpt,-0.5,0,'Subtract'); % basecorrect at [-0.5,0]
            Data(:,:,i)= squeeze(mean(mean(data,4),2));% reduce the dimensions of channel and event
            Subjectindex{i}=subjectnamelist{i};
            end
        end
end