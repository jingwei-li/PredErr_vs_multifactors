function HCP_scatter_PhenoCorr_vs_PredErrCorr(PhenoCorr_mat, PredErrCorr_mat, outpng)

% HCP_scatter_PhenoCorr_vs_PredErrCorr(PhenoCorr_mat, PredErrCorr_mat, outpng)
%
% 
addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

load(PhenoCorr_mat)
load(PredErrCorr_mat)

outdir = fileparts(outpng);
if(~exist(outdir, 'dir'))
    mkdir(outdir);
end

for c = 1:2
    if c == 1
        if(size(y_corr, 2) == 1)
            Xdata = abs(y_corr);
        else
            Xdata = abs(mean(y_corr, 2));
        end
        Ydata = abs(mean(err_corr, 2));
    else
        if(size(y_spcorr, 2) == 1)
            Xdata = abs(y_spcorr);
        else
            Xdata = abs(mean(y_spcorr, 2));
        end
        Ydata = abs(mean(err_spcorr, 2));
    end

    sz = 25;
    colormat = [211 94 96] ./ 255;

    if c == 1
        label_prefix = 'Pearson''s r ';
    else
        label_prefix = 'Spearman'' rho ';
    end
    x_label = [label_prefix 'between behavioral scores'];
    y_label = [label_prefix 'between prediction errors'];
    f = figure;
    scatter(Xdata, Ydata, sz, colormat, 'filled')

    hold on
    xli = get(gca, 'xlim');
    xpoints = xli(1):((xli(2)-xli(1))/5):xli(2);

    p = polyfit(Xdata, Ydata, 1);
    r = polyval(p, xpoints);
    plot(xpoints, r, 'k', 'LineWidth', 2)
    hold off

    [rho, pval] = corr(Xdata, Ydata);
    title(sprintf('X- vs Y-axes Peason''s r: %.3f, p value: %e', rho, pval))

    xlabel(x_label, 'fontsize', 12)
    ylabel(y_label, 'fontsize', 12);

    if c == 1
        outname = [outpng '_Pearson'];
    else
        outname = [outpng '_Spearman'];
    end
    export_fig(outname, '-png', '-nofontswap', '-a1');
    set(gcf, 'color', 'w')
    hgexport(f, outname)
    close

end

rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))
    
end