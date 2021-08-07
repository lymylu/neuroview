% ----------------------------------------------------------------------- %
%                     M U L T I P L E    T E S T I N G                    %
% ----------------------------------------------------------------------- %
% Function 'mt_fisher' computes the Combined Probability of Fisher for    %
% multiple comparisons.                                                   %
%                                                                         %
%   Input parameters:                                                     %
%       - pvalues:      List of p-values to correct.                      %
%       - alpha:        Significance level (commonly, alpha=0.05).        %
%       - plotting:     (Optional, default=false) Plotting boolean.       %
%                                                                         %
%   Output variables:                                                     %
%       - c_pvalues:    Adjusted p-values.                                %
%       - chi2_2k:      Values of X^2_2k                                  %
%       - h:            Hypothesis rejection. If h=1, H0 is rejected; if  %
%                       h=0, H0 is accepted.                              %
%       - extra:        Struct that contains additional information.      %
% ----------------------------------------------------------------------- %
%   Example of use:                                                       %
%       [c_pvalues, chi2_2k, h, extra] = mt_fisher(rand(10,1),0.05);      %
% ----------------------------------------------------------------------- %
%   Script information:                                                   %
%       - Version:      1.0.                                              %
%       - Author:       V. Mart¨ªnez-Cagigal                               %
%       - Date:         18/03/2019                                        %
% ----------------------------------------------------------------------- %
%   References:                                                           %
%       [1] Diz, A. P., Carvajal-Rodr¨ªguez, A., & Skibinski, D. O. (2011).%
%           Multiple hypothesis testing in proteomics: a strategy for     %
%           experimental work. Molecular & Cellular Proteomics, 10(3),    %
%           M110-004374.                                                  %
%       [2] Whitlock, M. C. (2005). Combining probability from independent%
%           tests: the weighted Z-method is superior to Fisher's approach.%
%           Journal of evolutionary biology, 18(5), 1368-1373.            %
% ----------------------------------------------------------------------- %
function [c_pvalues, chi2_2k, h, extra] = mt_fisher(pvalues, alpha, plotting)

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
    s_c_pvalues = NaN(1,m);
    s_chi2_2k = NaN(1,m);
    
    % Sort the p-values in ascending order
    [s_pvalues, idx] = sort(pvalues,'ascend');
    for i = 1:m
        % Extract the adjusted p-value from a chi-squared distribution
        s_chi2_2k(i) = -2*sum(log(s_pvalues(i:m)));
        s_c_pvalues(i) = chi2cdf(s_chi2_2k(i), 2*(m-i+1), 'upper');
    end
    s_c_pvalues(s_c_pvalues>1) = 1;
    
    % Unsort the adjusted p-values
    chi2_2k(idx) = s_chi2_2k;
    c_pvalues(idx) = s_c_pvalues;
    
    % Rejected H0
    h = c_pvalues(:) < alpha;
    
    % Extra information
    extra.s_pvalues = s_pvalues;
    extra.s_c_pvalues = s_c_pvalues;
    extra.s_c_alpha = s_chi2_2k;
    extra.alpha = alpha;
    extra.pvalues = pvalues;
    
    % Plotting
    if plotting
        figure;
        subplot(2,2,1:2);
        s_pvalues = sort(pvalues,'ascend');
        s_c_pvalues = sort(c_pvalues,'ascend');
        plot(s_pvalues, s_c_pvalues, 'b', 'linewidth',2);
        ylabel('Adj. p-values'); xlabel('p-values');
        title('Fisher');
        
        subplot(2,2,3);
        hist(pvalues); xlabel('p-values'); ylabel('Histogram');
        
        subplot(2,2,4);
        hist(c_pvalues); xlabel('Adj. p-values'); ylabel('Histogram');
    end
end


