#!/usr/bin/env python3
"""
Calculate V-measure scores for clustering results.

This script calculates clustering performance metrics (V-measure, homogeneity, completeness)
by comparing predicted clusters against ground truth labels. It processes all available
clustering results and skips datasets where clustering failed.

Usage:
    python calculate_vmeasure.py

Output:
    - ../results/vmeasure_scores.tsv: Detailed scores for each dataset/method combination
    - ../results/vmeasure_summary.tsv: Summary statistics by method
"""

import os
import sys
import pandas as pd
import numpy as np
from pathlib import Path
from sklearn.metrics import v_measure_score, homogeneity_score, completeness_score, adjusted_rand_score

# Configuration
SCRIPT_DIR = Path(__file__).parent.absolute()
DATA_DIR = SCRIPT_DIR.parent / "data"
RESULTS_DIR = SCRIPT_DIR.parent / "results"
INDEX_FILE = SCRIPT_DIR / "dataset_index.tsv"

METHODS = ["gmm", "hierarchical", "kmeans", "spectral", "kml", "dtwclust", "traj", "mfuzz"]

def load_dataset_index():
    """Load the dataset index file."""
    df = pd.read_csv(INDEX_FILE, sep='\t')
    return df

def load_ground_truth(traj_file):
    """Load ground truth labels from trajectory file."""
    df = pd.read_csv(traj_file, sep='\t')
    # Ground truth is in the 'func' column
    return df['func'].values

def load_predicted_clusters(cluster_file):
    """Load predicted cluster assignments."""
    if not os.path.exists(cluster_file):
        return None
    try:
        df = pd.read_csv(cluster_file, sep='\t')
        # Predicted clusters are in the 'cluster' column
        if 'cluster' not in df.columns:
            print(f"Warning: 'cluster' column not found in {cluster_file}")
            print(f"Available columns: {list(df.columns)}")
            return None
        return df['cluster'].values
    except Exception as e:
        print(f"Warning: Could not load {cluster_file}: {e}")
        return None

def calculate_metrics(y_true, y_pred):
    """Calculate V-measure, homogeneity, completeness, and ARI."""
    v_measure = v_measure_score(y_true, y_pred)
    homogeneity = homogeneity_score(y_true, y_pred)
    completeness = completeness_score(y_true, y_pred)
    ari = adjusted_rand_score(y_true, y_pred)

    return {
        'v_measure': v_measure,
        'homogeneity': homogeneity,
        'completeness': completeness,
        'ari': ari
    }

def main():
    print("=" * 60)
    print("V-Measure Calculation")
    print("=" * 60)
    print()

    # Load dataset index
    print(f"Loading dataset index from {INDEX_FILE}...")
    index_df = load_dataset_index()
    print(f"Found {len(index_df)} datasets")
    print()

    # Prepare results storage
    results = []

    # Process each dataset and method
    total_combinations = len(index_df) * len(METHODS)
    processed = 0
    skipped = 0

    for idx, row in index_df.iterrows():
        dataset_idx = row['index']
        num_classes = row['num_classes']
        func_combo = row['function_combo']
        noise_level = row['noise_level']
        seed = row['seed']
        traj_file = row['dataset_path']

        # Load ground truth
        try:
            y_true = load_ground_truth(traj_file)
        except Exception as e:
            print(f"Warning: Could not load ground truth for dataset {dataset_idx}: {e}")
            skipped += len(METHODS)
            continue

        # Check each clustering method
        for method in METHODS:
            # Determine cluster file path based on method
            traj_dir = Path(traj_file).parent

            if method in ["kml", "dtwclust", "traj", "mfuzz"]:
                # R methods use method_kN format
                cluster_dir = traj_dir / "clustering" / f"{method}_k{num_classes}"
            else:
                # LoClust methods use method_kN format
                cluster_dir = traj_dir / "clustering" / f"{method}_k{num_classes}"

            cluster_file = cluster_dir / "trajectories.clust.tsv"

            # Try to load predicted clusters
            y_pred = load_predicted_clusters(cluster_file)

            if y_pred is None:
                # Clustering file doesn't exist - method failed for this dataset
                skipped += 1
                continue

            # Calculate metrics
            try:
                metrics = calculate_metrics(y_true, y_pred)

                results.append({
                    'dataset_idx': dataset_idx,
                    'num_classes': num_classes,
                    'func_combo': func_combo,
                    'noise_level': noise_level,
                    'seed': seed,
                    'method': method,
                    'v_measure': metrics['v_measure'],
                    'homogeneity': metrics['homogeneity'],
                    'completeness': metrics['completeness'],
                    'ari': metrics['ari']
                })

                processed += 1

            except Exception as e:
                print(f"Warning: Error calculating metrics for dataset {dataset_idx}, method {method}: {e}")
                skipped += 1
                continue

    print()
    print(f"Processed: {processed}/{total_combinations} dataset-method combinations")
    print(f"Skipped: {skipped}/{total_combinations} (missing clustering results)")
    print()

    # Create results DataFrame
    results_df = pd.DataFrame(results)

    # Save detailed results
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    output_file = RESULTS_DIR / "vmeasure_scores.tsv"
    results_df.to_csv(output_file, sep='\t', index=False)
    print(f"✓ Saved detailed results to {output_file}")

    # Calculate summary statistics by method
    summary = results_df.groupby('method').agg({
        'v_measure': ['mean', 'std', 'min', 'max', 'count'],
        'homogeneity': ['mean', 'std'],
        'completeness': ['mean', 'std'],
        'ari': ['mean', 'std']
    }).round(4)

    # Flatten column names
    summary.columns = ['_'.join(col).strip() for col in summary.columns.values]
    summary = summary.reset_index()

    # Save summary
    summary_file = RESULTS_DIR / "vmeasure_summary.tsv"
    summary.to_csv(summary_file, sep='\t', index=False)
    print(f"✓ Saved summary statistics to {summary_file}")

    print()
    print("Summary by method:")
    print(summary.to_string(index=False))
    print()
    print("=" * 60)
    print("V-Measure Calculation Complete")
    print("=" * 60)

if __name__ == "__main__":
    main()
