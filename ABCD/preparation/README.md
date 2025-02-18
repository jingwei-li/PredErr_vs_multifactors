## ABCD data processing

Raw data:
```console
datalad clone "ria+ssh://judac.fz-juelich.de/p/data1/inm7/ria-ABCD/fmriprep_outputstore#~ABCD_fMRIprep"
```

### Subject list

1. All subjects with raw resting-state data (N = 10038) (`abcd_subjects.txt`):

```console
./collect_subjects_rest.sh
```

2. Subjects finished fmriprep preprocessing (also extract the run numbers):

```console
python3 find_runs_per_sub.py --in_ls abcd_subjects.txt --out_txt abcd_preproc_runs.txt
```

3. Outlier detection (based on volumetric AROMA-denoised data), similar to Chen et al. 2022:

```console
matlab914 -nojvm -singlecompThread \
    -batch "censor_fd_vars('abcd_preproc_runs.txt', 'results/abcd_censor')"
```

4. Exclude subjects where Philips scanner was used:

```console
python3 remove_Philips_subjects.py --in_ls abcd_subjects_censor_passed.txt \
    --out_ls abcd_subjects_noPhilips.txt
```

5. Subjects with all behavior data:

```console
python3 collect_pheno.py --pheno_dir ${inm7-superds}/original/abcd/phenotype/phenotype \
    --sublist_txt abcd_subjects_noPhilips.txt \
    --out_csv results/abcd_subjects_pheno.csv \
    --fs_dir data/ABCD_freesurfer \
    --fp_dir data/ABCD_fMRIprep/fmriprep \
    --censor_mat results/abcd_censor/ABCD_censor.mat
```

### Features computation

1. Timesereis extraction:

```console
matlab914 -nojvm -singlecompThread \
    -batch "extract_rest_timeseries('results/abcd_subjects_pheno.csv')"
```

2. RSFC (Pearson's correlation) computation:

```console
matlab914 -nojvm -singlecompThread -batch "compute_RSFC_censor('results/abcd_subjects_pheno.csv')"
```