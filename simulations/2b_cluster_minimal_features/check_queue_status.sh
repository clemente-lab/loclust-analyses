#!/bin/bash
# Check LSF job queue status for clustering jobs
# Shows running vs pending jobs

echo "=================================================="
echo "LSF Job Queue Status"
echo "=================================================="
echo "$(date)"
echo ""

# Check if running on cluster (has bjobs command)
if ! command -v bjobs &> /dev/null; then
    echo "ERROR: This script must be run on the cluster (bjobs command not found)"
    echo "Run via SSH: bash /sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_minimal_features/check_queue_status.sh"
    exit 1
fi

echo "--- Job Status Summary ---"
echo ""

# LoClust jobs
for method in gmm hierarchical kmeans spectral; do
    JOB_NAME="loclust_${method}"

    # Count by status
    RUNNING=$(bjobs -J "$JOB_NAME" 2>/dev/null | grep -c "RUN" || echo "0")
    PENDING=$(bjobs -J "$JOB_NAME" 2>/dev/null | grep -c "PEND" || echo "0")
    DONE=$(bjobs -J "$JOB_NAME" 2>/dev/null | grep -c "DONE" || echo "0")

    TOTAL=$((RUNNING + PENDING + DONE))

    if [ "$TOTAL" -gt 0 ]; then
        echo "${JOB_NAME}:"
        echo "  Running:  $RUNNING"
        echo "  Pending:  $PENDING"
        echo "  Done:     $DONE"
        echo "  Total:    $TOTAL"
        echo ""
    fi
done

# R method jobs
for method in kml dtwclust mfuzz traj; do
    JOB_NAME="r_${method}"

    RUNNING=$(bjobs -J "$JOB_NAME" 2>/dev/null | grep -c "RUN" || echo "0")
    PENDING=$(bjobs -J "$JOB_NAME" 2>/dev/null | grep -c "PEND" || echo "0")
    DONE=$(bjobs -J "$JOB_NAME" 2>/dev/null | grep -c "DONE" || echo "0")

    TOTAL=$((RUNNING + PENDING + DONE))

    if [ "$TOTAL" -gt 0 ]; then
        echo "${JOB_NAME}:"
        echo "  Running:  $RUNNING"
        echo "  Pending:  $PENDING"
        echo "  Done:     $DONE"
        echo "  Total:    $TOTAL"
        echo ""
    fi
done

echo "=================================================="
echo "Overall Summary"
echo "=================================================="
bjobs -u windae01 -sum 2>/dev/null || echo "Could not get user job summary"

echo ""
echo "=================================================="
echo "Queue Load"
echo "=================================================="
bqueues premium 2>/dev/null || echo "Could not get queue info"
