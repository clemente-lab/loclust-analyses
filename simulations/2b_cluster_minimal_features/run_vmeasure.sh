#!/bin/bash
# LSF script to calculate v-measure metrics after all clustering completes
#
# Can be submitted as LSF job or run directly:
#   bsub < run_vmeasure.sh
#   OR
#   bash run_vmeasure.sh [run_name]
#
# Optional argument:
#   run_name - Name for this run (default: timestamp)
#
# Examples:
#   bash run_vmeasure.sh                    # Uses timestamp
#   bash run_vmeasure.sh baseline           # Names run "baseline"
#   bash run_vmeasure.sh experiment_v2      # Names run "experiment_v2"

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RESULTS_DIR="${SCRIPT_DIR}/../results_potentially_simple"

# Parse optional run name argument
RUN_NAME="${1:-$(date +%Y%m%d_%H%M%S)}"

# Create archive directory structure
ARCHIVE_DIR="${RESULTS_DIR}/archive/${RUN_NAME}"
mkdir -p "${ARCHIVE_DIR}"

echo "=========================================="
echo "V-Measure Calculation"
echo "=========================================="
echo "Run name: $RUN_NAME"
echo "Archive: $ARCHIVE_DIR"
if [ -n "${LSB_JOBID:-}" ]; then
    echo "Job ID: $LSB_JOBID"
fi
echo "Host: $(hostname)"
echo "Start time: $(date)"
echo "=========================================="
echo ""

# Create results directory
mkdir -p "$RESULTS_DIR"

# Load modules and environment
module purge
module load python/3.8.2
export PATH="/sc/arion/projects/clemej05a/erli/envs/loclust_cluster/bin:$PATH"

# Run v-measure calculation on all clustered files
ANALYZE_DIR="${SCRIPT_DIR}/../3_analyze_potentially_simple"
cd "$ANALYZE_DIR"

echo "Calculating clustering metrics for all methods..."
echo "(Skipping datasets where clustering failed)"
/sc/arion/projects/clemej05a/erli/envs/loclust_cluster/bin/python calculate_vmeasure.py

echo ""
echo "=========================================="
echo "V-Measure Calculation Complete"
echo "=========================================="
echo ""

# Copy results to archive
echo "Archiving vmeasure results..."
cp "${RESULTS_DIR}/vmeasure_scores.tsv" "${ARCHIVE_DIR}/vmeasure_scores.tsv"
cp "${RESULTS_DIR}/vmeasure_summary.tsv" "${ARCHIVE_DIR}/vmeasure_summary.tsv"

echo "Results saved to:"
echo "  ${RESULTS_DIR}/vmeasure_scores.tsv (current run)"
echo "  ${RESULTS_DIR}/vmeasure_summary.tsv (current run)"
echo "  ${ARCHIVE_DIR}/ (archived)"
echo ""

# Generate plots
echo "=========================================="
echo "Generating V-Measure Plots"
echo "=========================================="
echo ""

# Activate conda environment for R (has tidyverse and other packages)
# Check if already in conda environment
if [ -z "${CONDA_DEFAULT_ENV:-}" ]; then
    echo "Activating conda environment loclust_cluster..."
    # Try common conda initialization paths
    if [ -f "/hpc/packages/minerva-centos7/anaconda3/2020.11/etc/profile.d/conda.sh" ]; then
        source /hpc/packages/minerva-centos7/anaconda3/2020.11/etc/profile.d/conda.sh
    elif [ -f "$CONDA_PREFIX/../etc/profile.d/conda.sh" ]; then
        source "$CONDA_PREFIX/../etc/profile.d/conda.sh"
    elif command -v conda &> /dev/null; then
        eval "$(conda shell.bash hook)"
    else
        echo "Warning: Could not find conda. Attempting to use R from PATH..."
    fi

    # Try to activate if conda is available
    if command -v conda &> /dev/null; then
        conda activate loclust_cluster || echo "Warning: Could not activate loclust_cluster, using current environment"
    fi
else
    echo "Already in conda environment: $CONDA_DEFAULT_ENV"
fi

# Run main plotting script
echo "Running plot_vmeasure.R..."
cd "$ANALYZE_DIR"
Rscript plot_vmeasure.R

# Run legacy style plotting script
echo "Running plot_vmeasure_legacy_style.R..."
Rscript plot_vmeasure_legacy_style.R

echo ""

# Archive plots
echo "Archiving plots..."
if [ -d "${RESULTS_DIR}" ]; then
    # Copy any PNG/PDF/SVG files from results directory to archive
    find "${RESULTS_DIR}" -maxdepth 1 -type f \( -name "*.png" -o -name "*.pdf" -o -name "*.svg" \) -exec cp {} "${ARCHIVE_DIR}/" \; 2>/dev/null || true
fi

# Create/update "latest" symlink
rm -f "${RESULTS_DIR}/archive/latest"
ln -s "${RUN_NAME}" "${RESULTS_DIR}/archive/latest"

echo ""
echo "=========================================="
echo "All Analysis Complete"
echo "=========================================="
echo "Run name: $RUN_NAME"
echo "End time: $(date)"
echo ""
echo "Results locations:"
echo "  ${RESULTS_DIR}/ (current run)"
echo "  ${ARCHIVE_DIR}/ (archived)"
echo "  ${RESULTS_DIR}/archive/latest -> ${RUN_NAME} (symlink)"
echo ""
echo "Archived files:"
echo "  - vmeasure_scores.tsv"
echo "  - vmeasure_summary.tsv"
echo "  - plots (*.png, *.pdf, *.svg)"
echo "=========================================="
