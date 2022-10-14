%SaveEvents - Write events to file.
%
%  USAGE
%
%    SaveEvents(filename,events)
%
%    filename            event file name
%    events              event data
%
%  SEE
%
%    See also NewEvents, LoadEvents, SaveRippleEvents.

% Copyright (C) 2004-2006 by Michaël Zugaro
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.

function SaveEvents(filename,events,opt)
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

for i = 1:length(events.time)
	fprintf(file,'%f\t%s\n',events.time(i)*1000,events.description{i}); % Convert to milliseconds
end

fclose(file);