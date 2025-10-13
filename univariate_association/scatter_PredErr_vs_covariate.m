function scatter_PredErr_vs_covariate(err_avg, Ydata, outdir, outbase, Xlabels, Ylabel)
    addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

    sz = 25;
    colormat = [211 94 96] ./ 255;

    targets = fieldnames(err_avg);
    N = length(targets);
    row = floor(sqrt(N));
    col = ceil(N/row);
    f = figure;
    set(gcf, 'position', [0 0 400*col 350*row])

    for c = 1:N
        Xdata = err_avg.(targets{c});
        idx = ~isnan(Xdata) & ~isnan(Ydata);
        Xdata = Xdata(idx);
        Ydata_c = Ydata(idx);

        [~, top_err_idx] = sort(Xdata, 'descend');
        Xdata = Xdata(top_err_idx);
        Ydata_c = Ydata_c(top_err_idx);

        subplot(row, col, c);
        scatter_kde(Xdata, Ydata_c, 'MarkerSize', sz, 'filled');

        hold on
        xli = get(gca, 'xlim');
        xpoints = xli(1):((xli(2)-xli(1))/5):xli(2);
        p = polyfit(Xdata, Ydata_c, 1);
        r = polyval(p, xpoints);
        plot(xpoints, r, 'k', 'LineWidth', 2)
        hold off

        [rho, pval] = corr(Xdata, Ydata_c);
        [s_rho, s_pval] = corr(Xdata, Ydata_c, 'Type', 'Spearman');
        title(sprintf('X- vs Y-axes Peason''s r: %.3f, p value: %.2e\n Spearman rho: %.3f, p value: %.2e', rho, pval, s_rho, s_pval))

        xlabel_c = strcat("Absolute prediction error of ", Xlabels{c});
        xlabel(xlabel_c, 'fontsize', 12)
        ylabel(Ylabel, 'fontsize', 12);
    end

    if(~exist(outdir, 'dir'))
        mkdir(outdir)
    end
    outname = strcat(outdir, '/PredErr_vs_', outbase);
    export_fig(char(outname), '-png', '-nofontswap', '-a1');
    set(gcf, 'color', 'w')
    hgexport(f, outname)
    close

    rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

end