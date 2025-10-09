#!/bin/bash
#BSUB -J r_METHOD[1-2100]
#BSUB -o logs/r_METHOD_%I_%J.out
#BSUB -e logs/r_METHOD_%I_%J.err
#BSUB -n 1
#BSUB -R "rusage[mem=4GB]"
#BSUB -W 1:00
#BSUB -q premium

# LSF Job Array Script for R Clustering Methods
#
# This script runs one dataset per array element for a specified method.
# Submit separately for each method: kml, dtwclust, mfuzz
#
# Usage:
#   # Replace METHOD in the script with actual method name, then:
#   bsub < run_r_kml.sh
#   bsub < run_r_dtwclust.sh
#   bsub < run_r_mfuzz.sh
#
# Or use the submit_all_r.sh wrapper script

set -e
set -u

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DATA_INDEX="${SCRIPT_DIR}/dataset_index.tsv"
R_SCRIPT="${SCRIPT_DIR}/../clustering_scripts/run_r_methods.R"

# METHOD MUST BE SET - this is a template
METHOD="METHOD"

# LSB_JOBINDEX corresponds to dataset index (1-based)
DATASET_IDX=$LSB_JOBINDEX

echo "=================================================="
echo "R Clustering Job"
echo "=================================================="
echo "Job ID: $LSB_JOBID"
echo "Array Index: $LSB_JOBINDEX"
echo "Dataset Index: $DATASET_IDX"
echo "Method: $METHOD"
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

# Get parent directory
TRAJ_DIR=$(dirname "$TRAJ_FILE")

# Create output directory
OUTPUT_DIR="${TRAJ_DIR}/clustering/${METHOD}_k${NUM_CLASSES}"
mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="${OUTPUT_DIR}/trajectories.clust.tsv"

echo ""
echo "Dataset: ${FUNC_COMBO} / noise_${NOISE_LEVEL} / seed_${SEED}"
echo "k = $NUM_CLASSES"
echo "Output: $OUTPUT_FILE"
echo ""

# Load R module if needed (comment out if not using environment modules)
# module load R/4.2.0

# Run R clustering using single-file wrapper script
SINGLE_R_SCRIPT="${SCRIPT_DIR}/run_single_r_method.R"

Rscript "$SINGLE_R_SCRIPT" "$METHOD" "$TRAJ_FILE" "$NUM_CLASSES"

# Check success
if [ -f "$OUTPUT_FILE" ]; then
    NUM_LINES=$(wc -l < "$OUTPUT_FILE")
    echo "SUCCESS: Created $OUTPUT_FILE ($NUM_LINES lines)"
    exit 0
else
    echo "FAILED: Output file not created"
    exit 1
fi
