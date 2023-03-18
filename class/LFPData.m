classdef LFPData < BasicTag 
    properties (Access='public')
        Filename=[];
        Channelnum=[];
        Samplerate=[];
        fileTag=[];
        ADconvert=[];
    end
    methods (Access='public')
         function obj = fileappend(obj)
             [lfppath,path]=uigetfile('*.lfp','Please select the Path of the LFP file(s)','Multiselect','on');
             if ischar(lfppath)
                 lfppath={lfppath};
             end
             for i=1:length(lfppath)
                 tmp=LFPData();
                 tmp.Filename=fullfile(path,lfppath{i});
                 obj(i)=tmp;
             end
         end
         function obj = initialize(obj,Channelnum,Samplerate,ADconvert)
            obj.Channelnum=Channelnum;
            obj.Samplerate=Samplerate;
            obj.ADconvert=ADconvert;
         end
         function obj = Taginfo(obj,Tagname,informationtype, information)
             obj = Taginfo@BasicTag(obj, Tagname,informationtype, information);
         end
         function bool = Tagchoose(obj, Tagname,informationtype, information)
             bool = Tagchoose@BasicTag(obj,Tagname,informationtype,information);
         end          
         function obj = SampleRate(obj, samplerate)
             obj.Samplerate=samplerate;
         end   
         function [informationtype, information]= Tagcontent(obj,Tagname,informationtype)
              if nargin<3
             [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,[]);
              else
                  [informationtype, information]=Tagcontent@BasicTag(obj,Tagname,informationtype);
              end
         end
    end
    methods(Static)
        function obj=Clone(neurodata)
             obj=LFPData();
             obj.Filename=neurodata.Filename;
             obj.Channelnum=neurodata.Channelnum;
             obj.Samplerate=neurodata.Samplerate;
             obj.fileTag=neurodata.fileTag;
             obj.ADconvert=neurodata.ADconvert;
        end
    end
end
