function ABCD_hist_subsample_rho(asso, bhvr_cls_names, figout)

% ABCD_hist_subsample_rho(asso, bhvr_cls_names, figout)
%
% Plot the distribution of subsampled association between prediction errors and covariates.
%
%   - asso
%     Struct. It is the output of `ABCD_subsample_PredErr_vs_continuous_var.m`. The first-level
%     field names should be `class1`, `class2`, etc. The second-level field names should 
%     contain `rho`, `rho_mean`, `rho_CI`, `s_rho`, `s_rho_mean`, `s_rho_CI`.
%   - bhvr_cls_names
%     A cell array contains the names for each behavioral cluster. The number of entries 
%     in `bhvr_cls_names` should be the same with the number of fields in the `asso` structure.
%     Example: bhvr_cls_names = {'Verbal Memory', 'Cognition', 'Mental Rotation', 'CBCL', 'Prodromal Psychosis'};
%   - figout
%     Output name (without extension, full-path).
%

addpath(genpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'external_packages', 'fig_util')))

self(asso, bhvr_cls_names, 'Pearson''s r', [figout '_Pearson'], 'rho')
self(asso, bhvr_cls_names, 'Spearman''s rho', [figout '_Spearman'], 's_rho')

rmpath(genpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'external_packages', 'fig_util')))
    
end



function self(asso, bhvr_cls_names, Xlabel, figout, rho_name)

N = length(fieldnames(asso));
row = floor(sqrt(N));
col = ceil(N/row);
f = figure;
set(gcf, 'position', [0 0 400*col 350*row])
    
for c = 1:N
    subplot(row, col, c);
    histogram(asso.(['class' num2str(c)]).(rho_name), 20);

    hold on
    yli = get(gca, 'ylim');
    plot(repmat(asso.(['class' num2str(c)]).([rho_name '_CI'])(1), 1,2), yli, '-.k' )
    plot(repmat(asso.(['class' num2str(c)]).([rho_name '_CI'])(2), 1,2), yli, '-.k' )
    hold off

    title(bhvr_cls_names{c})

    xlabel(sprintf([Xlabel ' [mean = %.3f]'], asso.(['class' num2str(c)]).([rho_name '_mean'])), 'fontsize', 12)
    ylabel('Subsampled frequencies', 'fontsize', 12);
    set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 12);
end

export_fig(figout, '-png', '-nofontswap', '-a1');
set(gcf, 'color', 'w')
hgexport(f, figout)
close

end