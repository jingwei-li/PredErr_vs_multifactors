function ABCD_scatter_PredErr_vs_other_var(err_avg, Ydata, outdir, outbase, Xlabels, Ylabel, threshold)

    addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

    if(~exist('threshold', 'var'))
        threshold = 0.5;
    end

    sz = 25;
    colormat = [211 94 96] ./ 255;

    N = length(fieldnames(err_avg));
    row = floor(sqrt(N));
    col = ceil(N/row);
    f = figure;
    set(gcf, 'position', [0 0 400*col 350*row])

    for c = 1:N 
        Xdata = err_avg.(['class' num2str(c)]);
        idx = ~isnan(Xdata) & ~isnan(Ydata);
        Xdata = Xdata(idx);
        Ydata_c = Ydata(idx);

        Nsub = length(Xdata);
        Nkeep = round(Nsub * abs(threshold));
        if(threshold>0)
            [~, top_err_idx] = sort(Xdata, 'descend');
        else
            [~, top_err_idx] = sort(Xdata, 'ascend');
        end
        top_err_idx = top_err_idx(1:Nkeep);
        Xdata = Xdata(top_err_idx);
        Ydata_c = Ydata_c(top_err_idx);

        subplot(row, col, c);
        %scatter(Xdata, Ydata_c, sz, colormat, 'filled')
        scatter_kde(Xdata, Ydata_c, 'MarkerSize', sz, 'filled')

        hold on
        xli = get(gca, 'xlim');
        xpoints = xli(1):((xli(2)-xli(1))/5):xli(2);

        p = polyfit(Xdata, Ydata_c, 1);
        r = polyval(p, xpoints);
        plot(xpoints, r, 'k', 'LineWidth', 2)
        hold off

        [rho, pval] = corr(Xdata, Ydata_c);
        [s_rho, s_pval] = corr(Xdata, Ydata_c, 'Type', 'Spearman')
        title(sprintf('X- vs Y-axes Peason''s r: %.3f, p value: %.2e\n Spearman rho: %.3f, p value: %.2e', rho, pval, s_rho, s_pval))

        xlabel(Xlabels{c}, 'fontsize', 12)
        ylabel(Ylabel, 'fontsize', 12);
    end

    if(~exist(outdir, 'dir'))
        mkdir(outdir)
    end
    outname = fullfile(outdir, [outbase '_dens_th' num2str(threshold)]);
    export_fig(outname, '-png', '-nofontswap', '-a1');
    set(gcf, 'color', 'w')
    hgexport(f, outname)
    close

    rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

end