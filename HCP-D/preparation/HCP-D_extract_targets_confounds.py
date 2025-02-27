import pandas as pd
import argparse
import os, copy
import datalad.api as dl

def isNaN(string):
    return string != string

def add_data(in_dir, in_file, col, sub_col, colname, coltype, data, comqother=None):
    input = in_dir + '/' + in_file
    dl.get(input, dataset=os.path.dirname(in_dir), source='inm7-storage', on_failure='stop')
    coltypes = {'src_subject_id': str, colname: coltype}
    colnames = ['Sub_Key', colname]

    df = pd.read_table(input, sep='\t', skiprows=[1])
    if (isinstance(col, str)):
        col = df.columns.get_loc(col)
    if comqother:
        comqother_col = df.columns.get_loc('comqother')

    if not comqother:
        data_curr = pd.read_table(input, sep='\t', header=0, skiprows=[1], usecols=[sub_col, col], dtype=coltypes, 
                                     names=colnames)
        data_curr = data_curr.dropna().reset_index(drop=True).drop_duplicates(subset='Sub_Key')
    else:
        coltypes['comqother'] = str
        colnames.append('comqother')
        data_curr = pd.read_table(input, sep='\t', header=0, skiprows=[1], usecols=[sub_col, col, comqother_col], dtype=coltypes, 
                                     names=colnames)
        data_curr = data_curr[data_curr['comqother']==comqother]
        data_curr = data_curr.drop(columns=['comqother'])
        
    data = data.merge(data_curr, how='inner', on='Sub_Key')
    
    return data

parser = argparse.ArgumentParser(description="Extract psychometric and confounding variables for HCP-Development",
                                 formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, width=100))
parser.add_argument("--in_dir", type=str, help="Absolute path to input directory")
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

data = pd.read_csv(args.sub_list, header=None, names=['Sub_Key'])
data["Sub_Key"] = data["Sub_Key"].str.removesuffix("_V1_MR")
subjects = copy.deepcopy(data)
# Psychometric variables
colnames = []
psy = pd.read_csv(args.psy_csv)
colloq = pd.read_csv(args.colloq_csv)
for c in psy.columns:   # headers are the phenotype tsv names.
    i = 0
    while i<len(psy[c]):
        n1 = psy[c][i]
        n2 = colloq[c][i]
        if (not isNaN(n1)):
            print(n1,n2)
            if c=='bisbas01' or c=='upps01':
                data = add_data(args.in_dir, c+'.txt', n1, 4, n2, float, data, 'caregiver about child subject')
            else:
                data = add_data(args.in_dir, c+'.txt', n1, 4, n2, float, data)
            colnames.append(n2)
        i+=1
    print(data)


# Confounding variables
conf_list = ['interview_age', 'sex', 'site', 'education', 'FD', 'DVARS', 'ICV']
conf_list_new = ['interview_age']
data = add_data(args.in_dir, 'ndar_subject01.txt', 6, 4, conf_list[0], float, data)
## sex
data = add_data(args.in_dir, 'ndar_subject01.txt', 7, 4, conf_list[1], str, data)
new_data = pd.get_dummies(data[conf_list[1]]).astype(int)
for c in new_data.columns:
    data[conf_list[1]+'_'+c] = new_data[c]
    conf_list_new.append(conf_list[1]+'_'+c)
data.drop(columns=[conf_list[1]], inplace=True)

## site
data = add_data(args.in_dir, 'ndar_subject01.txt', 17, 4, conf_list[2], str, data)
new_data = pd.get_dummies(data[conf_list[2]]).astype(int)
for c in new_data.columns:
    data[conf_list[2]+'_'+c] = new_data[c]
    conf_list_new.append(conf_list[2]+'_'+c)
data.drop(columns=[conf_list[2]], inplace=True)
print(data)

#data = add_data(args.in_dir, 'socdem01.txt', 61, 4, conf_list[3], str, data)
data = add_data(args.in_dir, 'socdem01.txt', 10, 4, conf_list[3], str, data)
new_data = pd.get_dummies(data[conf_list[3]]).astype(int)
for c in new_data.columns:
    data[conf_list[3]+'_'+c.replace(" ", "_").replace(',','')] = new_data[c]
    conf_list_new.append(conf_list[3]+'_'+c.replace(" ", "_").replace(',',''))
data.drop(columns=[conf_list[3]], inplace=True)

#!!!!! need to fix subject ordering!!!
with open(args.FD_txt, 'r') as f:
    FD = f.readlines()
    FD = [float(line.rstrip()) for line in FD]
subjects[conf_list[4]] = FD
conf_list_new.append('FD')

with open(args.DV_txt, 'r') as f:
    DV = f.readlines()
    DV = [float(line.rstrip()) for line in DV]
subjects[conf_list[5]] = DV
conf_list_new.append('DVARS')

with open(args.ICV_txt, 'r') as f:
    ICV = f.readlines()
    ICV = [float(line.rstrip()) for line in ICV]
subjects[conf_list[6]] = ICV
conf_list_new.append('ICV')

print(subjects.loc[subjects[conf_list[4]]==0].index)
print(subjects.shape)
subjects.drop(subjects.loc[subjects[conf_list[4]]==0].index, inplace=True)
subjects.drop(subjects.loc[subjects[conf_list[5]]==0].index, inplace=True)
print(subjects.shape)

data = data.merge(subjects, how='inner', on='Sub_Key')
print(data)


# save outputs separately
data[['Sub_Key']+colnames].to_csv((args.out_dir + '/HCP-D_y.csv'), index=None)
data[['Sub_Key']+conf_list_new].to_csv((args.out_dir + '/HCP-D_conf.csv'), index=None)
data[['Sub_Key']].to_csv(args.out_dir + '/sublist_allbehavior.csv', index=None, header=None)
with open(os.path.join(args.out_dir, 'confound_list.txt'), 'w') as f:
    for item in conf_list_new:
        f.write("%s\n" % item)
