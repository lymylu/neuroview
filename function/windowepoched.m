function [epochtime,t]=windowepoched(data,windowsize,timestart,timestop,Fs)
% get the spilt data index from given windowsize
windowwidth=windowsize(1);
windowstep=windowsize(2);
N=size(data,1);
Nwin=round(Fs*windowwidth); % number of samples in window
Nstep=round(windowstep*Fs); % number of samples to step through
winstart=1:Nstep:N-Nwin+1;
nw=length(winstart);
for n=1:nw
   epochtime(:,n)=winstart(n):winstart(n)+Nwin-1;
   t(n)=mean(epochtime(:,n),1)/Fs+timestart;
end

