function weights=get_kriging_channel_weights(good_position, bad_position, sigma_um)
% See spikeinterface preprocessing_tools.getkriging_channel_weights
    pyenv(Version="/usr/bin/python3.10") % set the env same as spikeinterface
            try
                 v=py.importlib.import_module('spikeinterface.preprocessing.preprocessing_tools');
            catch
                error('set the python env and spikeinterface');
            end
            weights=v.get_kriging_channel_weights(good_position,bad_position,sigma_um,1.3);
            

end