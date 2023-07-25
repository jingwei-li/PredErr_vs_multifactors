function HCPA_plot_accuracy(colloq_txt, cbpp_dir, outdir, outstem)

script_dir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(fileparts(script_dir), 'external_packages', 'fig_util')));

method = 'SVR';
atlas = 'SchMel4';
nrep = 100;

colloq_names = table2array(readtable(colloq_txt, 'delimiter', ',', 'ReadVariableNames', false));
convert_fun = @(x)regexprep(x, ' +', '_');
filestems = convert_fun(colloq_names);

nbhvr = length(filestems);
acc = zeros(nrep, nbhvr);
for i = 1:nbhvr
    matname = fullfile(cbpp_dir, ['wbCBPP_' method '_standard_' filestems{i} '_' atlas '.mat']);
    load(matname)
    acc(:,i) = mean(r_test, 2);
    clear r_test
end

[~, idx] = sort(mean(acc,1), 'descend');
acc = acc(:, idx);
colloq_names = colloq_names(idx);

%% plot
colormat = [200, 200, 200]./255;
f = figure('visible', 'off');
vio = violinplot(acc, [], [], 'ViolinColor', colormat, 'ShowMean', true);
for i = 1:length(vio)
    vio(i).ViolinPlot.LineWidth = 2;
    %vio(i).ScatterPlot.Marker = '.';
    vio(i).ScatterPlot.SizeData = 12;
    vio(i).MedianPlot.SizeData = 18;
end
hold on
xlimit = get(gca, 'xlim');
plot(xlimit, [0 0], ':k');
hold off

pf = get(gcf, 'position');
set(gcf, 'position', [0 0 100+50*nbhvr 900])
set(gca, 'position', [0.35 0.4 0.6 0.5])

y_label = 'Cross-validated Pearson''s r';
yl = ylabel(y_label);
set(yl, 'fontsize', 16, 'linewidth', 2)

set(gca, 'xticklabel', colloq_names, 'fontsize', 16, 'linewidth', 2);
rotateXLabels( gca(), 45 );
set(gca, 'tickdir', 'out', 'box', 'off')

if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
outname = fullfile(outdir, [outstem ]);
export_fig(outname, '-png', '-nofontswap', '-a1');
set(gcf, 'color', 'w');
hgexport(f, outname)
close

rmpath(fullfile(fileparts(script_dir), 'external_packages', 'fig_util'));

end