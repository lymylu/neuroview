% Automatic Cellexplorer session initialized
function Cellexplorer_initialized(obj)
basepath=obj.Datapath;
session = sessionTemplate(basepath);
% load the extracelluar information from the xml
session = import_xml2session([],session);
session.extracellular.spikeGroups = session.extracellular.electrodeGroups;
session.spikeSorting{1}.format='Neurosuite';
session.spikeSorting{1}.method='Klustakwik';
session.spikeSorting{1}.manuallyCurated=1;
ProcessCellMetrics('session',session);


