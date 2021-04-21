classdef VideoData < BasicTag
    %UNTITLED �˴���ʾ�йش����ժҪ
    %   �˴���ʾ��ϸ˵��
    
    properties
          Filename=[];
          fileTag=[];
          correcttime=[];
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
                 objmatrix(i)=tmp;
             end
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
             % ��Video��ʼ����ʱ�����ڼ�¼ϵͳ�ϵ�ʱ�䡣���Ϊ��������Video�����ڼ�¼֮ǰ�����Ϊ��������Video�����ڼ�¼֮��
            obj.correcttime=correcttime;
       end
           function Videoobj=ReadVideo(obj)
            Videoobj.video=VideoReader(obj.filename);
       end
    end
end

