###
# This script is to calculate v-measure scores based on cluster results 
# and .
# 
# Author: Hilary Monaco
###

# %% Interpolate all trajectories with smoothing level 5

import numpy as np
import pandas as pd
from pathlib import Path
from glob import glob
from loclust.parse import read_trajectories
from loclust.stats import v_measure
from loclust.util import get_mdata

# %% 
base_dir_dict = {
    "C:/Users/mathr/Documents/GitHub/Sean/outputs/": ["Diet"]
}

for base_dir in base_dir_dict.keys():
    # Pre-allocate DFs for results
    df_vscore = pd.DataFrame(columns=['file_path', "traj_fn", "mdata_var", 'v_measure_score'])
    # Get list of traj files to analyze
    infp_list = glob(base_dir + "*/*.tsv")
    for mdata_cat_OI in base_dir_dict[base_dir]:

        for infp in infp_list:
            if "_R.tsv" in infp:
                continue

            traj_fn = Path(infp).name

            trajs = read_trajectories(infp)

            mdata = get_mdata(trajs)

            v_measure_score = v_measure(mdata, traj_label_key=mdata_cat_OI, assigned_key="cluster")

            with open(f'{str(Path(infp).parent)}/v_measure_score2.txt', 'w') as f:
                f.write(f'V measure score for {base_dir} is \n{v_measure_score}')
            
            results_list = [infp, traj_fn, mdata_cat_OI, v_measure_score]
            df = pd.DataFrame([results_list], columns=['file_path', 'traj_fn', 'mdata_var', 'v_measure_score'])
            df_vscore = pd.concat([df_vscore, df])

    df_vscore.to_csv(str(Path(base_dir)) + '/v-measure_scores.tsv', sep='\t', index=False)

def strip_space(stringg):
    string_to_return = stringg.strip()
    return string_to_return

def determine_taxa_name(stringg):
    string_to_return = stringg.split('_')[1]
    return string_to_return

# %% Merge silhouette score and v-measure score files

base_dir = "C:/Users/mathr/Documents/GitHub/Sean/outputs/"
df_v = pd.read_csv(base_dir + "taxa_trajs_v-measure_results.tsv", sep='\t')
df_s = pd.read_csv(base_dir + 'sean_jobs_silhouette_scores.tsv', sep='\t')

# Strip spaces from silhouette score info
df_s['cluster_data_fn'] = df_s['cluster_data_fn'].apply(strip_space)
df_s['taxa_name'] = df_s['cluster_data_fn'].apply(determine_taxa_name)

df_merge = df_v.merge(df_s, left_on="traj_fn", right_on="cluster_data_fn")
df_merge.to_csv(base_dir + 'silhouette_v-measure_merge.tsv', sep='\t', index=False)

# %%
