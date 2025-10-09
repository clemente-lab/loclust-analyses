#!/usr/bin/env python3
"""
Test script to verify that random seeding produces reproducible simulations.

This script will:
1. Generate simulations with seed=42
2. Generate simulations again with seed=42
3. Generate simulations with seed=99
4. Compare outputs to verify reproducibility
"""

import sys
import subprocess
from pathlib import Path
import pandas as pd
import numpy as np

# Path to the simulation script
LOCLUST_REPO = Path("/home/ewa/cleme/hilary/repos/loclust")
SIMULATE_SCRIPT = LOCLUST_REPO / "scripts" / "simulate_trajectories.py"

# Test output directory
TEST_DIR = Path("/home/ewa/Dropbox/mssm_research/loclust/simulations/seed_test")
TEST_DIR.mkdir(exist_ok=True)

def run_simulation_with_seed(seed, output_file):
    """
    Run simulate_trajectories.py with a specific random seed.

    We need to modify the script to accept a seed parameter.
    For now, we'll call it via Python and set seeds programmatically.
    """
    # Import the simulation module
    sys.path.insert(0, str(LOCLUST_REPO))

    from random import seed as set_random_seed
    import numpy as np
    from loclust.simulate import simu
    from loclust.parse import write_trajectories

    # Set seeds
    set_random_seed(seed)
    np.random.seed(seed)

    # Run simulation with specific parameters
    trajectories = simu(
        num_traj=10,           # Small number for testing
        num_points=20,         # 20 time points
        noise_lev="0.04",      # Single noise level
        funcs="exponential,hyperbolic,norm",  # 3 functions
        rep=5,                 # 5 replicates
        combine_funcs=3,       # Combine all 3 functions
        params="default",      # Use random parameters
        percent_remove=0.0,    # No removal
        end=False,
        x_noise="0.0"          # No X-axis noise
    )

    # Write trajectories
    write_trajectories(trajectories, output_file)

    print(f"Generated {len(trajectories)} trajectories with seed={seed}")
    print(f"Output: {output_file}")

    return trajectories

def compare_trajectory_files(file1, file2):
    """Compare two trajectory files to check if they're identical."""
    df1 = pd.read_csv(file1, sep='\t', index_col=0)
    df2 = pd.read_csv(file2, sep='\t', index_col=0)

    print(f"\nComparing {file1.name} vs {file2.name}:")
    print(f"  Shape: {df1.shape} vs {df2.shape}")

    if df1.shape != df2.shape:
        print("  ❌ DIFFERENT SHAPES")
        return False

    # Sort by index to ensure same order
    df1 = df1.sort_index()
    df2 = df2.sort_index()

    # Compare all columns
    differences = []

    for col in df1.columns:
        if col in ['X', 'Y']:
            # For X and Y, we need to compare comma-separated values
            for i, idx in enumerate(df1.index):
                val1_str = str(df1.iloc[i][col])
                val2_str = str(df2.iloc[i][col])

                val1 = [float(x) for x in val1_str.split(',')]
                val2 = [float(x) for x in val2_str.split(',')]

                if not np.allclose(val1, val2, rtol=1e-10):
                    differences.append(f"Row {idx}, column {col}")
                    if len(differences) <= 3:  # Show first 3 differences
                        print(f"  Difference at row {i} (ID={idx}), {col}:")
                        print(f"    File 1: {val1[:3]}...")
                        print(f"    File 2: {val2[:3]}...")
        else:
            # For other columns, direct comparison
            if not df1[col].equals(df2[col]):
                differences.append(f"Column {col}")
                # Show which values differ
                print(f"  Column '{col}' has differences:")
                diff_rows = df1[col] != df2[col]
                for i, idx in enumerate(df1.index):
                    if diff_rows.iloc[i]:
                        print(f"    Row {i} (ID={idx}): '{df1.iloc[i][col]}' vs '{df2.iloc[i][col]}'")

    if differences:
        print(f"  ❌ FOUND {len(differences)} DIFFERENCES")
        return False
    else:
        print(f"  ✅ FILES ARE IDENTICAL")
        return True

def main():
    print("="*80)
    print("SEED REPRODUCIBILITY TEST")
    print("="*80)

    # Test 1: Generate with seed=42 (first run)
    print("\nTest 1: Generate simulations with seed=42 (run 1)")
    print("-" * 80)
    out1 = TEST_DIR / "seed42_run1.tsv"
    run_simulation_with_seed(42, out1)

    # Test 2: Generate with seed=42 (second run)
    print("\nTest 2: Generate simulations with seed=42 (run 2)")
    print("-" * 80)
    out2 = TEST_DIR / "seed42_run2.tsv"
    run_simulation_with_seed(42, out2)

    # Test 3: Generate with seed=99
    print("\nTest 3: Generate simulations with seed=99")
    print("-" * 80)
    out3 = TEST_DIR / "seed99_run1.tsv"
    run_simulation_with_seed(99, out3)

    # Compare results
    print("\n" + "="*80)
    print("COMPARISON RESULTS")
    print("="*80)

    # Same seed should produce identical results
    identical_42 = compare_trajectory_files(out1, out2)

    # Different seed should produce different results
    different_seed = compare_trajectory_files(out1, out3)

    # Summary
    print("\n" + "="*80)
    print("VERIFICATION SUMMARY")
    print("="*80)

    if identical_42:
        print("✅ PASS: Same seed (42) produces identical results")
    else:
        print("❌ FAIL: Same seed (42) produces different results")

    if not different_seed:
        print("✅ PASS: Different seeds (42 vs 99) produce different results")
    else:
        print("❌ FAIL: Different seeds (42 vs 99) produce identical results")

    if identical_42 and not different_seed:
        print("\n🎉 REPRODUCIBILITY VERIFIED: Seeding works correctly!")
        print("   You can safely reproduce simulations with proper seed tracking.")
        return 0
    else:
        print("\n⚠️  REPRODUCIBILITY ISSUES DETECTED")
        print("   Further investigation needed before proceeding.")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
