function HCP_avgPredErr(model_dir, full_bhvr_ls, bhvr_cls_csv, PredErr_in, PredErr_out)

% HCP_avgPredErr(mode_dir, full_bhvr_ls, bhvr_cls_csv, PredErr_in, PredErr_out)
%
% 
    
[bhvr_nm, nbhr] = CBIG_text2cell(full_bhvr_ls);
T = readtable(bhvr_cls_csv, 'Delimiter', ',', 'headerlines', 0);
headers = T.Properties.VariableNames;
all_err = load(PredErr_in);

for c = 1:length(headers)
    bhvr_cls = T.(headers{c});
    bhvr_cls = bhvr_cls(~cellfun('isempty', bhvr_cls));
    err_norm.(headers{c}) = [];
    for b = 1:length(bhvr_cls)
        load(fullfile(model_dir, ['y_' bhvr_cls{b} '.mat']));
        idx = strcmp(bhvr_nm, bhvr_cls{b});
        err_norm.(headers{c}) = [err_norm.(headers{c}) mean(all_err.err(:,idx,:),3) ./ std(y, 1)];
    end
    err_avg.(headers{c}) = mean(abs(err_norm.(headers{c})), 2);
end

save(PredErr_out, 'err_norm', 'err_avg', 'T')

end