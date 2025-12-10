function hist_subsample_pval(asso, bhvr_cls_names, figout)
% hist_subsample_pval(asso, bhvr_cls_names, figout)
%
% Plot the distribution of subsampled p values indicating the association between prediction errors and covariates.
%
%   - asso
%     Struct. It is the output of `subsample_PredErr_vs_covariate.m`.
%     The first-level field names should be `class1`, `class2`, etc.
%     The second-level field names should contain `pval`, `s_pval`.
%   - bhvr_cls_names
%     A cell array contains the names for each behavioral cluster.
%   - figout
%     Output name (without extension, full-path).

    addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')));

    N = length(fieldnames(asso));
    row = floor(sqrt(N));
    col = ceil(N/row);

    if(isfield(asso.class1, 's_pval')) % continuous covariate
        Xlabel = 'p values of Spearman''s r';
        figname = strcat(figout, '_s_pval');
        p_name = 's_pval';
    elseif(isfield(asso.class1, 'p')) % categorical covariate
        Xlabel = 'p values';
        figname = strcat(figout, '_p');
        p_name = 'p';
    end

    f = figure;
    set(gcf, 'position', [0 0 400*col 350*row])
        
    for c = 1:N
        subplot(row, col, c);
        histogram(asso.(strcat('class', num2str(c))).(p_name), 20);

        title(bhvr_cls_names{c})
        xlabel(Xlabel, 'fontsize', 12)
        ylabel('Subsampled frequencies', 'fontsize', 12);
        set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 12);
    end

    export_fig(figname, '-png', '-nofontswap', '-a1');
    set(gcf, 'color', 'w')
    hgexport(f, figname)
    close

    rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')));
end
