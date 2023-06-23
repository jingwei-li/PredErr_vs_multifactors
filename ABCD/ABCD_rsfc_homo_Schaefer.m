function ABCD_rsfc_homo_Schaefer(scale, subj_ls, data_dir, outname)

% ABCD_rsfc_homo_Schaefer(scale, subj_ls, data_dir, outname)
%
% Compute RSFC homogeneity given a list of ABCD subjects.
%
%
%   - data_dir
%     '/mnt/isilon/CSC2/Yeolab/Data/ABCD/process/y0/rs_GSR'

if(~ischar(scale))
    scale = num2str(scale);
end

parc_dir = fullfile(getenv('CBIG_CODE_DIR'), 'stable_projects', 'brain_parcellation', ...
    'Schaefer2018_LocalGlobal', 'Parcellations', 'FreeSurfer5.3', 'fsaverage6', 'label');
lh_parc = fullfile(parc_dir, ['lh.Schaefer2018_' scale 'Parcels_17Networks_order.annot']);
rh_parc = fullfile(parc_dir, ['rh.Schaefer2018_' scale 'Parcels_17Networks_order.annot']);

lh_labels = CBIG_read_annotation(lh_parc);
rh_labels = CBIG_read_annotation(rh_parc);

subjects = CBIG_text2cell(subj_ls);
homo_out = zeros(length(subjects), 1);

for i = 1:length(subjects)
    s = subjects{i};
    fprintf('Subject: %s\n', s);

    runs = fileread(fullfile(data_dir, s, 'logs', [s '.bold']));
    runs = strsplit(runs);
    runs = runs(~cellfun(@isempty, runs));

    for j = 1:length(runs)
        r = runs{j};
        lh_mri = fullfile(data_dir, s, 'surf', ['lh.' s '_bld' r ...
            '_rest_mc_skip_residc_interp_FDRMS0.3_DVARS50_bp_0.009_0.08_fs6_sm6.nii.gz']);
        rh_mri = fullfile(data_dir, s, 'surf', ['rh.' s '_bld' r ...
            '_rest_mc_skip_residc_interp_FDRMS0.3_DVARS50_bp_0.009_0.08_fs6_sm6.nii.gz']);
        [~, lh_vol] = read_fmri(lh_mri);
        [~, rh_vol] = read_fmri(rh_mri);
        size(lh_vol)

        [lh_homo_parc, lh_labels_size] = rsfc_homo_each_parcel(lh_vol, lh_labels);
        [rh_homo_parc, rh_labels_size] = rsfc_homo_each_parcel(rh_vol, rh_labels);
        homo_parc = [lh_homo_parc; rh_homo_parc];
        labels_size = [lh_labels_size rh_labels_size];

        curr_homo = sum(labels_size*homo_parc)/sum(labels_size);
        homo_out(i,1) = homo_out(i,1) + curr_homo;
    end
    

    homo_out(i,1) = homo_out(i,1) / length(runs); 
end

outdir = fileparts(outname);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(outname, 'homo_out', '-v7.3')

end

function [homo_parc, labels_size] = rsfc_homo_each_parcel(vol, labels)

    all_nan=find(isnan(mean(vol,2))==1);  % nan vertices
    labels_size = [];
    for l = 2:max(labels)       % 1 is medial wall; 2-201 are the 200 parcels of current hemisphere
        c = l - 1;
        index_cluster = find(labels==l);
        index_cluster = setdiff(index_cluster, all_nan);
        a = vol(index_cluster,:)';  % #timepoints x #vertices
        a_std = std(a,0,1);
        idx_zerostd = find(a_std == 0);
        if(~isempty(idx_zerostd))
            a(:,idx_zerostd) = [];
            index_cluster(idx_zerostd) = [];
        end
        labels_size(1,c) = length(index_cluster);
                        
        a = bsxfun(@minus, a, mean(a, 1));  % remove mean timeseries
        a = bsxfun(@times, a, 1./sqrt(sum(a.^2, 1)));  % normalize std of timeseries
        corr_mat = a' * a;  % correlation across timepoints
        
        %% compute homogeneity
        homo_parc(c,1)=(sum(sum(corr_mat))-size(corr_mat,1)) / ...
            (size(corr_mat,1) * (size(corr_mat,1)-1));
        if(size(corr_mat,1)==1||size(corr_mat,1)==0)
            homo_parc(c,1)=0;
        end
                        
    end
end

function [fmri, vol, vol_size] = read_fmri(fmri_name)

    % [fmri, vol] = read_fmri(fmri_name)
    % Given the name of functional MRI file (fmri_name), this function read in
    % the fmri structure and the content of signals (vol).
    % 
    % Input:
    %     - fmri_name:
    %       The full path of input file name.
    %
    % Output:
    %     - fmri:
    %       The structure read in by MRIread() or ft_read_cifti(). To save
    %       the memory, fmri.vol (for NIFTI) or fmri.dtseries (for CIFTI) is
    %       set to be empty after it is transfered to "vol".
    %
    %     - vol:
    %       A num_voxels x num_timepoints matrix which is the content of
    %       fmri.vol (for NIFTI) or fmri.dtseries (for CIFTI) after reshape.
    %
    %     - vol_size:
    %       The size of fmri.vol (NIFTI) or fmri.dtseries (CIFTI).
    
    if (isempty(strfind(fmri_name, '.dtseries.nii')))
        % if input file is NIFTI file
        fmri = MRIread(fmri_name);
        vol = single(fmri.vol);
        vol_size = size(vol);
        vol = reshape(vol, prod(vol_size(1:3)), prod(vol_size)/prod(vol_size(1:3)));
        fmri.vol = [];
    else
        % if input file is CIFTI file
        fmri = ft_read_cifti(fmri_name);
        vol = single(fmri.dtseries);
        vol_size = size(vol);
        fmri.dtseries = [];
    end
    
end