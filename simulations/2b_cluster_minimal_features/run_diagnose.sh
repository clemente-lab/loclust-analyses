#!/bin/bash
#BSUB -J traj_diagnose
#BSUB -o logs/traj_diagnose.out
#BSUB -e logs/traj_diagnose.err
#BSUB -n 1
#BSUB -R "rusage[mem=4GB]"
#BSUB -W 0:30
#BSUB -P acc_CVDlung
#BSUB -q premium

# Use same environment as actual traj runs
module purge
module load python/3.8.2

# Activate conda environment
source /hpc/packages/minerva-centos7/anaconda3/2020.07/etc/profile.d/conda.sh
conda activate loclust_cluster

cd /sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_potentially_simple

Rscript diagnose_traj_failures.R > traj_diagnostics.txt 2>&1

echo "Diagnostic complete. Results saved to traj_diagnostics.txt"
