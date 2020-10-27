classdef NeuroData < BasicTag
    %% 
    properties (Access='public')
        Datapath=[];
        LFPdata=[];
%         Videodata
        SPKdata=[];
        EVTdata=[];
        fileTag=[];
        ChannelTag=[];
    end
    methods (Access='public')
        function obj = fileappend(obj, filepath)
            obj.Datapath=filepath;
            cd(filepath);
            filename=struct2table(dir(filepath));
            filetype={'.lfp','.evt','.clu.'};
            Classtype={'LFPdata','EVTdata','SPKdata'};
            Vartype={'LFPData','EVTData','SPKData'};
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
                        if ispc
                         index2=contains(datafilename,[filepath,'\',filename.name{index(i)}]);
                        else
                         index2=contains(datafilename,[filepath,'/',filename.name{index(i)}]);
                        end
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
            [timestart, timestop,eventdescription]=obj.EVTdata.LoadEVT(DetailsAnalysis);
            switch DataType
                case 'LFP' 
                    dataoutput=obj.LFPdata.ReadLFP(channelselect,timestart,timestop);
                    dataoutput.channeldescription=channeldescription;
                case 'SPKtime'    
                    dataoutput=obj.SPKdata.ReadSPK(channelselect,channeldescription,timestart,timestop,'time');
                case 'SPKwave' 
                    dataoutput=obj.SPKdata.ReadSPK(channelselect,channeldescription,timestart,timestop,'wave');
            end
            dataoutput.eventdescription=eventdescription;
        end
    end
end
