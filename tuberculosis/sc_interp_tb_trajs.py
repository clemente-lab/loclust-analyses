#%% ###
# This script is to interpolate babies microbiome data as loclust trajectory objects.
# 
# Author: Hilary Monaco
###

# %% Interpolate all trajectories with smoothing level 5

import numpy as np
import pandas as pd
from pathlib import Path
from copy import deepcopy
from loclust.parse import read_trajectories, write_trajectories
from loclust.util import remove_duplicate_timepoints
from loclust.trajectory import determine_traj_interpolation_points
from glob import glob
from scipy.interpolate import interp1d

# %%
# base_path = Path('C:/Users/mathr/Documents/GitHub/tb_mmeds_initial/')
# traj_paths = ['taxa_trajs_lego_interp_test']
base_path = Path('C:/Users/mathr/Documents/GitHub/tb_mmeds_initial/taxa_trajs/')
traj_paths = ['time-corrected-trajs']

for folder_name in traj_paths:
    new_folder_name = folder_name +'_lego_interp'
    new_path = base_path / new_folder_name
    new_path.mkdir(parents=True, exist_ok=True)

    folder = base_path / folder_name
    print(folder)
    print(len(glob(f'{folder}/*.out')))
    for t_file in glob(f'{folder}/*.out'):

        print(t_file)
        trajs_orig = read_trajectories(t_file)

        # Remove trajectories with duplicate timepoints
        trajs = remove_duplicate_timepoints(trajs_orig)

        # Remove trajectories that are too short
        num_drop = 0
        trajs_new = []
        for t in trajs: 
            if len(t) < 5:
                print('dropped' + t.id, str(len(t)))
                num_drop = num_drop + 1
                continue
            else:
                trajs_new.append(t)
                
        print(str(num_drop)+ " trajectories dropped for being too short. " 
            + str(len(trajs_new)) + " trajs remaining.")
        
        trajs = deepcopy(trajs_new)

        # Calculate the union of all timepoints across all trajectories
        # timepoints_list, trajs = determine_traj_interpolation_points(trajs)
        timepoints_list, trajs = determine_traj_interpolation_points(trajs)

       # Interpolate the trajs using lowess method
        # smoothing_order = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] #[4]
        smoothing_order = [7]
        for s in smoothing_order:
            trajs_lego = []
            for t in trajs:
                t_lego = deepcopy(t)
                if s == 0:
                    continue
                t_lego_sm = t_lego.interpolate_and_smooth(method='lego', \
                                            timepoints_list=timepoints_list,
                                            sigma=s)
                trajs_lego.append(t_lego_sm)
            write_trajectories(trajs_lego, new_path / f'{Path(t_file).stem}_lego-interp_sig_{s}.tsv')

        
# %%
