function extract_rest_timeseries(sub_data_csv)
    % extract_rest_timeseries(sub_data_csv)
    % Extract and average the resting-state timeseries within each parcel for every run (fsLR32k 
    % space), using the 400-parcel Schaefer atlas and the 54-parcel Melbourne atlas.

    proj_dir = '/data/project/parcellate_ABCD_preprocessed';
    addpath(genpath(fullfile(proj_dir, 'scripts', 'external', 'cifti-matlab')));
    indir = fullfile(proj_dir, 'data', 'ABCD_fMRIprep', 'fmriprep');
    outdir = fullfile(proj_dir, 'results', 'parcellated_timeseries');
    sub_data = readtable(sub_data_csv);
    load(fullfile(proj_dir, 'results', 'abcd_censor', 'ABCD_censor.mat'));

    parc_file = fullfile(proj_dir, 'data', 'SchaeferParcellations', 'HCP', 'fslr32k', 'cifti', ...
        'Schaefer2018_400Parcels_17Networks_order.dlabel.nii');
    parc_sch = ft_read_cifti(parc_file, 'mapname', 'array');
    parc_file = fullfile(proj_dir, 'data', 'Tian2020MSA', '3T', 'Subcortex-Only', ...
        'Tian_Subcortex_S4_3T.nii.gz');
    parc_mel = MRIread(parc_file);

    % loop through subjects
    ses = 'ses-baselineYear1Arm1';
    for i = 1:size(sub_data, 1)
        s = sub_data.participant_id{i};
        fprintf('%i: %s\n', i, s);
        [~, s_ind] = ismember(s, subjects{:, :});
        runs = pass_runs{s_ind};
        cd(indir);
        system(sprintf('datalad get -n %s', s));
        system(sprintf('git -C %s config --local --add remote.datalad.annex-ignore true', s));
        cd(fullfile(indir, s, ses, 'func'));

        for run = runs
            fslr_file = [s '_' ses '_task-rest_' char(run) '_space-fsLR_den-91k_bold.dtseries.nii'];
            system(sprintf('datalad get %s', fslr_file));
            fslr_sm_file = fslr_smooth(fslr_file, proj_dir, [s '_' ses '_' char(run)]);
            ts_fslr_sm = ft_read_cifti(fslr_sm_file);

            mni_file =  [s '_' ses '_task-rest_' char(run) ...
                '_space-MNI152NLin6Asym_desc-smoothAROMAnonaggr_bold.nii.gz'];
            system(sprintf('datalad get %s', mni_file));
            ts_mni = MRIread(mni_file);
            ts_mni.vol = reshape(ts_mni.vol, ...
                size(ts_mni.vol,1)*size(ts_mni.vol,2)*size(ts_mni.vol,3), size(ts_mni.vol,4));
            
            melodic_file = [s '_' ses '_task-rest_' char(run) '_desc-MELODIC_mixing.tsv'];
            system(sprintf('datalad get %s', melodic_file));
            melodic = readtable(melodic_file, "FileType", "text", "Delimiter", "\t");
            filter_file = [s '_' ses '_task-rest_' char(run) '_AROMAnoiseICs.csv'];
            system(sprintf('datalad get %s', filter_file));
            filter = readtable(filter_file);
            
            [ts_fslr_cut, ts_mni_cut, melodic_cut] = rm_nonsteady(ts_fslr_sm, ts_mni, melodic);
            ts_fslr_aroma = fslr_appply_aroma(ts_fslr_cut, melodic_cut, filter);

            mt_tsv = [s '_' ses '_task-rest_' runnum '_desc-confounds_timeseries.tsv'];
            system(sprintf('datalad get %s', mt_tsv));
            mt_conf = readtable(mt_tsv, "FileType", "text", "Delimiter", "\t");
            ts_fslr_resid, ts_mni_resid = nuisance_reg(ts_fslr_aroma, ts_mni_cut, mt_conf);

            pts = zeros(454, size(ts_fslr_resid, 2));
            for roi = 1:400
                pts(roi, :) = mean(ts_fslr_resid(parc_sch.dlabel==roi, :), 1);
            end
            for roi = 1:54
                pts(roi+400, :) = mean(ts_mni_resid.vol(find(parc_mel.vol == roi), :), 1);
            end

            save(fullfile(outdir, [s '_' ses '_' char(run) '_S4_timeseries.mat']), 'pts', '-v7.3');
            system(sprintf('datalad drop --reckless kill %s %s', fslr_file, mni_file));
            delete(fslr_sm_file);
        end        
    end
    rmpath(genpath(fullfile(proj_dir, 'scripts', 'external', 'cifti-matlab')));
end

function fslr_sm_file = fslr_smooth(fslr_file, proj_dir, prefix)
    fslr_dir = fullfile(proj_dir, 'data', 'CBIG_private', 'data', 'templates', 'surface', ...
        'fs_LR_32k');
    surf_l_file = fullfile(fslr_dir, 'fsaverage.L.midthickness_orig.32k_fs_LR.surf.gii');
    surf_r_file = fullfile(fslr_dir, 'fsaverage.R.midthickness_orig.32k_fs_LR.surf.gii');
    fslr_sm_file = fullfile(proj_dir, 'work', [prefix '_fsLR_sm.dtseries.nii']);
    system(sprintf(['wb_command -cifti-smoothing %s 6 6 COLUMN %s -left-surface %s ' ...
        '-right-surface %s -fwhm'], fslr_file, fslr_sm_file, surf_l_file, surf_r_file));
end

function [ts_fslr, ts_mni, melodic] = rm_nonsteady(ts_fslr, ts_mni, melodic)
    nonss_vol = find(all(melodic{:, :}==0, 2));
    melodic(nonss_vol, :) = [];
    ts_fslr.dtseries(:, nonss_vol) = [];
    ts_mni.vol(:, nonss_vol) = [];
end

function ts_fslr_aroma = fslr_appply_aroma(ts_fslr, melodic, filter)
    data_map = pinv(melodic{:, :}) * ts_fslr.dtseries';

    noise_design = zeros(size(melodic, 1), size(filter, 2));
    noise_map = zeros(size(filter, 2), size(ts_fslr.dtseries, 1));
    for i = 1:size(filter, 2)
        noise_design(:, i) = melodic{:, filter{:, i}};
        noise_map(i, :) = data_map(filter{:, i}, :);
    end
    
    ts_fslr_aroma = ts_fslr.dtseries - (noise_design * noise_map)';
end

function [ts_fslr_resid, ts_mni_resid] = nuisance_reg(ts_fslr, ts_mni, mt_conf)
    % global, CSF, WM, 24 motion
    regressors = [mt_conf.global_signal, mt_conf.global_signal_derivative1, ...
                  mt_conf.csf, mt_conf.csf_derivative1, ...
                  mt_conf.white_matter, mt_conf.white_matter.derivative1, ...
                  mt_conf.trans_x, mt_conf.trans_x_derivative1, ...
                  mt_conf.trans_x_power2, mt_conf.trans_x_derivative1_power2, ...
                  mt_conf.trans_y, mt_conf.trans_y_derivative1, ...
                  mt_conf.trans_y_power2, mt_conf.trans_y_derivative1_power2, ...
                  mt_conf.trans_z, mt_conf.trans_z_derivative1 ...
                  mt_conf.trans_z_power2, mt_conf.trans_z_derivative1_power2, ...
                  mt_conf.trans_x, mt_conf.trans_x_derivative1, ...
                  mt_conf.trans_x_power2, mt_conf.trans_x_derivative1_power2, ...
                  mt_conf.trans_y, mt_conf.trans_y_derivative1, ...
                  mt_conf.trans_y_power2, mt_conf.trans_y_derivative1_power2, ...
                  mt_conf.trans_z, mt_conf.trans_z_derivative1 ...
                  mt_conf.trans_z_power2, mt_conf.trans_z_derivative1_power2];

    ts_surf = single(ts_fslr)';
    [ts_fslr_resid, ~, ~, ~] = CBIG_glm_regress_matrix(ts_surf, regressors, 1. []);

    dim = size(ts_mni.vol);
    ts_vol = reshape(ts_mni.vol, prod(dim(1:3)), dim(4))';
    [ts_mni_resid, ~, ~, ~] = CBIG_glm_regress_matrix(ts_vol, regressors, 1, [])
end
