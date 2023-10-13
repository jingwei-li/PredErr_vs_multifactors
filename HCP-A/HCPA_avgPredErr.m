function HCPA_avgPredErr(colloq_txt, colloq_cls_csv, pheno_in, PredErr_in, PredErr_out)

% HCPA_avgPredErr(colloq_txt, colloq_cls_csv, pheno_in, PredErr_in, PredErr_out)
%
% 

colloq_names = table2array(readtable(colloq_txt, 'delimiter', ',', 'ReadVariableNames', false));
T = readtable(colloq_cls_csv, 'Delimiter', ',', 'headerlines', 0);
headers = T.Properties.VariableNames;
all_err = load(PredErr_in);
load(pheno_in, 'y')

for c = 1:length(headers)
    bhvr_cls = T.(headers{c});
    bhvr_cls = bhvr_cls(~cellfun('isempty', bhvr_cls));
    err_norm.(headers{c}) = [];
    for b = 1:length(bhvr_cls)
        idx = strcmp(colloq_names, bhvr_cls{b});
        err_norm.(headers{c}) = [err_norm.(headers{c}) mean(all_err.err(:,idx,:),3) ./ std(y.(colloq_names{idx}), 1)];
    end
    err_avg.(headers{c}) = mean(abs(err_norm.(headers{c})), 2);
end

save(PredErr_out, 'err_norm', 'err_avg', 'T')

end