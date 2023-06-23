function ABCD_hist_avgPredErr(avgPredErr, outname, Xlabels)

% ABCD_hist_avgPredErr(avgPredErr, outname, Xlabels)
%
% Plot histograms of average prediction error in each behavior class, with vertical lines
% drawn at different thresholds.
%
%   - Xlabels
%     A cell array contains the X-axis names for each behavioral cluster. The number of
%     entries in `Xlabels` should be the same with the number of fields in the `err_arg` structure
%     passed in by `avgPredErr` variable.
%     e.g. {'Verbal Memory', 'Cognition', 'Mental Rotation', 'CBCL', 'Prodomal Psychosis'};

addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

thresholds = [0.9 0.75 0.5, 0.25, 0.1];
load(avgPredErr)

N = length(fieldnames(err_avg));
row = floor(sqrt(N));
col = ceil(N/row);
f = figure;
set(gcf, 'position', [0 0 550*col 350*row])

for c = 1:N
    data = err_avg.(['class' num2str(c)]);
    idx = ~isnan(data);
    data = data(idx);

    subplot(row, col, c);
    hist(data, 50);

    hold on
    for t = 1:length(thresholds)
        x = prctile(data, 100-thresholds(t)*100);
        ylims = get(gca, 'ylim');
        plot([x, x], ylims, 'k')
        text(x, ylims(2)+0.02*(ylims(2)-ylims(1)), sprintf('%d%%', 100*thresholds(t)), 'fontsize', 6, 'linewidth', 3)
    end
    hold off
    xlabel(Xlabels{c}, 'fontsize', 12)
    ylabel('Count', 'fontsize', 12);
    set(gca, 'tickdir', 'out', 'box', 'off');
end

outdir = dirname(outname);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
export_fig(outname, '-png', '-nofontswap', '-a1');
set(gcf, 'color', 'w')
hgexport(f, outname)
close

rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))
    
end