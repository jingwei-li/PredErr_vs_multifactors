import pandas as pd
import argparse
import os, copy


parser = argparse.ArgumentParser(description="Extract psychometric and confounding variables for HCP-Development",
                                 formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, width=100))
parser.add_argument("--unres_csv", type=str, help="Absolute path to HCP unrestricted phenotype csv")
parser.add_argument("--res_csv", type=str, help="Absolute path to HCP restricted phenotype csv")
parser.add_argument("--sub_list", type=str, help="Absolute path to the subject list")
parser.add_argument("--ICV_txt", type=str, help="Absolute path to the text file of all subjects' intracranial volume")
parser.add_argument("--FD_txt", type=str, help="Absolute path to the text file of all subjects' framewise displacement")
parser.add_argument("--DV_txt", type=str, help="Absolute path to the text file of all subjects' DVARS")
parser.add_argument("--psy_csv", type=str,  
                    help="A csv file with psychometric measures. The headers in this csv file are the phenotype filenames from HCP-D dataset.")
parser.add_argument('--colloq_csv', type=str,
                    help='A csv file with colloquial names of the psychometric measures one-to-one corresponded to "psy_csv".')
parser.add_argument("--out_dir", dest="out_dir", type=str, 
                    help="Absolute path to the output directory")
args = parser.parse_args()

data = pd.read_csv(args.sub_list, header=None, names=['Subject'])
subjects = copy.deepcopy(data)

# Psychometric variables
psy = pd.read_csv(args.psy_csv, header=None).squeeze().to_list()
colloq = pd.read_csv(args.colloq_csv).squeeze().to_dict()

# Unrestricted confounding variables: gender
data_unres = pd.read_csv(args.unres_csv, usecols=psy+["Gender", "Subject"], index_col="Subject")
data_unres = data_unres.rename(columns=colloq)

# Restricted confounding variables: age, education
data_res = pd.read_csv(
    args.res_csv, usecols=["Subject", "Age_in_Yrs", "SSAGA_Educ"], index_col="Subject")
data = data.merge(data_unres, how="inner", on="Subject").merge(data_res, how="inner", on="Subject")
data = data.dropna()

# Edit confounding variables
conf_list = ["Age_in_Yrs", "FD", "DVARS", "ICV"]
conf_list_drop = []
conf_list_pred = ["Age_in_Yrs", "Gender", "SSAGA_Educ", "FD", "DVARS", "ICV"]
new_data = pd.get_dummies(data["Gender"]).astype(int)
for c in new_data.columns:
    data["Gender"+'_'+c] = new_data[c]
    conf_list.append("Gender"+'_'+c)
    conf_list_drop.append("Gender"+'_'+c)
data["Gender"] = data["Gender"].astype("category").cat.codes
new_data = pd.get_dummies(data["SSAGA_Educ"]).astype(int)
for c in new_data.columns:
    data["Educ"+'_'+str(c)] = new_data[c]
    conf_list.append("Educ"+'_'+str(c))
    conf_list_drop.append("Educ"+'_'+str(c))
data["SSAGA_Educ"] = data["SSAGA_Educ"].astype("category").cat.codes

#!!!!! need to fix subject ordering!!!
print(subjects)
with open(args.FD_txt, 'r') as f:
    FD = f.readlines()
    FD = [float(line.rstrip()) for line in FD]
subjects["FD"] = FD

with open(args.DV_txt, 'r') as f:
    DV = f.readlines()
    DV = [float(line.rstrip()) for line in DV]
subjects["DVARS"] = DV

with open(args.ICV_txt, 'r') as f:
    ICV = f.readlines()
    ICV = [float(line.rstrip()) for line in ICV]
subjects["ICV"] = ICV

subjects.drop(subjects.loc[subjects["FD"]==0].index, inplace=True)
subjects.drop(subjects.loc[subjects["DVARS"]==0].index, inplace=True)

data = data.merge(subjects, how='inner', on="Subject")
data_split = data.copy()
data_split.drop(columns=['Gender', 'SSAGA_Educ'], inplace=True)
data.drop(columns=conf_list_drop, inplace=True)

# save outputs separately
colnames = [colname for colname in colloq.values()]
data[['Subject']+colnames].to_csv((args.out_dir + '/HCP_y.csv'), index=None)
data[['Subject']+conf_list_pred].to_csv((args.out_dir + '/HCP_conf.csv'), index=None)
data_split[['Subject']+conf_list].to_csv((args.out_dir + '/HCP_conf_split.csv'), index=None)
data[['Subject']].to_csv(args.out_dir + '/sublist_allbehavior.csv', index=None, header=None)
with open(os.path.join(args.out_dir, 'confound_list.txt'), 'w') as f:
    for item in conf_list:
        f.write("%s\n" % item)

print(data[['Subject']+conf_list_pred])
