function asso = subsample_PredErr_vs_continuous_covar(err_avg, covar, s_size, repeats, bhvr_cls_names, covar_name, outdir)

% ass = subsample_PredErr_vs_continuous_covar(err_avg, s_size, repeats, bhvr_cls_names, covar_name, outdir)
%
% Basic function of subsampling.
%
%   - err_avg
%     Struct. Average prediction error from the groups of behavioral measures which share 
%     similar patterns in the errors. It is computed by the function `ABCD_avgPredErr`.
%   - covar
%     A vector, the covariate values.
%   - s_size
%     Size of each subsample.
%   - repeats
%     Number of repetitions of subsampling.
%
%   - asso
%     Struct. The association between averaged errors and covariate under examination.
%   - bhvr_cls_name
%     Optional. If this variable is passed in, then a scatter plot is created for each 
%     subsample and each behavioral class.
%   - covar_name
%     Optional, the name of current covariate shown in a plot. If this variable is passed 
%     in, then a scatter plot is created for each subsample and each behavioral class. 

addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

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
        sample = datasample(1:Nsub, s_size, 'replace', true);
        X = Xdata(sample);
        Y = Ydata(sample);
        [rho(n), pval(n)] = corr(X, Y);
        [s_rho(n), s_pval(n)] = corr(X, Y, 'Type', 'Spearman');

        %% create scatter plot for each subsample
        if(exist('bhvr_cls_names', 'var') && exist('covar_name', 'var') && exist('outdir', 'var'))
            f = figure;
            set(gcf, 'position', [0 0 400 350])
            scatter_kde(X, Y, 'MarkerSize', 25, 'filled')
            hold on
            xli = get(gca, 'xlim');
            xpoints = xli(1):((xli(2)-xli(1))/5):xli(2);

            p = polyfit(X, Y, 1);
            r = polyval(p, xpoints);
            plot(xpoints, r, 'k', 'LineWidth', 2)
            hold off

            title(sprintf('X- vs Y-axes Peason''s r: %.3f, p value: %.2e\n Spearman rho: %.3f, p value: %.2e', rho(n), pval(n), s_rho(n), s_pval(n)))
            xlabel(bhvr_cls_names{c}, 'fontsize', 12)
            ylabel(covar_name, 'fontsize', 12);

            outname = fullfile(outdir, [bhvr_cls_names{c} '_repeat' num2str(n)]);
            export_fig(outname, '-png', '-nofontswap', '-a1');
            set(gcf, 'color', 'w')
            hgexport(f, outname)
            close
        end
    end
    asso.(['class' num2str(c)]).rho = rho;
    asso.(['class' num2str(c)]).pval = pval;
    asso.(['class' num2str(c)]).s_rho = s_rho;
    asso.(['class' num2str(c)]).s_pval = s_pval;

    asso.(['class' num2str(c)]).rho_mean = mean(rho);
    asso.(['class' num2str(c)]).rho_var = mean((rho - mean(rho)).^2);
    % confidence interval reference: https://normaldeviate.wordpress.com/2013/01/27/bootstrapping-and-subsampling-part-ii/
    L = (rho - mean(rho)) .* sqrt(s_size);
    t1 = prctile(L, 1 - alpha/2);   t2 = prctile(L, alpha/2);
    asso.(['class' num2str(c)]).rho_CI = [mean(rho) - t1/sqrt(Nsub), mean(rho) + t2/sqrt(Nsub)];

    asso.(['class' num2str(c)]).s_rho_mean = mean(s_rho);
    asso.(['class' num2str(c)]).s_rho_var = mean((s_rho - mean(s_rho)).^2);
    L = (s_rho - mean(s_rho)) .* sqrt(s_size);
    t1 = prctile(L, 1 - alpha/2);   t2 = prctile(L, alpha/2);
    asso.(['class' num2str(c)]).s_rho_CI = [mean(s_rho) - t1/sqrt(Nsub), mean(s_rho) + t2/sqrt(Nsub)];

    % confidence interval 
    %zCritical = norminv(1 - alpha / 2, 0, 1); % Z-score for two-tailed test
    %marginOfError = zCritical * (std(rho) / sqrt(repeats));
    %lowerBound = mean(rho) - marginOfError;
    %upperBound = mean(rho) + marginOfError;
    %asso.(['class' num2str(c)]).rho_CI = [lowerBound upperBound];
    %marginOfError = zCritical * (std(s_rho) / sqrt(repeats));
    %lowerBound = mean(s_rho) - marginOfError;
    %upperBound = mean(s_rho) + marginOfError;
    %asso.(['class' num2str(c)]).s_rho_CI = [lowerBound upperBound];
end

rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))
    
end