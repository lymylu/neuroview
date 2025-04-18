% sample script for data analysis using neuroview
% generate the NeuroData object for beginning.
load('/media/huli/My Book/RJ/Timecoding/information.mat','objmatrix');

% the NeuroData objmatrix contains several LFPdata (with different
% preprocess method,like filter, interpolation, period silence...),
% SPKdata(with different sorting method) and EVTdata （the modified event, new event generation...）
% select given LFPdata, SPKdata and EVTdata files to generate the extracted
% NeuroResult object
%%
% % % % % % % % % Spectrogram analysis method % % % % % %
extractdata=objmatrix.ExtractData('LFPdata',1,'EVTdata',1); % using the first LFPdata file and first EVTdata file.
% not that no channel or event was defined, here extract the whole channel and time of the LFPdata.

% you can define the channel and event information using
extractdata2=NeuroMethod.getParams(extractdata);
% before read the data. 

% Read data from the neurodata extractdata to generate the NeuroResult object for further analysis.
neuroresult=extractdata2.ReadData();  % or extractdata2.ReadData(neuroresult) to read the data from an exist NeuroResult object.

% to apply the analysis method, just using
% params=[AnalysisMethod].getParams and Analysis.cal(params,neuroresult,resultname)

params=Spectrogram.getParams;
neuroresult=Spectrogram.cal(params,neuroresult,'Spectrogram1');

% you can change the params and get another calculation as Spectrogram 2
params2=Spectrogram.getParams;
neuroresult=Spectrogram.cal(params2,neuroresult,'Spectrogram2');

% to save the calculation using neuroresult.Savedata(savepath,savefilename,format,varname)
neuroresult.SaveData('.','sample_data','hdf5','sample');

% to plot the result, use NeuroPlot.NeuroPlot
figure;
fig=NeuroPlot.NeuroPlot();
fig.Plot(gcf,{fullfile('.','sample_data','sample')});
%%
% % % % % % % % % % PerieventHistogram method % % % % % % % % % %
extractdata=objmatrix.Extractdata('SPKdata',1,'EVTdata',1);
extractdata2=NeuroMethod.getParams(extractdata);

