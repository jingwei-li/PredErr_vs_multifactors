function avg_PredErr(dataset, method, cbpp_dir, colloq_txt, bhvr_cls_csv, PredErr_out)
    % avg_PredErr(dataset, method, cbpp_dir, colloq_txt, bhvr_cls_csv, PredErr_out)

    colloq_names = table2array(readtable(colloq_txt, 'delimiter', ',', 'ReadVariableNames', false));
    convert_fun = @(x)regexprep(x, ' +', '_');
    filestems = convert_fun(colloq_names);
    convert_fun = @(x)regexprep(x, '/+', '-');
    filestems = convert_fun(filestems);
    
    T = readtable(bhvr_cls_csv, 'Delimiter', ',', 'headerlines', 0);
    headers = T.Properties.VariableNames;
    all_err = load(fullfile(cbpp_dir, strcat('corr_PredErr_', method, '.mat')));
    
    for c = 1:length(headers)
        fprintf("%i: %s\n", c, headers{c})
        bhvr_cls = T.(headers{c});
        bhvr_cls = bhvr_cls(~cellfun('isempty', bhvr_cls));
        err_norm.(headers{c}) = [];

        for b = 1:length(bhvr_cls)
            idx = find(strcmp(filestems, bhvr_cls{b}));
            fprintf("   %i: %s -> %i: %s\n", b, bhvr_cls{b}, idx, filestems{idx})
            load(fullfile(cbpp_dir, strcat('wbCBPP_', method, '_standard_', filestems{idx}, '_SchMel4.mat')));
            err_norm.(headers{c}) = [err_norm.(headers{c}) all_err.err(:,idx) ./ std(yt, 1)];
        end

        err_avg.(headers{c}) = mean(abs(err_norm.(headers{c})), 2, "omitnan");
    end
    
    save(PredErr_out, 'err_norm', 'err_avg', 'T')
end
