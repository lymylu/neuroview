classdef VideoData< BasicTag   
    properties
          Filename=[];
          fileTag=[];
          correcttime=[];
          Videoinfo=[];
    end
    properties(GetAccess='private')
        CurrentVideo=[];
        currenttime=[];
    end
    methods
       function obj =  fileappend(obj, filename)
             [videopath,path]=uigetfile('*.avi','Please select the Path of the video file(s)','Multiselect','on');
             if ischar(videopath)
                videopath={videopath};
             end
             for i=1:length(videopath)
                 tmp=VideoData();
                 tmp.Filename=fullfile(path,videopath{i});
                 obj(i)=tmp;
             end
       end   
         function dataoutput=getTaginfo(obj,option,parent)
            dataoutput=getTaginfo@BasicTag(obj,option,parent);
        end
         function data=struct(obj)
             data=struct@BasicTag(obj);
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
       function obj=initialize(obj,correcttime)
            obj.correcttime=correcttime;
       end
       function obj=getTimerange(obj,timestart,timestop)
           % get the videoframes between given timestart and timestop 
           % the timestart timestop is relative to the video, not ephys
           % data.
            try 
                obj.CurrentVideo=mmread(obj.Filename,[],[timestart,timestop]);        
            catch
                Video=VideoReader(obj.Filename);
                Video.Currenttime=timestart;
                i=1;
                while hasFrame(Video)
                    if Video.Currenttime>timestop
                        break;
                    else
                    obj.CurrentVideo.frame(i).cdata=readFrame(Video);
                    obj.CurrentVideo.time(i)=Video.Currenttime;
                        i=i+1;
                    end
                end
            end
       end
        function obj=Showframe(obj,framenum,parent)
            if isempty(parent)
                parent=figure();
            end
            imshow(obj.CurrentVideo.frames(framenum).cdata,'Parent',parent);
            obj.currenttime=obj.CurrentVideo.times(framenum); 
        end   
        function videodata=videosplit(obj,timestart,timestop)
            % epoch data according to [timestart,timestop]
            % the begin time of each epoch will be set at 0s
            % return multiple videodata objects
        end
    end
    methods(Static)
         function obj=VideoData(varargin)
              if nargin==1
             varname=fieldnames(varargin{1});
             data=varargin{1};
             for j=1:length(data)
                 obj(j)=VideoData();
             for i=1:length(varname)
                 eval(['obj(j).',varname{i},'=data(j).',varname{i},';']);
             end
             end
             end
        end
    end
end
