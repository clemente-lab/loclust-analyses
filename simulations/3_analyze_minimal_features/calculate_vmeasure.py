#!/usr/bin/env python3
"""
Calculate v-measure and other clustering metrics for all clustered datasets.

This script:
1. Finds all trajectories.clust.tsv files
2. Calculates v-measure, NVI, F-measure, ARI, etc.
3. Aggregates results into comprehensive TSV file

Usage:
    python calculate_vmeasure.py                    # Process all methods
    python calculate_vmeasure.py --method gmm       # Process specific method
    python calculate_vmeasure.py --batch 3_classes  # Process specific batch
"""

import sys
import argparse
from pathlib import Path
from collections import defaultdict
import pandas as pd
import numpy as np

# Import from loclust (fixed from legacy 'lodi')
from loclust.parse import read_trajectories

# Import sklearn metrics directly (avoid loclust wrappers that expect different format)
from sklearn.metrics import (
    homogeneity_completeness_v_measure,
    adjusted_rand_score,
    normalized_mutual_info_score,
    f1_score
)


def find_clustered_files(data_dir, method_filter=None, batch_filter=None):
    """
    Find all *.clust.tsv files in data_minimal_features structure.

    Structure: data_minimal_features/input_trajs/8/{3,6,9}/clustering/{method}_k{k}/*.clust.tsv
    Filename format: {noise}noise.{functions}.200reps.{rep}.clust.tsv

    Returns list of dicts with file path and metadata
    """
    data_path = Path(data_dir)
    files = []

    # Pattern: data_minimal_features/input_trajs/8/{3,6,9}/clustering/{method}_k{k}/*.clust.tsv
    for clust_file in data_path.glob('input_trajs/8/*/clustering/*/*.clust.tsv'):
        # Skip sample directory
        if 'sample' in clust_file.parts:
            continue

        parts = clust_file.parts

        # Find indices of key directories
        try:
            input_idx = parts.index('input_trajs')
            num_classes = int(parts[input_idx + 2])  # "3", "6", or "9"
        except (ValueError, IndexError):
            print(f"  WARNING: Cannot parse num_classes from {clust_file}")
            continue

        # Skip if batch filter specified
        if batch_filter and f"{num_classes}_classes" != batch_filter:
            continue

        # Get method directory (e.g., "gmm_k3")
        method_dir = parts[-2]
        try:
            method_parts = method_dir.split('_k')
            method = method_parts[0]
            k = int(method_parts[1])
        except (ValueError, IndexError):
            print(f"  WARNING: Cannot parse method from {method_dir}")
            continue

        # Skip if method filter specified
        if method_filter and method != method_filter:
            continue

        # Parse filename: 0.0noise.exponential-hyperbolic-norm.200reps.0.clust.tsv
        filename = clust_file.name
        name_parts = filename.replace('.clust.tsv', '').split('.')

        try:
            # Extract noise level: "0" + "04noise" -> 0.04
            # Files like: 0.04noise.exponential-hyperbolic-norm.200reps.0.clust.tsv
            # Split by '.' gives: ['0', '04noise', 'exponential-hyperbolic-norm', '200reps', '0']
            # Need to combine parts[0] and parts[1] to get full noise level
            if 'noise' in name_parts[1]:
                noise_str = name_parts[0] + '.' + name_parts[1]
                noise_level = float(noise_str.replace('noise', ''))
                func_start_idx = 2
            else:
                # Fallback for files without decimal in noise (e.g., "0noise")
                noise_str = name_parts[0]
                noise_level = float(noise_str.replace('noise', ''))
                func_start_idx = 1

            # Extract replicate/seed number from "200reps.X" -> X
            seed = int(name_parts[-1])

            # Extract function combination: everything between noise and "200reps"
            func_combo = '.'.join(name_parts[func_start_idx:-1])
            func_combo = func_combo.replace('.200reps', '')
        except (ValueError, IndexError):
            print(f"  WARNING: Cannot parse metadata from {filename}")
            continue

        files.append({
            'file': clust_file,
            'method': method,
            'k': k,
            'num_classes': num_classes,
            'function_combo': func_combo,
            'noise_level': noise_level,
            'seed': seed,
        })

    return sorted(files, key=lambda x: (x['num_classes'], x['method'],
                                         x['function_combo'], x['noise_level'], x['seed']))


def calculate_metrics(file_path, true_label_key='func'):
    """
    Calculate clustering metrics for a single clustered file.

    Returns dict with metrics or None if error
    """
    try:
        # Read trajectories
        trajs = read_trajectories(file_path)

        if not trajs:
            print(f"  WARNING: No trajectories found in {file_path}")
            return None

        # Extract cluster assignments and true labels
        data = defaultdict(list)
        for t in trajs:
            for k in t.mdata.keys():
                data[k].append(t.mdata[k])

        # Check required columns exist
        if 'cluster' not in data:
            print(f"  WARNING: No 'cluster' column in {file_path}")
            return None

        if true_label_key not in data:
            print(f"  WARNING: No '{true_label_key}' column in {file_path}")
            return None

        # Prepare data for metrics
        dat = {
            'cluster': data['cluster'],
            'original_trajectory': list(data[true_label_key])
        }

        # Number of clusters
        k = len(set(data['cluster']))

        # Calculate metrics using sklearn directly
        metrics = {'k': k}

        true_labels = dat['original_trajectory']
        pred_labels = dat['cluster']

        try:
            # NVI = 1 - NMI (Normalized Mutual Information)
            nmi = normalized_mutual_info_score(true_labels, pred_labels)
            metrics['nvi'] = 1.0 - nmi
        except (ValueError, ZeroDivisionError):
            metrics['nvi'] = np.nan

        try:
            # F-measure with weighted average for multiclass
            metrics['f_measure'] = f1_score(true_labels, pred_labels, average='weighted')
        except (ValueError, ZeroDivisionError):
            metrics['f_measure'] = np.nan

        try:
            homogeneity, completeness, v_measure_score = homogeneity_completeness_v_measure(
                true_labels, pred_labels
            )
            metrics['v_measure'] = v_measure_score
            metrics['homogeneity'] = homogeneity
            metrics['completeness'] = completeness
        except (ValueError, ZeroDivisionError):
            metrics['v_measure'] = np.nan
            metrics['homogeneity'] = np.nan
            metrics['completeness'] = np.nan

        try:
            metrics['ari'] = adjusted_rand_score(true_labels, pred_labels)
        except (ValueError, ZeroDivisionError):
            metrics['ari'] = np.nan

        return metrics

    except Exception as e:
        print(f"  ERROR calculating metrics for {file_path}: {e}")
        return None


def main():
    parser = argparse.ArgumentParser(
        description='Calculate clustering metrics for all clustered datasets'
    )
    parser.add_argument(
        '--method',
        type=str,
        default=None,
        help='Filter by specific method (gmm, hierarchical, kmeans, spectral, kml, etc.)'
    )
    parser.add_argument(
        '--batch',
        type=str,
        choices=['3_classes', '6_classes', '9_classes'],
        default=None,
        help='Process only specific batch'
    )
    parser.add_argument(
        '--data-dir',
        type=str,
        default='../data_minimal_features',
        help='Path to data directory (default: ../data_minimal_features)'
    )
    parser.add_argument(
        '--output',
        type=str,
        default='../results_minimal_features/vmeasure_scores.tsv',
        help='Output file for aggregated results'
    )
    parser.add_argument(
        '--true-label-key',
        type=str,
        default='func',
        help='Column name for true labels (default: func)'
    )

    args = parser.parse_args()

    # Resolve paths
    script_dir = Path(__file__).parent
    data_dir = (script_dir / args.data_dir).resolve()
    output_file = (script_dir / args.output).resolve()

    if not data_dir.exists():
        print(f"ERROR: Data directory not found: {data_dir}")
        return 1

    print(f"Data directory: {data_dir}")
    print(f"Output file: {output_file}")

    # Find all clustered files
    print("\nFinding clustered files...")
    files = find_clustered_files(data_dir, args.method, args.batch)

    if not files:
        print("No clustered files found!")
        print("\nMake sure you've run clustering first:")
        print("  cd ../clustering_scripts")
        print("  python run_clustering.py --method gmm")
        return 1

    # Group by method
    by_method = defaultdict(list)
    for f in files:
        by_method[f['method']].append(f)

    print(f"\nFound {len(files)} clustered files:")
    for method in sorted(by_method.keys()):
        print(f"  {method:12s}: {len(by_method[method])} files")

    # Calculate metrics for all files
    print(f"\n{'='*80}")
    print("CALCULATING METRICS")
    print(f"{'='*80}\n")

    results = []
    successful = 0
    failed = 0

    for file_info in files:
        # Create classes_dir description from num_classes
        classes_dir = f"{file_info['num_classes']}_classes"
        desc = f"{classes_dir}/{file_info['function_combo']}/noise_{file_info['noise_level']:.2f}/seed_{file_info['seed']:03d}"
        print(f"  {file_info['method']:12s} → {desc}", end='')

        metrics = calculate_metrics(file_info['file'], args.true_label_key)

        if metrics:
            # Combine file metadata with calculated metrics
            result = {
                'method': file_info['method'],
                'num_classes': file_info['num_classes'],
                'function_combo': file_info['function_combo'],
                'noise_level': file_info['noise_level'],
                'seed': file_info['seed'],
                'k_detected': metrics['k'],
                'k_correct': file_info['num_classes'] == metrics['k'],
                'nvi': metrics['nvi'],
                'v_measure': metrics['v_measure'],
                'homogeneity': metrics['homogeneity'],
                'completeness': metrics['completeness'],
                'f_measure': metrics['f_measure'],
                'ari': metrics['ari']
            }
            results.append(result)
            successful += 1
            print(f" ✓ (ARI={metrics['ari']:.3f}, V={metrics['v_measure']:.3f})")
        else:
            failed += 1
            print(" ✗")

    print(f"\n{'='*80}")
    print("METRICS CALCULATION COMPLETE")
    print(f"{'='*80}")
    print(f"Total files: {len(files)}")
    print(f"Successful: {successful}")
    print(f"Failed: {failed}")
    print(f"{'='*80}\n")

    if not results:
        print("No results to save!")
        return 1

    # Convert to DataFrame and save
    df = pd.DataFrame(results)

    # Ensure output directory exists
    output_file.parent.mkdir(parents=True, exist_ok=True)

    # Save to TSV
    df.to_csv(output_file, sep='\t', index=False)
    print(f"Results saved to: {output_file}")

    # Print summary statistics
    print("\n" + "="*80)
    print("SUMMARY BY METHOD")
    print("="*80 + "\n")

    summary = df.groupby('method').agg({
        'ari': ['mean', 'std', 'count'],
        'v_measure': ['mean', 'std'],
        'nvi': ['mean', 'std'],
        'k_correct': 'mean'
    }).round(3)

    print(summary)
    print()

    # Save summary
    summary_file = output_file.parent / 'vmeasure_summary.tsv'
    summary.to_csv(summary_file, sep='\t')
    print(f"Summary saved to: {summary_file}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
