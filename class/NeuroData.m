classdef NeuroData < BasicTag
    %% 
    properties (Access='public')
        Datapath=[];
        LFPdata=[];
%         Videodata
        SPKdata=[];
        EVTdata=[];
        Videodata=[];
        fileTag=[];
        ChannelTag=[];
    end
    methods (Access='public')
        function obj = fileappend(obj, filepath)
            obj.Datapath=filepath;
            cd(filepath);
            filename=struct2table(dir(filepath));
            filetype={'.lfp','.evt','.clu.','.avi'};
            Classtype={'LFPdata','EVTdata','SPKdata','Videodata'};
            Vartype={'LFPData','EVTData','SPKData','VideoData'};
            for ftype=1:length(filetype)
                index=cell2mat(cellfun(@(x) ~isempty(regexpi(x,['(?:\',filetype{ftype},')'],'match')),filename.name,'UniformOutput',0));
                index=find(index==1);
                datafilename=[];
                if ~isempty(eval(['obj.',Classtype{ftype}]))
                    for i=1:length(eval(['obj.',Classtype{ftype}]))
                        datafilename{i}=eval(['obj.',Classtype{ftype},'(i).Filename']);
                    end
                end
                for i=1:length(index)
                    if ~isempty(datafilename)
                         index2=contains(datafilename,fullfile(filepath,filename.name{index(i)}));
                    else
                        index2=0;
                    end
                    if sum(index2)==0
                    tmpdata=eval([Vartype{ftype},'()']);
                    if ispc
                        eval(['obj.',Classtype{ftype},'=horzcat(obj.',Classtype{ftype},',tmpdata.fileappend([filepath,''\'',filename.name{index(i)}]))']);
                    else
                        eval(['obj.',Classtype{ftype},'=horzcat(obj.',Classtype{ftype},',tmpdata.fileappend([filepath,''/'',filename.name{index(i)}]))']);
                    end
                    end
                end
            end
            subdir=filename.name(filename.isdir);
            subdir(1:2)=[];
            if ~isempty(subdir)
                msgbox('find the sub directory from the main directory, the files in the sub directory were also included!')
                for dirindex=1:length(subdir)
                    subfilename=struct2table(dir(subdir{dirindex}));
                    for ftype=1:length(filetype)
                    index=cell2mat(cellfun(@(x) ~isempty(regexpi(x,['(?:\',filetype{ftype},')'],'match')),subfilename.name,'UniformOutput',0));
                    index=find(index==1);
                    datafilename=[];
                    if ~isempty(eval(['obj.',Classtype{ftype}]))
                        for i=1:length(eval(['obj.',Classtype{ftype}]))
                            datafilename{i}=eval(['obj.',Classtype{ftype},'(i).Filename']);
                        end
                    end
                    for i=1:length(index)
                        if ~isempty(datafilename)
                             index2=contains(datafilename,fullfile(filepath,subdir{dirindex},subfilename.name{index(i)}));
                        else
                            index2=0;
                        end
                        if sum(index2)==0
                            tmpdata=eval([Vartype{ftype},'()']);
                            eval(['obj.',Classtype{ftype},'=horzcat(obj.',Classtype{ftype},',tmpdata.fileappend(fullfile(filepath,subdir{dirindex},subfilename.name{index(i)})));']);
                        end
                    end
                    end
                end
            end
            %index=cell2mat(cellfun(@(x) ~isempty(regexpi(x,'(?:\.avi)','match'))),filename.name,'UniformOutput',0)));
%         obj.Videodata=cellfun(@(x) VideoData(x), filename.name(index),'UniformOutput',0);
            
        end
        function obj = Taginfo(obj, Tagname, informationtype, information)
            obj=Taginfo@BasicTag(obj,Tagname,informationtype,information);
        end
        function bool = Tagchoose(obj,Tagname,informationtype, information)
            bool=Tagchoose@BasicTag(obj,Tagname,informationtype,information);
        end
        function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
             [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                  [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
          end
        function [chselect, channeldescription] = Channelchoose(obj, informationtype)
             chselect=eval(['obj.ChannelTag.',informationtype]);
             chselect=str2num(chselect);
             channeldescription=repmat({informationtype},[length(chselect),1]);
         end
        function dataoutput=loadData(obj,DetailsAnalysis,DataType)
            %% load the LFP or SPK data from the determined events
            Channel=cellfun(@(x) contains(x,'ChannelTag:'),DetailsAnalysis,'UniformOutput',1);
            Channel=strrep(DetailsAnalysis{Channel},'ChannelTag:','');
            Channel=regexpi(Channel,',','split');
            channeldescription=[];channelselect=[];
            for i=1:length(Channel)
                [channelselecttmp,channeldescriptiontmp]=obj.Channelchoose(Channel{i}); 
                channelselect=cat(2,channelselect,channelselecttmp);
                channeldescription=cat(1,channeldescription,channeldescriptiontmp);
            end
            [timestart, timestop,eventdescription,eventselect]=obj.EVTdata.LoadEVT(DetailsAnalysis);
            switch DataType
                case 'LFP' 
                    dataoutput=obj.LFPdata.ReadLFP(channelselect,timestart,timestop);
                    dataoutput.channeldescription=channeldescription;
                    dataoutput.channelselect=channelselect;
                case 'SPKtime'    
                    dataoutput=obj.SPKdata.ReadSPK(channelselect,channeldescription,timestart,timestop,'time');
                case 'SPKwave' 
                    dataoutput=obj.SPKdata.ReadSPK(channelselect,channeldescription,timestart,timestop,'wave');
                case 'SPKsingle'
                    dataoutput=obj.SPKdata.ReadSPK(channelselect,channeldescription,timestart,timestop,'single');
            end
             dataoutput.eventdescription=eventdescription;
             dataoutput.eventselect=eventselect;
        end
    end
end
