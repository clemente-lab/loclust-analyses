#!/bin/bash
# Helper script to list archived vmeasure results
#
# Usage:
#   bash list_archived_results.sh              # List all archives
#   bash list_archived_results.sh compare      # Compare summary stats
#   bash list_archived_results.sh RUN_NAME     # Show details for specific run

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RESULTS_DIR="${SCRIPT_DIR}/../results"
ARCHIVE_DIR="${RESULTS_DIR}/archive"

if [ ! -d "$ARCHIVE_DIR" ]; then
    echo "No archived results found at: $ARCHIVE_DIR"
    exit 0
fi

# Function to list all archives
list_archives() {
    echo "=========================================="
    echo "Archived vmeasure Results"
    echo "=========================================="
    echo ""

    if [ -L "${ARCHIVE_DIR}/latest" ]; then
        LATEST=$(readlink "${ARCHIVE_DIR}/latest")
        echo "Latest run: $LATEST"
        echo ""
    fi

    echo "Available archives:"
    ls -1dt "${ARCHIVE_DIR}"/*/ 2>/dev/null | while read -r dir; do
        RUN_NAME=$(basename "$dir")
        if [ "$RUN_NAME" != "latest" ]; then
            TIMESTAMP=$(stat -c %y "$dir" | cut -d. -f1)
            NUM_FILES=$(ls "$dir" 2>/dev/null | wc -l)
            echo "  $RUN_NAME ($TIMESTAMP) - $NUM_FILES files"
        fi
    done

    echo ""
    echo "View specific run:"
    echo "  bash $0 RUN_NAME"
    echo ""
    echo "Compare all runs:"
    echo "  bash $0 compare"
}

# Function to compare summary statistics across runs
compare_archives() {
    echo "=========================================="
    echo "Comparing vmeasure Results Across Runs"
    echo "=========================================="
    echo ""

    echo "Method performance (v_measure_mean) by run:"
    echo ""
    printf "%-20s" "Method"

    # Print header with run names
    ls -1dt "${ARCHIVE_DIR}"/*/ 2>/dev/null | while read -r dir; do
        RUN_NAME=$(basename "$dir")
        if [ "$RUN_NAME" != "latest" ] && [ -f "$dir/vmeasure_summary.tsv" ]; then
            printf "%-15s" "$RUN_NAME"
        fi
    done
    echo ""

    # For each method, print v_measure_mean across runs
    METHODS=$(tail -n +2 "${ARCHIVE_DIR}"/*/vmeasure_summary.tsv 2>/dev/null | cut -f1 | sort -u)

    for method in $METHODS; do
        printf "%-20s" "$method"

        ls -1dt "${ARCHIVE_DIR}"/*/ 2>/dev/null | while read -r dir; do
            RUN_NAME=$(basename "$dir")
            if [ "$RUN_NAME" != "latest" ] && [ -f "$dir/vmeasure_summary.tsv" ]; then
                SCORE=$(grep "^${method}" "$dir/vmeasure_summary.tsv" 2>/dev/null | cut -f2)
                if [ -z "$SCORE" ]; then
                    printf "%-15s" "N/A"
                else
                    printf "%-15s" "$SCORE"
                fi
            fi
        done
        echo ""
    done

    echo ""
}

# Function to show details for specific run
show_run_details() {
    RUN_NAME="$1"
    RUN_DIR="${ARCHIVE_DIR}/${RUN_NAME}"

    if [ ! -d "$RUN_DIR" ]; then
        echo "Error: Run '$RUN_NAME' not found"
        echo ""
        list_archives
        exit 1
    fi

    echo "=========================================="
    echo "Results for: $RUN_NAME"
    echo "=========================================="
    echo ""

    if [ -f "$RUN_DIR/vmeasure_summary.tsv" ]; then
        echo "V-Measure Summary:"
        column -t -s $'\t' "$RUN_DIR/vmeasure_summary.tsv"
        echo ""
    fi

    echo "Files in archive:"
    ls -lh "$RUN_DIR" | tail -n +2
    echo ""

    echo "Location: $RUN_DIR"
}

# Main
case "${1:-list}" in
    compare)
        compare_archives
        ;;
    list)
        list_archives
        ;;
    *)
        show_run_details "$1"
        ;;
esac
