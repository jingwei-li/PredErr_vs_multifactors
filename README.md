# Prediction bias related to individual characteristics

## References
t.b.a.

## Code Release
Our original code for data processing and analysis are contained in the following folders:

- `ABCD`: scripts for censoring, brain feature extraction, and phenotype extraction from the ABCD dataset
- `HCP-D`: scripts for extracting brain features, confounds, and phenotypes from the HCP Development dataset
- `HCP`: scripts for extracting brain features, confounds, and phenotypes from the HCP Young Adult dataset
- `prediction`: scripts for performing behaviour prediction, clustering behavioural phenotypes based on prediction error, and computing summary errors for the behavioural clusters
- `association`: scripts for multivariate (GLM) association analysis and covariate association analysis.

For replication instructions, refer to the README files inside each folder. 

For the ABCD cohort, we ran fMRIPrep on the raw data before any analysis in this project. For the HCP and HCP-D cohorts, the resting-state functional connectivity features were computed in another project (see https://github.com/jadecci/mpp for more details).
