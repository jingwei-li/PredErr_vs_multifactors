function generalise_data_proc(dataset, atlas, in_dir, conf_dir, psy_file, conf_file, out_dir, sublist)
% This script processes the resting-state data with nuisance regression, followed by parcellation and functional 
%connectivity (FC) computation.
%
% ARGUMENTS:
% dataset      short-form name of the dataset/cohort. Choose from 'HCP-YA', 'eNKI-RS_fluidcog', 'eNKI-RS_openness',
%                'GSP', 'HCP-A_fluidcog' and 'HCP-A_openness'
% atlas        short-form name of the atlas to use for parcellation. Choose from 'AICHA', 'SchMel1', 'SchMel2', 
%                'SchMel3' and 'SchMel4'
% input_dir    absolute path to input directory
% conf_dir     absolute path to confounds directory
% psy_file     absolute path to the .csv file containing the psychometric variables to predict
% conf_file    absolute path to the .mat file containing the confounding variables
% output_dir   absolute path to output directory
% sublist      (optional) absolute path to custom subject list (.csv file where each line is one subject ID)
%
% OUTPUT:
% 1 output file in the output directory containing the combined FC matrix across all subjects
% For example: fc_HCP-YA_AICHA.mat
%
% Jianxiao Wu, last edited on 03-Feb-2022

if nargin < 7
    disp('Usage: generalise_data_proc(dataset, atlas, in_dir, conf_dir, psy_file, conf_file, out_dir, <sublist>)'); return
end

if nargin < 8
    sublist='';
end

script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(script_dir), 'bin', 'external_packages'));
addpath(fullfile(fileparts(script_dir), 'HCP_CBPP', 'utilities'));
atlas_dir = fullfile(fileparts(script_dir), 'bin', 'parcellations');
output = fullfile(out_dir, [dataset '_fix_wmcsf_' atlas '_Pearson.mat']);

if isfile(output)
    fprintf('Output %s already exists\n', output); return
end

switch atlas
case 'AICHA'
    nparc = 384;
case 'SchMel1'
    nparc = 100 + 16;
case 'SchMel2'
    nparc = 200 + 32;
case 'SchMel3'
    nparc = 300 + 50;
case 'SchMel4'
    nparc = 400 + 54;
otherwise
    error('Invalid atlas option'); return
end

switch dataset
case 'HCP-YA'
    if nargin < 8
        sublist = fullfile(fileparts(script_dir), 'bin', 'sublist', 'HCP_MNI_fix_wmcsf_allRun_sub.csv');
    end
    subjects = csvread(sublist);
    run = {'rfMRI_REST1_LR', 'rfMRI_REST1_RL', 'rfMRI_REST2_LR', 'rfMRI_REST2_RL'};
    fc = zeros(nparc, nparc, length(subjects));
    for sub_ind = 1:length(subjects)
        subject = num2str(subjects(sub_ind));
        for i = 1:length(run)
            input_dir = fullfile(in_dir, subject, 'MNINonLinear', 'Results', run{i});
            input = MRIread(fullfile(input_dir, [run{i} '_hp2000_clean.nii.gz']));
            dims = size(input.vol);
            input = reshape(input.vol, prod(dims(1:3)), dims(4))';
            % imaging counfounds (gx2 & reg): 
            %   WM & CSF (gx2) extracted from CAT segmented images
            %   motion parameters (reg) extracted from HCP published Movement_Regressors.txt
            load(fullfile(conf_dir, subject, 'MNINonLinear', 'Results', run{i}, ['Confounds_' subject '.mat']));
            regressors = [reg(:, 9:32) gx2([2:3], :)' [zeros(1, 2); diff(gx2([2:3], :)')]];
            [resid, ~, ~, ~] = CBIG_glm_regress_matrix(input, regressors, 1, []);
            parc_data = parcellate_MNI(atlas, resid', atlas_dir);
            fc(:, :, sub_ind) = fc(:, :, sub_ind) + FC_Pearson(parc_data);
        end
        fc(:, :, sub_ind) = fc(:, :, sub_ind) ./ length(run);
    end
case {'HCP-A_fluidcog', 'HCP-A_openness'}
    if nargin < 8
        sublist = fullfile(fileparts(script_dir), 'bin', 'sublist', [dataset '_allRun_sub.csv']);
    end
    subjects = table2array(readtable(sublist, 'ReadVariableNames', false));
    run = {'rfMRI_REST1_AP', 'rfMRI_REST1_PA', 'rfMRI_REST2_AP', 'rfMRI_REST2_PA'};
    fc = zeros(nparc, nparc, length(subjects));
    for sub_ind = 1:length(subjects)
        subject = num2str(subjects{sub_ind});
        for i = 1:length(run)
            input_dir = fullfile(in_dir, [subject '_V1_MR'], 'MNINonLinear', 'Results', run{i});
            input = MRIread(fullfile(input_dir, [run{i} '_hp0_clean.nii.gz']));
            dims = size(input.vol);
            input = reshape(input.vol, prod(dims(1:3)), dims(4))';
            % imaging counfounds (regressors): 
            %   WM & CSF extracted from HCP published Atlas_wmparc.2.nii.gz
            %   motion parameters extracted from HCP published Movement_Regressors_hp0_clean.txt
            regressors = csvread(fullfile(conf_dir, [subject '_' run{i}(7:end) '_resid0.csv']));
            regressors = zscore(regressors, [], 1);
            [resid, ~, ~, ~] = CBIG_glm_regress_matrix(input, regressors, 1, []);
            parc_data = parcellate_MNI(atlas, resid', atlas_dir);
            fc(:, :, sub_ind) = fc(:, :, sub_ind) + FC_Pearson(parc_data);
        end
        fc(:, :, sub_ind) = fc(:, :, sub_ind) ./ length(run);
    end
case {'eNKI-RS_fluidcog', 'eNKI-RS_openness'}
    if nargin < 8
        sublist= fullfile(fileparts(script_dir), 'bin', 'sublist', [dataset '_allRun_sub.csv']);
    end
    subjects = readtable(sublist);
    fc = zeros(nparc, nparc, length(subjects.Subject));
    for sub_ind = 1:length(subjects.Subject)
        subject = subjects.Subject{sub_ind};
        session = subjects.SessionRS{sub_ind};
        input_dir = fullfile(in_dir, subject, session, 'func');
        input = MRIread(fullfile(input_dir, [subject '_' session ...
                '_task-rest_acq-645_space-MNI152NLin6Asym_desc-smoothAROMAnonaggr_bold.nii.gz']));
        dims = size(input.vol);
        input = reshape(input.vol, prod(dims(1:3)), dims(4))';
        regressors = extract_confs_eNKI(conf_dir, subject, session);
        regressors = zscore(regressors, [], 1);
        [resid, ~, ~, ~] = CBIG_glm_regress_matrix(input, regressors, 1, []);
        resid = reshape(flip(reshape(resid', dims), 2), prod(dims(1:3)), dims(4)); % eNKI images got left-right flipped
        parc_data = parcellate_MNI(atlas, resid, atlas_dir);
        fc(:, :, sub_ind) = FC_Pearson(parc_data);
    end 
case 'GSP'
    if nargin < 8
        sublist = fullfile(fileparts(script_dir), 'bin', 'sublist', 'GSP_allRun_sub.csv');
    end
    subjects = csvread(sublist);
    fc = zeros(nparc, nparc, length(subjects));
    for sub_ind = 1:length(subjects)
        subject = num2str(subjects(sub_ind), '%04d');
        input = MRIread(fullfile(in_dir, ['sub-' subject], 'ses-01', ['wsub-' subject '_ses-01.nii.gz']));
        dims = size(input.vol);
        input = reshape(input.vol, prod(dims(1:3)), dims(4))';
        % imaging counfounds (gx2 & reg): 
            %   WM & CSF (gx2) extracted from CAT segmented images
            %   motion parameters (reg) extracted from SPM realignment parameter
        load(fullfile(conf_dir, ['sub-' subject], 'ses-01', ['Confounds_sub-' subject '_ses-01.mat']));
        regressors = [reg(:, 9:32) gx2([2:3], :)' [zeros(1, 2); diff(gx2([2:3], :)')]];
        [resid, ~, ~, ~] = CBIG_glm_regress_matrix(input, regressors, 1, []);
        parc_data = parcellate_MNI(atlas, resid', atlas_dir);
        fc(:, :, sub_ind) = FC_Pearson(parc_data);
    end
otherwise
    disp('Invalid dataset option.'); return
end

y = csvread(psy_file);
conf = csvread(conf_file);
output = fullfile(out_dir, [dataset '_fix_wmcsf_' atlas '_Pearson.mat']);
save(output, 'fc', 'y', 'conf');

end

function parc_data = parcellate_MNI(atlas, input, atlas_dir)

switch atlas
case 'AICHA'
    parc = MRIread(fullfile(atlas_dir, 'AICHA.nii'));  
    parc_data = extract_timeseries(parc.vol, input);
case {'SchMel1', 'SchMel2', 'SchMel3', 'SchMel4'}
    level = num2str(atlas(end));
    parc_sch = MRIread(fullfile(atlas_dir, ['Schaefer2018_' level '00Parcels_17Networks_MNI2mm.nii.gz']));
    parc_mel = MRIread(fullfile(atlas_dir, ['Tian_Subcortex_S' level '_3T.nii.gz']));
    parc_data_sch = extract_timeseries(parc_sch.vol, input);
    parc_data_mel = extract_timeseries(parc_mel.vol, input);
    parc_data = cat(1, parc_data_sch, parc_data_mel);
end

end

function parc_data = extract_timeseries(parc, input)

parcels = unique(parc);
parc_data = zeros(length(parcels)-1, size(input, 2));
for parcel_ind = 2:length(parcels)
    selected = input(parc==parcels(parcel_ind), :);
    selected(isnan(selected(:, 1))==1, :) = [];
    selected(abs(mean(selected, 2))<eps, :) = []; % non-brain voxels
    parc_data(parcel_ind-1, :) = mean(selected, 1);
end

end

function confounds = extract_confs_eNKI(in_dir, subject, session)

conf = tdfread(fullfile(in_dir, subject, session, 'func', ...
         [subject '_' session '_task-rest_acq-645_desc-confounds_regressors.tsv']));

motion = [conf.trans_x, [0; str2num(conf.trans_x_derivative1(2:end, :))], conf.trans_x_power2, ...
    [0; str2num(conf.trans_x_derivative1_power2(2:end, :))], ...
    conf.trans_y, [0; str2num(conf.trans_y_derivative1(2:end, :))], conf.trans_y_power2, ...
    [0; str2num(conf.trans_y_derivative1_power2(2:end, :))], ...
    conf.trans_z, [0; str2num(conf.trans_z_derivative1(2:end, :))], conf.trans_z_power2, ...
    [0; str2num(conf.trans_z_derivative1_power2(2:end, :))], ....
    conf.rot_x, [0; str2num(conf.rot_x_derivative1(2:end, :))], conf.rot_x_power2, ...
    [0; str2num(conf.rot_x_derivative1_power2(2:end, :))], ...
    conf.rot_y, [0; str2num(conf.rot_y_derivative1(2:end, :))], conf.rot_y_power2, ...
    [0; str2num(conf.rot_y_derivative1_power2(2:end, :))], ...
    conf.rot_z, [0; str2num(conf.rot_z_derivative1(2:end, :))], conf.rot_z_power2, ...
    [0; str2num(conf.rot_z_derivative1_power2(2:end, :))]];
signals = [conf.csf, [0; str2num(conf.csf_derivative1(2:end, :))], conf.white_matter, ...
    [0; str2num(conf.white_matter_derivative1(2:end, :))]];
confounds = [motion, signals];

end