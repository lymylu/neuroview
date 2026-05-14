% set python environment for neuroview functions
% need conda
 workpath=fullfile(fileparts(which('neuroview.m')),'python');
 system(['conda env create -f ',fullfile(workpath,'environment.yaml'),' --prefix ',fullfile(workpath,'kCSD')]);