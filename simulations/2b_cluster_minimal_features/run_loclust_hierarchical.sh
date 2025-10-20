#!/bin/bash
#BSUB -J loclust_hierarchical[1-1740]
#BSUB -o logs/loclust_hierarchical.out
#BSUB -e logs/loclust_hierarchical.err
#BSUB -n 1
#BSUB -R "rusage[mem=4GB]"
#BSUB -W 1:30
#BSUB -P acc_CVDlung
#BSUB -q premium

# LSF Job Array Script for LoClust Clustering Methods
#
# This script runs one dataset per array element for a specified method.
# Submit separately for each method: gmm, hierarchical, kmeans, spectral
#
# Usage:
#   # Replace hierarchical in the script with actual method name, then:
#   bsub < run_loclust_gmm.sh
#   bsub < run_loclust_hierarchical.sh
#   bsub < run_loclust_kmeans.sh
#   bsub < run_loclust_spectral.sh
#
# Or use the submit_all_loclust.sh wrapper script

set -e
set -u

# Load required modules and use conda environment directly
module purge
module load python/3.8.2
# Bypass broken conda activation - use environment directly
export PATH="/sc/arion/projects/clemej05a/erli/envs/loclust_cluster/bin:$PATH"
export PYTHONPATH="/sc/arion/projects/CVDlung/earl/loclust:$PYTHONPATH"

# Configuration - use absolute paths for LSF
SCRIPT_DIR="/sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_minimal_features"
DATA_INDEX="${SCRIPT_DIR}/dataset_index.tsv"
CLUSTER_SCRIPT="/sc/arion/projects/CVDlung/earl/loclust/scripts/cluster_trajectories.py"

# hierarchical MUST BE SET - this is a template, create copies with actual method names
hierarchical="hierarchical"

# LSB_JOBINDEX corresponds to dataset index (1-based)
DATASET_IDX=$LSB_JOBINDEX

echo "=================================================="
echo "LoClust Clustering Job"
echo "=================================================="
echo "Job ID: $LSB_JOBID"
echo "Array Index: $LSB_JOBINDEX"
echo "Dataset Index: $DATASET_IDX"
echo "Method: $hierarchical"
echo "Host: $(hostname)"
echo "Start time: $(date)"
echo "=================================================="

# Read dataset info from index file (skip header, get line DATASET_IDX)
DATASET_INFO=$(sed -n "$((DATASET_IDX + 1))p" "$DATA_INDEX")

# Parse dataset info
NUM_CLASSES=$(echo "$DATASET_INFO" | cut -f2)
FUNC_COMBO=$(echo "$DATASET_INFO" | cut -f3)
NOISE_LEVEL=$(echo "$DATASET_INFO" | cut -f4)
SEED=$(echo "$DATASET_INFO" | cut -f5)
TRAJ_FILE=$(echo "$DATASET_INFO" | cut -f6)

# Verify trajectory file exists
if [ ! -f "$TRAJ_FILE" ]; then
    echo "ERROR: Trajectory file not found: $TRAJ_FILE"
    exit 1
fi

# Get parent directory and filename
TRAJ_DIR=$(dirname "$TRAJ_FILE")
TRAJ_FILENAME=$(basename "$TRAJ_FILE")

# Create output directory (replace data_potentially_simple with data_minimal_features)
OUTPUT_DIR="${TRAJ_DIR/data_potentially_simple/data_minimal_features}/clustering/${hierarchical}_k${NUM_CLASSES}"
mkdir -p "$OUTPUT_DIR"

# Generate output filename based on input filename
OUTPUT_BASENAME="${TRAJ_FILENAME%.tsv}.clust.tsv"
OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_BASENAME}"
LOG_FILE="${OUTPUT_DIR}/clustering_log.txt"

echo ""
echo "Dataset: ${FUNC_COMBO} / noise_${NOISE_LEVEL} / seed_${SEED}"
echo "k = $NUM_CLASSES"
echo "Output: $OUTPUT_FILE"
echo ""

# Add loclust to PYTHONPATH
export PYTHONPATH="/sc/arion/projects/CVDlung/earl/loclust:$PYTHONPATH"

# Set matplotlib backend for headless execution
export MPLBACKEND=Agg

# Run clustering
python "$CLUSTER_SCRIPT" \
    -fi "$TRAJ_FILENAME" \
    -di "$TRAJ_DIR" \
    -fo "$OUTPUT_FILE" \
    -do "$OUTPUT_DIR" \
    -c "$hierarchical" \
    -tk func \
    -ak cluster \
    --force-k "$NUM_CLASSES" \
    -rs 42 \
    --write_flag \
    --pca_flag \
    -pn 9 \
    --no-interpolate \
    --use-original-stats \
    --no_cluster_plots_flag \
    > "$LOG_FILE" 2>&1

# Check success
if [ -f "$OUTPUT_FILE" ]; then
    NUM_LINES=$(wc -l < "$OUTPUT_FILE")
    echo "SUCCESS: Created $OUTPUT_FILE ($NUM_LINES lines)"
    exit 0
else
    echo "FAILED: Output file not created"
    exit 1
fi
