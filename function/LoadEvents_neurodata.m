% Load Events from legendary version (for neurosuite, contains time and description)
% and for neuroview 

function events = LoadEvents_neurodata(filename)


if ~exist(filename),
	error(['File ''' filename ''' not found.']);
end

file = fopen(filename,'r');
if file == -1,
	error(['Cannot read ' filename ' (insufficient access rights?).']);
end
 line = fgetl(file);
 headerdescription=regexp(line,'\s','split');
 
 if strcmp(headerdescription{1},'time') % neuroview version
    for c=1:length(headerdescription)-1
     eval(['events.',headerdescription{c},'=[];']);
    end
    while ~feof(file)
        line=fgetl(file);
        start=regexp(line,'\s','split');
        for c=1:length(start)-1
        eval(['events.',headerdescription{c},'{end+1,1}=start{c};']);
        end
    end
    events.time=cellfun(@(x) str2num(x),events.time,'UniformOutput',1);
 else
    events.time = [];
    events.description = [];
    events.time(end+1,1)=str2num(headerdescription{1});
    events.description{end+1,1}=headerdescription{2};
    while ~feof(file),        
        time = fscanf(file,'%f',1);
        events.time(end+1,1) = time;
        line = fgetl(file);
         start = regexp(line,'[^\s]','once');
        events.description{end+1,1} = sscanf(line(start:end),'%c');
    end
 end
fclose(file);

% Convert to seconds
if ~isempty(events.time), events.time(:,1) = events.time(:,1) / 1000; end

