#!/bin/bash
# Monitor clustering job progress
# Shows real-time status of all methods

SCRIPT_DIR="/sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_minimal_features"
DATA_DIR="/sc/arion/projects/CVDlung/earl/loclust/simulations/data_potentially_simple"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=================================================="
echo "Clustering Job Monitor - minimal_features Pipeline"
echo "=================================================="
echo "$(date)"
echo ""

# LoClust methods
LOCLUST_METHODS=("gmm" "hierarchical" "kmeans" "spectral")
R_METHODS=("kml" "dtwclust" "mfuzz" "traj")

echo "--- LoClust Methods ---"
for method in "${LOCLUST_METHODS[@]}"; do
    LOG_FILE="$SCRIPT_DIR/logs/loclust_${method}.out"
    if [ -f "$LOG_FILE" ]; then
        SUCCESS_COUNT=$(grep -c "SUCCESS:" "$LOG_FILE" 2>/dev/null || echo "0")
        FAIL_COUNT=$(grep -c "FAILED:" "$LOG_FILE" 2>/dev/null || echo "0")

        if [ "$SUCCESS_COUNT" -gt 0 ] || [ "$FAIL_COUNT" -gt 0 ]; then
            echo -e "${method}: ${GREEN}${SUCCESS_COUNT} success${NC}, ${RED}${FAIL_COUNT} failed${NC}"
        else
            echo -e "${method}: ${YELLOW}Running (no completions yet)${NC}"
        fi
    else
        echo -e "${method}: Not started"
    fi
done

echo ""
echo "--- R Methods ---"
for method in "${R_METHODS[@]}"; do
    LOG_FILE="$SCRIPT_DIR/logs/r_${method}.out"
    if [ -f "$LOG_FILE" ]; then
        SUCCESS_COUNT=$(grep -c "SUCCESS:" "$LOG_FILE" 2>/dev/null || echo "0")
        FAIL_COUNT=$(grep -c "FAILED\|ERROR:" "$LOG_FILE" 2>/dev/null || echo "0")

        if [ "$SUCCESS_COUNT" -gt 0 ] || [ "$FAIL_COUNT" -gt 0 ]; then
            echo -e "${method}: ${GREEN}${SUCCESS_COUNT} success${NC}, ${RED}${FAIL_COUNT} failed${NC}"
        else
            echo -e "${method}: ${YELLOW}Running (no completions yet)${NC}"
        fi
    else
        echo -e "${method}: Not started"
    fi
done

echo ""
echo "--- Output File Counts ---"
if [ -d "$DATA_DIR/input_trajs/8" ]; then
    for method in "${LOCLUST_METHODS[@]}" "${R_METHODS[@]}"; do
        COUNT=$(find "$DATA_DIR/input_trajs/8" -name "*.clust.tsv" -path "*/${method}_k*/*" 2>/dev/null | wc -l)
        echo "${method}: $COUNT files created"
    done
else
    echo "Data directory not found"
fi

echo ""
echo "=================================================="
echo "Expected: 1740 files per method"
echo "=================================================="
