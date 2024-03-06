function neuroview
% import the neurodata from the files, and tag the different types of the
% data in the files.
% save the tag information about the files
% manage the root path, choose the tag-related files for the further
% Neuroanalysis module
global NV
NV.Neurodatatag=neurodatatag();
NV.Neuroselected=neurodataextract();
% % % % GUI generation
NV.MainWindow=figure('menubar','none','numbertitle','off','name','NeuroView Ver 1.3.0','DeleteFcn',@(~,~) DeleteFcn);
NV.TagDefined=uimenu(NV.MainWindow,'Text','&Tag Defined');
NV.DataExtract=uimenu(NV.MainWindow,'Text','&Data Extract');
NV.AnalysisMethod=uimenu(NV.MainWindow,'Text','&Analysis Method');
NV.Plot=uimenu(NV.MainWindow,'Text','&Plot Result');
NV.Stat=uimenu(NV.MainWindow,"Text",'&Summarize Result');
uimenu('Parent',NV.TagDefined,'Text','Open Tag Defined Panel','MenuSelectedFcn',@(~,~) Neurodatatag_open); 
uimenu('Parent',NV.DataExtract,'Text','Open Data Extract Panel','MenuSelectedFcn',@(~,~) Neuroselected_open); 
methodnamelist=dir([fileparts(which('neuroview.m')),'/methodlist']);
for i=1:length(methodnamelist)
    if ~methodnamelist(i).isdir
        uimenu(NV.AnalysisMethod,'Text',methodnamelist(i).name(1:end-2),'MenuSelectedFcn',@(~,~) Analysis(methodnamelist(i).name(1:end-2)));
    end
end
uimenu('Parent',NV.AnalysisMethod,'Text','CustomMethod', 'MenuSelectedFcn', @(~,~) CustomMethod);
uimenu('Parent',NV.Plot,'Text','Choose the Result Dir to Plot','MenuSelectedFcn', @(~,~) PlotResult_open); 
uimenu('Parent',NV.Stat,'Text','Choose the Result Dir to Summarize', 'MenuSelectedFcn',@(~,~) SummarizeResult_open);
% % % %  check the input and excuate the relative GUI.
end
% % % % % % % % %
function Neurodatatag_open
global NV objmatrixpath
    Neuro_delete;
    objmatrixpath=[];
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
    uimenu('Parent',NV.DataExtract,'Text','Calculate the Neuron Properties (Cell Explorer)','MenuSelectedFcn',@(~,~) NV.Neuroselected.FiringProperties);
end
function Neuroselected_delete
global NV choosematrix
    choosematrix=[];
    closeobj=findobj(NV.DataExtract);
    delete(closeobj(2:end));
    delete(NV.Neuroselected.mainWindow);
    uimenu('Parent',NV.DataExtract,'Text','Open Data Extract Panel','MenuSelectedFcn',@(~,~) Neuroselected_open); 
end
function Neuro_delete
    try
        Neurodatatag_delete;
    end
    try
        Neuroselected_delete;
    end
    try
        Neuroanalysis_delete
    end
    try
        PlotResult_delete
    end
end
function DeleteFcn
global objmatrix objmatrixpath
    if isempty(objmatrixpath)
          NV.Neurodatatag.SaveTagInfo;
    end
    objmatrix=[];
    objmatrixpath=[];
end
function Analysis(methodname)
global choosematrix objmatrixpath objindex
    NeuroMethod.CheckValid(methodname);
    if isempty(choosematrix)
        choosematrix=NeuroResult();
        [filelist,path]=uigetfile('Choose the epoched data matrix file','Multiselect','on');
        for i=1:length(filelist)
            choosematrix(i)=NeuroResult(matfile(fullfile(path,filelist{i})));
        end
    else
        NeuroMethod.getParams(choosematrix); 
    end
    params=eval([methodname,'.getParams();']); 
    resultname=inputdlg('name the variable name of this calculation');
    switch questdlg('save the result in each subject dirs or in a new dir?','select dirs','subject dirs','new dir','subject dirs')
        case 'subject dirs'
            savefilepath=[];
        case 'new dir'
            savefilepath=uigetdir('the save path');
    end
    saveformatlist={'matfile','hdf5'};
    saveformat=listdlg("PromptString",'select the saveformat','ListString',saveformatlist);
    saveformat=saveformatlist{saveformat};
    multiWaitbar('Calculating..',0);
    originmatrix=matfile(objmatrixpath,'Writable',true);
    neuromatrix=originmatrix.objmatrix;
    for i=1:length(choosematrix)
          try
            analysis=eval([methodname,'();']);
            result=analysis.cal(params,choosematrix(i),resultname{:});
          if isempty(savefilepath)
           mkdir(fullfile(choosematrix(i).Datapath,'Result'));
           savefilepath1=fullfile(choosematrix(i).Datapath,'Result');
           result.SaveData(savefilepath1,resultname{:},saveformat,[]);% may support the choosen varname in the future;
           tmpneuroresult=NeuroResult();
           tmpneuroresult.fileappend(fullfile(savefilepath1,resultname{:}));
           switch saveformat
               case 'matfile'
                  tmpneuroresult.Taginfo('fileTag',methodname,[resultname{:},'.mat']);
               case 'hdf5'
                   tmpneuroresult.Taginfo('fileTag',methodname,[resultname{:},'.mat']);
           end
           neuromatrix(objindex(i)).Neuroresult=cat(2,neuromatrix(objindex(i)).Neuroresult,tmpneuroresult);
          else
           [~,filename]=fileparts(choosematrix(i).Datapath);
            result.SaveData(savefilepath,filename,saveformat,[]);% may support the choosen varname in the future;
          end
           catch ME
              disp(ME);
          end
           multiWaitbar('Calculating..',i/length(choosematrix));
    end
    originmatrix.objmatrix=neuromatrix;
end
function PlotResult_open
global NV choosematrix
     NV.PlotPanel=uix.Panel('Parent',NV.MainWindow);
     try
     neurodataextract.CheckValid('Neuroresult');
     for i=1:length(choosematrix)
         Filelist{i}=choosematrix(i).Neuroresult.Filename;
     end
     PlotResult(NV.PlotPanel,Filelist,[]);
     catch
        Neuro_delete;
        path=uigetdir('open the results dir');
        FileList=dir(path);
        FileList=struct2table(FileList);
        FileList=FileList.name(3:end);
        parent=figure();
        panel=uix.VBox('Parent',parent);
        plotbutton=uicontrol(panel,'Style','pushbutton','String','choose the file(s) to show and average in the subject level');
        Filelist=uicontrol(panel,'Style','listbox','String',FileList,'Min',0,'Max',3);
        set(plotbutton,'Callback',@(~,~) PlotResult(NV.PlotPanel,Filelist,path));
        set(panel,'Height',[-1,-3]);
        uiwait;
     end
end
function PlotResult(figparent,filelist,path)
        tmpobj=findobj(figparent);
        delete(tmpobj(2:end));
        if ~isempty(path)
        filenamelist=filelist.String(filelist.Value);
        for i=1:length(filenamelist)
                Resultfile{i}=fullfile(path,filenamelist{i});
        end
        uiresume;
        else
            Resultfile=filelist;
        end
        obj=NeuroPlot.NeuroPlot;
        obj.setParent(figparent);
        obj.GenerateObjects(Resultfile);
        obj.Changefilemat(Resultfile);
end
function PlotResult_delete
global NV
    closeobj=findobj(NV.PlotPanel);
    delete(closeobj(2:end));
end
function SummarizeResult_open
% defined the between-subject and within-subject conditions
global NV
    Neuro_delete
    path=uigetdir('open the results dir');
    Filelist=dir(path);
    Filelist=struct2table(Filelist);
    parent=figure();
    panel=uix.VBox('Parent',parent);
    plotbutton=uicontrol(panel,'Style','pushbutton','String','choose the file(s) to show and average in the group level');
    Filelist=uicontrol(panel,'Style','listbox','String',FileList.name(~FileList.isdir),'Min',0,'Max',3);
    NV.PlotPanel=uix.Panel('Parent',NV.MainWindow);
    set(plotbutton,'Callback',@(~,~) SummarizeResult(NV.PlotPanel,Filelist,path))
    set(panel,'Height',[-1,-3]);
    uiwait;
end









