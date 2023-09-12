function ABCD_hist_subsample_pval(asso, bhvr_cls_names, figout)

% ABCD_hist_subsample_pval(asso, bhvr_cls_names, figout)
%
% Plot the distribution of subsampled p values indicating the association between prediction errors and covariates.
%
%   - asso
%     Struct. It is the output of `ABCD_subsample_PredErr_vs_continuous_var.m` or 
%     `ABCD_subsample_PredErr_vs_categorical_var.m`. The first-level field names should be 
%     `class1`, `class2`, etc. The second-level field names should 
%     contain `pval`, `s_pval`.
%   - bhvr_cls_names
%     A cell array contains the names for each behavioral cluster. The number of entries 
%     in `bhvr_cls_names` should be the same with the number of fields in the `asso` structure.
%     Example: bhvr_cls_names = {'Verbal Memory', 'Cognition', 'Mental Rotation', 'CBCL', 'Prodromal Psychosis'};
%   - figout
%     Output name (without extension, full-path).

addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

%% when covariate is continuous
if(isfield(asso.class1, 'pval'))
    self(asso, bhvr_cls_names, 'p values of Pearson''s r', [figout '_pval'], 'pval')
end

if(isfield(asso.class1, 's_pval'))
    self(asso, bhvr_cls_names, 'p values of Spearman''s rho', [figout '_s_pval'], 's_pval')
end

%% when covariate is categorical (t test or ANOVA)
if(isfield(asso.class1, 'p'))
    self(asso, bhvr_cls_names, 'p values', [figout '_p'], 'p')
end

rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))
    
end


function self(asso, bhvr_cls_names, Xlabel, figout, p_name)

N = length(fieldnames(asso));
row = floor(sqrt(N));
col = ceil(N/row);
f = figure;
set(gcf, 'position', [0 0 400*col 350*row])
    
for c = 1:N
    subplot(row, col, c);
    histogram(asso.(['class' num2str(c)]).(p_name), 20);

    title(bhvr_cls_names{c})

    xlabel(Xlabel, 'fontsize', 12)
    ylabel('Subsampled frequencies', 'fontsize', 12);
    set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 12);
end

export_fig(figout, '-png', '-nofontswap', '-a1');
set(gcf, 'color', 'w')
hgexport(f, figout)
close

end