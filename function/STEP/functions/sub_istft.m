function [x_rec] = sub_istft(Px, xtimes, t, f, Fs, winsize, wintype)
% This sub-function is used to estimate waveforms from time-varying complex spectrum using 
% inverse short-time Fourier transform (invere STFT)
% Note that it is only used for multi-channel EEG data.

% /Input/
% Px: the STFT matrix (Freq x Time x Trial)
% xtimes: the time axis of the original data
% t: evaluated time points in STFT
% f: evaluated frequency bins in STFT
% Fs: sampling rate
% winsize: window size (NOTE: the unit is sec)
% wintype: window type (default: hanning window)

% /Output/
% x_rec: reconstructed time-series from complex time-freqeuncy data Px

fprintf('\nInverse Short-time Fourier Transform: ')
if length(winsize)>1 % winsize is a vector
    fprintf('\nInverse STFT can only be used when window size is fixed!\n')
    STOP
end
%% Parameters
N_Trials = size(Px,3); % number of trials
if nargin<=6; wintype = 'hann'; end; % default winow type is 'hann'
L = round(winsize*Fs/2); % half of window size (points)
h = L*2+1; %  window size (points)
win = window(wintype,h); % window (one trial)
if ismember(0,win); win = window(wintype,h+2); win = win(find(win~=0)); end % remove zeros points in the window
W = repmat(win,1,N_Trials); % window (all trials)
U = win'*win;  % compensates for the power of the window

% index of time points in time-frequency domain
dt = t(2)-t(1); % time interval (uniform step)
[junk,t_idx_min] = min(abs(xtimes-t(1)));
[junk,t_idx_max] = min(abs(xtimes-t(end)));
t_idx = t_idx_min:round(dt*Fs):t_idx_max; 
N_T = length(t);

% index of time points in time-frequency domain
df = f(2)-f(1); % frequency step (uniform step)
nfft = round(Fs/df) * max(1,2^(nextpow2(h/round(Fs/df)))); % points of FFT
f_full = Fs/2*linspace(0,1,round(nfft/2)+1);
[junk,f_idx_min] = min(abs(f_full-f(1)));
[junk,f_idx_max] = min(abs(f_full-f(end)));
f_idx = f_idx_min:max(1,2^(nextpow2(h/round(Fs/df)))):f_idx_max; 
if numel(f_idx)>numel(f); f_idx = f_idx(1:end-1); end
N_F = length(f);

fprintf('%d Time Points x %d Frequency Bins x %d Trials\n',N_T,N_F,N_Trials);

%% Inverse STFT
fprintf('Processing...     ')

x_rec = NaN*zeros(L*2+length(xtimes),N_T,N_Trials);
for n=1:N_T
    Px_half = zeros(numel(f_full),N_Trials);
    Px_half(f_idx,:) = squeeze(Px(:,n,:));
    Px_full = [Px_half; conj(Px_half(end-1-rem(nfft,2):-1:2,:))];
    x_n = ifft(Px_full,nfft,1);
    x_rec(t_idx(n)+[0:h-1],n,:) = x_n(1:h,:)./W;
end
x_rec = squeeze(real(nanmean(x_rec(L+1:end-L,:,:),2)))*sqrt(U);

fprintf('  Done!\n')