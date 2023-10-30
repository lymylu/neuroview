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
global choosematrix DetailsAnalysis
    NeuroMethod.CheckValid(methodname);
    if isempty(choosematrix)
        [filelist,path]=uigetfile('Choose the epoched data matrix file','Multiselect','on');
        for i=1:length(filelist)
            choosematrix(i).Datapath=fullfile(path,filelist{i});
        end
        DetailsAnalysis_All=inputdlg('input the variable name(s) of the choosed epoched data, use comma to split multiple names');
        DetailsAnalysis_All=regexpi(DetailsAnalysis_All{:},',','split');
    else
        NeuroMethod.getParams(choosematrix); 
        DetailsAnalysis_All{1}=DetailsAnalysis;
    end
    params=eval([methodname,'.getParams();']); 
    resultname=inputdlg('name the variable name of this calculation');
    savefilepath=uigetdir('the save path');
    saveformatlist={'matfile','hdf5'};
    saveformat=listdlg("PromptString",'select the saveformat','ListString',saveformatlist);
    saveformat=saveformatlist{saveformat};
    multiWaitbar('Calculating..',0);
    for i=1:length(choosematrix)
       for j=1:length(DetailsAnalysis_All)    
           try
           multiWaitbar([choosematrix(i).Datapath,':',DetailsAnalysis_All{j}],0);  
           catch
               multiWaitbar([choosematrix(i).Datapath],0);  
           end
          if length(DetailsAnalysis_All)>1
            mkdir(fullfile(savefilepath,DetailsAnalysis_All{j}));
          end
          try
            analysis=eval([methodname,'();']);
            result=analysis.cal(params,choosematrix(i),DetailsAnalysis_All{j},resultname{:});
          catch ME
              disp(ME);
          end
           [filepath,filename]=fileparts(choosematrix(i).Datapath);
           [~,filename]=fileparts(filepath);
           if length(DetailsAnalysis_All)>1
            mkdir(fullfile(savefilepath,DetailsAnalysis_All{j}));
            savefilepath=fullfile(savefilepath,DetailsAnalysis_All{j});
           end
           result.SaveData(savefilepath,filename,saveformat,[]);% may support the choosen varname in the future;
           try
                multiWaitbar([choosematrix(i).Datapath,':',DetailsAnalysis_All{j}],'close');
           catch
               multiWaitbar([choosematrix(i).Datapath],'close');
           end
       end
       multiWaitbar('Calculating..',i/length(choosematrix));
    end
end
function PlotResult_open
global NV
     Neuro_delete;
     path=uigetdir('open the results dir');
     FileList=dir(path);
     FileList=struct2table(FileList);
     parent=figure();
     panel=uix.VBox('Parent',parent);
     plotbutton=uicontrol(panel,'Style','pushbutton','String','choose the file(s) to show and average in the subject level');
     Filelist=uicontrol(panel,'Style','listbox','String',FileList.name(3:end),'Min',0,'Max',3);
     NV.PlotPanel=uix.Panel('Parent',NV.MainWindow);
     set(plotbutton,'Callback',@(~,~) PlotResult(NV.PlotPanel,Filelist,path))
     set(panel,'Height',[-1,-3]);
     uiwait;
end
function PlotResult(figparent,filelist,path)
        tmpobj=findobj(figparent);
        delete(tmpobj(2:end));
        filenamelist=filelist.String(filelist.Value);
        for i=1:length(filenamelist)
                Resultfile{i}=fullfile(path,filenamelist{i});
        end
        uiresume;
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









