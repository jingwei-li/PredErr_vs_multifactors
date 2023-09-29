function ABCD_glm_scan(avgPredErr, outdir, Euler_lh, Euler_rh, subj_ls, my_pheno_csv)

% ABCD_glm_scan(outdir, Euler_lh, Euler_rh, subj_ls, my_pheno_csv)
%
% Build a full GLM with all scan-related covariates: Euler characteristic, ICV, and FD.
% Assess the importance of each covariate by the likelihood ratio test between the full
% model and the model without the examined covariate.
%
% Inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `ABCD_avgPredErr`.
%   - outdir
%     Output directory
%   - Euler_lh
%     A text file of the Euler characteristic of the left hemisphere, across all individuals.
%   - Euler_rh
%     A text file of the Euler characteristic of the right hemisphere, across all individuals.
%   - subj_ls
%     Subject list.
%   - my_pheno_csv
%     The csv file created by this set of code: 
%     https://github.com/jingwei-li/Unfairness_ABCD_process/tree/master/preparation
%

load(avgPredErr)
T = struct2table(err_avg);
N = length(fieldnames(err_avg));
for c = 1:N 
    T = renamevars(T, ['class' num2str(c)], ['err_class' num2str(c)]);
end

%% read Euler characteristic
lh_euler = dlmread(Euler_lh);
rh_euler = dlmread(Euler_rh);
euler = (lh_euler + rh_euler) ./ 2;

d = readtable(my_pheno_csv);
[subjects, nsub] = CBIG_text2cell(subj_ls);
[~, ~, idx] = intersect(subjects, d.subjectkey, 'stable');
site = d.site(idx);
uq_st = unique(site);
euler_proc = zeros(size(euler));
for s = 1:length(uq_st)
    euler_st = euler(strcmp(site, uq_st{s}));
    euler_proc(strcmp(site, uq_st{s})) = euler_st - median(euler_st);
end

%% read ICV and FD
d = readtable(my_pheno_csv);
[subjects, nsub] = CBIG_text2cell(subj_ls);
[~, ~, idx] = intersect(subjects, d.subjectkey, 'stable');
ICV = d.ICV(idx);
FD = d.FD(idx);

%% write these variables to a csv file
T = addvars(T, euler_proc, ICV, FD);
T = T(~any(ismissing(T), 2), :);
writetable(T, fullfile(outdir, 'scan_related.csv'))

%% call R script
script_dir = fileparts(fileparts(mfilename('fullpath')));
rScriptFilename = fullfile(script_dir, 'glm', 'glm_scan.r');
command = sprintf('Rscript %s %s %s', rScriptFilename, fullfile(outdir, 'scan_related.csv'), ...
    outdir);
status = system(command);
if status == 0
    disp('R script executed successfully.');
else
    error('Error executing R script.');
end

    
end