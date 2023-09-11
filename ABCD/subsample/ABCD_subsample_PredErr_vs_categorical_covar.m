function asso = ABCD_subsample_PredErr_vs_categorical_covar(err_avg, covar, s_size, repeats)

% asso = ABCD_subsample_PredErr_vs_categorical_covar(err_avg, covar, s_size, repeats)
%
% Core function of subsampling when the covariate is a categorical variable (e.g. sex).
%
%   - err_avg
%     Struct. Average prediction error from the groups of behavioral measures which share 
%     similar patterns in the errors. It is computed by the function `ABCD_avgPredErr`.
%   - covar
%     a vector of covariate.
%   - s_size
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
    Ydata = err_avg.(['class' num2str(c)]);
    idx = ~isnan(Ydata) & ~isnan(covar);
    Ydata = Ydata(idx);
    Xdata = covar(idx);
    Nsub = length(Xdata);

    Xclasses_all = unique(Xdata);

    %% start bootstrapping
    rng('default')
    p = zeros(repeats, 1);  Effect = zeros(repeats, 1); Effect_CI = zeros(repeats,2);
    for n = 1:repeats
        sample = datasample(1:Nsub, s_size, 'replace', true);
        X = Xdata(sample);
        Y = Ydata(sample);

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

            % Calculate critical values of (variance of factor / variance of error) from the F-distribution
            F_critical_lower = finv(alpha / 2, df_effect, df_error);
            F_critical_upper = finv(1 - alpha / 2, df_effect, df_error);

            % Calculate the confidence interval for effect size
            Effect_CI(n,1) = 1 / ( F_critical_upper * (tbl{3, 2} / tbl{2, 2}) + 1 );
            Effect_CI(n,2) = 1 / ( F_critical_lower * (tbl{3, 2} / tbl{2, 2}) + 1 );
            % `tbl{3, 2} / tbl{2, 2}` is the variance of error / variance of factor.
            % hint: effect size = var(factor) / var(total) = var(factor) / (var(factor) + var(error))
            % we can first derive the CI of var(error) / var(factor), then +1, then revert
        end
    end

    asso.(['class' num2str(c)]).p = p;
    asso.(['class' num2str(c)]).Effect = Effect;
    asso.(['class' num2str(c)]).Effect_CI = Effect_CI;
end
    
end