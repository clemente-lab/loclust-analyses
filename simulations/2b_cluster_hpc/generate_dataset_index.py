#!/usr/bin/env python3
"""
Generate index file mapping job array indices to datasets.

This creates a TSV file where each row is:
    index   num_classes   function_combo   noise_level   seed   dataset_path

Job array scripts use LSB_JOBINDEX to look up which dataset to process.
"""

import sys
from pathlib import Path

# Add parent directories to path
sys.path.insert(0, str(Path(__file__).parent.parent / "clustering_scripts"))

from run_clustering import find_all_datasets


def main():
    # Find all datasets
    script_dir = Path(__file__).parent
    data_dir = script_dir.parent / "data"

    datasets = find_all_datasets(data_dir)

    if not datasets:
        print("ERROR: No datasets found!")
        return 1

    # Create index file
    index_file = script_dir / "dataset_index.tsv"

    with open(index_file, 'w') as f:
        # Write header
        f.write("index\tnum_classes\tfunction_combo\tnoise_level\tseed\tdataset_path\n")

        # Write each dataset with 1-based index (LSF uses 1-based indexing)
        for idx, (traj_file, num_classes, metadata) in enumerate(datasets, start=1):
            f.write(f"{idx}\t{num_classes}\t{metadata['function_combo']}\t"
                   f"{metadata['noise_level']}\t{metadata['seed']}\t{traj_file}\n")

    print(f"Created dataset index: {index_file}")
    print(f"Total datasets: {len(datasets)}")

    # Print summary
    by_classes = {}
    for traj_file, num_classes, metadata in datasets:
        by_classes.setdefault(num_classes, []).append(traj_file)

    print("\nDatasets by class:")
    for num_classes in sorted(by_classes.keys()):
        print(f"  {num_classes}-class: {len(by_classes[num_classes])}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
