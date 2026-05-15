function [channelindex,channelposition,channelshank]=LoadChannelinfo(filename)
            % load the prb files contains the channel informations
            workpath=fullfile(fileparts(which('neuroview.m')),'python');
            pyenv(Version=fullfile(workpath,'/kCSD/bin/python3.9'));
            %pyenv(Version='/usr/bin/python3')
            try
                 v=py.importlib.import_module('probeinterface');
            catch
                error('set the python env and probeinterface');
            end
            probegroup=v.read_prb(filename);
            probegroup=cell(probegroup.probes);
            channelindex=[];
            channelposition=[];% x y z position
            channelshank=[];
            for i=1:length(probegroup)        
                channelindex=cat(2,channelindex,double(probegroup{i}.device_channel_indices)+1);
                channelposition=cat(1,channelposition,double(probegroup{i}.contact_positions));
                channelshank=cat(1,channelshank,i*ones(length(double(probegroup{i}.device_channel_indices)),1));
            end
            channelindex=channelindex';
end