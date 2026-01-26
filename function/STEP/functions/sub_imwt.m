function [y] = sub_imwt(P, phi, f, Fs, omega, sigma)
% inverse Morlet continuous wavelet transform

fprintf('Calculating Inverse Morlet Wavelet Transform ... ')

% // Input // %
% P:        complex values of Morlet wavelet transform
% phi:      wavelet basis functions; used for fast inverse transfrom
% f:        discrete frequency samples
% Fs:       sampling rate
% omega:    a parameter to define the central frequency of Morlet wavelet
% sigma:    a parameter to define the spread of Morlet wavelet in time domain
% // Output // %
% y:        data samples reconstructed from wavelet coefficients

%% Pre-processing and Parameters
N_F = length(f);
N_T = size(P,2);
t = [1:N_T].';
f = f/Fs;     % normalized frequency

%% inverse continuous Morlet wavelet transform
% caculate normalized factor C_phi
phi_sampling_rate = f(2)-f(1);
xx = [-20+phi_sampling_rate:phi_sampling_rate:20];
phi_t = exp(-(xx.^2)/(2*sigma.^2)).* exp(1i*2*pi*omega*xx);
C_phi = sum(abs(phi_t).^2)/2; % divided by 2 because only real frequency components are computed

for tau=1:N_T
    for fi=1:N_F
        if isempty(phi)
            % if phi is empty, estimate phi here
            scaling_factor = omega./f(fi);
            u = (t-tau) ./ scaling_factor;
            phi_f_t = sqrt(1/scaling_factor)*exp(-(u.^2)/(2*sigma.^2)).* exp(1i*2*pi*omega*u);
        else
            phi_f_t = phi(:,fi,tau);
        end
        P_fi(fi) = P(fi,:)*conj(phi_f_t);
    end
    y(tau,1) = real(sum(P_fi)/C_phi);    
end

fprintf('Done!\n')