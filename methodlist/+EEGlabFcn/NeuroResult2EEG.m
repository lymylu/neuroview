function ALLEEG=NeuroResult2EEG(neuroresult)
% transfer neuroresult obj(s) to EEG struct for EEGlab calculation
% only LFPdata and ChannelPosition could be transfered.
for i=1:length(neuroresult)
subjectname=neuroresult(i).Subjectname;
if isfield(neuroresult(i).ChannelTag,'ChannelPosition')
    channelposition=neuroresult(i).ChannelTag.ChannelPosition;
    for n=1:length(channelposition)
        if ~ischar(channelposition(n).labels)
        channelposition(n).labels=char(channelposition(n).labels);
        end
    end
else
    channelposition=[];
end
if ~isprop(neuroresult(i),'LFPdata')
    warning(['no LFPdata in ',neuroresult(i).Subjectname],', could not transfer to EEG dataset.');
    continue;
end
% for timepoint mode
if isprop(neuroresult(i),'EVTinfo')&&strcmp(neuroresult(i).EVTinfo.timetype,'timepoint')
    LFPdata=cell2mat(neuroresult(i).LFPdata);
    LFPdata=reshape(LFPdata,size(neuroresult(i).LFPdata{1},1),size(neuroresult(i).LFPdata{1},2),[]);
    LFPdata=permute(LFPdata,[2,1,3]); % channel*time*epoch;
else % for timeduration mode
        neuroresult(i)=neuroresult(i).Split2Splice();
        LFPdata=cell2mat(neuroresult(i).LFPdata); % only one epoch
        LFPdata=permute(LFPdata,[2,1,3]);
end
srate=neuroresult(i).LFPinfo.Fs;
EEG=pop_importdata('data',LFPdata,'dataformat','array','setname',char(subjectname),'nbchan',size(LFPdata,1),'srate',srate,'chanlocs',channelposition);
eventfieldname=fieldnames(neuroresult(i).EVTinfo);
reservename={'description','timerange','timetype','time'};
if isprop(neuroresult(i),'EVTinfo')&&strcmp(neuroresult(i).EVTinfo.timetype,'timepoint')
    EEG=pop_importdata('data',LFPdata,'dataformat','array','setname',char(subjectname),'nbchan',size(LFPdata,1),'srate',srate,'chanlocs',channelposition,'xmin',neuroresult(i).EVTinfo.timerange(1));
    epochtime=linspace(neuroresult(i).EVTinfo.timerange(1),neuroresult(i).EVTinfo.timerange(2),EEG.pnts);
    v=cumsum(repmat(EEG.pnts,[size(LFPdata,3),1]));
    eventtime=num2cell((find(epochtime==0)+v(1:end)-EEG.pnts));
    eventdescription=cellstr(neuroresult(i).EVTinfo.description);
    EEG=eeg_addnewevents(EEG,eventtime,eventdescription,{'epoch'},{1:size(LFPdata,3)});
elseif isprop(neuroresult(i),'EVTinfo')&&strcmp(neuroresult(i).EVTinfo.timetype,'timeduration')
    % add the epoch begin and epoch end according LFPinfo.splicindex
    timebegin=[1,neuroresult(i).LFPinfo.spliceindex(1:end-1)+1];
    timeend=[neuroresult(i).LFPinfo.spliceindex(1:end)];
    timebegin=num2cell(timebegin);
    timeend=num2cell(timeend);
    eventtimebegin=cellstr(neuroresult(i).EVTinfo.description(:,1));
    eventtimeend=cellstr(neuroresult(i).EVTinfo.description(:,2));
    EEG=eeg_addnewevents(EEG,cat(2,timebegin,timeend),cat(1,eventtimebegin,eventtimeend));
end
EEG=eeg_checkset(EEG);
ALLEEG(i)=EEG;
end
eeg_checkset(ALLEEG);
end