#!/bin/bash
# Run only the plotting scripts
# Usage: bash run_plots_only.sh

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANALYZE_DIR="${SCRIPT_DIR}/../3_analyze_potentially_simple"

echo "=========================================="
echo "Generating V-Measure Plots"
echo "=========================================="
echo ""

cd "$ANALYZE_DIR"

echo "Running plot_vmeasure.R..."
Rscript plot_vmeasure.R

echo "Running plot_vmeasure_legacy_style.R..."
Rscript plot_vmeasure_legacy_style.R

echo ""
echo "=========================================="
echo "Plotting Complete"
echo "=========================================="
echo "Check ../results_potentially_simple/ for output plots"
