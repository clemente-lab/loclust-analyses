#!/bin/bash
# Master script to submit all clustering jobs to LSF cluster
#
# This script:
# 1. Generates dataset index file
# 2. Creates method-specific LSF scripts from templates
# 3. Submits all clustering jobs as job arrays
# 4. Submits v-measure calculation job with dependency on all clustering
#
# Usage:
#   bash submit_all_clustering.sh [--loclust-only | --r-only]

set -e
set -u

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Parse arguments
RUN_LOCLUST=true
RUN_R=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --loclust-only)
            RUN_R=false
            shift
            ;;
        --r-only)
            RUN_LOCLUST=false
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--loclust-only | --r-only]"
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "LoClust Cluster Submission Script"
echo "=========================================="
echo "Run LoClust methods: $RUN_LOCLUST"
echo "Run R methods: $RUN_R"
echo ""

# Create logs directory
mkdir -p "${SCRIPT_DIR}/logs"

# Step 1: Generate dataset index
echo "[1/4] Generating dataset index..."
python "${SCRIPT_DIR}/generate_dataset_index.py"

# Read number of datasets
DATA_INDEX="${SCRIPT_DIR}/dataset_index.tsv"
NUM_DATASETS=$(tail -n +2 "$DATA_INDEX" | wc -l)
echo "      Found $NUM_DATASETS datasets"
echo ""

# Step 2: Create and submit LoClust method jobs
LOCLUST_METHODS="gmm hierarchical kmeans spectral"
LOCLUST_JOB_IDS=()

if [ "$RUN_LOCLUST" = true ]; then
    echo "[2/4] Submitting LoClust clustering jobs..."

    for method in $LOCLUST_METHODS; do
        # Create method-specific script from template
        METHOD_SCRIPT="${SCRIPT_DIR}/run_loclust_${method}.sh"

        sed "s/METHOD/${method}/g" "${SCRIPT_DIR}/run_loclust_array.sh" > "$METHOD_SCRIPT"
        sed -i "s/\[1-2100\]/[1-${NUM_DATASETS}]/" "$METHOD_SCRIPT"
        chmod +x "$METHOD_SCRIPT"

        # Submit job
        echo "      Submitting $method (${NUM_DATASETS} datasets)..."
        JOB_OUTPUT=$(bsub < "$METHOD_SCRIPT")
        JOB_ID=$(echo "$JOB_OUTPUT" | grep -oP 'Job <\K[0-9]+')
        LOCLUST_JOB_IDS+=($JOB_ID)
        echo "        Job ID: $JOB_ID"
    done
    echo ""
else
    echo "[2/4] Skipping LoClust jobs (--r-only specified)"
    echo ""
fi

# Step 3: Create and submit R method jobs
R_METHODS="kml dtwclust mfuzz"
R_JOB_IDS=()

if [ "$RUN_R" = true ]; then
    echo "[3/4] Submitting R clustering jobs..."

    for method in $R_METHODS; do
        # Create method-specific script from template
        METHOD_SCRIPT="${SCRIPT_DIR}/run_r_${method}.sh"

        sed "s/METHOD/${method}/g" "${SCRIPT_DIR}/run_r_method_array.sh" > "$METHOD_SCRIPT"
        sed -i "s/\[1-2100\]/[1-${NUM_DATASETS}]/" "$METHOD_SCRIPT"
        chmod +x "$METHOD_SCRIPT"

        # Submit job
        echo "      Submitting $method (${NUM_DATASETS} datasets)..."
        JOB_OUTPUT=$(bsub < "$METHOD_SCRIPT")
        JOB_ID=$(echo "$JOB_OUTPUT" | grep -oP 'Job <\K[0-9]+')
        R_JOB_IDS+=($JOB_ID)
        echo "        Job ID: $JOB_ID"
    done
    echo ""
else
    echo "[3/4] Skipping R jobs (--loclust-only specified)"
    echo ""
fi

# Step 4: Submit v-measure calculation job with dependency
echo "[4/4] Submitting v-measure calculation job..."

# Combine all job IDs for dependency
ALL_JOB_IDS=("${LOCLUST_JOB_IDS[@]}" "${R_JOB_IDS[@]}")

if [ ${#ALL_JOB_IDS[@]} -eq 0 ]; then
    echo "      ERROR: No jobs submitted, cannot submit v-measure job"
    exit 1
fi

# Create dependency string: "done(job1) && done(job2) && ..."
DEPENDENCY=""
for job_id in "${ALL_JOB_IDS[@]}"; do
    if [ -z "$DEPENDENCY" ]; then
        DEPENDENCY="done(${job_id})"
    else
        DEPENDENCY="${DEPENDENCY} && done(${job_id})"
    fi
done

# Submit v-measure job
VMEASURE_SCRIPT="${SCRIPT_DIR}/run_vmeasure.sh"

bsub \
    -J vmeasure_calculation \
    -o "${SCRIPT_DIR}/logs/vmeasure_%J.out" \
    -e "${SCRIPT_DIR}/logs/vmeasure_%J.err" \
    -n 1 \
    -R "rusage[mem=8GB]" \
    -W 0:10 \
    -q premium \
    -w "$DEPENDENCY" \
    < "$VMEASURE_SCRIPT"

echo ""
echo "=========================================="
echo "Submission Complete!"
echo "=========================================="
echo "LoClust jobs: ${#LOCLUST_JOB_IDS[@]}"
for i in "${!LOCLUST_JOB_IDS[@]}"; do
    method=$(echo $LOCLUST_METHODS | cut -d' ' -f$((i+1)))
    echo "  $method: ${LOCLUST_JOB_IDS[$i]}"
done

echo "R jobs: ${#R_JOB_IDS[@]}"
for i in "${!R_JOB_IDS[@]}"; do
    method=$(echo $R_METHODS | cut -d' ' -f$((i+1)))
    echo "  $method: ${R_JOB_IDS[$i]}"
done

echo ""
echo "V-measure job will run when all clustering jobs complete"
echo ""
echo "Monitor progress:"
echo "  bjobs -w          # Check job status"
echo "  bjobs -sum        # Summary"
echo "  ls logs/          # Check log files"
echo "=========================================="
