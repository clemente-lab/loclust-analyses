#!/usr/bin/env python3
"""
Run systematic clustering on all generated simulation datasets.

This script:
1. Finds all trajectories.tsv files in data/
2. Determines k from directory structure (3_classes → k=3, etc.)
3. Runs LoClust clustering with FIXED k for fair comparison with R methods
4. Outputs trajectories.clust.tsv for v-measure calculation

Usage:
    python run_clustering.py --method gmm                    # Run single method
    python run_clustering.py --method all                     # Run all LoClust methods
    python run_clustering.py --method gmm --dry-run          # Preview what will run
    python run_clustering.py --batch 3_classes --method gmm  # Run specific batch only
"""

import sys
import argparse
import subprocess
from pathlib import Path
from datetime import datetime
import json

# LoClust clustering methods
LOCLUST_METHODS = {
    'gmm': 'Gaussian Mixture Model',
    'hierarchical': 'Hierarchical (Ward linkage)',
    'kmeans': 'K-means',
    'spectral': 'Spectral clustering'
}


def find_all_datasets(data_dir, batch=None, pilot_only=False):
    """
    Find all trajectories.tsv files in the data directory.

    Args:
        data_dir: Path to data directory
        batch: Filter to specific batch (3_classes, 6_classes, 9_classes)
        pilot_only: If True, only include pilot datasets (seeds 042 and 043)

    Returns list of tuples: (trajectories_path, num_classes, metadata)
    """
    data_path = Path(data_dir)
    datasets = []

    # Pattern: data/{N}_classes/{functions}/noise_{X}/seed_{Y}/trajectories.tsv
    for traj_file in data_path.glob('*_classes/*/*/*/trajectories.tsv'):
        parts = traj_file.parts

        # Extract num_classes from directory name (e.g., "3_classes" → 3)
        classes_dir = [p for p in parts if '_classes' in p][0]
        num_classes = int(classes_dir.split('_')[0])

        # Skip if batch filter specified
        if batch and classes_dir != batch:
            continue

        # Extract other metadata from path
        func_combo = parts[-4]  # e.g., "exponential-hyperbolic-norm"
        noise_dir = parts[-3]   # e.g., "noise_0.04"
        seed_dir = parts[-2]    # e.g., "seed_042"

        noise_level = float(noise_dir.split('_')[1])
        seed = int(seed_dir.split('_')[1])

        # Filter to pilot seeds only if requested
        if pilot_only and seed not in [42, 43]:
            continue

        metadata = {
            'num_classes': num_classes,
            'function_combo': func_combo,
            'noise_level': noise_level,
            'seed': seed,
            'classes_dir': classes_dir,
            'noise_dir': noise_dir,
            'seed_dir': seed_dir
        }

        datasets.append((traj_file, num_classes, metadata))

    return sorted(datasets, key=lambda x: (x[2]['num_classes'], x[2]['function_combo'],
                                            x[2]['noise_level'], x[2]['seed']))


def run_loclust_clustering(traj_file, num_classes, metadata, method, dry_run=False):
    """
    Run LoClust clustering on a single dataset with FIXED k.

    Args:
        traj_file: Path to trajectories.tsv
        num_classes: Number of classes (k value to use)
        metadata: Dataset metadata dict
        method: Clustering method (gmm, hierarchical, kmeans, spectral)
        dry_run: If True, print command without running

    Returns:
        output_file path or None if dry_run
    """
    traj_path = Path(traj_file)

    # Create output directory: data/.../clustering/{method}_k{k}/
    clustering_dir = traj_path.parent / 'clustering' / f'{method}_k{num_classes}'
    clustering_dir.mkdir(parents=True, exist_ok=True)

    # Output file: trajectories.clust.tsv (required for compare_clustering.py)
    output_file = clustering_dir / 'trajectories.clust.tsv'
    log_file = clustering_dir / 'clustering_log.txt'

    # Path to cluster_trajectories.py
    cluster_script = Path(__file__).parent.parent.parent / 'scripts' / 'cluster_trajectories.py'

    if not cluster_script.exists():
        print(f"ERROR: cluster_trajectories.py not found at {cluster_script}")
        return None

    # Build command
    cmd = [
        'python', str(cluster_script),
        '-fi', 'trajectories.tsv',
        '-di', str(traj_path.parent),
        '-fo', str(output_file),
        '-do', str(clustering_dir),
        '-c', method,
        '-tk', 'func',  # True label column in our simulations
        '-ak', 'cluster',  # Assigned cluster column to create
        '--force-k', str(num_classes),  # FIXED k - no automatic selection (fair comparison with R methods)
        '-rs', '42',  # Random seed for reproducibility
        '--write_flag',  # Write output files
        '--pca_flag',  # Use PCA (as in R comparison)
        '--no_cluster_plots_flag'  # Don't generate plots (headless mode)
    ]

    # Print what we're doing
    dataset_desc = f"{metadata['classes_dir']}/{metadata['function_combo']}/noise_{metadata['noise_level']:.2f}/seed_{metadata['seed']:03d}"
    print(f"  {method:12s} k={num_classes} → {dataset_desc}")

    if dry_run:
        print(f"    Command: {' '.join(cmd)}")
        return None

    # Run clustering
    start_time = datetime.now()

    try:
        # Redirect output to log file
        with open(log_file, 'w') as log:
            log.write(f"LoClust Clustering Log\n")
            log.write(f"Method: {method}\n")
            log.write(f"k (fixed): {num_classes}\n")
            log.write(f"Dataset: {dataset_desc}\n")
            log.write(f"Started: {start_time.isoformat()}\n")
            log.write(f"Command: {' '.join(cmd)}\n")
            log.write(f"\n{'='*80}\n\n")

            result = subprocess.run(
                cmd,
                stdout=log,
                stderr=subprocess.STDOUT,
                text=True
            )

        end_time = datetime.now()
        duration = end_time - start_time

        # Check if clustering succeeded
        if result.returncode == 0 and output_file.exists():
            # Log success
            with open(log_file, 'a') as log:
                log.write(f"\n{'='*80}\n")
                log.write(f"Completed: {end_time.isoformat()}\n")
                log.write(f"Duration: {duration}\n")
                log.write(f"Status: SUCCESS\n")

            print(f"    ✓ Success ({duration.total_seconds():.1f}s)")
            return output_file
        else:
            with open(log_file, 'a') as log:
                log.write(f"\n{'='*80}\n")
                log.write(f"Status: FAILED (return code {result.returncode})\n")

            print(f"    ✗ Failed (return code {result.returncode})")
            return None

    except Exception as e:
        print(f"    ✗ Error: {e}")
        with open(log_file, 'a') as log:
            log.write(f"\nERROR: {e}\n")
        return None


def main():
    parser = argparse.ArgumentParser(
        description='Run systematic clustering on all simulation datasets'
    )
    parser.add_argument(
        '--method',
        type=str,
        choices=list(LOCLUST_METHODS.keys()) + ['all'],
        required=True,
        help='Clustering method to run (or "all" for all LoClust methods)'
    )
    parser.add_argument(
        '--batch',
        type=str,
        choices=['3_classes', '6_classes', '9_classes'],
        default=None,
        help='Run only specific batch (default: all batches)'
    )
    parser.add_argument(
        '--data-dir',
        type=str,
        default='../data',
        help='Path to data directory (default: ../data)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Print what would be run without actually running'
    )
    parser.add_argument(
        '--pilot-only',
        action='store_true',
        help='Run only on pilot datasets (seeds 042 and 043)'
    )

    args = parser.parse_args()

    # Resolve data directory
    script_dir = Path(__file__).parent
    data_dir = (script_dir / args.data_dir).resolve()

    if not data_dir.exists():
        print(f"ERROR: Data directory not found: {data_dir}")
        return 1

    print(f"Data directory: {data_dir}")
    if args.pilot_only:
        print("PILOT MODE: Only processing seeds 042 and 043")

    # Find all datasets
    print("\nFinding datasets...")
    datasets = find_all_datasets(data_dir, args.batch, pilot_only=args.pilot_only)

    if not datasets:
        print("No datasets found!")
        return 1

    # Group by num_classes
    by_classes = {}
    for traj_file, num_classes, metadata in datasets:
        by_classes.setdefault(num_classes, []).append((traj_file, metadata))

    print(f"\nFound {len(datasets)} datasets:")
    for num_classes in sorted(by_classes.keys()):
        print(f"  {num_classes}-class: {len(by_classes[num_classes])} datasets")

    # Determine which methods to run
    if args.method == 'all':
        methods = list(LOCLUST_METHODS.keys())
    else:
        methods = [args.method]

    print(f"\nMethods to run: {', '.join(methods)}")

    if args.dry_run:
        print("\n*** DRY RUN MODE ***\n")

    # Run clustering
    total_runs = len(datasets) * len(methods)
    successful = 0
    failed = 0

    print(f"\n{'='*80}")
    print(f"STARTING CLUSTERING: {total_runs} runs")
    print(f"{'='*80}\n")

    start_time = datetime.now()

    for method in methods:
        print(f"\n[METHOD: {method.upper()} - {LOCLUST_METHODS[method]}]")

        for traj_file, num_classes, metadata in datasets:
            result = run_loclust_clustering(
                traj_file, num_classes, metadata, method, args.dry_run
            )

            if not args.dry_run:
                if result:
                    successful += 1
                else:
                    failed += 1

    end_time = datetime.now()
    duration = end_time - start_time

    # Summary
    print(f"\n{'='*80}")
    print(f"CLUSTERING COMPLETE")
    print(f"{'='*80}")
    if not args.dry_run:
        print(f"Total runs: {total_runs}")
        print(f"Successful: {successful}")
        print(f"Failed: {failed}")
        print(f"Duration: {duration}")
    else:
        print(f"Would run: {total_runs} clustering jobs")
    print(f"{'='*80}\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
