###
# This script is to transform Gnobiotic colitis mouse weight data into loclust trajectory objects
# 
# Author: Hilary Monaco
# Data collected by: Graham Britton
###
# %%
import numpy as np
import pandas as pd
from pathlib import Path
from copy import deepcopy
from loclust.parse import create_trajs_from_dataframe

# %%
data_fp_orig = 'C:/Users/mathr/Documents/GitHub/graham/Gnotobiotic_colitis_data.csv'
df = pd.read_csv(data_fp_orig)

# Initial dataset parsing/column creation
## De-duplicating mouse IDs 
def dedup_mouseID(exp, mouse_id, microbiota_ID):
    if exp == 'GB007' or exp == 'GB063':
        mouse_id = f'{mouse_id}_{microbiota_ID}'
    return mouse_id


## Separating Gender 
def determine_gender(exp, mouse_id):
    if exp == 'GB115' or exp == 'RTP_VI' or exp == 'RTP_V':
        gender = 'NA'
    elif exp[0] == 'R':
        gender = mouse_id.split('_')[3]
    else:
        gender = mouse_id.split('_')[1]
    return gender


vectorized_mouseID = np.vectorize(dedup_mouseID)
df['Subject_ID'] = vectorized_mouseID(df['Experiment'], df['Mouse_unique_ID'], df['MicrobiotaID'])

vectorized_gender = np.vectorize(determine_gender)
df['Gender'] = vectorized_gender(df['Experiment'], df['Mouse_unique_ID'])

## Create column for sample ID
df['Sample_ID'] = deepcopy(df.index)

df.rename(columns={"Mouse_unique_ID": "Mouse_ID_original"})

data_fp_for_trajs = 'C:/Users/mathr/Documents/GitHub/graham/Gnotobiotic_colitis_data_for_trajs.tsv'
df.to_csv(data_fp_for_trajs, sep='\t', index=False)


# Setup variables for parsing data to trajectory objects
data_fp = data_fp_for_trajs
tsv_flag = True
sample_ID_col = "Sample_ID"
subject_ID_col = "Subject_ID"
time_col = "Measurement_day"
value_cols = ["Measurement"]
cross_sectional_meta_cols = ["MicrobiotaID", "Mouse_#", "Donor_disease_state", "Disease_detail", "Experiment", "Gender"]
temporal_meta_cols = None
name_tag = f'{Path(data_fp_orig).parent}/weight_trajs/weight'

# %%
g_trajs = create_trajs_from_dataframe(data_fp, 
                                     subject_ID_col=subject_ID_col,
                                     time_col=time_col,
                                     value_cols=value_cols,
                                     cross_sectional_meta_cols=cross_sectional_meta_cols,
                                     temporal_meta_cols=temporal_meta_cols,
                                     name_tag=name_tag)

# %%
