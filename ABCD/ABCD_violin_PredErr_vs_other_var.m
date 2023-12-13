function ABCD_violin_PredErr_vs_other_var(Xdata, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, titles, threshold, factor_site)

addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

if(~exist('threshold', 'var'))
    threshold = 1;
end

colors = [172, 146, 235; ...
          79, 193, 232; ...
          160, 213, 104; ...
          255, 206, 84; ...
          237, 85, 100]./255;
Xclasses_orig = unique(Xdata(~isnan(Xdata)));
if(length(Xclasses_orig) > 5)
    colors = repmat(linspace(0,1,length(Xclasses_orig))', 1, 3);
end

N = length(fieldnames(err_avg));
row = floor(sqrt(N));
col = ceil(N/row);

f = figure;
if(length(Xclasses_orig)<=5)
    set(gcf, 'position', [0 0 400*col 350*row])
else
    set(gcf, 'position', [0 0 900*col 350*row])
end

for c = 1:N 
    curr_err = err_avg.(['class' num2str(c)]);

    idx = ~isnan(Xdata) & ~isnan(curr_err);
    Xdata_cut = Xdata(idx);
    curr_err = curr_err(idx);
    if(exist('factor_site', 'var'))
        curr_factor_site = factor_site(idx);
    end

    Nsub = length(curr_err);
    Nkeep = round(Nsub * abs(threshold));
    if(threshold>0)
        [~, top_err_idx] = sort(curr_err, 'descend');
    else
        [~, top_err_idx] = sort(curr_err, 'ascend');
    end
    top_err_idx = top_err_idx(1:Nkeep);
    Xdata_cut = Xdata_cut(top_err_idx);
    curr_err = curr_err(top_err_idx);
    if(exist('factor_site', 'var'))
        curr_factor_site = curr_factor_site(top_err_idx);
    end

    subplot(row, col, c);

    Xclasses = unique(Xdata_cut);
    maxL = 0;
    for c2 = 1:length(Xclasses)
        m = length(find(Xdata_cut == Xclasses(c2)));
        if(m>maxL)
            maxL = m;
        end
    end
    Ydata = nan(maxL, length(Xclasses));
    [~,~,XTickLabels_idx] = intersect(Xclasses, Xclasses_orig, 'stable');
    
    Ydata_anova = [];
    grp_anova = [];
    if(exist('factor_site', 'var'))
        site_anova = [];
    end
    for c2 = 1:length(Xclasses)
        cidx = find(Xdata_cut == Xclasses(c2));
        Ydata(1:length(cidx), c2) = curr_err(cidx);
        Ydata_anova = [Ydata_anova; curr_err(cidx)];
        grp_anova = [grp_anova; repmat(c2, size(curr_err(cidx)))];
        if(exist('factor_site', 'var'))
            site_anova = [site_anova; curr_factor_site(cidx)];
        end
    end
    
    if(length(Xclasses) == 2)
        Y1 = Ydata(~isnan(Ydata(:,1)),1);
        Y2 = Ydata(~isnan(Ydata(:,2)),2);
        [H, p] = ttest2(Y1, Y2);
        effect = meanEffectSize(Y1, Y2, VarianceType="unequal");
        effect = effect.Effect;
    else
        [p, anovatab, stats] = anova1(Ydata_anova, grp_anova, 'off');
        fprintf('ANOVA table for %s\n', titles{c})
        anovatab
        effect = anovatab{2, 2} / anovatab{4, 2};

        if(exist('factor_site', 'var'))
            [p2, tbl2, stats2] = anovan(Ydata_anova, {grp_anova, site_anova}, 'model', 2, 'display', 'off');
            fprintf('Two-way ANOVA table for %s\n', titles{c})
            tbl2
            effect_main = tbl2{2, 2} / tbl2{6, 2};
            effect_site = tbl2{3, 2} / tbl2{6, 2};
        end
    end

    vio = violinplot(Ydata, [], [], 'ShowMean', true);
    for i = 1:length(vio)
        if(isvalid(vio(i).MedianPlot))
            vio(i).ViolinPlot.LineWidth = 2;
            vio(i).ScatterPlot.Marker = '.';
            vio(i).MedianPlot.SizeData = 12;
            vio(i).ViolinPlot.FaceColor = colors(i,:);
        end
    end

    Xlims = get(gca, 'xlim');
    Ylims = get(gca, 'ylim');
    if(length(Xclasses) == 2)
        text(mean(Xlims)-0.5, Ylims(2)-0.02*(Ylims(2)-Ylims(1)), sprintf('p = %.2e; eff = %.2e', p, effect), 'fontsize', 11)
    else
        if(~exist('p2', 'var'))
            text(Xlims(1) + 0.3, Ylims(2)-0.02*(Ylims(2)-Ylims(1)), sprintf('p = %.2e; eff = %.2e', p, effect), 'fontsize', 11)
        else
            text(Xlims(1) + 0.3, Ylims(2)-0.02*(Ylims(2)-Ylims(1)), sprintf('Factor 1 p = %.2e; eff = %.2e', p2(1), effect_main), 'fontsize', 11)
            text(Xlims(1) + 0.3, Ylims(2)-0.12*(Ylims(2)-Ylims(1)), sprintf('Factor 2 (site) p = %.2e; eff = %.2e', p2(2), effect_site), 'fontsize', 11)
            text(Xlims(1) + 0.3, Ylims(2)-0.22*(Ylims(2)-Ylims(1)), sprintf('Interaction p = %.2e', p2(3)), 'fontsize', 11)
        end
    end

    xlabel(Xlabel, 'fontsize', 12);
    ylabel(Ylabel, 'fontsize', 12);
    title(titles{c}, 'fontsize', 12, 'linewidth', 2)
    set(gca, 'XTickLabel', XTickLabels(XTickLabels_idx), 'fontsize', 12)
    if(length(Xclasses) > 5)
        rotateXLabels( gca(), 30 );
    end
    set(gca, 'tickdir', 'out', 'box', 'off');
end

if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
outname = fullfile(outdir, [outbase '_th' num2str(threshold)]);
export_fig(outname, '-png', '-nofontswap', '-a1');
set(gcf, 'color', 'w')
hgexport(f, outname)
close


rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

end