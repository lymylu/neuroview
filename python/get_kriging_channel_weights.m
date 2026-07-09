function weights=get_kriging_channel_weights(good_position, bad_position, sigma_um)
% See spikeinterface preprocessing_tools.getkriging_channel_weights

    workpath=fullfile(fileparts(which('neuroview.m')),'python');
    %pyenv(Version=fullfile(workpath,'/kCSD/bin/python3.9'));
    pyenv(Version="/usr/bin/python3") % set the env same as spikeinterface
            try
                 v=py.importlib.import_module('spikeinterface.preprocessing.preprocessing_tools');
            catch
                error('set the python env and spikeinterface');
            end
            n=py.importlib.import_module('numpy');
            good_position=n.array(good_position);
            bad_position=n.array(bad_position);
            if length(double(bad_position.shape))<2
                bad_position=bad_position.reshape(int32(1),int32(-1));
            end
            weights=v.get_kriging_channel_weights(good_position,bad_position,sigma_um,1.3);
            

end