function heatmap_covariates_corr(input_mat, figout)
% heatmap_covariates_corr(input_mat, figout)
%
% Plot three matrices in one figure: correlation among continuous covariates,
% Cramer's V among categorical covariates, and logistic regression accuracy
% using each continuous covariate to predict every categorical covariate.
%
%   - input_mat
%     Path to input .mat file. It is the output of <dataset>_covariates_association.m
%     It should contain three struct variables: `continuous`, `categoric`, and `cont_cate`.
%     `continuous` should contain field names `names` and `corr`.
%     `categoric` should contain field names `names` and `CramerV`.
%     `cont_cate` should contain field names `names1`, `names2`, and `acc`.
%   - figout
%     Filename of output figure, without extension.
%

addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

load(input_mat)

f = figure;
set(gcf, 'position', [0 0 400*3 350])

%% plot continuous covariates' correlation
subplot(1,3,1);
imagesc(abs(continuous.corr));
hcb = colorbar('northoutside');
colorTitleHandle = get(hcb, 'Title');
set(colorTitleHandle, 'String', 'Absolute Pearson''s correlation', 'fontsize', 12);
clim([0,1])
set(gca, 'XTick', [1:length(continuous.names)])
set(gca, 'YTick', [1:length(continuous.names)])
set(gca, 'XTickLabel', continuous.names, 'YTickLabel', continuous.names, 'fontsize', 12)
rotateXLabels( gca(), 30 );

for i = 1:length(continuous.names)-1
    for j = (i+1):length(continuous.names)
        text(i-0.3, j, sprintf('%.3f', continuous.corr(i,j)), 'fontsize', 10, 'Color', 'w')
    end
end

%% plot categorical covariates' Cramer's V
subplot(1,3,2);
imagesc(categoric.CramerV)
hcb = colorbar('northoutside');
colorTitleHandle = get(hcb, 'Title');
set(colorTitleHandle, 'String', 'Cramer''s V', 'fontsize', 12);
clim([0,1])
set(gca, 'XTick', [1:length(categoric.names)])
set(gca, 'YTick', [1:length(categoric.names)])
set(gca, 'XTickLabel', categoric.names, 'YTickLabel', categoric.names, 'fontsize', 12)
rotateXLabels( gca(), 30 );

for i = 1:length(categoric.names)-1
    for j = (i+1):length(categoric.names)
        text(i-0.3, j, sprintf('%.3f', categoric.CramerV(i,j)), 'fontsize', 10, 'Color', 'w')
    end
end

%% plot logistic regression accuracy predicting a categorical covariate from a continuous covariate
subplot(1,3,3);
imagesc(cont_cate.acc)
hcb = colorbar('northoutside');
colorTitleHandle = get(hcb, 'Title');
set(colorTitleHandle, 'String', 'Logistic regression accuracy', 'fontsize', 12);
clim([0,1])
set(gca, 'XTick', [1:length(cont_cate.names2)])
set(gca, 'YTick', [1:length(cont_cate.names1)])
set(gca, 'XTickLabel', cont_cate.names2, 'YTickLabel', cont_cate.names1, 'fontsize', 12)
rotateXLabels( gca(), 30 );

for i = 1:length(cont_cate.names1)
    for j = 1:length(cont_cate.names2)
        text(j-0.3, i, sprintf('%.3f', cont_cate.acc(i,j)), 'fontsize', 10, 'Color', 'w')
    end
end

%% output
export_fig(figout, '-png', '-nofontswap', '-a1');
set(gcf, 'color', 'w')
hgexport(f, figout)
close

rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

end