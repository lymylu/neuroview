function out = SRH_test(Data,var1_name,var2_name)
    
    % Compute the rank of the measure column (COLUMN 1)
    Ranks = tiedrank(Data(:,1));
    
    % Get the number of ties for each unique rank
    Ties = histcounts(categorical(Ranks));
    
    % Replace true measure values by corresponding ranks
    Data(:,1) = Ranks;
    
    % Tabulate data
    T = table(Data(:,1),Data(:,2),Data(:,3),'VariableNames',{'measure',var1_name,var2_name});
    
    % Construct linear model
    M = fitlm(T,['measure ~ ',var1_name,' + ',var2_name,' + ',var1_name,':',var2_name],...
              'CategoricalVars',{var1_name,var2_name});
    
    % ANOVA of model
    anaTbl = anova(M);
    
    % Get relevant data in a matrix 
    MS = anaTbl{:,1:3};
    
    % Compute H and p-values 
    n = length(Ranks);
    D = (1 - sum(Ties.^3 - Ties)/(n^3 - n));
    MStotalSokal = n*(n+1)/12;
    SS = MS(1:3,1);
    H = SS / MStotalSokal;
    Hadj = H / D;
    MS(1:3,4) = Hadj; MS(4,4) = NaN; MS(4,5) = NaN;
    MS(1:3,5) = chi2cdf(MS(1:3,4),MS(1:3,2),'upper');
    
    Factors = {var1_name, var2_name, cat(2,var1_name,' x ', var2_name),'Residuals'};
    
    % Construct output table
    out = table(Factors',MS(:,1),MS(:,2),MS(:,4),MS(:,5),'VariableNames',{'Factor','SS','DF','H','pvalue'});
end