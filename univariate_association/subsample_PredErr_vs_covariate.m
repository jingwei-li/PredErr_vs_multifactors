function subsample_PredErr_vs_covariate(err_avg, covar, vartype, bhvr_cls_names, covar_name, outdir)
% subsample_PredErr_vs_covariate(err_avg, covar, vartype, bhvr_cls_names, covar_name, outdir)
%
% Basic function of subsampling.
%
%   - err_avg
%     Struct. Average prediction error from the groups of behavioral measures which share 
%     similar patterns in the errors. It is computed by the function `ABCD_avgPredErr`.
%   - covar
%     A vector, the covariate values.
%   - vartype
%     Variable type of covariate ("continuous" or "categorical")
%
%   - asso
%     Struct. The association between averaged errors and covariate under examination.
%   - bhvr_cls_name
%     A cell array contains the names for each behavioral cluster.
%   - covar_name
%     Name of current covariate

    addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')));

    sub_size = 432; % matching HCP-D sample size
    repeats = 100;
    alpha = 0.05;
    N = length(fieldnames(err_avg));
    assert(length(err_avg.class1) == length(covar), "Err_avg and covar differ in length");

    if strcmp(vartype, "continuous")
        plot_dir = fullfile(outdir, "scatter_repeat");
        mkdir(plot_dir);
    end

    for c = 1:N
        cls_name = bhvr_cls_names{c};
        cls_idx = strcat("class", num2str(c));
        Xdata = err_avg.(cls_idx);
        idx = ~isnan(Xdata) & ~isnan(covar);
        Xdata = Xdata(idx);
        Ydata = covar(idx);
        Nsub = length(Xdata);

        rng('default');
        if strcmp(vartype, "continuous")
            s_rho = zeros(repeats, 1);
            s_pval = zeros(repeats, 1);
            for n = 1:repeats
                sample = datasample(1:Nsub, sub_size, 'replace', true);
                X = Xdata(sample);
                Y = Ydata(sample);

                X = reallog(X);
                Y = reallog(Y);

                [s_rho(n), s_pval(n)] = corr(X, Y, "Type", "Spearman");
                f = figure;
                set(gcf, 'position', [0 0 400 350]);
                scatter_kde(X, Y, 'MarkerSize', 25, 'filled');

                hold on
                xli = get(gca, 'xlim');
                xpoints = xli(1):((xli(2)-xli(1))/5):xli(2);
                p = polyfit(X, Y, 1);
                r = polyval(p, xpoints);
                plot(xpoints, r, 'k', 'LineWidth', 2);
                hold off

                title(sprintf('Spearman rho: %.3f, p value: %.2e\n', s_rho(n), s_pval(n)));
                xlabel(cls_name, 'fontsize', 12);
                ylabel(covar_name, 'fontsize', 12);

                outname = fullfile(plot_dir, strcat(cls_name, '_vs_', covar_name, '_repeat', num2str(n)));
                export_fig(outname, '-png', '-nofontswap', '-a1');
                set(gcf, 'color', 'w')
                hgexport(f, outname)
                close
            end

            asso.(cls_idx).s_rho = s_rho;
            asso.(cls_idx).s_pval = s_pval;

            asso.(cls_idx).s_rho_mean = mean(s_rho);
            asso.(cls_idx).s_rho_var = mean((s_rho - mean(s_rho)).^2);

            % confidence interval reference: https://normaldeviate.wordpress.com/2013/01/27/bootstrapping-and-subsampling-part-ii/
            L = (s_rho - mean(s_rho)) .* sqrt(sub_size);
            t1 = prctile(L, 1 - alpha/2);
            t2 = prctile(L, alpha/2);
            asso.(cls_idx).s_rho_CI = [mean(s_rho) - t1/sqrt(Nsub), mean(s_rho) + t2/sqrt(Nsub)];

        elseif strcmp(vartype, "categorical")
            Xclasses_all = unique(Ydata);
            p = zeros(repeats, 1);
            Effect = zeros(repeats, 1);
            Effect_CI = zeros(repeats,2);
            for n = 1:repeats
                sample = datasample(1:Nsub, sub_size, 'replace', true);
                X = Ydata(sample); % covariate
                Y = Xdata(sample); % error

                Y = reallog(Y);

                Xclasses = unique(X);
                maxL = 0;
                for c2 = 1:length(Xclasses)
                    m = length(find(X == Xclasses(c2)));
                    if(m>maxL)
                        maxL = m;
                    end
                end
                Y_dummy = nan(maxL, length(Xclasses));

                Y_anova = [];
                grp_anova = [];
                for c2 = 1:length(Xclasses)
                    cidx = find(X == Xclasses(c2));
                    Y_dummy(1:length(cidx), c2) = Y(cidx);
                    Y_anova = [Y_anova; Y(cidx)];
                    grp_anova = [grp_anova; repmat(c2, size(Y(cidx)))];
                end

                if(length(Xclasses_all) == 2)
                    Y1 = Y_dummy(~isnan(Y_dummy(:,1)),1);
                    Y2 = Y_dummy(~isnan(Y_dummy(:,2)),2);
                    [H, p(n)] = ttest2(Y1, Y2);
                    effect = meanEffectSize(Y1, Y2, VarianceType="unequal");
                    Effect(n) = effect.Effect;
                    Effect_CI(n,:) = effect.ConfidenceIntervals;
                else
                    [p(n), tbl, stats] = anova1(Y_anova, grp_anova, 'off');
                    tbl
                    Effect(n) = tbl{2, 2} / tbl{4, 2};

                    % Degrees of freedom
                    df_effect = tbl{2, 3};
                    df_error = tbl{3, 3};

                    % Critical values of (variance of factor / variance of error) from F-distribution
                    F_critical_lower = finv(alpha / 2, df_effect, df_error);
                    F_critical_upper = finv(1 - alpha / 2, df_effect, df_error);

                    % Confidence interval for effect size
                    Effect_CI(n,1) = 1 / ( F_critical_upper * (tbl{3, 2} / tbl{2, 2}) + 1 );
                    Effect_CI(n,2) = 1 / ( F_critical_lower * (tbl{3, 2} / tbl{2, 2}) + 1 );
                end
            end

            asso.(cls_idx).p = p;
            asso.(cls_idx).Effect = Effect;
            asso.(cls_idx).Effect_CI = Effect_CI;
        end
    end

    outmat = fullfile(outdir, strcat("subsample_PredErr_vs_", covar_name, ".mat"));
    save(outmat, "asso");

    figout = fullfile(outdir, strcat("subsample_PredErr_vs_", covar_name));
    hist_subsample_pval(asso, bhvr_cls_names, figout);
    if strcmp(vartype, "continuous")
        hist_subsample_rho(asso, bhvr_cls_names, figout);
    elseif strcmp(vartype, "categorical")
        shade_subsample_effect(asso, bhvr_cls_names, figout);
    end

    rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))
end
