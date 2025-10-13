function censor_use_motion_mask(subj_ls, out_dir)
% censor_use_motion_mask(subj_ls, out_dir)
%
% Input:
%
% - subj_ls
%   Subject list who have preprocessed resting-state fMRI data.
%
% - out_dir
%   Output directory
%

start_dir = pwd;
proj_dir = '/data/project/parcellate_ABCD_preprocessed';
data_dir = fullfile(proj_dir, 'data', 'ABCD_fMRIprep', 'fmriprep');
subjects = readtable(subj_ls, "Format", "%s%s%s%s%s%s%s%s%s%s");
ses = 'ses-baselineYear1Arm1';
tr = 0.8; % seconds
log = fopen(fullfile(out_dir, 'ABCD_censor.log'), 'w');

subjects_pass = {};
pass_runs = cell(1, size(subjects, 1)); 
unpass_runs = cell(1, size(subjects, 1)); 
for i = 1:size(subjects, 1)
    s = char(subjects{i, 1});
    n_runs = sum(~cellfun(@isempty, subjects{i, 2:end}));
    if n_runs == 0
        continue
    else
        pass_runs{i} = {}; unpass_runs{i} = {}; data_remain = 0;

        cd(data_dir);
        system(sprintf('datalad get -n %s', s));
        system(sprintf('git -C %s config --local --add remote.datalad.annex-ignore true', s));
        cd(fullfile(data_dir, s, ses, 'func'));

        for j = 1:n_runs
            runnum = ['run-' char(subjects{i, j+1})];
            mt_tsv = [s '_' ses '_task-rest_' runnum '_desc-confounds_timeseries.tsv'];
            system(sprintf('datalad get %s', mt_tsv));
            if ~isfile(mt_tsv)
                fprintf(log, '%s %s: motion file does not exist.\n', s, runnum);
                unpass_runs{i} = [unpass_runs{i} {runnum}];
                continue
            end

            mt_conf = readtable(mt_tsv, "FileType", "text", "Delimiter", "\t");
            n_frames = size(mt_conf, 1);
            if (n_frames < 50)  % check for extremely low number of frames
                fprintf(log, '%s %s: only has %i frames \n', s, runnum, n_frames);
                unpass_runs{i} = [unpass_runs{i} {runnum}];
                continue
            end

            [curr_outliers, frame_start] = find_outliers(mt_conf);
            dlmwrite(fullfile(out_dir, [s '_' ses '_task-rest_' runnum '_outliers.txt']), ...
                curr_outliers);
            frame_thresh = (n_frames - frame_start + 1) / 2;
            frames_remain = n_frames - frame_start + 1 - sum(curr_outliers);
            if (frames_remain < frame_thresh)
                fprintf(log, '%s %s: has less than 50%% frames left (%i). \n', s, runnum, ...
                    frames_remain);
                unpass_runs{i} = [unpass_runs{i} {runnum}];
            else
                data_remain = data_remain + frames_remain;
                pass_runs{i} = [pass_runs{i} {runnum}];
            end
        end

        min_remain = data_remain * tr / 60;
        if (min_remain >= 4)
            subjects_pass = [subjects_pass {s}];
        else
            fprintf(log, '%s: %.2f minutes left in total, \n', s, min_remain);
        end
    end
    cd(data_dir);
    system(sprintf('datalad drop -r %s', s));
end

subjects_all = table2cell(subjects);
save(fullfile(out_dir, "ABCD_censor.mat"), 'subjects', 'subjects_all', 'subjects_pass', ...
    'pass_runs', 'unpass_runs');
writecell(subjects_pass', fullfile(out_dir, "abcd_subjects_censor_passed.txt"));

end

function [outliers, frame_start] = find_outliers(mt_conf)
    % FD_thr = 0.3, DVARS_thr = 50, skip frames of non-steady state
    if ismember("non_steady_state_outlier00", mt_conf.Properties.VariableNames)
        frame_start = sum(mt_conf.non_steady_state_outlier00) + 1;
    else
        frame_start = 1;
    end
    fd_outliers = mt_conf.rmsd(frame_start:end) > 0.3;
    dvars_outliers = mt_conf.dvars(frame_start:end) > 50;

    % remove 1 frame before and 2 frames after
    fd_censor = (fd_outliers | [fd_outliers(2:end); 0] | [0; fd_outliers(1:(end-1))] | ...
        [0; 0; fd_outliers(1:(end-2))]);
    dvars_censor = (dvars_outliers | [dvars_outliers(2:end); 0] | ...
        [0; dvars_outliers(1:(end-1))] | [0; 0; dvars_outliers(1:(end-2))]);

    common_outliers = fd_censor | dvars_censor;

    % fill segments with less than 5 contiguous volumes
    outliers = common_outliers;
    outlier_ind = find(common_outliers);
    for i = 2:size(outlier_ind, 1)
        if (outlier_ind(i) - outlier_ind(i-1) + 1 < 5)
            outliers(outlier_ind(i-1):outlier_ind(i)) = 1;
        end
    end
end
