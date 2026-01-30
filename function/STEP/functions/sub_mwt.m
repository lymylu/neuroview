function [P, phi] = sub_mwt(x, xtimes, t, f, Fs, omega, sigma, detrend_opt, algm_opt)
% Morlet continuous wavelet transform
                                        
fprintf('Calculating Morlet Wavelet Transform ... ')

% // Input // %
% x:            the original data samples (Time Points x Channels)
% xtimes:       the time axis of the original data
% t:            evaluated time points in STFT
% f:            evaluated frequency bins in STFT
% Fs:           sampling rate
% omega:        a parameter to define the central frequency of Morlet wavelet
% sigma:        a parameter to define the spread of Morlet wavelet in time domain
% detrend_opt:  detrend or not ('1' for detrend is default, '0' for not)
% algm_opt:     'normal' - calculate P and phi, relatively slow but useful for inverse transform
%               'fast'   - calculate P only, fast but inverse transform takes a longer time  
%               'phi'    - calculate phi only, useful for inverse transform
% // Output // %
% P:            complex values of Morlet wavelet transform
% phi:          wavelet basis functions; used for fast inverse transfrom
%               phi can also be left empty, then it is calculated in each inverse transfrom

%% Pre-processing and Parameters
if nargin<8;  detrend_opt = 1;      end      % detrend (1, default) the data or not (0)
if nargin<9;  algm_opt = 'fast';    end      % default algm_opt is 'fast'

if size(x,2)==1; x = x.'; end
if detrend_opt; x = detrend(x); end; % Remove linear trends

% Downsample (if necessary)
DS_factor = round(median(diff(t))/median(diff(xtimes)));
Fs = Fs/DS_factor;
f = f/Fs;     % normalized frequency
[tmp1 idx_t] = ismember(t, xtimes); % evaluated time index
x = x(idx_t);

N_F = length(f);
N_T = length(x);
t = [1:N_T].';

P = single(zeros(N_F,N_T));
phi = [];

%% Morlet wavelet transform
L_hw = N_T; % filter length

if (strcmp(algm_opt,'normal')==1)||(strcmp(algm_opt,'fast')==1)
    for fi=1:N_F
        scaling_factor = omega./f(fi);
        u = (-[-L_hw:L_hw])./scaling_factor;
        
        hw = sqrt(1/scaling_factor)*exp(-(u.^2)/(2*sigma.^2)).* exp(1i*2*pi*omega*u);
        % below is used in Letswave, but is not precise
        % hw = pi*(1/scaling_factor)*exp(-(u.^2)/(2*sigma.^2)).* exp(1i*2*pi*omega*u); 
        
        P_full = conv(x,conj(hw));
        P(fi,:) = P_full(L_hw+1:L_hw+N_T);
    end
end
% P = P(:,idx_t);

%% obtain basis functions
if (strcmp(algm_opt,'normal')==1)||(strcmp(algm_opt,'phi')==1)
    phi = single(zeros(N_T,N_F,N_T));
    for tau=1:N_T
        for fi=1:N_F
            scaling_factor = omega./f(fi);
            u = (t-tau) ./ scaling_factor;
            phi(:,fi,tau) = sqrt(1/scaling_factor)*exp(-(u.^2)/(2*sigma.^2)).* exp(1i*2*pi*omega*u);
        end
    end
end

fprintf('Done!\n')