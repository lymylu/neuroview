classdef NeuroStat < dynamicprops
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties (Access='protected')
        Methodname
        NS % NeuroStat main figure
        MainBox
        LeftPanel
        RightPanel
        ResultExportPanel
        ResultSelectPanel
        FigurePanel
        ConditionPanel        
    end
    
    methods
        function obj=setParent(obj,parent)
            obj.NP=parent;
        end
        function obj=Startupfcn(obj)
            global SummaryPath methodname
                methodnamelist={'PowerSpectralDensity','Spectrogram','EventRelatedPotentials','TimeVaringConnectivity','SpikeFieldCoherence','PerieventFiringHistogram','PhaseLocking'};
                index=listdlg('PromptString','Choose the AverageDatatype','ListString',methodnamelist);
                methodname=methodnamelist{index};
                SummaryPath=uigetdir('Input the Save path');
        end
        function obj = GenerateObjects(obj,methodname)
            global ConditionPath Conditiontype SubjectString Subjectindex
            %   generate the NeuroStat GUI in neuroview
              obj.MainBox=uix.HBoxFlex('Parent',obj.NP,'Spacing',4); 
              obj.LeftPanel=uix.VBoxFlex('Parent',obj.MainBox,'Padding',5);
              obj.RightPanel=uix.VBoxFlex('Parent',obj.MainBox,'Padding',5);
              set(obj.MainBox,'Width',[-1,-2]);  
              obj=obj.GenerateSaveResultPanel();
              obj=obj.GenerateConditionpanel;
              obj=obj.GenerateSubjectpanel(methodname);
              obj=obj.GenerateFigurepanel;
              ConditionPath=[];
              Conditiontype=[];
              SubjectString=[];
              Subjectindex=[];
        end
        function obj=GenerateSaveResultPanel(obj)
             obj.ResultExportPanel=uix.Panel('Parent',obj.LeftPanel,'Padding',5,'Title','SaveResult');
             ResultOutputBox=uix.VBox('Parent',obj.ResultExportPanel,'Padding',0);
             uicontrol('Style','pushbutton','Parent',ResultOutputBox,'String','Export SummaryData','Tag','Exportresult','Callback',@(~,~) obj.Resultexportfcn());
             uicontrol('Style','pushbutton','Parent',ResultOutputBox,'String','Export SummaryFigure','Tag','Exportfigure','Callback',@(~,~) obj.Figureexportfcn());
        end
        function obj=GenerateConditionpanel(obj)
            obj.ConditionPanel=uix.Panel('Parent',obj.LeftPanel,'Padding',5,'Title','Condition Select');
            ConditionSelectBox=uix.VBox('Parent',obj.ConditionPanel,'Padding',0);
            uicontrol('Style','pushbutton','Parent',ConditionSelectBox,'String','AddConditionPath','Callback',@(~,~) obj.ConditionSelectfcn());
            uicontrol('Style','pushbutton','Parent',ConditionSelectBox,'String','DeleteConditionPath','Callback',@(~,~) obj.ConditionDeletefcn());
        end
        function obj=GenerateSubjectpanel(obj,methodname)
            global Conditionpanel
            obj.SubjectPanel=uix.Panel('Parent',obj.LeftPanel,'Padding',5,'Title','Subject information');
            SubjectSelectBox=uix.HBox('Parent',obj.SubjectPanel,'Padding',0);
            Conditiontypepanel=uix.VBox('Parent',SubjectSelectBox,'Tag','Conditiontypepanel');
            Conditionpanel=NeuroPlot.selectpanel;
            Conditionpanel=Conditionpanel.create('Parent',Conditiontypepanel,'listtitle',{'SubjectSelect'},'listtag',{'SubjectIndex'},'typeTag',{'Conditiontype'});
        end
        function obj=ConditionSelectfcn(obj)
            global ConditionPath Conditiontype SubjectString Conditionpanel SummaryPath methodname Conditiontypemat
            [f,p]=uigetfile('*.mat','Select the Conditioned resultfilemat!');
            tmpmat=matfile([p,f]);
            ConditionPath=cat(1,ConditionPath,tmpmat);
            type=inputdlg('Name the select resultfilemat');
            if logical(sum(contains(Conditiontype,type)))
                error('the conditioned name has been used, please change another type name!');
            end
            typemat=matfile(fullfile(SummaryPath,[type,'.mat']),'writable',true);
            Conditiontypemat=cat(1,Condtiontypemat,typemat);
            namelist=fieldnames(tmpmat);
            index=cellfun(@(x) ~strcmp(x,'Properties'),namelist,'UniformOutput',1);
            namelist=namelist(index);
            switch methodname
                case {'PowerSpectralDensity','Spectrogram','EventRelatedPotentials','TimeVaringConnectivity'} %% subject mode
                    SubjectString=cat(1,SubjectString,namelist);
                    typemat.SubjectString=namelist;
                    eval(['typemat.',methodname,'=NeuroStat.GetSummarizedData(tmpmat);']);
                    Conditiontype=cat(1,Conditiontype,repmat(type,[length(namelist),1]));
                case {'SpikeFieldCoherence','PerieventFiringHistogram','PhaseLocking'}
                    for i=1:length(namelist)
                        tmp=eval(['getfield(tmpmat.',namelist{i},',''Chooseinfo'')']);
                        spikename=tmp.spikename;
                        spikename=cellfun(@(x) [namelist{i},'.',x],spikename,'UniformOutput',0);
                        SubjectString=cat(1,SubjectString,spikename);
                        typemat.SubjectString=spikename;
                        Conditiontype=cat(1,Conditiontype,repmat(type,[length(spikename),1]));
                        eval(['typemat.',methodname,'=NeuroStat.GetSummarizedData(tmpmat);']);
                    end
            end
            Conditionpanel=Conditionpanel.assign('liststring',SubjectString,'listtag',{'SubjectIndex'},'typetag',{'Conditiontype'},'typestring',Conditiontype,'blacklist',[]);
        end
        function obj=ConditionDeletefcn(obj)
           global Conditiontypemat Conditionpanel Condtiontype SubjectString
           type=unique(Conditiontype);
           index=listdlg('PromptString','Choose the Conditiontype to delete, the summarized files will not be deleted!','ListString',type);
           for i=1:length(Conditiontypemat)
               if strfind(Conditiontypemat(i).Properties.Source,type{index})
                   Conditiontypemat(i)=[];
               end
           end
           index=ismember(Conditiontype,type{index});
           Condtiontype(index)=[];
           SubjectString(index)=[];
           Conditionpanel=Conditionpanel.assign('liststring',SubjectString,'listtag',{'SubjectIndex'},'typetag',{'Conditiontype'},'typestring',Conditiontype,'blacklist',[]);
        end
    end
    methods (Static)
        function Data =GetSummarizedData(datamat)
            global  functionname
            if isempty(functioname)
            Data=NeuroStat.Summarize(datamat,subjectnamelist,[]);
            else
                index=listdlg('PromptString','Select summaryfunctionfile','ListString',functioname);
                Data=NeuroStat.Summarize(datamat,subjectnamelist,functionname{index});
            end
        end
        function Data=Summarize(filemat,summaryfunctionname)
            % summarize multiple subjects data after Averageallda function
            global functionname
            if isempty(summaryfunctionname)
                msgbox('The data should be a matrix (data(maybe several demensions) * subject) after summarizing the multiple subjects data, ...using customized function to get it')
                [f,p]=uigetfile('*.mat','Select the customized functions to summarized the subjects data');
                summaryfunctionname=fullfile(p,f);
                functionname=cat(1,functionname,fullfile(p,f));
                functionname=unique(functioname);
            end
            [summaryfunctionpath,summaryfunction]=fileparts(summaryfunctionname);
            addpath(summaryfunctionpath);
            eval('Data=',summaryfunction,'(filemat);');
        end
    end


end