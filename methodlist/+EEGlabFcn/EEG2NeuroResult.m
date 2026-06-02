function neuroresult=EEG2NeuroResult(ALLEEG,eventfield)
% transfer ALLEEG (multiple) or EEG struct to NeuroResult object
% only support ERP experiment (each epoch contains only one event)
% if eventfield contains several names, the first name were used for the
% description of the trials, others used for scalr evaluations about the
% trial (e.g., ratings).
% if isempty EEG.subject, EEG.condition and EEG.group,
% convert them into the fileTag as neuroresult.fileTag.subject, condition
% and group.
% only EEG.data, EEG.events (epoched) and EEG.chanlocs were transfered into
% NeuroResults
% NeuroResult.LFPinfo: the information about LFPdata, contains 
% Fs=EEG.srate, 
% Channeldescription,cellmatrix of EEG.chanlocs.labels,
% channelselect=(1:length(Channeldescription),
% blackchannel=false(1,length(Channeldescription),
% time=EEG.times/Fs;
% datatype='splitting';
% NeuroResult.EVTinfo: the information about events, contians
% timetype='timepoint',
% time:  time start and stop of EEG epochs (cumsum EEG.pnts, start from zero);
% timerange: timerange relative to the events
% description: cellmatrix of the selected fieldname of EEG.events  
% eventselect=1:length(description);
% blackevt=false(1,length(description);

% neuroresult=EEG2NeuroResult(ALLEEG,'type'); (EVTinfo.contains description
% with type.
% neuroresult=EEG2NeuroResult(ALLEEG,{'type','rating'}); (EVTinfo contains description and rating)
% the whole toolbox of neuroview is available in www.gitee.com/lymylu/neuroview
if ischar(eventfield)
    eventfield={eventfield};
end
for i=1:length(ALLEEG)
    neuroresult(i)=NeuroResult();
    neuroresult(i).Subjectname=ALLEEG(i).subject;
    neuroresult(i).Filename=ALLEEG(i).filename;
    if isempty(ALLEEG(i).subject)
        neuroresult(i)=neuroresult(i).Taginfo('fileTag','subject',ALLEEG(i).subject);
    end
     if isempty(ALLEEG(i).condition)
        neuroresult(i)=neuroresult(i).Taginfo('fileTag','condition',ALLEEG(i).condition);
     end
     if isempty(ALLEEG(i).group)
        neuroresult(i)=neuroresult(i).Taginfo('fileTag','group',ALLEEG(i).group);
     end
     channelposition=ALLEEG(i).chanlocs;
        try
            addprop(neuroresult(i),'ChannelTag');
        end
    neuroresult(i).ChannelTag.ChannelPosition=channelposition;
    events=struct2table(ALLEEG(i).event);% only transfer them as the timepoint mode
    channelposition=struct2table(channelposition);
    LFPinfo.Fs=ALLEEG(i).srate;
    LFPinfo.channeldescription=channelposition.labels;
    LFPinfo.channelselect=1:length(LFPinfo.channeldescription);
    LFPinfo.datatype='splitting';
    LFPinfo.blackchannel=false(1,length(LFPinfo.channeldescription));
    LFPinfo.time=ALLEEG(i).times;
    try
        addprop(neuroresult(i),'LFPinfo');
    end
    neuroresult(i).LFPinfo=LFPinfo;
    LFPdata=[];
    for j=1:size(ALLEEG(i).data,3);
        LFPdata{j}=ALLEEG(i).data(:,:,j)';
    end
    try
        addprop(neuroresult(i),'LFPdata');
    end
    neuroresult(i).LFPdata=LFPdata;
    try
        EVTinfo.description=eval(['events.',eventfield{1}]);
    catch
        disp(['no event field name', eventfield{1},'was found in ',ALLEEG(i).filename]);
        continue;
    end
    for j=1:length(eventfield)-1
        try
            tmp=eval(['events.',eventfield{j+1},';']);
            if isnumeric(tmp)
                tmp=arrayfun(@(x) num2str(x),tmp,'UniformOutput',0);
            end
            eval(['EVTinfo.',eventfield{j+1},'=tmp;']);
        catch
              disp(['no event field name', eventfield{j+1},'was found in ',ALLEEG(i).filename]);
        continue;
        end
    end
    epochlength=ALLEEG(i).pnts;
    epochlength=cumsum(repmat(epochlength,[size(ALLEEG(i).data,3),1]));
    timestart=[1;epochlength(1:end-1)+1];
    timestop=[epochlength(1:end)];
    EVTinfo.time=cat(2,timestart,timestop)/ALLEEG(i).srate;
    EVTinfo.timetype='timepoint';
    EVTinfo.blackevt=false(1,length(EVTinfo.description));
    EVTinfo.eventselect=1:length(EVTinfo.description);
    EVTinfo.timerange=[min(ALLEEG(i).times),max(ALLEEG(i).times)]/ALLEEG(i).srate;
    try 
        addprop(neuroresult(i),'EVTinfo');
    end
    neuroresult(i).EVTinfo=EVTinfo;
end
    