% ----------------------------------------------------------------------- %
%                     M U L T I P L E    T E S T I N G                    %
% ----------------------------------------------------------------------- %
% Function 'fwer_bonf' computes the Bonferroni correction of Family-Wise  %
% Error Rate for multiple comparisons.                                    %
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
%       [c_pvalues, c_alpha, h] = mt_bonf(rand(5,1), 0.05);               %
% ----------------------------------------------------------------------- %
%   Script information:                                                   %
%       - Version:      1.0.                                              %
%       - Author:       V. Mart¨ªnez-Cagigal                               %
%       - Date:         13/03/2019                                        %
% ----------------------------------------------------------------------- %
%   References:                                                           %
%       [1] Bonferroni, C. (1936). Teoria statistica delle classi e calcolo
%           delle probabilita. Pubblicazioni del R Istituto Superiore di  %
%           Scienze Economiche e Commericiali di Firenze, 8, 3-62.        %
% ----------------------------------------------------------------------- %
function [c_pvalues, c_alpha, h, extra] = fwer_bonf(pvalues, alpha, plotting)
    
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
    
    % Corrected pvalues
    c_pvalues = min(pvalues.*m,1);
    
    % Corrected significance levels
    c_alpha = (alpha/m).*ones(length(pvalues),1);
    
    % Rejected H0
    h = pvalues(:) < c_alpha(:);
    
    % Extra information
    extra.s_pvalues = sort(pvalues,'ascend');
    extra.s_c_pvalues = sort(c_pvalues,'ascend');
    extra.alpha = alpha;
    extra.pvalues = pvalues;
    
    % Plotting
    if plotting
        figure;
        subplot(2,2,1:2);
        plot(extra.s_pvalues, extra.s_c_pvalues, 'b', 'linewidth',2);
        ylabel('Adj. p-values'); xlabel('p-values');
        title('Bonferroni');
        
        subplot(2,2,3);
        hist(pvalues); xlabel('p-values'); ylabel('Histogram');
        
        subplot(2,2,4);
        hist(c_pvalues); xlabel('Adj. p-values'); ylabel('Histogram');
    end
end


