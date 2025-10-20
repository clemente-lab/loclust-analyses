#!/bin/bash
# Script to clean up old clustering results before rerunning pipeline
#
# WARNING: This will delete all clustering output directories!
# Make sure you have backed up any results you want to keep.
#
# Usage:
#   bash cleanup_old_results.sh [--dry-run]

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DATA_DIR="${SCRIPT_DIR}/../data"
RESULTS_DIR="${SCRIPT_DIR}/../results"

DRY_RUN=false

if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "DRY RUN MODE - no files will be deleted"
    echo ""
fi

echo "=========================================="
echo "Cleanup Old Clustering Results"
echo "=========================================="
echo ""

# Use dataset index to find clustering directories (much faster than find)
INDEX_FILE="${SCRIPT_DIR}/dataset_index.tsv"

if [ ! -f "$INDEX_FILE" ]; then
    echo "ERROR: Dataset index not found: $INDEX_FILE"
    echo "Run generate_dataset_index.py first"
    exit 1
fi

echo "Reading dataset paths from index file..."
DATASET_PATHS=$(tail -n +2 "$INDEX_FILE" | cut -f6)
NUM_DATASETS=$(echo "$DATASET_PATHS" | wc -l)
echo "Found $NUM_DATASETS datasets"

DELETED_COUNT=0
PREVIEW_COUNT=0

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "Would delete clustering directories in:"
    for traj_file in $DATASET_PATHS; do
        traj_dir=$(dirname "$traj_file")
        clust_dir="${traj_dir}/clustering"
        if [ -d "$clust_dir" ]; then
            DELETED_COUNT=$((DELETED_COUNT + 1))
            if [ "$PREVIEW_COUNT" -lt 10 ]; then
                echo "  $clust_dir"
                PREVIEW_COUNT=$((PREVIEW_COUNT + 1))
            fi
        fi
    done
    if [ "$DELETED_COUNT" -gt 10 ]; then
        echo "  ... and $((DELETED_COUNT - 10)) more"
    fi
    echo ""
    echo "Total clustering directories to delete: $DELETED_COUNT"
else
    echo ""
    read -p "Are you sure you want to delete all clustering results? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Cancelled."
        exit 0
    fi

    echo ""
    echo "Deleting clustering directories..."
    for traj_file in $DATASET_PATHS; do
        traj_dir=$(dirname "$traj_file")
        clust_dir="${traj_dir}/clustering"
        if [ -d "$clust_dir" ]; then
            rm -rf "$clust_dir"
            DELETED_COUNT=$((DELETED_COUNT + 1))
            if [ $((DELETED_COUNT % 100)) -eq 0 ]; then
                echo "  Deleted $DELETED_COUNT directories..."
            fi
        fi
    done
    echo "✓ Deleted $DELETED_COUNT clustering directories"
fi

echo ""

# Clean up results directory
if [ -d "$RESULTS_DIR" ]; then
    RESULT_FILES=$(ls "$RESULTS_DIR" 2>/dev/null | wc -l)
    echo "Found $RESULT_FILES files in results directory"

    if [ "$RESULT_FILES" -gt 0 ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "Would delete:"
            ls "$RESULTS_DIR" | head -10
        else
            read -p "Delete results directory contents? (yes/no): " CONFIRM
            if [ "$CONFIRM" = "yes" ]; then
                rm -rf "$RESULTS_DIR"/*
                echo "✓ Deleted results directory contents"
            fi
        fi
    fi
fi

echo ""
echo "=========================================="
if [ "$DRY_RUN" = true ]; then
    echo "Dry run complete - no changes made"
else
    echo "Cleanup complete!"
fi
echo "=========================================="
