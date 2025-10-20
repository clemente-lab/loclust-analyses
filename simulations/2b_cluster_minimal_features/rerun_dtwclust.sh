#!/bin/bash
# Script to rerun ONLY dtwclust clustering
#
# This deletes old dtwclust files and resubmits dtwclust jobs
#
# Usage:
#   bash rerun_dtwclust.sh

set -e
set -u

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=========================================="
echo "DTWclust Rerun Script"
echo "=========================================="
echo ""

# Step 1: Clean old dtwclust output files
echo "[1/4] Cleaning old dtwclust output files..."
DELETED=$(find "${SCRIPT_DIR}/../data" -path "*/dtwclust_k*/trajectories.clust.tsv" -type f | wc -l)
find "${SCRIPT_DIR}/../data" -path "*/dtwclust_k*/trajectories.clust.tsv" -type f -delete
echo "      Deleted $DELETED old dtwclust output files"
echo ""

# Step 2: Clean old logs
echo "[2/4] Cleaning old dtwclust logs..."
rm -f "${SCRIPT_DIR}/logs/r_dtwclust.out" "${SCRIPT_DIR}/logs/r_dtwclust.err"
echo "      Cleaned log files"
echo ""

# Step 3: Generate dataset index
echo "[3/4] Generating dataset index..."
python "${SCRIPT_DIR}/generate_dataset_index.py"

# Read number of datasets
DATA_INDEX="${SCRIPT_DIR}/dataset_index.tsv"
NUM_DATASETS=$(tail -n +2 "$DATA_INDEX" | wc -l)
echo "      Found $NUM_DATASETS datasets"
echo ""

# Step 4: Create and submit dtwclust job
echo "[4/4] Submitting dtwclust clustering job..."

METHOD_SCRIPT="${SCRIPT_DIR}/run_r_dtwclust.sh"

# Create method-specific script from template
sed "s/METHOD/dtwclust/g" "${SCRIPT_DIR}/run_r_method_array.sh" > "$METHOD_SCRIPT"
sed -i "s/\[1-2100\]/[1-${NUM_DATASETS}]/" "$METHOD_SCRIPT"
chmod +x "$METHOD_SCRIPT"

# Submit job
echo "      Submitting dtwclust (${NUM_DATASETS} datasets)..."
JOB_OUTPUT=$(bsub < "$METHOD_SCRIPT")
JOB_ID=$(echo "$JOB_OUTPUT" | grep -oP 'Job <\K[0-9]+')
echo "        Job ID: $JOB_ID"
echo ""

echo "=========================================="
echo "Submission Complete!"
echo "=========================================="
echo "DTWclust job ID: $JOB_ID"
echo ""
echo "Monitor progress:"
echo "  bjobs -w          # Check job status"
echo "  bjobs $JOB_ID     # Check this specific job"
echo "  tail -f logs/r_dtwclust.out  # Watch output"
echo ""
echo "After completion, run v-measure calculation:"
echo "  cd ${SCRIPT_DIR}"
echo "  bash run_vmeasure.sh"
echo "=========================================="
