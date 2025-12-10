function violin_PredErr_vs_covariate(err_avg, Xdata, outdir, outbase, Ylabels, Xlabel, XTickLabels)
    addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))
    
    colors = [172, 146, 235; ...
              79, 193, 232; ...
              160, 213, 104; ...
              255, 206, 84; ...
              237, 85, 100]./255;
    Xclasses_orig = unique(Xdata(~isnan(Xdata)));
    if(length(Xclasses_orig) > 5)
        colors = repmat(linspace(0,1,length(Xclasses_orig))', 1, 3);
    end
    
    targets = fieldnames(err_avg);
    N = length(targets);
    row = floor(sqrt(N));
    col = ceil(N/row);
    
    f = figure;
    if(length(Xclasses_orig)<=5)
        set(gcf, 'position', [0 0 400*col 350*row])
    else
        set(gcf, 'position', [0 0 900*col 350*row])
    end
    
    for c = 1:N
        curr_err = err_avg.(targets{c});
        idx = ~isnan(Xdata) & ~isnan(curr_err);
        Xdata_cut = Xdata(idx);
        curr_err = curr_err(idx);
    
        [~, top_err_idx] = sort(curr_err, 'descend');
        Xdata_cut = Xdata_cut(top_err_idx);
        curr_err = curr_err(top_err_idx);

        curr_err = reallog(curr_err);

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
        for c2 = 1:length(Xclasses)
            cidx = find(Xdata_cut == Xclasses(c2));
            Ydata(1:length(cidx), c2) = curr_err(cidx);
            Ydata_anova = [Ydata_anova; curr_err(cidx)];
            grp_anova = [grp_anova; repmat(c2, size(curr_err(cidx)))];
        end
    
        if(length(Xclasses) == 2)
            Y1 = Ydata(~isnan(Ydata(:,1)),1);
            Y2 = Ydata(~isnan(Ydata(:,2)),2);
            [H, p] = ttest2(Y1, Y2);
            effect = meanEffectSize(Y1, Y2, VarianceType="unequal");
            effect = effect.Effect;
        else
            [p, anovatab, stats] = anova1(Ydata_anova, grp_anova, 'off');
            fprintf('ANOVA table for %s\n', Ylabels{c})
            anovatab
            effect = anovatab{2, 2} / anovatab{4, 2};
        end
    
        subplot(row, col, c);
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
            text(Xlims(1) + 0.3, Ylims(2)-0.02*(Ylims(2)-Ylims(1)), sprintf('p = %.2e; eff = %.2e', p, effect), 'fontsize', 11)
        end
    
        ylabel_c = strcat("Absolute prediction error of ", Ylabels{c});
        xlabel(Xlabel, 'fontsize', 12);
        ylabel(ylabel_c, 'fontsize', 12);
        set(gca, 'XTickLabel', XTickLabels(XTickLabels_idx), 'fontsize', 12)
        if(length(Xclasses) > 5)
            rotateXLabels( gca(), 30 );
        end
        set(gca, 'tickdir', 'out', 'box', 'off');
    end
    
    if(~exist(outdir, 'dir'))
        mkdir(outdir)
    end
    outname = strcat(outdir, '/PredErr_vs_', outbase);
    export_fig(char(outname), '-png', '-nofontswap', '-a1');
    set(gcf, 'color', 'w');
    hgexport(f, outname);
    close
    
    rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))
    
end