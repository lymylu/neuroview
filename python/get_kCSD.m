function Source=get_kCSD(electrodeposition, data, parameters)
% parameters: struct containing KCSD parameters
%   - src_type: basis function type ('gauss', 'step', 'gauss_lim')
%   - sigma: conductivity (S/m)
%   - h: tissue thickness (m)
%   - n_src_init: initial number of sources
%   - R_init: basis function width (mm)
%   - lambd: regularization parameter
%   - ext_x, ext_y: extension in x/y direction (mm)
%   - gdx, gdy: grid density in x/y direction (mm)
%   - dist_table_density: distance table density
%   - xmin, xmax, ymin, ymax: boundaries (mm)
%   - MoI_iters: Method of Images iterations
%   - sigma_S: saline conductivity (S/m)
%   - cross_validate: whether to perform cross validation
%   - l_curve: whether to use L-curve
% See Also kcsd-python
        workpath=fullfile(fileparts(which('neuroview.m')),'python');
        tmpfilename=[tempname,'.mat'];
        tmpfilename=fullfile(workpath,tmpfilename(6:end));
        tmpmat=matfile(tmpfilename,'Writable',true);
        tmpmat.electrodeposition=electrodeposition/1000; % transfer it into mm.
        tmpmat.data=data/1000; % transfer it into mV. 
        %tmpmat.data=data;
        paranames=fieldnames(parameters);
        for i=1:length(paranames)
            paravalues=parameters.(paranames{i});
            if isempty(paravalues)
                continue;
            end
            eval(['tmpmat.',paranames{i},'=paravalues;']);
        end
        try
            system([fullfile(workpath,'/kCSD/bin/python3.9'),' ',fullfile(workpath,'get_kCSD_ai.py'),' ',tmpfilename]) % set the env same as spikeinterface
        catch
            error('set the python env and kcsd toolbox');
        end
        Source.CSD=tmpmat.CSD;
        try
            Source.csd_x=tmpmat.estm_x;
        end
        try
            Source.csd_y=tmpmat.estm_y;
        end
        system(['rm ',tmpfilename]);
end