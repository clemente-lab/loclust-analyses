#!/bin/bash
#BSUB -J check_step2
#BSUB -o logs/check_step2.out
#BSUB -e logs/check_step2.err
#BSUB -n 1
#BSUB -R "rusage[mem=1GB]"
#BSUB -W 0:10
#BSUB -P acc_CVDlung
#BSUB -q premium

# Use same environment as actual traj runs
module purge
module load python/3.8.2
export PATH="/sc/arion/projects/clemej05a/erli/envs/loclust_cluster/bin:$PATH"

cd /sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_potentially_simple

Rscript check_step2_params.R
