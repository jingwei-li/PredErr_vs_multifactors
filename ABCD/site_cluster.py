import argparse

import pandas as pd


parser = argparse.ArgumentParser(
    description="Get the final subject list with phenotypes and cross-vaidation indices")
parser.add_argument("--conf_csv", help="Absolute path to confound data csv")
parser.add_argument("--out_csv", help="Absolute path to output csv file")
args = parser.parse_args()

data = pd.read_csv(args.conf_csv)
cluster_assign = {
    "site16": "A", "site14": "B", "site22": "B", "site19": "B", "site01": "B", "site02": "C",
    "site12": "C", "site04": "D", "site15": "D", "site06": "E", "site07": "E", "site03": "F",
    "site08": "F", "site20": "G", "site18": "G", "site21": "H", "site05": "H", "site13": "I",
    "site11": "I", "site10": "J", "site09": "J"}

if "site_id_l" in data.columns:
    site_clusters = dict.fromkeys(data["participant_id"].to_list())
    for _, data_row in data.iterrows():
        site_clusters[data_row["participant_id"]] = cluster_assign[data_row["site_id_l"]]
    data = data.join(pd.Series(site_clusters).rename("site-cluster"), on="participant_id")
    data.drop(columns=["site_id_l"], inplace=True)
    data.to_csv(args.out_csv)
else:
    print("Site data already processed.")
