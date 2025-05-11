% sample script for data analysis using neuroview
% generate the NeuroData object for beginning.
% load the information file info.yaml
c=yaml.loadFile('./sample_data/info.yaml','ConvertToArray',true);
objmatrix=NeuroData(c);
% the NeuroData objmatrix contains several LFPdata (with different
% preprocess method,like filter, interpolation, period silence...),
% SPKdata(with different sorting method) and EVTdata （the modified event, new event generation...）
% select given LFPdata, SPKdata and EVTdata files to generate the extracted
% NeuroResult object
%%
% to general view of LFPdata just
objmatrix.LFPdata.gui_plot([]);

% % % % % % % % % Spectrogram analysis method % % % % % %
extractdata=objmatrix.choose('LFPdata',1,'EVTdata',1);
% using the first LFPdata file and first EVTdata file (if there are many in
% the NeuroData object), alternatively, using type:value also work.
extractdata=objmatrix.choose('LFPdata','LFPdata:raw','EVTdata','EVT:opto');
% for further analysis, only one LFP data and one EVT data must be detected!
% in this tutorial, objmatrix and extractdata are the same.

% you can define the channel and event information using
extractdata2=NeuroMethod.getParams(extractdata); 
% open the interface to select the event and channel of the LFPdata,
% choose the timepoint and -2 to 2 because the event file contains several
% laser stimulus event.
% channel and eventtype could be changed or select all of them.

% Read data from the neurodata extractdata to generate the NeuroResult object for further analysis.
neuroresult=extractdata2.ReadData();  % or extractdata2.ReadData(neuroresult) to read the data from an exist NeuroResult object.
% see neuroresult.LFPdata for the extracted LFP epoches.

% to apply the analysis method, just using
% params=[AnalysisMethod].getParams and Analysis.cal(params,neuroresult,resultname)

params=Spectrogram.getParams;
neuroresult=Spectrogram.cal(params,neuroresult,'Spectrogram1');
% here, the field 'Spectrogram' in neuroresult with the Name 'Spectrogram1' in fileTag is the transformation of
% time-frequency domain of the extract LFP.

% you can change the params and get another calculation as Spectrogram 2
params2=Spectrogram.getParams;
neuroresult=Spectrogram.cal(params2,neuroresult,'Spectrogram2');

% to save the calculation using neuroresult.Savedata(savepath,savefilename,format,varname)
neuroresultnew=neuroresult;
neuroresultnew.SaveData(pwd,'sample_data','hdf5','sample1');
% could be 'matfile' or 'hdf5', better to use the absolute path.
% a hdf5 file was added in 'pwd/sample_data/sample'; note that if dir
% 'pwd/sample_data/sample' is exist, it will be not work to save.
% a matfile was added in 'pwd/sample_data named 'sample.mat'; if .mat is
% exist, it will be not work to save.
% plotting and loading matfile is slow. I suggest to use hdf5 save.
% note that neuroresult were transfered to struct and the data were clear in the Spectrogram and LFPdata when use hdf5 to save

% to plot the result, use NeuroPlot.NeuroPlot
figure;
fig=NeuroPlot.NeuroPlot();
fig.Plot(gcf,{fullfile(pwd,'sample_data','sample')});
% you can select the different events, channels to plot in the gui.
%%
% % % % % % % % % % % PerieventHistogram method % % % % % % % % % %
% extractdata=objmatrix.Extractdata('SPKdata',1,'EVTdata',1);
% extractdata2=NeuroMethod.getParams(extractdata);

