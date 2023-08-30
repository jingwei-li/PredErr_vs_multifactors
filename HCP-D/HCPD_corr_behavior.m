function HCPD_corr_behavior(colloq_txt, in_mat, outmat)

% HCPA_corr_behavior(colloq_txt, in_mat, outmat)
%
% 

colloq_names = table2array(readtable(colloq_txt, 'delimiter', ',', 'ReadVariableNames', false));
nbhvr = length(colloq_names);
load(in_mat, 'y')

y_corr = nan(nbhvr*(nbhvr-1)/2, 1);
pair = 1;
for b1 = 1:(nbhvr-1)
    y1 = y.(colloq_names{b1});
    for b2 = (b1+1):nbhvr
        y2 = y.(colloq_names{b2});
        y_corr(pair, 1) = CBIG_corr(y1, y2);
        y_spcorr(pair, 1) = corr(y1, y2, 'Type', 'Spearman');

        pair = pair + 1;
    end
end

outdir = fileparts(outmat);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(outmat, 'y_corr', 'y_spcorr')
    
end