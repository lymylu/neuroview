function neuroview(varargin)
% import the neurodata from the files, and tag the different types of the
% data in the files.
% save the tag information about the files
% manage the root path, choose the tag-related files for the further
% Neuroanalysis module
% Example: neurodatatag('/information.mat');
% Example:
% neurodatatag('./information.mat','SubjectTag',{'Rat','Day'},'SubjectTagValue',{'6,7,8','1d,2d,3d'});
global NV
NV.Neurodatatag=neurodatatag();
NV.Neuroselected=neurodataextract();
p=inputParser;
addOptional(p,'TagPath',[],@isstring);
addParameter(p,'SubjectInfo',[],@iscell);
addParameter(p,'FileInfo',[],@iscell);
addParameter(p,'AnalysisMethod',[],@iscell);
addParameter(p,'OutputPath',[],@isstring);
addParameter(p,'ChannelPosition',[],@iscell);
parse(p,varargin{:});
% % % % GUI generation
NV.MainWindow=figure('menubar','none','numbertitle','off','name','NeuroView Ver 1.0.0','DeleteFcn',@(~,~) DeleteFcn);
NV.TagDefined=uimenu(NV.MainWindow,'Text','&Tag Defined');
NV.DataExtract=uimenu(NV.MainWindow,'Text','&Data Extract');
NV.AnalysisMethod=uimenu(NV.MainWindow,'Text','&Analysis Method');
NV.Plot=uimenu(NV.MainWindow,'Text','&Plot Result');
uimenu('Parent',NV.TagDefined,'Text','Open Tag Defined Panel','MenuSelectedFcn',@(~,~) Neurodatatag_open); % neurodatatag
uimenu('Parent',NV.DataExtract,'Text','Open Data Extract Panel','MenuSelectedFcn',@(~,~) Neuroselected_open); %  neurodataanalysis1&2
methodnamelist=dir([fileparts(which('neuroview.m')),'/methodlist']);
for i=1:length(methodnamelist)
    if ~methodnamelist(i).isdir
        uimenu(NV.AnalysisMethod,'Text',methodnamelist(i).name(1:end-2),'MenuSelectedFcn',@(~,~) Analysis(methodnamelist(i).name(1:end-2)));
    end
end
uimenu('Parent',NV.AnalysisMethod,'Text','CustomMethod', 'MenuSelectedFcn', @(~,~) CustomMethod);
uimenu('Parent',NV.Plot,'Text','Choose the Result Dir to Plot','MenuSelectedFcn', @(~,~) PlotResult); % neurodataanalysis3

% % % %  check the input and excuate the relative GUI.
if isempty(p.Results.TagPath)% GUI neurodatatag;
     Neurodatatag_open;
elseif isempty(p.Results.SubjectInfo)||isempty(p.Results.FileInfo) % GUI neuroselect
     NeuroSelected_open;
elseif isempty(p.Results.AnalysisMethod) % GUI neuroanalysis
     NeuroAnalysis_open;
end
end
% % % % % % % % %
function Neurodatatag_open
global NV
    Neuro_delete;
    NV.Neurodatatag=NV.Neurodatatag.CreateGUI(NV.MainWindow);
    openobj=findobj(NV.TagDefined,'Text','Open Tag Defined Panel');
    delete(openobj);
    uimenu('Parent',NV.TagDefined,'Text','Close Tag Defined Panel','MenuSelectedFcn',@(~,~) Neurodatatag_delete);
    uimenu('Parent',NV.TagDefined,'Text','&Save the Tag information','MenuSelectedFcn',@(~,~) NV.Neurodatatag.SaveTagInfo);
    uimenu('Parent',NV.TagDefined,'Text','&Load the Tag information','MenuSelectedFcn',@(~,~) NV.Neurodatatag.LoadTagInfo);
    uimenu('Parent',NV.TagDefined,'Text','Change the Tag root Dir','MenuSelectedFcn',@(~,~) NV.Neurodatatag.ChangeRoot);
    uimenu('Parent',NV.TagDefined,'Text','Check the Tag File(s)','MenuSelectedFcn',@(~,~) NV.Neurodatatag.CheckTagInfo);
end
function Neurodatatag_delete
    global NV objmatrixpath
            if isempty(objmatrixpath)
                   NV.Neurodatatag.SaveTagInfo;
            end
           closeobj=findobj(NV.TagDefined);
           delete(closeobj(2:end));
           delete(NV.Neurodatatag.mainWindow);
           uimenu('Parent',NV.TagDefined,'Text','Open Tag Defined Panel','MenuSelectedFcn',@(~,~) Neurodatatag_open); 
    % neurodatatag
end
function Neuroselected_open
global NV 
    Neuro_delete;
    NV.Neuroselected=NV.Neuroselected.CreateGUI(NV.MainWindow);
        openobj=findobj(NV.DataExtract,'Text','Open Data Extract Panel');
    delete(openobj);
    uimenu('Parent',NV.DataExtract,'Text','Close Data Extract Panel','MenuSelectedFcn',@(~,~) Neuroselected_delete);
    uimenu('Parent',NV.DataExtract,'Text','Generate the Filtered LFPfile','MenuSelectedFcn',@(~,~) NV.Neuroselected.LFPFilter);
    uimenu('Parent',NV.DataExtract,'Text','Modify the EVTfile','MenuSelectedFcn',@(~,~) NV.Neuroselected.EventModify);
    uimenu('Parent',NV.DataExtract,'Text','Extract the Choosed matrix','MenuSelectedFcn',@(~,~) NV.Neuroselected.DataOutput);
    uimenu('Parent',NV.DataExtract,'Text','Check the Tag File(s)','MenuSelectedFcn',@(~,~) NV.Neuroselected.CheckTagInfo);  
end
function Neuroselected_delete
global NV 
    delete(NV.Neuroselected.mainWindow);
end
function Neuroanalysis_open
global NV choosematrix
try
    Neuro_delete;
end
end
function Neuro_delete
    try
        Neurodatatag_delete;
    end
    try
        Neuroselected_delete;
    end
end
function DeleteFcn
global objmatrix objmatrixpath
    objmatrix=[];
    objmatrixpath=[];
end







