function HCPD_preproc_for_CBPP(in_dir, conf_dir, psy_file, conf_file, out_dir, sublist)
% This script processes the resting-state data with nuisance regression, followed by parcellation and functional 
%connectivity (FC) computation.
%
% ARGUMENTS:
% input_dir    absolute path to input directory
% conf_dir     absolute path to confounds directory
% psy_file     absolute path to the .csv file containing the psychometric variables to predict
% conf_file    absolute path to the .mat file containing the confounding variables
% output_dir   absolute path to output directory
% sublist      absolute path to custom subject list (.csv file where each line is one subject ID)
%
% OUTPUT:
% 1 output file in the output directory containing the combined FC matrix across all subjects
% For example: HCPD_fix_resid0_SchMel4_Pearson.mat
%
% Jianxiao Wu, last edited on 03-Feb-2022


atlas = 'SchMel4';
nparc = 400 + 54;

script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(script_dir), 'external_packages', 'cbpp', 'bin', 'external_packages'));
addpath(fullfile(fileparts(script_dir), 'external_packages', 'cbpp', 'HCP_CBPP', 'utilities'));
atlas_dir = fullfile(fileparts(script_dir), 'external_packages', 'cbpp', 'bin', 'parcellations');
output = fullfile(out_dir, ['HCPD_fix_resid0_' atlas '_Pearson.mat']);

if isfile(output)
    fprintf('Output %s already exists\n', output); return
end


%% FC preprocessing
subjects = table2array(readtable(sublist, 'ReadVariableNames', false));
run = {'rfMRI_REST1_AP', 'rfMRI_REST1_PA', 'rfMRI_REST2_AP', 'rfMRI_REST2_PA'};
fc = zeros(nparc, nparc, length(subjects));
for sub_ind = 1:length(subjects)
    subject = num2str(subjects{sub_ind});
    cd(in_dir)
    system(sprintf('datalad get -n %s', [subject '_V1_MR']));
    cd(fullfile([subject '_V1_MR'], 'MNINonLinear'))
    system('datalad get -n .');
    system('git -C . config --local --add remote.datalad.annex-ignore true');
    r = 1;
    for i = 1:length(run)
        input_dir = fullfile(in_dir, [subject '_V1_MR'], 'MNINonLinear', 'Results', run{i});
        if(exist(input_dir, 'dir'))
            cd(input_dir)
            rname = [run{i} '_hp0_clean.nii.gz'];
            system(sprintf('datalad get -s inm7-storage %s', rname));
            input = MRIread(fullfile(input_dir, rname));
            dims = size(input.vol);
            input = reshape(input.vol, prod(dims(1:3)), dims(4))';
            % imaging counfounds (regressors): 
            %   WM & CSF extracted from HCP published Atlas_wmparc.2.nii.gz
            %   motion parameters extracted from HCP published Movement_Regressors_hp0_clean.txt
            regressors = csvread(fullfile(conf_dir, [subject '_' run{i} '_resid0.csv']));
            regressors = zscore(regressors, [], 1);
            [resid, ~, ~, ~] = CBIG_glm_regress_matrix(input, regressors, 1, []);
            parc_data = parcellate_MNI(atlas, resid', atlas_dir);
            fc(:, :, sub_ind) = fc(:, :, sub_ind) + FC_Pearson(parc_data);

            system(sprintf('datalad drop %s', rname));
            r = r+1;
        end
    end
    fc(:, :, sub_ind) = fc(:, :, sub_ind) ./ r;
    cd(in_dir)
    system(sprintf('datalad uninstall %s --recursive', [subject '_V1_MR']))
end

outdir = fileparts(output);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(output, 'fc');
y = readtable(psy_file, 'VariableNamingRule', 'preserve');
y = removevars(y, ['Sub_Key']);
conf = readtable(conf_file, 'VariableNamingRule', 'preserve');
conf = removevars(conf, ['Sub_Key']);
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

