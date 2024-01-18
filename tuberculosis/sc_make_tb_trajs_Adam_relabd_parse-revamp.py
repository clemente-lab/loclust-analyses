# Creating TB trajs form Adam's relative abundance table
# %%
import os
import fnmatch
import numpy as np
import pandas as pd
from pathlib import Path
from copy import deepcopy
from loclust.parse import create_trajs_from_dataframe, read_trajectories, write_trajectories
from loclust.trajectory import make_trajectory
from glob import glob

# %%
base_dir = 'C:/Users/mathr/Documents/GitHub/tb_mmeds_initial/'
level = 'L6'
data_fp_orig = f'{base_dir}feature-table-all-{level}.tsv'
df = pd.read_csv(data_fp_orig, sep='\t', header=1)

# Metadata
mdata_fp_orig = f'{base_dir}20211117.bar.map.tsv'
mdata = pd.read_csv(mdata_fp_orig, sep='\t', header=0)
mdata = mdata.rename(columns = {'Unnamed: 0':'sample_ID'})

# Alpha diversity
alpha_fp_orig = f'{base_dir}alpha-diversity_rarefied_all_samples.tsv'
alpha = pd.read_csv(alpha_fp_orig, sep='\t', header=0)
# %%
df = df.set_index(['#OTU ID'])
df = df.T

df.reset_index(inplace=True)
# df = df.rename(columns = {'index':'sample_ID'})
df = df.rename(columns = {'index':'sample_ID'})
# %%
df_merged = df.merge(mdata, how='inner', left_on="sample_ID", right_on="#SampleID")
df_merged = df_merged.merge(alpha, how='inner', left_on="sample_ID", right_on="#SampleID")

# Save
# data_fp_for_trajs = f'{base_dir}otu_table_{level}_with_mdata.tsv'
data_fp_for_trajs = f'{base_dir}rel_otu_table_{level}_with_mdata.tsv'
df_merged.to_csv(data_fp_for_trajs, sep='\t', index=False)

# %% 
# Parameters for this dataset
data_fp_for_trajs = f'{base_dir}rel_otu_table_{level}_with_mdata.tsv'
data_fp = f'{data_fp_for_trajs}'
subject_ID_col = "subject_id"
time_col = "visit_c"
not_value_cols = [
    'sample_ID',
    '#SampleID',
    'BarcodeSequence',
    'LinkerPrimerSequence',
    'Amp_Well_Plate',
    'PI',
    'MSQ',
    'subject_id',
    'redcap_id',
    'drugs',
    'treatment_stop_date1',
    'treatment_stop_date2',
    'treatment_stop_date3',
    'enrolment_date',
    'recency_months',
    'bmi_less_than_18',
    'bmi_less_than_16',
    'muc_less_than_220',
    'muc_less_than_200',
    'dyspnoea',
    'hb',
    'outcome',
    'smear_grade_copy',
    'smear2_grade_copy',
    'new_outcome'
]
cross_sectional_meta_cols = [
    'Sample_Type',
    'complete_set',
    'arm_c', 
    'arm', 
    'pairs', 
    'age',
    'age_category', 
    'sex_c', 
    'sex', 
    'ethnicity_c', 
    'ethnicity', 
    'hiv', 
    'hiv_status',
    'arvs', 
    'xpert', 
    'prior_tb_c', 
    'prior_tb', 
    'alcohol_c',
    'alcohol',
    'audit_score',
    'audit_category',
    'current_smoker',
    'previous_smoker',
    'fagerstrom_score',
    'fagerstrom_category',
    'cough',
    'chestpain',
    'bmi',
    'anaemia',
    'tb_score',
    'tb_score_class',
    'tb_score_category',
    'load_ttp',
    'smear_combined',
    'smear_combined_category'
    ]
temporal_meta_cols = [
    'tempus_shipment', 
    'visit_c', 
    'visit', 
    'default', 
    'adverse_events',
    'antibiotics',
    'smear_result',
    'smear_grade',
    'smear2_result',
    'smear2_grade',
    'mgit',
    'ttp',
    'mgit_2',
    'ttp_2',
    # 'outcome',
    'outcome_c',
    'new_outcome_c'
    ]

## Generate all Value columns
value_cols = []
for col in df_merged.columns:
    if col in cross_sectional_meta_cols:
        continue
    elif col in temporal_meta_cols:
        continue
    elif col in not_value_cols:
        continue
    else:
        value_cols.append(col)

# %% 
# Separate sputum from stool
##############################################################################
### Step 2: Separate df into smaller dfs with respect to patient vs contacts and stool vs sputum
##############################################################################
df_all = df_merged

# Patients only
df_patients = deepcopy(df_all)
# Separate out patient data and by sample type - save separate files for each sample type
df_patients.drop(df_all[df_all['outcome'].str.contains('contact')].index, inplace=True)
# Group PATIENT data by Sample_Type
poop = df_patients[df_patients['Sample_Type'] == 'stool']
spit = df_patients[df_patients['Sample_Type'] == 'sputum']
# Save data as tsv files 
poop.to_csv(f'{base_dir}tb_stool_pts_rel_L6.tsv', sep='\t', index=False)
spit.to_csv(f'{base_dir}tb_sputum_pts_rel_L6.tsv', sep='\t', index=False)

# %%
# Make trajs
data_fps = [
    f'{base_dir}tb_stool_pts_rel_L6.tsv',
    f'{base_dir}tb_sputum_pts_rel_L6.tsv'
]
for data_fp in data_fps:
    os.makedirs(f'{base_dir}taxa_trajs/', exist_ok=True)
    filename_base = f"{base_dir}taxa_trajs/" + Path(data_fp).name.split('_')[1]
    name_tag_base = Path(data_fp).parents[1]/filename_base
    name_tag = f'{name_tag_base}_trajs'
    
    # for value_col in value_cols:
    g_trajs = create_trajs_from_dataframe(data_fp, 
                                        subject_ID_col=subject_ID_col,
                                        time_col=time_col,
                                        value_cols=value_cols,
                                        cross_sectional_meta_cols=cross_sectional_meta_cols,
                                        temporal_meta_cols=temporal_meta_cols,
                                        name_tag=name_tag)

# %%
# Adjust the time points to their month equivalents

data_folder_fn = 'C:/Users/mathr/Documents/GitHub/tb_mmeds_initial/taxa_trajs/'
data_folder = Path(data_folder_fn)
data_fps = glob(data_folder_fn + '/*.out')
new_dir = Path(data_folder_fn + 'time-corrected-trajs/')
new_dir.mkdir(exist_ok=True, parents=True)

for data_fp in data_fps:
    print("...reading data 1\n")
    print(data_fp)
    trajs = read_trajectories(Path(data_fp))
    new_trajs = []
    for traj in trajs:
        new_time = []
        for t in traj.time:
            if round(t,1) == 0.0:
                new_time.append(0)
            elif round(t, 1) == 1.0:
                new_time.append(2)
            elif round(t, 1) == 2.0:
                new_time.append(6)
            elif round(t, 1) == 3.0:
                new_time.append(12)
            elif round(t, 1) == 4.0:
                new_time.append(18)
        traj_new = make_trajectory(traj.id, new_time, traj.values, traj.mdata)
        new_trajs.append(traj_new)
    
    write_trajectories(new_trajs, data_folder_fn + new_dir.name + '/' + Path(data_fp).name[:-4] + '_timeInMonths.out')

# %%
