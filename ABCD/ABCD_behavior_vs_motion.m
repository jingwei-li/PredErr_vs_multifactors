function ABCD_behavior_vs_motion(subj_ls, avgBehavior, outdir, Xlabels, pheno_csv)

% ABCD_behavior_vs_motion(subj_ls, avgBehavior, outdir, Xlabels, pheno_csv)
%
% Compulsory inputs:
%   - subj_ls
%     Full path to the subject list. 
%   - avgBehavior
%     Average behavioral scores from the groups of behavioral measures which share similar
%     patterns in the prediction errors. It is computed by the function `ABCD_avgBehavior.m`.
%   - outdir
%     Full path to output directory.
%   - Xlabels
%     A cell array contains the X-axis names for each behavioral cluster. The number of 
%     entries in `Xlabels` should be the same with the number of fields in the `bhvr_avg` 
%     structure passed in by `avgBehavior` variable.
%     Example: Xlabels = {'Verbal Memory', 'Cognition', 'Mental Rotation', 'CBCL', 'Prodromal Psychosis'};
%   - pheno_csv
%     Full path to the CSV file containing FD and DVARS of all subjects.
%

load(avgBehavior)
d = readtable(pheno_csv);
subjects = CBIG_text2cell(subj_ls);
[~,~,idx] = intersect(subjects, d.subjectkey, 'stable');

FD = d.FD(idx);
DV = d.DVARS(idx);

Ylabel = 'FD';
outbase = 'behavior_vs_FD';
ABCD_scatter_PredErr_vs_other_var(bhvr_avg, FD, outdir, outbase, Xlabels, Ylabel, 1)

Ylabel = 'DVARS';
outbase = 'behavior_vs_DV';
ABCD_scatter_PredErr_vs_other_var(bhvr_avg, DV, outdir, outbase, Xlabels, Ylabel, 1)

    
end