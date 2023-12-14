function HCPD_avgBehavior(colloq_txt, colloq_cls_csv, pheno_in, outmat)

% - colloq_txt
%   e.g. /data/project/predict_stereotype/new_scripts/PredErr_vs_multifactors/HCP-D/lists/colloquial_list3.txt
% - colloq_cls_csv
%   e.g. /data/project/predict_stereotype/new_results/HCP-D/lists/22behaviors_colloquial_list_absErrCorr_above0.3.csv
% - pheno_in
%   e.g. /data/project/predict_stereotype/new_results/HCP-D/cbpp/455sub_22behaviors/HCPD_fix_resid0_SchMel4_Pearson.mat
% - outmat
%   e.g. /data/project/predict_stereotype/new_results/HCP-D/avgBehavior/22behaviors_class_absErrCorr_above0.3.mat
%

colloq_names = table2array(readtable(colloq_txt, 'delimiter', ',', 'ReadVariableNames', false));
T = readtable(colloq_cls_csv, 'Delimiter', ',', 'headerlines', 0);
headers = T.Properties.VariableNames;
load(pheno_in, 'y')

for c = 1:length(headers)
    bhvr_cls = T.(headers{c});
    bhvr_cls = bhvr_cls(~cellfun('isempty', bhvr_cls));

    bhvr1 = (y.(bhvr_cls{1}) - mean(y.(bhvr_cls{1}))) ./ std(y.(bhvr_cls{1}), 1);
    bhvr_avg.(headers{c}) = bhvr1;

    for b = 2:length(bhvr_cls)
        curr_bhvr = (y.(bhvr_cls{b}) - mean(y.(bhvr_cls{b}))) ./ std(y.(bhvr_cls{b}), 1);
        curr_corr = corr(bhvr1, curr_bhvr);
        fprintf('Class %d: corr(behavior1, behavior%d) = %f\n', c, b, curr_corr)
        if(curr_corr >= 0)
            bhvr_avg.(headers{c}) = bhvr_avg.(headers{c}) + curr_bhvr;
        else
            bhvr_avg.(headers{c}) = bhvr_avg.(headers{c}) + curr_bhvr .* -1;
        end
    end
    bhvr_avg.(headers{c}) = bhvr_avg.(headers{c}) ./ length(bhvr_cls);
end

outdir = fileparts(outmat);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(outmat, 'bhvr_avg')

end