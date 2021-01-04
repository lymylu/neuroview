classdef VideoData < BasicTag
    %UNTITLED 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
          Filename=[];
          fileTag=[];
          correcttime=[];
    end
    
    methods
       function obj =  fileappend(obj, filename)
            obj.Filename=filename;
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
             % 是Video开始播放时，其在记录系统上的时间。如果为负数，则Video播放在记录之前，如果为正数，则Video播放在记录之后。
            obj.correcttime=correcttime;
       end
           function Videoobj=ReadVideo(obj)
            Videoobj.video=VideoReader(obj.filename);
       end
    end
end

