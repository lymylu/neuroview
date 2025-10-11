% sample script for data analysis using neuroview
% generate the NeuroData object for beginning.
% load the information file info.yaml 
% info.yaml could be generate by neuroview.m
c=yaml.loadFile('./sample_data/eyedata/info.yaml','ConvertToArray',true);
objmatrix=NeuroData(c);
% the NeuroData objmatrix contains several LFPdata (with different
% preprocess method,like filter, interpolation, period silence...),
% SPKdata(with different sorting method) and EVTdata （the modified event, new event generation...）
% select given LFPdata, SPKdata and EVTdata files to generate the extracted
% NeuroResult object
%%
% to general view of LFPdata just
figure;
objmatrix.LFPdata.gui_plot(gcf);

% % % % % % % % % Spectrogram analysis method % % % % % %
extractdata=objmatrix.choose('LFPdata',1,'EVTdata',1);
% using the first LFPdata file and first EVTdata file (if there are many in
% the NeuroData object), alternatively, using type:value also work.
%extractdata=objmatrix.choose('LFPdata','LFP:raw','EVTdata','EVT:opto');
% for further analysis, only one LFP data and one EVT data must be detected!
% in this tutorial, objmatrix and extractdata are the same.

% note that the extract data with one eventdata and lfpdata
% also could be general view by:
figure;
extractdata.gui_plot(gcf);
% You can choose specific event to jump to the given time in LFPdata file.


%%%%% method for Spectrogram %%%%%%
% you can define the channel and event information using
extractdata=NeuroMethod.getParams(extractdata); 
% open the interface to select the event and channel of the LFPdata,
% choose the timepoint and -2 to 2 because the event file contains several
% laser stimulus event.
% channel and eventtype could be changed or select all of them.
% or you can just input the varagin like this:
 % extractdata=objmatrix.choose('LFPdata',1,'EVTdata',1);
 % EVTinfo.timetype='timepoint';
 % EVTinfo.timestart=-1;
 % EVTinfo.timestop=2;
 % EVTinfo.selectdescription=cellstr(extractdata.EVTdata.EVTinfo.description);
 % channel={'V1'};
 % extractdata=NeuroMethod.getParams(extractdata,EVTinfo,'channel',channel);
% 

% to apply the analysis method, just using
% params=[AnalysisMethod].getParams and Analysis.cal(params,neuroresult,resultname)

params=Spectrogram.getParams;
neuroresult=Spectrogram.cal(params,extractdata,'Spectrogram1');
% here, the field 'Spectrogram' in neuroresult with the Name 'Spectrogram1' in fileTag is the transformation of
% time-frequency domain of the extract LFP.

% you can change the params and get another calculation as Spectrogram 2
%params2=Spectrogram.getParams;
%neuroresult=Spectrogram.cal(params2,neuroresult,'Spectrogram2');

% to save the calculation using neuroresult.Savedata(savepath,savefilename,format,varname)
neuroresult.SaveData('./sample_data/eyedata/Result','spec','hdf5');
% could be 'matfile' or 'hdf5', better to use the absolute path.
% a hdf5 file was added in './sample_data/eyedata/Result/spec'; note that if the path is exist, it will be not work to save.
% a matfile was added in './sample_data/eyedata/Result' named 'spec.mat'; if .mat is
% exist, it will be not work to save.
% plotting and loading matfile is slow. I suggest to use hdf5 format.
% note that neuroresult were transfered to struct and were clear in the Spectrogram and LFPdata when use hdf5 to save
% to plot the result, use NeuroPlot.NeuroPlot
figure;
fig=NeuroPlot.NeuroPlot();
fig.Plot(gcf,{'./sample_data/eyedata/Result/spec'});
% you can select the different events, channels to plot in the gui and
% manually delete the bad trials/channels

% To average the results use neuroresult.AverageSubject by the given
% averageparams.
Specparams=Spectrogram.getAverageparams('Event','separate','Channel','separate','AverageBeforeCorrection',true,'Baseline',[-1,0],'Correctmode','Changepercent');
LFPparams=LFPData.getAverageparams('Event','separate','Channel','separate','AverageBeforeCorrection',false,'Baseline',[-1,0],'Correctmode','subtract');
% or use the inputdlg to set the average parameters
% Specparams=Spectogram.getAverageparams;
% LFPparams=LFPData.getAverageparams;
neuroresult=neuroresult.AverageSubject({'LFPData','Spectrogram'},{LFPparams,Specparams});
% now neuroresult.LFPdata is time*1*9 matrix, each type of event (9 types with 110 trials) and
% V1 channels (16) were averaged.
% neuroresult.Spectrogram.Spectro is time*101*1*9 matrix
%%
% % % % % % % % % % % PerieventHistogram method % % % % % % % % % %
% similar code for Spectrogram
extractdata = objmatrix.choose('SPKdata',1,'EVTdata',1);
extractdata = NeuroMethod.getParams(extractdata);

params=PerieventFiringHistogram.getParams;
neuroresult=PerieventFiringHistogram.cal(params,extractdata,'PSTH1');
% here, the field 'PerieventHistogram' in neuroresult with the Name 'PSTH1'
% in fileTag is the binspike or gaussian smoothed spike firing function of
% the extract spikes.
% save the calculation
neuroresult.SaveData('./sample_data/eyedata/Result','PSTH','matfile');
% plot the neuroresult.
figure;
fig=NeuroPlot.NeuroPlot();
fig.Plot(gcf,{'./sample_data/eyedata/Result/PSTH.mat'});



