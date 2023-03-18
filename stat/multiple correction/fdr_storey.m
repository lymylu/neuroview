% ----------------------------------------------------------------------- %
%                     M U L T I P L E    T E S T I N G                    %
% ----------------------------------------------------------------------- %
% Function 'fdr_storey' computes the Storey correction of the False       %
% Discovery Rate for multiple comparisons, returning the q-values, which  %
% directly measures the expected number of false positives.               %
% Note: the method is not recommended if N<10000 and the histogram does not
% show a defined distribution.                                            %
%                                                                         %
%   Input parameters:                                                     %
%       - pvalues:      List of p-values to correct.                      %
%       - alpha:        Significance level (commonly, alpha=0.05).        %
%       - plotting:     (Optional, default=false) Plotting boolean.       %
%                                                                         %
%   Output variables:                                                     %
%       - qvalues:      Q-values.                                         %
%       - fdr:          FDR for each p-value.                             %
%       - h:            Hypothesis rejection. If h=1, H0 is rejected; if  %
%                       h=0, H0 is accepted.                              %
%       - extra:        Struct that contains additional information.      %
% ----------------------------------------------------------------------- %
%   Example of use:                                                       %
%       load prostatecancerexpdata                                        %
%       pvalues = mattest(dependentData,independentData,'permute',true);  %
%       [qvalues, fdr, h] = fdr_storey(pvalues, 0.05, true)               %
% ----------------------------------------------------------------------- %
%   Script information:                                                   %
%       - Version:      1.0.                                              %
%       - Author:       V. Mart¨ªnez-Cagigal                               %
%       - Date:         14/03/2019                                        %
% ----------------------------------------------------------------------- %
%   References:                                                           %
%       [1] Storey, J. D. (2002). A direct approach to false discovery    %
%           rates. Journal of the Royal Statistical Society: Series B     %
%           (Statistical Methodology), 64(3), 479-498.                    %
%       [2] Storey, J. D., & Tibshirani, R. (2003). Statistical           %
%           significance for genomewide studies. Proceedings of the       %
%           National Academy of Sciences, 100(16), 9440-9445.             %
% ----------------------------------------------------------------------- %
function [qvalues, fdr, h, extra] = fdr_storey(pvalues, alpha, plotting)
    
    % Error detection
    if nargin < 3, plotting = false; end
    if nargin < 2, error('Not enough parameters.'); end
    if ~isnumeric(pvalues) && ~isnumeric(alpha)
        error('Parameters pvalues and alpha must be numeric.');
    end
    pvalues = pvalues(:);
    if length(pvalues) < 2, error('Not enough tests to perform the correction.'); end
    if ~islogical(plotting), error('Plotting parameter must be a boolean'); end
        
    % Parameters
    m = length(pvalues);    % No. tests
    if m < 10000
        warning(['Perhaps the number of p-values (m= %i) is too small to perform' ...
            'the FDR correction of Storey (recommended m > 10000)', m]);
        if ~plotting
            warning('The use of the plotting flag is strongly recommended.');
        end
    end
    lambda = 0.01:0.01:0.95;
    order = 3;
    
    % Compute pi0 (proportion of H0 out of m)
    %   Note: the following commended code is likely to be quicker, but it
    %   is counter-intuitive to understand it
    %       [F, p0] = ecdf(p);
    %       pi0 = interp1q(p0, 1-F, lambda) ./ (1-lambda);
    pi0 = NaN(1,length(lambda));
    for i = 1:length(lambda)
        pi0(i) = sum(pvalues>lambda(i))/(m*(1-lambda(i)));
    end
    
    % Approximate the scatter with a continuous curve
    %   Note: cubic spline of order 3 is used
    [poly_values, s] = polyfit(lambda, pi0, order);
    
    % Estimate the pi0 value at the optimal lambda value
    d = diff(polyval(poly_values,lambda))./diff(lambda);
    [mind, idx] = min(abs(d));
    if mind < 0.005
        % If the estimation is pretty accurate take the minimum lambda
        % value that reachs a difference between the approximated curve and
        % the scattered points that is lower than 0.005
        sel_point = lambda(idx);
    else
        % Common case: the estimation is suitable, thus take lambda=1
        sel_point = 1;
    end
    pi0_est = polyval(poly_values, sel_point);
    
    % If the estimation is very bad, take pi0_est=1 (same as BH procedure)
    if pi0_est > 1 || pi0_est < 0
         warning(['Badly estimated pi0 value (pi0 has been set to 1).' ...
                  'Please, revise the histogram of the p-values.']);
         pi0_est = 1;
    end
    
    % Check if the polynomial fitting is poor
    sd = std(pi0);
    n = numel(lambda) - 1;
    rs = 1 - s.normr^2/(n*sd^2);
    if rs < 0.90 
        warning(['Poorly estimated polynomial line.' ...
                  'Please, type pi0 vs. lambda for more details.']);
    end
    
    % Compute the FDR for each significance level
    [s_pvalues, idx] = sort(pvalues,'ascend');
    s_fdr = pi0_est*m.*s_pvalues./(1:m)';
    
    % Compute the q-values
    s_q = cummin(s_fdr, 'reverse');

    % Unsort the FDR and the q-values
    fdr(idx) = s_fdr;
    qvalues(idx) = s_q;
    
    % Rejected H0
    h = qvalues(:) < alpha;
    
    % Extra information
    extra.s_pvalues = s_pvalues;
    extra.s_c_pvalues = s_q;
    extra.s_c_alpha = s_fdr;
    extra.alpha = alpha;
    extra.pvalues = pvalues;
    extra.rs = rs;
    extra.pi0 = pi0;
    extra.pi0_est = pi0_est;
    extra.sel_point = sel_point;
    
    % Plotting
    if plotting
        figure;
        subplot(2,2,1:2);
        histogram(pvalues, 50, 'normalization', 'pdf'); hold on;
        plot([0 1], [pi0_est pi0_est], '--r', 'linewidth', 2); grid on;
        ylabel('Density histogram');
        xlabel('No. p-values');
        title(['$$\hat{\pi}_0 = ' sprintf('%.4f',pi0_est) '$$'], 'Interpreter','Latex');
        legend({'PDF hist','$$\hat{\pi}_0$$'},'Interpreter','Latex');
        
        subplot(2,2,3);
        plot(lambda, pi0, '.b'); hold on;
        plot(0:0.01:1, polyval(poly_values,0:0.01:1), '--r', 'linewidth',2); hold on;
        plot(sel_point, polyval(poly_values,sel_point), 'xk');
        legend({'Scattered $$\pi_0$$', 'Polynomial fitting', ...
            ['$$\hat{\pi}_0(' sprintf('%.2f',sel_point) ')$$']}, 'Interpreter','Latex');
        grid on;
        ylabel(['$$\hat{\pi}_0(\lambda)$$'], 'Interpreter','Latex');
        xlabel(['$$\lambda$$'], 'Interpreter','Latex');
        title(['$$\hat{\pi}_0$$ estimation'], 'Interpreter','Latex');
        
        subplot(2,2,4);
        plot(s_pvalues, s_fdr, 'k'); hold on;
        plot(s_pvalues, s_q, 'm', 'linewidth', 2);
        ylabel('q-values');
        xlabel('p-values');
        title('FDR correction');
        grid on;
        legend('(p, FDR)','(p, q)');
    end
end



