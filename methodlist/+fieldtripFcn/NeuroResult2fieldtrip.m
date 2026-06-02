function cfg=NeuroResult2fieldtrip(neuroresult)
% not worked!
% transfer neuroresult obj(s) to fieldtrip cfg
% LFPdata SPKdata and EVTinfo would be transfered.
% for different usage, use different transformation
% option: 'LFPdata', using raw (only LFPdata, for TimeVaringConnectivty, Spectrogram,
% PowerSpectralDensity, Currentsourcedensity)
% 'SPKdata', using spike (SPKdata (and LFPdata), for PhaseLocking, SpikeFieldCoherence, PerieventFiringHistogram)
% See also ft_datatype_raw, ft_datatype_timelock, ft_datatype_spike

for i=1:length(neuroresult)
subjectname=neuroresult(i).Subjectname;
if isfield(neuroresult(i).ChannelTag,'ChannelPosition')
    channelposition=neuroresult(i).ChannelTag.ChannelPosition;
    for n=1:length(channelposition)
        if ~ischar(channelposition(n).labels)
        channelposition(n).labels=char(channelposition(n).labels);
        end
    end
    data.elec=channelposition;
else
    channelposition=[];
end
if isprop(neuroresult(i),'LFPdata')
    % ft_datatype_raw
    if ~isempty(channelposition) % use ChannelPosition as labels, for eeg format
        tmp=struct2table(channelposition);
        label=tmp.labels;
    else % use channelTag as labels
        label=num2cell(1:size(neuroresult(i).LFPdata{1},2));
        label=cellfun(@(x) num2str(x),label,'UniformOutput',true);
    end
    data.trial=cellfun(@(x) x',neuroresult(i).LFPData,'UniformOutput',true);
    data.label=label;

     if isprop(neuroresult(i),'EVTinfo')
         for j=1:size(neuroresult(i).EVTinfo.time,1)
             data.time{i}=linspace(neuroresult(i).EVTinfo.time(j,1),linspace(neuroresult(i).EVTinfo.time(j,2)),size(neuroresult(i).LFPdata{j},1));
         end
     end
     data=ft_datatype_raw(data);
elseif isprop(neuroresult(i),'SPKdata')
    data.label=neuroresult(i).SPKinfo.spikename;
    data.timestamp=neuroresult(i).SPKdata;
    data.timestampdimord='{chan_trial}_spike';
    if isprop(neuroresult(i),'EVTinfo')
        data.trialtime=neuroresult(i).EVTinfo.time;
    end
    data=ft_datatype_spike(data);
end
end
end

            