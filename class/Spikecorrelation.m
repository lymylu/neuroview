classdef Spikecorrelation < NeuroMethod
    % caculate the cross- or auto-correlations of spikes using FMAtoolbox
    properties
    end   
    methods
        function obj=getParams(obj)
                prompt={'binSize','duration','smooth',};
                title='ÊäÈë²ÎÊý';
                lines=4;
                def={'0.01','2','0'};
                x=inputdlg(prompt,title,lines,def,'on');
                obj.Params.binSize=str2num(x{1});
                obj.Params.duration=str2num(x{2});
                obj.Params.smooth=str2num(x{3});
                obj.Params.methodname='Spikecorrelation';
        end
        function Spikedata=loadData(obj,objmatrix,DetailsAnalysis)
           Spikedata=loadData@NeuroMethod(obj,objmatrix,DetailsAnalysis,'SPKtime');
        end
        function obj=cal(obj,objmatrix,DetailsAnalysis)
            Spikeoutput=objmatrix.loadData(DetailsAnalysis,'SPKtime');   
            Spike=[];Spikename=[];Channeldescription=[];channelname=[];
            for i=1:length(Spikeoutput.spiketime)
                Spike=cat(1,Spike,Spikeoutput.spiketime{i});
                Spikename=cat(1,Spikename,Spikeoutput.spikename{i});
            end
            Spikenameall=unique(Spikename);
            Spikeid=zeros(1,length(Spike));
            Spikeindex=1:length(Spikename);
            for j=1:length(Spikenameall)
                Spikeid(ismember(Spikename,Spikenameall{j}))=j;
            end
             [ccg,t,tau,c] = CCG(Spike,Spikeid,...
                 'binSize',obj.Params.binSize,'duration',obj.Params.duration,...
                 'smooth',obj.Params.smooth,'mode','ccv');
              obj.Result.CCG=ccg;
              obj.Result.tau=tau;
              obj.Result.C=c;
              obj.Constant.t=t;
              obj.Description.eventdescription=Spikeoutput.eventdescription;
              obj.Description.spikename=Spikenameall;
              obj.Description.channeldescription=Spikedata.channeldescription;
              obj.Description.channelname=Spikedata.channelname;
              obj.methodname='Spikecorrealtion';
        end
        function savematfile=writeData(obj,savematfile,option)
            savematfile=writeData@NeuroMethod(obj,savematfile,option);
        end
    end
end

