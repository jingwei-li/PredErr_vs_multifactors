function compute_RSFC_with_censor(sub_data_csv)
    % compute_RSFC_with_censor(sub_data_csv)
    % Compute ROI-to-ROI functional connectivity. The ROIs are defined by a combination of
    % cortical Schaefer's parcellation and subcortical Tian's parcellation at a certain scale.

    proj_dir = '/data/project/predict_stereotype';
    censor_dir = fullfile(proj_dir, 'results', 'ABCD', 'censor');
    ts_dir = fullfile(proj_dir, 'results', 'ABCD', 'parcellated_timeseries');
    outdir = fullfile(proj_dir, 'results', 'ABCD', 'rsfc_pearson');
    sub_data = readtable(sub_data_csv);
    load(fullfile(proj_dir, 'results', 'ABCD', 'censor', 'ABCD_censor.mat'));

    ses = 'ses-baselineYear1Arm1';
    for i = 1:size(sub_data, 1)
        s = sub_data.participant_id{i};
        fprintf('%i: %s\n', i, s);
        [~, s_ind] = ismember(s, subjects{:, :});
        runs = pass_runs{s_ind};
        out_name = fullfile(outdir, [s '_' ses '_RSFC_S4.mat']);

        ts_all = cell(size(runs));
        for j = 1:length(runs)
            run = runs{j};

            outlier_file = fullfile(censor_dir, [s '_' ses '_task-rest_' char(run) '_outliers.txt']);
            outliers = readmatrix(outlier_file)';
            ts_file = fullfile(ts_dir, [s '_' ses '_' char(run) '_S4_timeseries.mat']);
            ts = importdata(ts_file);

            frame_start = size(outliers, 2) - size(ts, 2) + 1;
            outliers_cut = outliers(:, frame_start:end);
            ts_all{1, j} = ts(:, outliers_cut==0);
        end

        ts_mat = cell2mat(ts_all);
        corr_mat = my_corr(ts_mat', ts_mat');
        save(out_name, 'corr_mat');
    end
end

function corr_mat = my_corr(X, Y)
    % Calculate correlation matrix between each column of two matrix.
    % 
    % 	corr_mat = my_corr(X, Y)
    % 	Input:
    % 		X: D x N1 matrix
    % 		Y: D x N2 matrix
    % 	Output:
    % 		corr_mat: N1 x N2 matrix    
    
    X = bsxfun(@minus, X, mean(X, 1));
    X = bsxfun(@times, X, 1./sqrt(sum(X.^2, 1)));
    
    Y = bsxfun(@minus, Y, mean(Y, 1));
    Y = bsxfun(@times, Y, 1./sqrt(sum(Y.^2, 1)));
    
    corr_mat = X' * Y;
end
