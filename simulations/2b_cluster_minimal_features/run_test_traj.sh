#!/bin/bash
#BSUB -J test_traj
#BSUB -o logs/test_traj.out
#BSUB -e logs/test_traj.err
#BSUB -n 1
#BSUB -R "rusage[mem=2GB]"
#BSUB -W 0:10
#BSUB -P acc_CVDlung
#BSUB -q premium

module purge
module load python/3.8.2
export PATH="/sc/arion/projects/clemej05a/erli/envs/loclust_cluster/bin:$PATH"

cd /sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_potentially_simple

Rscript test_traj_workflow.R
