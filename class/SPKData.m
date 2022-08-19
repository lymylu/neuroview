classdef SPKData< BasicTag
     properties
        SortingType=[];
        Filename=[];
        Samplerate=[];
        fileTag=[];
    end
    methods (Access='public')
        function obj =  fileappend(obj)
            % support the .clu. file from KlustaKwik and .npy file from Phy
            Sortinglist={'KlustaKwik','Phy','Inscopix'};
            index=listdlg('PromptString','choose the SoringType of SPKfile','ListString',Sortinglist);
            obj.SortingType=Sortinglist{index};
            spikepath=uigetdir('Please select the Path of the sorted files');
            obj.Filename=spikepath;
        end
        function obj = initialize(obj, params)
            obj.Samplerate=Samplerate;
        end
        function obj = Taginfo(obj, Tagname,informationtype, information)
            obj = Taginfo@BasicTag(obj,Tagname,informationtype,information);
        end
        function bool = Tagchoose(obj,Tagname, informationtype, information)
             bool = Tagchoose@BasicTag(obj,Tagname,informationtype,information);
         end          
       function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
             [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                  [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
       end    
    end
end