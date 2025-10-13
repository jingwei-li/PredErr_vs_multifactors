## ABCD data processing

Raw data:
```bash
datalad clone "ria+ssh://judac.fz-juelich.de/p/data1/inm7/ria-ABCD/fmriprep_outputstore#~ABCD_fMRIprep"
```

### Subject list & data extraction

1. All subjects with raw resting-state data (N = 10038) (`abcd_subjects.txt`):

```bash
./collect_subjects_rest.sh
```

2. Subjects finished fmriprep preprocessing (also extract the run numbers):

```bash
python3 find_runs_per_sub.py --in_ls abcd_subjects.txt --out_txt abcd_preproc_runs.txt
```

3. Outlier detection (based on volumetric AROMA-denoised data), similar to Chen et al. 2022:

```bash
matlab914 -nojvm -singleCompThread \
    -batch "censor_fd_vars('abcd_preproc_runs.txt', '${proj_dir}/results/ABCD/censor')"
```

4. Exclude subjects where Philips scanner was used:

```bash
python3 remove_Philips_subjects.py --in_ls abcd_subjects_censor_passed.txt \
    --out_ls abcd_subjects_noPhilips.txt
```

5. Subjects with all behavior data:

```bash
python3 collect_pheno.py --pheno_dir ${inm7-superds}/original/abcd/phenotype/phenotype \
    --colloq_csv ${proj_dir}/scripts/PredErr_vs_multifactors/ABCD/lists/colloquial_names.csv \
    --sublist_txt abcd_subjects_noPhilips.txt \
    --out_dir ${proj_dir}/results/ABCD/lists \
    --fs_dir ${proj_dir}/data/ABCD_freesurfer \
    --fp_dir ${proj_dir}/data/ABCD_fMRIprep/fmriprep \
    --censor_mat ${proj_dir}/results/ABCD/censor/ABCD_censor.mat
```

6. Assign subjects to site clusters

```bash
python3 site_cluster.py -- conf_csv ${proj_dir}/results/ABCD/lists/ABCD_conf.csv \
    --out_csv ${proj_dir}/results/ABCD/lists/ABCD_conf_site.csv
```

7. Extract Euler characteristic data

```bash
./ABCD_collect_Euler.sh -outdir ${proj_dir}/results/ABCD/lists -outbase_suffix allsub
```
   

### Features computation

1. Timesereis extraction:

```bash
matlab914 -nojvm -singleCompThread -batch "extract_rest_timeseries('abcd_subjects_pheno.csv')"
```

2. RSFC (Pearson's correlation) computation:

```bash
matlab914 -nojvm -singleCompThread \
    -batch "compute_RSFC_censor('${proj_dir}/results/abcd_subjects_pheno.csv')"
```