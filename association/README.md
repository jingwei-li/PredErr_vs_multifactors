## Association analysis

### Multivariate association (prediction error vs. covariates)

#### HCP Development
```bash
pred_dir=${proj_dir}/results/HCP-D/cbpp/432sub_22behaviors
list_dir=${proj_dir}/results/HCP-D/lists
data_dir=${proj_dir}/data/datasets_repo/original/hcp/hcp_development/phenotype
outdir=${proj_dir}/results/HCP-D/multivariate_association
for method in SVR KRR; do
    matlab914 -singleCompThread -batch \
        "PredErr_vs_covariate('HCP-D', '$method', '$pred_dir', '$list_dir', '$data_dir', '$outdir')"
done
```

#### HCP Young Adult

```bash
pred_dir=${proj_dir}/results/HCP/cbpp/784sub_51behaviors
list_dir=${proj_dir}/results/HCP/lists
data_dir=${proj_dir}/data
outdir=${proj_dir}/results/HCP/multivariate__association
for method in SVR KRR; do
    matlab914 -singleCompThread -batch \
        "PredErr_vs_covariate('HCP', '$method', '$pred_dir', '$list_dir', '$data_dir', '$outdir')"
done
```

#### ABCD

```bash
pred_dir=${proj_dir}/results/ABCD/cbpp/4278sub_34behaviors
list_dir=${proj_dir}/results/ABCD/lists
data_dir=${proj_dir}/data/datasets_repo/original/abcd/phenotype/phenotype
outdir=${proj_dir}/results/ABCD/multivariate__association
for method in SVR KRR; do
    matlab914 -singleCompThread -batch \
        "PredErr_vs_covariate('ABCD', '$method', '$pred_dir', '$list_dir', '$data_dir', '$outdir')"
done
```

Finally, see `plot_glm_parcats.ipynb` for the plotting of figures.

### Covariate association
#### HCP Development

```bash
list_dir=${proj_dir}/results/HCP-D/lists
data_dir=${proj_dir}/data/datasets_repo/original/hcp/hcp_development/phenotype
outdir=${proj_dir}/results/HCP-D/covariate_association
matlab914 -singleCompThread -batch \
    "covariate_association('HCP-D', '$list_dir', '$data_dir', '$outdir')"
```

#### HCP Young Adult

```bash
list_dir=${proj_dir}/results/HCP/lists
data_dir=${proj_dir}/data
outdir=${proj_dir}/results/HCP/covariate_association
matlab914 -singleCompThread -batch \
    "covariate_association('HCP', '$list_dir', '$data_dir', '$outdir')"
```

#### ABCD

```bash
list_dir=${proj_dir}/results/ABCD/lists
data_dir=${proj_dir}/data/datasets_repo/original/abcd/phenotype/phenotype
outdir=${proj_dir}/results/ABCD/covariate_association
matlab914 -singleCompThread -batch \
    "covariate_association('ABCD', '$list_dir', '$data_dir', '$outdir')"
```

### Plotting heatmap

```bash
for dataset in HCP-D HCP ABCD; do
    outdir=${proj_dir}/results/${dataset}/covariate_association
    outname=${outdir}/covar_assoc
    inmat=${outname}.mat
    matlab914 -singleCompThread -batch "heatmap_covariates_corr('$inmat', '$outname')"
done
``` 
