function ABCD_PredErr_vs_motion_subsample(subj_ls, pheno_csv, avgPredErr, bhvr_cls_names, outmat, figout, s_size, repeats)

% ABCD_PredErr_vs_motion_subsample(subj_ls, pheno_csv, avgPredErr, bhvr_cls_names, outmat, figout, s_size, repeats)
%
%   - subj_ls
%     Full path to the subject list. The subjects should be corresponded to the prediction
%     errors provided by `avgPredErr`.
%   - pheno_csv
%     Full path to the CSV file containing FD and DVARS of all subjects. It was created by 
%     this set of code: https://github.com/jingwei-li/Unfairness_ABCD_process/tree/master/preparation
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `ABCD_avgPredErr`.
%   - bhvr_cls_names
%     A cell array contains the X-axis names for each behavioral cluster. The number of entries 
%     in `bhvr_cls_names` should be the same with the number of fields in the `asso` structure.
%     Example: bhvr_cls_names = {'Verbal Memory', 'Cognition', 'Mental Rotation', 'CBCL', 'Prodromal Psychosis'};
%   - outmat
%     Output mat file (without extension and suffix, the script will add suffix itself). 
%     It will contain a struct variable. Each field will be the bootstrapped 
%     association between prediction error of one behavioral class with the given covariate.
%   - figout
%     Output name (without extension, full-path).
%   - s_size
%     Size of each subsample.
%   - repeats
%     Number of repetitions of subsampling.
%

addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))

outdir = fileparts(outmat);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
outdir = fileparts(figout);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end

load(avgPredErr)
d = readtable(pheno_csv);
subjects = CBIG_text2cell(subj_ls);
[~,~,idx] = intersect(subjects, d.subjectkey, 'stable');

FD = d.FD(idx);
DV = d.DVARS(idx);

asso = subsample_PredErr_vs_continuous_covar(err_avg, FD, s_size, repeats);
save([outmat 'FD.mat'], 'asso')

hist_subsample_rho(asso, bhvr_cls_names, [figout 'FD'])
hist_subsample_pval(asso, bhvr_cls_names, [figout 'FD'])

asso = subsample_PredErr_vs_continuous_covar(err_avg, DV, s_size, repeats);
save([outmat 'DV.mat'], 'asso')

hist_subsample_rho(asso, bhvr_cls_names, [figout 'DV'])
hist_subsample_pval(asso, bhvr_cls_names, [figout 'DV'])
    
rmpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))

end