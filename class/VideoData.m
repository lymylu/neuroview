classdef VideoData< BasicTag   
    properties
          Filename=[];
          correcttime=[];
          Videoinfo=[];
    end
    properties(GetAccess='private')
        CurrentVideo=[];
        currenttime=[];
        videoaxes=[];
    end
    methods
       function obj =  fileappend(obj, filename)
             [videopath,path]=uigetfile('*.*','Please select the Path of the video file(s)','Multiselect','on');
             if ischar(videopath)
                videopath={videopath};
             end
             for i=1:length(videopath)
                 tmp=VideoData();
                 tmp.Filename=fullfile(path,videopath{i});
                 obj(i)=tmp;
             end
       end  
        function bool = check(obj)
             bool=~isempty(obj.correcttime);
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
        % function obj=Showframe(obj,framenum,parent)
        %     if isempty(parent)
        %         parent=figure();
        %     end
        %     imshow(obj.CurrentVideo.frames(framenum).cdata,'Parent',parent);
        %     obj.currenttime=obj.CurrentVideo.times(framenum);
        % end
        function videodata=videosplit(obj,timestart,timestop)
            % epoch data according to [timestart,timestop]
            % the begin time of each epoch will be set at 0s
            % return multiple videodata objects
        end
        function hbox=gui_plot(obj,parent)
             % generate gui plot of Videodata files in a BoxPanel 
                hbox = uix.VBox( 'Parent', parent );
                for i=1:length(obj) % for multiple video files within the subject
                % Add three box panels.
                    videocontrol(i)= NeuroPlot.videocontrol();
                    videocontrol(i).create(hbox,strcat('timerangepanel_',obj(i).Filename),obj(i));
                    %addlistener(videocontrol(i),'currenttime','PostSet', @(~,~) obj.getFrame(videocontrol(i)));
                    addlistener(videocontrol(i),'currenttime','PostSet', @(~,~) videocontrol(i).getFrame);
                end
        end
          function obj=getFrame(obj,videocontrol)
            tmpobj=findobj(videocontrol,'Tag','videoshow');
            videocontrol.CurrentVideo.currenttime=videocontrol.currenttime-videocontrol.offset(videocontrol.currentindex);
            frame=videocontrol.CurrentVideo.readFrame;
            if isempty(obj.videoaxes)
            obj.videoaxes=imshow(frame,'Parent',tmpobj);  
            else
            set(obj.videoaxes,'CData',frame);
            end
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
