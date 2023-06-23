function ABCD_PredErr_vs_motion(subj_ls, avgPredErr, outdir, Xlabels, pheno_csv)

% ABCD_PredErr_vs_motion(subj_ls, avgPredErr, outdir, Xlabels, pheno_csv)
%
% Compulsory inputs:
%   - subj_ls
%     Full path to the subject list. The subjects should be corresponded to the prediction
%     errors provided by `avgPredErr`.
%
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `ABCD_avgPredErr`.
%
%   - outdir
%     Full path to output directory.
%
%   - Xlabels
%     A cell array contains the X-axis names for each behavioral cluster. The number of
%     entries in `Xlabels` should be the same with the number of fields in the `err_arg` structure
%     passed in by `avgPredErr` variable.
%     Example: Xlabels = {'Verbal Memory', 'Cognition', 'Mental Rotation', 'CBCL', 'Prodromal Psychosis'};
%
%   - pheno_csv
%     Full path to the CSV file containing FD and DVARS of all subjects.
%

load(avgPredErr)
d = readtable(pheno_csv);
subjects = CBIG_text2cell(subj_ls);
[~,~,idx] = intersect(subjects, d.subjectkey, 'stable');

FD = d.FD(idx);
DV = d.DVARS(idx);

Ylabel = 'FD';
outbase = 'PredErr_vs_FD';
ABCD_scatter_PredErr_vs_other_var(err_avg, FD, outdir, outbase, Xlabels, Ylabel, -0.5)

Ylabel = 'log(FD)';
outbase = 'PredErr_vs_logFD';
ABCD_scatter_PredErr_vs_other_var(err_avg, log(FD), outdir, outbase, Xlabels, Ylabel, -0.5)

Ylabel = 'DVARS';
outbase = 'PredErr_vs_DV';
ABCD_scatter_PredErr_vs_other_var(err_avg, DV, outdir, outbase, Xlabels, Ylabel, 1)

end