#!/bin/bash
# Cleanup script for 2b_cluster_minimal_features pipeline
# This script cleans logs and optionally deletes clustering results
# WARNING: This only affects the minimal_features pipeline, NOT other pipelines

set -e

SCRIPT_DIR="/sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_minimal_features"
DATA_DIR="/sc/arion/projects/CVDlung/earl/loclust/simulations/data_potentially_simple"
RESULTS_DIR="/sc/arion/projects/CVDlung/earl/loclust/simulations/results_minimal_features"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=================================================="
echo "Cleanup Script for minimal_features Pipeline"
echo "=================================================="
echo ""
echo "This script will clean files ONLY for the minimal_features pipeline."
echo "Other pipelines (2b_cluster_hpc, 2b_cluster_potentially_simple) will NOT be affected."
echo ""

# Function to show file counts and sizes
show_status() {
    echo ""
    echo "Current Status:"
    echo "---------------"

    # Log files
    if [ -d "$SCRIPT_DIR/logs" ]; then
        LOG_COUNT=$(ls "$SCRIPT_DIR/logs"/*.out "$SCRIPT_DIR/logs"/*.err 2>/dev/null | wc -l)
        LOG_SIZE=$(du -sh "$SCRIPT_DIR/logs" 2>/dev/null | cut -f1)
        echo "Log files: $LOG_COUNT files ($LOG_SIZE)"
    else
        echo "Log files: None"
    fi

    # Clustering results in data directory
    if [ -d "$DATA_DIR/input_trajs" ]; then
        CLUST_COUNT=$(find "$DATA_DIR/input_trajs" -name "*.clust.tsv" 2>/dev/null | wc -l)
        CLUST_SIZE=$(du -sh "$DATA_DIR/input_trajs/8/*/clustering" 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "0")
        echo "Clustering result files: $CLUST_COUNT files"
    else
        echo "Clustering result files: None"
    fi

    # Aggregated results
    if [ -d "$RESULTS_DIR" ]; then
        RESULTS_COUNT=$(ls "$RESULTS_DIR"/*.tsv "$RESULTS_DIR"/*.png 2>/dev/null | wc -l)
        RESULTS_SIZE=$(du -sh "$RESULTS_DIR" 2>/dev/null | cut -f1)
        echo "Aggregated results: $RESULTS_COUNT files ($RESULTS_SIZE)"
    else
        echo "Aggregated results: None"
    fi

    echo ""
}

# Show current status
show_status

# Parse command line arguments
CLEAN_LOGS=false
CLEAN_RESULTS=false
CLEAN_AGGREGATED=false
CLEAN_ALL=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --logs)
            CLEAN_LOGS=true
            shift
            ;;
        --clustering-results)
            CLEAN_RESULTS=true
            shift
            ;;
        --aggregated-results)
            CLEAN_AGGREGATED=true
            shift
            ;;
        --all)
            CLEAN_ALL=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --logs                  Clean log files (*.out, *.err)"
            echo "  --clustering-results    Delete clustering output files (*.clust.tsv, logs)"
            echo "  --aggregated-results    Delete aggregated results (vmeasure scores, plots)"
            echo "  --all                   Clean everything (logs + results + aggregated)"
            echo "  --dry-run               Show what would be deleted without actually deleting"
            echo "  --help                  Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --logs                          # Clean only log files"
            echo "  $0 --clustering-results --dry-run  # Show what clustering results would be deleted"
            echo "  $0 --all                           # Clean everything"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}ERROR: Unknown option: $1${NC}"
            echo "Use --help to see available options"
            exit 1
            ;;
    esac
done

# If --all is specified, enable everything
if [ "$CLEAN_ALL" = true ]; then
    CLEAN_LOGS=true
    CLEAN_RESULTS=true
    CLEAN_AGGREGATED=true
fi

# If no options specified, show help
if [ "$CLEAN_LOGS" = false ] && [ "$CLEAN_RESULTS" = false ] && [ "$CLEAN_AGGREGATED" = false ]; then
    echo -e "${YELLOW}No cleanup options specified. Use --help to see available options.${NC}"
    exit 0
fi

# Confirm action unless dry-run
if [ "$DRY_RUN" = false ]; then
    echo -e "${RED}WARNING: This will permanently delete files!${NC}"
    echo ""
    echo "What will be cleaned:"
    [ "$CLEAN_LOGS" = true ] && echo "  - Log files in $SCRIPT_DIR/logs/"
    [ "$CLEAN_RESULTS" = true ] && echo "  - Clustering results in $DATA_DIR/input_trajs/*/clustering/"
    [ "$CLEAN_AGGREGATED" = true ] && echo "  - Aggregated results in $RESULTS_DIR/"
    echo ""
    read -p "Are you sure you want to proceed? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Cleanup cancelled."
        exit 0
    fi
else
    echo -e "${YELLOW}DRY RUN MODE - No files will actually be deleted${NC}"
    echo ""
fi

# Clean log files
if [ "$CLEAN_LOGS" = true ]; then
    echo ""
    echo "Cleaning log files..."
    if [ "$DRY_RUN" = true ]; then
        echo "Would delete:"
        ls "$SCRIPT_DIR/logs"/*.out "$SCRIPT_DIR/logs"/*.err 2>/dev/null || echo "  No log files found"
    else
        if [ -d "$SCRIPT_DIR/logs" ]; then
            rm -f "$SCRIPT_DIR/logs"/*.out "$SCRIPT_DIR/logs"/*.err
            echo -e "${GREEN}✓ Log files deleted${NC}"
        else
            echo "No log directory found"
        fi
    fi
fi

# Clean clustering results
if [ "$CLEAN_RESULTS" = true ]; then
    echo ""
    echo "Cleaning clustering results..."
    if [ "$DRY_RUN" = true ]; then
        echo "Would delete:"
        find "$DATA_DIR/input_trajs/8" -type d -name "clustering" 2>/dev/null || echo "  No clustering directories found"
    else
        if [ -d "$DATA_DIR/input_trajs" ]; then
            # Delete all clustering directories
            find "$DATA_DIR/input_trajs/8" -type d -name "clustering" -exec rm -rf {} + 2>/dev/null || true
            echo -e "${GREEN}✓ Clustering results deleted${NC}"
        else
            echo "No clustering results found"
        fi
    fi
fi

# Clean aggregated results
if [ "$CLEAN_AGGREGATED" = true ]; then
    echo ""
    echo "Cleaning aggregated results..."
    if [ "$DRY_RUN" = true ]; then
        echo "Would delete:"
        ls "$RESULTS_DIR"/*.tsv "$RESULTS_DIR"/*.png "$RESULTS_DIR"/*.log 2>/dev/null || echo "  No aggregated results found"
    else
        if [ -d "$RESULTS_DIR" ]; then
            rm -f "$RESULTS_DIR"/*.tsv "$RESULTS_DIR"/*.png "$RESULTS_DIR"/*.log 2>/dev/null || true
            echo -e "${GREEN}✓ Aggregated results deleted${NC}"
        else
            echo "No aggregated results directory found"
        fi
    fi
fi

echo ""
echo "=================================================="
echo "Cleanup Complete!"
echo "=================================================="

# Show status after cleanup
if [ "$DRY_RUN" = false ]; then
    show_status
fi
