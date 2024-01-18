#%% ###
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

# %% Babies bacteroides

def strip_space(stringg):
    string_to_return = stringg.strip()
    return string_to_return

def determine_taxa_name(stringg):
    string_to_return = stringg.split('_')[2]
    return string_to_return
# %% Merge silhouette score and v-measure score files

base_dir = "C:/Users/mathr/Documents/GitHub/babies_mg/otu_tables_and_mapping_files/outputs/"
df_v = pd.read_csv(base_dir + "taxa_trajs_lego_interp_v-measure_results.tsv", sep='\t')
df_s = pd.read_csv(base_dir + 'babies_mg_jobs_lego5_silhouette_scores.tsv', sep='\t')

df_s['cluster_data_fn'] = df_s['cluster_data_fn'].apply(strip_space)
df_s['cluster_data'] = df_s['cluster_data_fn'].apply(determine_taxa_name)
df_v['taxa_name'] = df_v['traj_fn'].apply(determine_taxa_name)

df_merge = df_v.merge(df_s, left_on="traj_fn", right_on="cluster_data_fn")
df_merge.to_csv(base_dir + 'lego5_silhouette_v-measure_merge.tsv', sep='\t', index=False)

# %%
