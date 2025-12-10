function hist_subsample_rho(asso, bhvr_cls_names, figout)
% hist_subsample_rho(asso, bhvr_cls_names, figout)
%
% Plot the distribution of subsampled association between prediction errors and covariates.
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

    Xlabel = "Spearman''s r";
    figname = strcat(figout, "_Spearman");
    rho_name = "s_rho";
    N = length(fieldnames(asso));
    row = floor(sqrt(N));
    col = ceil(N/row);

    f = figure;
    set(gcf, 'position', [0 0 400*col 350*row])
        
    for c = 1:N
        cls_name = strcat("class", num2str(c));
        subplot(row, col, c);
        histogram(asso.(cls_name).(rho_name), 20);

        hold on
        yli = get(gca, 'ylim');
        plot(repmat(asso.(cls_name).(strcat(rho_name, '_CI'))(1), 1,2), yli, '-.k' )
        plot(repmat(asso.(cls_name).(strcat(rho_name, '_CI'))(2), 1,2), yli, '-.k' )
        hold off

        title(bhvr_cls_names{c})
        xlabel(sprintf(strcat(Xlabel, ' [mean = %.3f]'), asso.(cls_name).(strcat(rho_name, '_mean'))), 'fontsize', 12)
        ylabel('Subsampled frequencies', 'fontsize', 12);
        set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 12);
    end

    export_fig(figname, '-png', '-nofontswap', '-a1');
    set(gcf, 'color', 'w')
    hgexport(f, figname)
    close

    rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')));
end