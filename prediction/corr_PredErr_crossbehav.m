function corr_PredErr_crossbehav(dataset, method, colloq_txt, cbpp_dir, outmat)
    % corr_PredErr_corssbehav(dataset, method, colloq_txt, cbpp_dir, outmat)

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(fileparts(script_dir), 'external_packages'));

    colloq_names = table2array(readtable(colloq_txt, 'delimiter', ',', 'ReadVariableNames', false));
    convert_fun = @(x)regexprep(x, ' +', '_');
    filestems = convert_fun(colloq_names);
    convert_fun = @(x)regexprep(x, '/+', '-');
    filestems = convert_fun(filestems);
    nbhvr = length(filestems);

    for i = 1:nbhvr
        matname = fullfile(cbpp_dir, ['wbCBPP_' method '_standard_' filestems{i} '_SchMel4.mat']);
        load(matname)
        if strcmp(dataset, "HCP-D")
            err(:, i) = abs(yt - yp)';
        elseif strcmp(dataset, "HCP")
            err(:, i) = abs(mean(yt, 1) - mean(yp, 1))';
        elseif strcmp(dataset, "ABCD")
            err(:, i) = abs(mean(yt, 1, 'omitmissing') - mean(yp, 1, 'omitmissing'))';
        end
    end

    pair = 1;
    for b1 = 1:(nbhvr-1)
        nan_idx1 = find(isnan(err(:, b1)));
        for b2 = (b1+1):nbhvr
            bhvr_pair(pair) = strcat(colloq_names{b1}, ", ", colloq_names{b2});
            nan_idx2 = find(isnan(err(:, b2)));
            idx = setdiff(1:size(err, 1), union(nan_idx1, nan_idx2));
            err_corr(pair) = CBIG_corr(err(idx,b1), err(idx,b2));
            pair = pair+1;
        end
    end

    outdir = fileparts(outmat);
    if(~exist(outdir, 'dir'))
        mkdir(outdir);
    end
    save(outmat, 'err', 'bhvr_pair', 'err_corr');   

end
