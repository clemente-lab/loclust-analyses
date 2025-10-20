#!/bin/bash
#BSUB -J vmeasure_and_plots
#BSUB -o logs/vmeasure_and_plots.out
#BSUB -e logs/vmeasure_and_plots.err
#BSUB -n 1
#BSUB -R "rusage[mem=8GB]"
#BSUB -W 2:00
#BSUB -P acc_CVDlung
#BSUB -q premium

# LSF job wrapper for v-measure calculation AND plotting
# Submit with: bsub < run_vmeasure_and_plots.sh

set -e
set -u

SCRIPT_DIR="/sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_minimal_features"
ANALYZE_DIR="/sc/arion/projects/CVDlung/earl/loclust/simulations/3_analyze_minimal_features"
RESULTS_DIR="/sc/arion/projects/CVDlung/earl/loclust/simulations/results_minimal_features"

echo "=========================================="
echo "V-Measure Calculation & Plotting Job"
echo "=========================================="
echo "Job ID: $LSB_JOBID"
echo "Host: $(hostname)"
echo "Start time: $(date)"
echo "=========================================="
echo ""

# Load required modules
module purge
module load python/3.8.2

# Use conda environment directly
export PATH="/sc/arion/projects/clemej05a/erli/envs/loclust_cluster/bin:$PATH"
export PYTHONPATH="/sc/arion/projects/CVDlung/earl/loclust:$PYTHONPATH"

# Create logs and results directories
mkdir -p "${SCRIPT_DIR}/logs"
mkdir -p "${ANALYZE_DIR}/logs"
mkdir -p "${RESULTS_DIR}"

# ============================================================
# STEP 1: Calculate v-measure metrics
# ============================================================
echo "=========================================="
echo "STEP 1: Calculating V-Measure Metrics"
echo "=========================================="
echo ""

cd "$ANALYZE_DIR"
python calculate_vmeasure.py

echo ""
echo "V-measure calculation complete!"
echo ""

# ============================================================
# STEP 2: Generate plots
# ============================================================
echo "=========================================="
echo "STEP 2: Generating Plots"
echo "=========================================="
echo ""

# Try to activate conda for R plotting (has tidyverse)
if [ -z "${CONDA_DEFAULT_ENV:-}" ]; then
    echo "Attempting to activate conda environment for R..."
    if [ -f "/hpc/packages/minerva-centos7/anaconda3/2020.11/etc/profile.d/conda.sh" ]; then
        source /hpc/packages/minerva-centos7/anaconda3/2020.11/etc/profile.d/conda.sh
        conda activate loclust_cluster || echo "Warning: Could not activate conda, using system R"
    fi
fi

echo "Running plot_vmeasure.R..."
Rscript plot_vmeasure.R

echo ""
echo "Running plot_vmeasure_legacy_style.R..."
Rscript plot_vmeasure_legacy_style.R

echo ""
echo "Plotting complete!"
echo ""

# ============================================================
# Summary
# ============================================================
echo "=========================================="
echo "Job Complete!"
echo "=========================================="
echo "End time: $(date)"
echo ""
echo "Results saved to:"
echo "  ${RESULTS_DIR}/vmeasure_scores.tsv"
echo "  ${RESULTS_DIR}/vmeasure_summary.tsv"
echo "  ${RESULTS_DIR}/*.png (plots)"
echo "=========================================="
