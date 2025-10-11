function [channelindex,channelposition]=LoadChannelinfo(filename)
            % load the prb files contains the channel informations
            try
                 v=py.importlib.import_module('probeinterface');
            catch
                error('set the python env and probeinterface');
            end
            probegroup=v.read_prb(filename);
            probegroup=cell(probegroup.probes);
            channelindex=[];
            channelposition=[];% x y z position
            for i=1:length(probegroup)        
                channelindex=cat(2,channelindex,double(probegroup{i}.device_channel_indices)+1);
                channelposition=cat(1,channelposition,double(probegroup{i}.contact_positions));
            end
            channelindex=channelindex';
end