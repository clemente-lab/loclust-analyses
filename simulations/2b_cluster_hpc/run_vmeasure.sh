#!/bin/bash
# LSF script to calculate v-measure metrics after all clustering completes
#
# This job should be submitted with dependency on all clustering jobs:
#   bsub -w "done(job1) && done(job2)" < run_vmeasure.sh

set -e
set -u

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANALYSIS_DIR="${SCRIPT_DIR}/../analysis"
RESULTS_DIR="${SCRIPT_DIR}/../results"

echo "=========================================="
echo "V-Measure Calculation"
echo "=========================================="
echo "Job ID: $LSB_JOBID"
echo "Host: $(hostname)"
echo "Start time: $(date)"
echo "=========================================="
echo ""

# Create results directory
mkdir -p "$RESULTS_DIR"

# Run v-measure calculation on all clustered files
cd "$ANALYSIS_DIR"

echo "Calculating clustering metrics for all methods..."
python calculate_vmeasure.py

echo ""
echo "=========================================="
echo "V-Measure Calculation Complete"
echo "=========================================="
echo "End time: $(date)"
echo ""
echo "Results saved to:"
echo "  ${RESULTS_DIR}/vmeasure_scores.tsv"
echo "  ${RESULTS_DIR}/vmeasure_summary.tsv"
echo "=========================================="
