function [p_bootstrap,p_bootstrap_r,p_bootstrap_l] = sub_tfd_bootstrp(P_Pre, P_Post, N_Bootstrap,block_length)
% bootstrap for TFD
%
% Copyright (C) 2011 The University of Hong Kong
% Authors:   Zhiguo Zhang, Li Hu, Yong Hu
%            zgzhang@eee.hku.hk
% reference: Durka et al., IEEE TBME 51(7), 2004
% modify by Lupeng Yue in Dec 2019 add the bootrap way of Moving-block bootstrap (MBB)
if nargin<4;
    disp('lack of Block length, using typical bootstrap!')
    bootstraptype='normal'
else
    disp('Using moving-block bootstrap')
    bootstraptype='mbb';
end

disp(['Bootstrapping for Time-frequency Distributions (Number of Resampling: ',num2str(N_Bootstrap),')'])
fprintf(['Progress: '])
% Bootstrap
[NF,NT_Pre,N_Trials] = size(P_Pre);
NT_Post = size(P_Post,2);
for fi=1:NF
    fprintf(1,'%03.0f%%',fi/NF*100)
    E_Pre1 = squeeze(P_Pre(fi,:,:));
    E_Pre = E_Pre1(:);
    % bootstrap
    for n_bs=1:N_Bootstrap
%         E_Pre_bs = randsample(E_Pre,NT_Pre*N_Trials,true);
       if strcmp(bootstraptype,'normal')
        E_Pre_bs = bootstrapsample(E_Pre1,'normal');
       elseif strcmp(bootstraptype,'mbb')
        E_Pre_bs = bootstrapsample(E_Pre1,'mbb',block_length);
       end
        E_Post_bs = randsample(E_Pre1(:),N_Trials,true);
        pooled_var = ((NT_Pre*N_Trials-1)*var(E_Pre_bs(:))+(N_Trials-1)*var(E_Post_bs)) / (NT_Pre*N_Trials+N_Trials-2);%% 样本标准差
        pseudo_t_bs{fi}(n_bs) = (mean(E_Post_bs)-mean(E_Pre_bs(:))) / pooled_var ;        
    end    
    for ti=1:NT_Post
        E_Post = squeeze(P_Post(fi,ti,:));
        pooled_var = ((NT_Pre*N_Trials-1)*var(E_Pre)+(N_Trials-1)*var(E_Post)) / (NT_Pre*N_Trials+N_Trials-2);
        pseudo_t(fi,ti) = (mean(E_Post)- mean(E_Pre)) / pooled_var;
        %The two-tailed P-value is twice the lower of the two one-tailed P-values
        p1 = numel(find(pseudo_t_bs{fi}>=pseudo_t(fi,ti)))/N_Bootstrap;
        p2 = numel(find(pseudo_t_bs{fi}<=pseudo_t(fi,ti)))/N_Bootstrap;
        p_bootstrap(fi,ti) = 2*min(p1,p2);
        p_bootstrap_r(fi,ti) = p1;
        p_bootstrap_l(fi,ti) = p2;
    end
    if fi<NF
        for nn=1:4; fprintf('\b'); end
    else
        fprintf('\n');
    end
end
end
function data=bootstrapsample(data,option,samplelength)
switch option
    case 'normal'
        data = randsample(data(:),size(data,1)*size(data,2),true);
    case 'mbb'
        data = overlappingBB(data,samplelength);
end
end
function Zb = overlappingBB(Z,b)
% PURPOSE: Overlapping Block Bootstrap for a vector time series
% ------------------------------------------------------------
% SYNTAX: Zb = overlappingBB(Z,b);
% ------------------------------------------------------------
% OUTPUT: Zb : (k*b)xkz resampled time series (with k=[n/b])
% ------------------------------------------------------------
% INPUT:  Z  :  nxkz --> vector time series to be resampled
%         b  :  1x1  --> block size (b>=1)
%         If b=1 the Efron's standard iid bootstrap is applied
% ------------------------------------------------------------
% LIBRARY: loopBB [internal]
% ------------------------------------------------------------
% SEE ALSO: stationaryBB, seasBB
% ------------------------------------------------------------
% REFERENCES: K?nsch, H.R.(1989) "The jacknife and the bootstrap 
% for general stationary observations",The Annals of Statistics, 
% vol. 17, n. 3, p. 1217-1241.
% Davison, A.C. y  Hinkley, D.V. (1997) "Bootstrap methods and 
% their application", Ch. 8: Complex Dependence, Cambridge 
% University Press, Cambridge. U.K.
% ------------------------------------------------------------

% written by:
%  Enrique M. Quilis
%  Macroeconomic Research Department
%  Fiscal Authority for Fiscal Responsibility (AIReF)
%  <enrique.quilis@airef.es>

% Version 1.1 [October 2015]

% ============================================================
% Dimension of time series to be bootstrapped
[n,kz] = size(Z);

% Number of blocks
k = fix(n/b);

% ------------------------------------------------------------
% INDEX SELECTION
% ------------------------------------------------------------
I = round(1+(n-b)*rand(1,k));

% ------------------------------------------------------------
% BOOTSTRAP REPLICATION
% ------------------------------------------------------------
Zb = [];
for j=1:kz
   Zb = [Zb loopBB(Z(:,j),k,b,I)];
end
end
% ============================================================
% loopBB ==> UNIVARIATE BOOTSTRAP LOOP
% ============================================================
function xb = loopBB(x,k,b,I);

xb = [];
for i=1:k
   xb = [xb ; x(I(i):I(i)+b-1)];
end
end