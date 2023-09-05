function asso = ABCD_subsample_PredErr_vs_other_var(err_avg, covar, size, repeats)

% ass = ABCD_subsample_PredErr_vs_other_var(err_avg, size, repeats)
%
% Basic function of subsampling.
%
%   - err_avg
%     Struct. Average prediction error from the groups of behavioral measures which share 
%     similar patterns in the errors. It is computed by the function `ABCD_avgPredErr`.
%   - covar
%     
%   - size
%     Size of each subsample.
%   - repeats
%     Number of repetitions of subsampling.
%
%   - asso
%     Struct. The association between averaged errors and covariate under examination.

alpha = 0.05;
N = length(fieldnames(err_avg));
assert(length(err_avg.class1) == length(covar), ...
    'Prediction error and covariate have different length.')

for c = 1:N 
    Xdata = err_avg.(['class' num2str(c)]);
    idx = ~isnan(Xdata) & ~isnan(covar);
    Xdata = Xdata(idx);
    Ydata = covar(idx);
    Nsub = length(Xdata);

    %% start bootstrapping
    rng('default')
    rho = zeros(repeats, 1);    pval = zeros(repeats, 1);
    s_rho = zeros(repeats, 1);    s_pval = zeros(repeats, 1);
    for n = 1:repeats
        sample = datasample(1:Nsub, size, 'replace', true);
        X = Xdata(sample);
        Y = Ydata(sample);
        [rho(n), pval(n)] = corr(X, Y);
        [s_rho(n), s_pval(n)] = corr(X, Y, 'Type', 'Spearman');
    end
    asso.(['class' num2str(c)]).rho = rho;
    asso.(['class' num2str(c)]).pval = pval;
    asso.(['class' num2str(c)]).s_rho = s_rho;
    asso.(['class' num2str(c)]).s_pval = s_pval;

    asso.(['class' num2str(c)]).rho_mean = mean(rho);
    asso.(['class' num2str(c)]).rho_var = mean((rho - mean(rho)).^2);
    % confidence interval reference: https://normaldeviate.wordpress.com/2013/01/27/bootstrapping-and-subsampling-part-ii/
    L = (rho - mean(rho)) .* sqrt(size);
    t1 = prctile(L, 1 - alpha/2);   t2 = prctile(L, alpha/2);
    asso.(['class' num2str(c)]).rho_CI = [mean(rho) - t1/sqrt(Nsub), mean(rho) + t2/sqrt(Nsub)];

    asso.(['class' num2str(c)]).s_rho_mean = mean(s_rho);
    asso.(['class' num2str(c)]).s_rho_var = mean((s_rho - mean(s_rho)).^2);
    L = (s_rho - mean(s_rho)) .* sqrt(size);
    t1 = prctile(L, 1 - alpha/2);   t2 = prctile(L, alpha/2);
    asso.(['class' num2str(c)]).s_rho_CI = [mean(s_rho) - t1/sqrt(Nsub), mean(s_rho) + t2/sqrt(Nsub)];
end

    
end