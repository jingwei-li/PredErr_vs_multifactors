function shade_subsample_effect(asso, bhvr_cls_names, figout)
% shade_subsample_effect(asso, bhvr_cls_names, figout)
%
% Create a plot of effect size with its confidence interval, across subsampling repetitions.
% Shade will be added between the confidence interval.
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

    repeats = length(asso.class1.Effect);
    N = length(fieldnames(asso));
    row = floor(sqrt(N));
    col = ceil(N/row);
    figname = strcat(figout, "_effect");

    f = figure;
    set(gcf, 'position', [0 0 800*col 350*row])
        
    for c = 1:N
        cls_name = strcat("class", num2str(c));
        subplot(row, col, c);

        hold on
        x = [1:repeats]';
        y1 = asso.(cls_name).Effect_CI(:,1);
        y2 = asso.(cls_name).Effect_CI(:,2);
        plot(x, asso.(cls_name).Effect, 'k', 'linewidth', 2)
        plot(x, y1, 'color', [.5 .5 .5])
        plot(x, y2, 'color', [.5 .5 .5])
        for i = 1:repeats-1
            fill([x(i) x(i+1) x(i+1) x(i)], [y1(i) y1(i+1) y2(i+1) y2(i)], [0.6 0.6 0.6], 'EdgeColor', 'none', 'FaceAlpha', 0.4)
        end
        hold off
    
        title(bhvr_cls_names{c})
        xlabel('Subsampling repetitions', 'fontsize', 12)
        ylabel('Effect size', 'fontsize', 12);
        set(gca, 'tickdir', 'out', 'box', 'off', 'fontsize', 12);
    end
    
    export_fig(figname, '-png', '-nofontswap', '-a1');
    set(gcf, 'color', 'w')
    hgexport(f, figname)
    close

    rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')));
end
