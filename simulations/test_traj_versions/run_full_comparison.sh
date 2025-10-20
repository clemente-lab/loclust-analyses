#!/bin/bash
# Full numerical comparison script - run locally
# Created: October 17, 2025

set -e

echo "================================================"
echo "FULL NUMERICAL COMPARISON: Traj 1.2 vs 2.2.1"
echo "================================================"
echo ""

# Ensure we're in the right directory
cd ~/traj_comparison_test

echo "Running OLD traj 1.2..."
conda run -n traj_old_local Rscript ../test_traj_versions/run_comparison.R

echo ""
echo "Running NEW traj 2.2.1..."
conda run -n traj_new_local Rscript ../test_traj_versions/run_comparison.R

echo ""
echo "================================================"
echo "COMPARISON RESULTS"
echo "================================================"

# Combine results
echo "version	traj_version	factors	v_measure	homogeneity	completeness	n_trajectories	dataset" > combined_results.tsv
cat old_1.2_result.tsv | tail -n +2 >> combined_results.tsv 2>/dev/null || echo "OLD results not found"
cat new_2.2.1_result.tsv | tail -n +2 >> combined_results.tsv 2>/dev/null || echo "NEW results not found"

if [ -f combined_results.tsv ] && [ $(wc -l < combined_results.tsv) -gt 1 ]; then
    echo ""
    echo "Combined Results:"
    cat combined_results.tsv | column -t -s$'\t'
    
    echo ""
    echo "NUMERICAL DIFFERENCE ANALYSIS:"
    echo "============================="
    
    # Extract values and calculate differences
    if [ $(wc -l < combined_results.tsv) -eq 3 ]; then
        python3 -c "
import pandas as pd
df = pd.read_csv('combined_results.tsv', sep='\t')
if len(df) == 2:
    old = df[df['version'].str.contains('OLD')].iloc[0]
    new = df[df['version'].str.contains('NEW')].iloc[0]
    
    print(f'OLD traj 1.2:   V-measure = {old.v_measure:.3f}, Factors = {old.factors}')
    print(f'NEW traj 2.2.1: V-measure = {new.v_measure:.3f}, Factors = {new.factors}')
    print(f'')
    print(f'DIFFERENCES:')
    print(f'  V-measure: {new.v_measure - old.v_measure:+.3f} ({(new.v_measure - old.v_measure)/old.v_measure*100:+.1f}%)')
    print(f'  Factors:   {new.factors - old.factors:+d}')
    print(f'')
    if new.v_measure > old.v_measure:
        print('✓ CONFIRMED: New traj performs better than old traj')
        print('This supports the hypothesis that the algorithm change explains the performance improvement.')
    else:
        print('✗ UNEXPECTED: New traj does not perform better')
else:
    print('Need both old and new results for comparison')
        "
    fi
else
    echo "Results files not found or incomplete"
    echo "Check individual result files:"
    ls -la *result.tsv 2>/dev/null || echo "No result files found"
fi

echo ""
echo "================================================"
echo "NUMERICAL COMPARISON COMPLETE!"
echo "================================================"