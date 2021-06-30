% ----------------------------------------------------------------------- %
%                     M U L T I P L E    T E S T I N G                    %
% ----------------------------------------------------------------------- %
% Function 'fwer_holmbonf' computes the Holn-Bonferroni correction, also  %
% known as sequential Bonferroni correction, of Family-Wise Error Rate for%
% multiple comparisons.                                                   %
%                                                                         %
%   Input parameters:                                                     %
%       - pvalues:      List of p-values to correct.                      %
%       - alpha:        Significance level (commonly, alpha=0.05).        %
%                                                                         %
%   Output variables:                                                     %
%       - c_pvalues:    Corrected p-values (that should be compared with  %
%                       the given alpha value to test the hypotheses).    %
%       - c_alpha:      Corrected significance levels (that should be     %
%                       compared with the given pvalues to test the       %
%                       hypotheses).                                      %
%       - h:            Hypothesis rejection. If h=1, H0 is rejected; if  %
%                       h=0, H0 is accepted.                              %
%       - extra:        Struct that contains additional information.      %
% ----------------------------------------------------------------------- %
%   Example of use:                                                       %
%       [c_pvalues, c_alpha, h] = mt_holmbonf(rand(5,1), 0.05);           %
% ----------------------------------------------------------------------- %
%   Script information:                                                   %
%       - Version:      1.0.                                              %
%       - Author:       V. Mart¨ªnez-Cagigal                               %
%       - Date:         13/03/2019                                        %
% ----------------------------------------------------------------------- %
function [c_pvalues, c_alpha, h, extra] = fwer_holmbonf(pvalues, alpha, plotting)
    
    % Error detection
    if nargin < 3, plotting = false; end
    if nargin < 2, error('Not enough parameters.'); end
    if ~isnumeric(pvalues) && ~isnumeric(alpha)
        error('Parameters pvalues and alpha must be numeric.');
    end
    pvalues = pvalues(:);
    if length(pvalues) < 2, error('Not enough tests to perform the correction.'); end
    
    % Parameters
    m = length(pvalues);    % No. tests
    
    % Step-up procedure
    [s_pvalues, idx] = sort(pvalues,'ascend');
    k = (1:1:m)';
    s_c_alpha = alpha./(m+1-k);                 % Sorted corrected alpha
    s_c_pvalues = min((m-k+1).*s_pvalues,1);    % Sorted corrected p-values
    
    % Unsorted corrected values and significance levels
    c_alpha(idx) = s_c_alpha;  
    c_pvalues(idx) = s_c_pvalues;
    
    % Rejected H0
    h = pvalues(:) < c_alpha(:);
    
    % Extra information
    extra.s_pvalues = s_pvalues;
    extra.s_c_pvalues = s_c_pvalues;
    extra.s_c_alpha = s_c_alpha;
    extra.alpha = alpha;
    extra.pvalues = pvalues;
    
    % Plotting
    if plotting
        figure;
        subplot(2,2,1:2);
        plot(s_pvalues, s_c_pvalues, 'b', 'linewidth',2);
        ylabel('Adj. p-values'); xlabel('p-values');
        title('Holm-Bonferroni');
        
        subplot(2,2,3);
        hist(pvalues); xlabel('p-values'); ylabel('Histogram');
        
        subplot(2,2,4);
        hist(c_pvalues); xlabel('Adj. p-values'); ylabel('Histogram');
    end
end


