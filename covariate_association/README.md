## Covariate association
### HCP Development

```bash
list_dir=${proj_dir}/results/HCP-D/lists
data_dir=${proj_dir}/data/datasets_repo/original/hcp/hcp_development/phenotype
outdir=${proj_dir}/results/HCP-D/covariate_association
matlab914 -singleCompThread -batch \
    "covariate_association('HCP-D', '$list_dir', '$data_dir', '$outdir')"
```

### HCP Young Adult

```bash
list_dir=${proj_dir}/results/HCP/lists
data_dir=${proj_dir}/data
outdir=${proj_dir}/results/HCP/covariate_association
matlab914 -singleCompThread -batch \
    "covariate_association('HCP', '$list_dir', '$data_dir', '$outdir')"
```

### ABCD

```bash
list_dir=${proj_dir}/results/ABCD/lists
data_dir=${proj_dir}/data/datasets_repo/original/abcd/phenotype/phenotype
outdir=${proj_dir}/results/ABCD/covariate_association
matlab914 -singleCompThread -batch \
    "covariate_association('ABCD', '$list_dir', '$data_dir', '$outdir')"
```

## Plotting heatmap

```bash
for dataset in HCP-D HCP ABCD; do
    outdir=${proj_dir}/results/${dataset}/covariate_association
    outname=${outdir}/covar_assoc
    inmat=${outname}.mat
    matlab914 -singleCompThread -batch "heatmap_covariates_corr('$inmat', '$outname')"
done
```