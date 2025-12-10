## Univariate association (prediction error vs. covariates)
### HCP Development

```bash
pred_dir=${proj_dir}/results/HCP-D/cbpp/432sub_22behaviors
list_dir=${proj_dir}/results/HCP-D/lists
data_dir=${proj_dir}/data/datasets_repo/original/hcp/hcp_development/phenotype
outdir=${proj_dir}/results/HCP-D/univariate_association
for method in SVR KRR; do
    matlab914 -singleCompThread -batch \
        "PredErr_vs_covariate('HCP-D', '$method', '$pred_dir', '$list_dir', '$data_dir', '$outdir', 0)"
done
```

### HCP Young Adult

This also runs the subsampling analysis.

```bash
pred_dir=${proj_dir}/results/HCP/cbpp/784sub_51behaviors
list_dir=${proj_dir}/results/HCP/lists
data_dir=${proj_dir}/data
outdir=${proj_dir}/results/HCP/univariate_association
for method in SVR KRR; do
    matlab914 -singleCompThread -batch \
        "PredErr_vs_covariate('HCP', '$method', '$pred_dir', '$list_dir', '$data_dir', '$outdir', 1)"
done
```

### ABCD

This also runs the subsampling analysis.

```bash
pred_dir=${proj_dir}/results/ABCD/cbpp/4278sub_34behaviors
list_dir=${proj_dir}/results/ABCD/lists
data_dir=${proj_dir}/data/datasets_repo/original/abcd/phenotype/phenotype
outdir=${proj_dir}/results/ABCD/univariate_association
for method in SVR KRR; do
    matlab914 -singleCompThread -batch \
        "PredErr_vs_covariate('ABCD', '$method', '$pred_dir', '$list_dir', '$data_dir', '$outdir', 1)"
done
```
