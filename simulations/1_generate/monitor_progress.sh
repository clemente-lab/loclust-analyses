#!/bin/bash

# Monitor data generation progress
PID=142015
DATA_DIR="/home/ewa/Dropbox/mssm_research/loclust/simulations/data"
TARGET=2100

while ps -p $PID > /dev/null 2>&1; do
    count=$(find "$DATA_DIR" -name "trajectories.tsv" 2>/dev/null | wc -l)
    pct=$((count * 100 / TARGET))
    echo "$(date '+%H:%M:%S') - Progress: $count / $TARGET datasets ($pct%)"
    sleep 30
done

echo ""
echo "Generation complete!"
count=$(find "$DATA_DIR" -name "trajectories.tsv" | wc -l)
pct=$((count * 100 / TARGET))
echo "Final count: $count datasets ($pct%)"
