%SaveEvents - Write events to file in legendary version (for neurosuite)
% and neuroview

function SaveEvents_neurodata(filename,events,opt)
if nargin<3;
if exist(filename)
    button=questdlg('File already exists, do you want to create a new file or replace it?','Choose','Create a new file','Replace it!','Create a new file');
    switch button
        case 'Create a new file'
            filename=[filename(1:end-4),'_new.evt'];
        case 'Replace it!'
            delete (filename);
    end;
end;
else
    if opt==1;
        delete(filename);
    end;
end
file = fopen(filename,'w');
if file == -1,
	error(['Cannot write to ' filename]);
end

if prod(contains(fieldnames(events),{'time','description'}))% for neurosuite old version
    for i = 1:length(events.time)
        events.time(i)=round(events.time(i),3);
        fprintf(file,'%d\t%s\n',events.time(i)*1000,events.description{i}); % Convert to milliseconds
    end
else % for neuroview
    head=fieldnames(events);
    for i=1:length(head)
        fprintf(file,'%s\t',head{i});
    end
    fprintf(file,'\n');
    for i=1:length(events.time)
        fprintf(file,'%d\t',events.time(i)*1000);
        for j=2:length(head)
            tmp=eval(['events.',head{j},'{i};']);
            fprintf(file,'%s\t',tmp);
        end
        fprintf(file,'\n');
    end
end
    fclose(file);