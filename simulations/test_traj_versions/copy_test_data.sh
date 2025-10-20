#!/bin/bash
# Copy test data to local machine for comparison
# Run this after setup_local.sh
# Created: October 17, 2025

echo "================================================"
echo "Copying test data from cluster to local"
echo "================================================"
echo ""

# Create local test directory
mkdir -p ~/traj_comparison_test
cd ~/traj_comparison_test

# Copy test file from cluster
echo "Copying test file from cluster..."
scp windae01@login.minerva.icahn.edu:/sc/arion/projects/CVDlung/earl/loclust/simulations/data_potentially_simple/input_trajs/8/3/0.04noise.exponential-hyperbolic-norm.200reps.0.tsv ./

if [ -f "0.04noise.exponential-hyperbolic-norm.200reps.0.tsv" ]; then
    echo "✓ Test data copied successfully"
    echo "File: $(ls -lh *.tsv)"
else
    echo "✗ Failed to copy test data"
    exit 1
fi

echo ""
echo "Test data ready in: ~/traj_comparison_test/"
echo ""