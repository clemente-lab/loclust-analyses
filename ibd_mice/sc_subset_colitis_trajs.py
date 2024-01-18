###
# This script is to subset Gnobiotic colitis mouse weight data per disease type for 
# disease-based clustering
# 
# Author: Hilary Monaco
# Data collected by: Graham Britton
###

import numpy as np
import pandas as pd
from pathlib import Path
from copy import deepcopy
from loclust.parse import read_trajectories, write_trajectories

# Plot all trajs, colored by cluster assignment
in_fn = 'C:/Users/mathr/Documents/GitHub/graham/weight_trajs/weight_Measurement_trajs.out'
trajs = read_trajectories(Path(in_fn))
output_path = 'C:/Users/mathr/Documents/GitHub/graham/'

# Subset the trajs for each disease and save as new trajs file 
healthy_trajs = []
ibd_trajs = []
ra_trajs = []
unaff_trajs = [] # "Unaffected"
spf_trajs = []

for t in trajs:
    disease = t.mdata["Donor_disease_state"]
    if disease == "Healthy":
        healthy_trajs.append(t)
    elif disease == "IBD":
        ibd_trajs.append(t)
    elif disease == "RA":
        ra_trajs.append(t)
    elif disease == "Unaffected":
        unaff_trajs.append(t)
    elif disease == "SPF":
        spf_trajs.append(t)
    else:
        print(f'Disease = {disease}')

ibd_healthy_trajs = ibd_trajs + healthy_trajs
ra_healthy_trajs = ra_trajs + healthy_trajs
unaff_healthy_trajs = unaff_trajs + healthy_trajs
spf_healthy_trajs = spf_trajs + healthy_trajs
ibd_unaff_healthy_trajs = ibd_trajs + healthy_trajs + unaff_trajs

# Save all new traj files
# TODO: Update the save location so it defaults to saving inside the output_path folder
name_tag = 'weight'
value_col_name_new = 'healthy'
write_trajectories(healthy_trajs, f'{Path(in_fn).parent}/{name_tag}_{value_col_name_new}_trajs.out', logging=True)
value_col_name_new = 'IBD'
write_trajectories(ibd_trajs, f'{Path(in_fn).parent}/{name_tag}_{value_col_name_new}_trajs.out', logging=True)
value_col_name_new = 'RA'
write_trajectories(ra_trajs, f'{Path(in_fn).parent}/{name_tag}_{value_col_name_new}_trajs.out', logging=True)
value_col_name_new = 'Unaffected'
write_trajectories(unaff_trajs, f'{Path(in_fn).parent}/{name_tag}_{value_col_name_new}_trajs.out', logging=True)
value_col_name_new = 'SPF'
write_trajectories(spf_trajs, f'{Path(in_fn).parent}/{name_tag}_{value_col_name_new}_trajs.out', logging=True)
value_col_name_new = 'IBD_healthy'
write_trajectories(ibd_healthy_trajs, f'{Path(in_fn).parent}/{name_tag}_{value_col_name_new}_trajs.out', logging=True)
value_col_name_new = 'RA_healthy'
write_trajectories(ra_healthy_trajs, f'{Path(in_fn).parent}/{name_tag}_{value_col_name_new}_trajs.out', logging=True)
value_col_name_new = 'Unaff_healthy'
write_trajectories(unaff_healthy_trajs, f'{Path(in_fn).parent}/{name_tag}_{value_col_name_new}_trajs.out', logging=True)
value_col_name_new = 'SPF_healthy'
write_trajectories(spf_healthy_trajs, f'{Path(in_fn).parent}/{name_tag}_{value_col_name_new}_trajs.out', logging=True)
value_col_name_new = 'IBD_Unaffected_healthy'
write_trajectories(ibd_unaff_healthy_trajs, f'{Path(in_fn).parent}/{name_tag}_{value_col_name_new}_trajs.out', logging=True)