#!/usr/bin/env python3
"""
Generate index file mapping job array indices to datasets.

ADAPTED FOR data_potentially_simple structure:
  - Flat directory structure: input_trajs/8/{3,6,9}/*.tsv
  - Metadata encoded in filename: {noise}noise.{functions}.200reps.{rep}.tsv

This creates a TSV file where each row is:
    index   num_classes   function_combo   noise_level   seed   dataset_path

Job array scripts use LSB_JOBINDEX to look up which dataset to process.
"""

import sys
from pathlib import Path


def find_all_datasets(data_dir):
    """
    Find all trajectory TSV files in the data_potentially_simple directory.

    Expected structure: data_potentially_simple/input_trajs/8/{3,6,9}/*.tsv
    Filename format: {noise}noise.{functions}.200reps.{rep}.tsv

    Returns list of tuples: (trajectories_path, num_classes, metadata)
    """
    data_path = Path(data_dir)
    datasets = []

    # Pattern: data_potentially_simple/input_trajs/8/{3,6,9}/*.tsv
    for traj_file in data_path.glob('input_trajs/8/*/*.tsv'):
        # Skip if in sample directory
        if 'sample' in traj_file.parts:
            continue

        # Get num_classes from parent directory name ("3", "6", or "9")
        num_classes = int(traj_file.parent.name)

        # Parse filename: 0.04noise.exponential-hyperbolic-linear-poly-scurve-sin.200reps.2.tsv
        filename = traj_file.name

        # Remove .tsv extension
        name_without_ext = filename.replace('.tsv', '')

        # Extract noise: everything before first occurrence of "noise."
        # Handle formats like "0.0noise", "0.04noise", "0.2noise"
        if 'noise.' not in name_without_ext:
            print(f"Warning: Cannot parse noise from {filename}, skipping")
            continue

        noise_part, rest = name_without_ext.split('noise.', 1)
        noise_level = float(noise_part)

        # Extract seed: last part after "200reps."
        # Format: {functions}.200reps.{seed}
        if '.200reps.' not in rest:
            print(f"Warning: Cannot parse seed from {filename}, skipping")
            continue

        func_combo, seed_str = rest.rsplit('.200reps.', 1)
        seed = int(seed_str)

        metadata = {
            'num_classes': num_classes,
            'function_combo': func_combo,
            'noise_level': noise_level,
            'seed': seed,
        }

        datasets.append((traj_file, num_classes, metadata))

    return sorted(datasets, key=lambda x: (x[2]['num_classes'], x[2]['function_combo'],
                                            x[2]['noise_level'], x[2]['seed']))


def main():
    script_dir = Path(__file__).parent.resolve()
    data_dir = script_dir.parent / "data_potentially_simple"

    datasets = find_all_datasets(data_dir)

    if not datasets:
        print("ERROR: No datasets found!")
        print(f"Looked in: {data_dir}")
        print(f"Expected pattern: input_trajs/8/{{3,6,9}}/*.tsv")
        return 1

    index_file = script_dir / "dataset_index.tsv"

    with open(index_file, 'w') as f:
        f.write("index\tnum_classes\tfunction_combo\tnoise_level\tseed\tdataset_path\n")
        for idx, (traj_file, num_classes, metadata) in enumerate(datasets, start=1):
            f.write(f"{idx}\t{num_classes}\t{metadata['function_combo']}\t"
                   f"{metadata['noise_level']}\t{metadata['seed']}\t{traj_file}\n")

    print(f"Created dataset index: {index_file}")
    print(f"Total datasets: {len(datasets)}")

    by_classes = {}
    for traj_file, num_classes, metadata in datasets:
        by_classes.setdefault(num_classes, []).append(traj_file)

    print("\nDatasets by class:")
    for num_classes in sorted(by_classes.keys()):
        print(f"  {num_classes}-class: {len(by_classes[num_classes])}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
