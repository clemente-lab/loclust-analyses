#!/bin/bash
# Fix race condition in all R method scripts

for script in run_r_dtwclust.sh run_r_kml.sh run_r_mfuzz.sh run_r_method_array.sh; do
    echo "Fixing $script..."

    # Create backup
    cp "$script" "${script}.bak"

    # Replace the problematic section with the simple version
    sed -i '80,116d' "$script"

    # Insert the fixed version at line 80
    sed -i '79a\
OUTPUT_FILE="${OUTPUT_DIR}/trajectories.clust.tsv"\
\
echo ""\
echo "Dataset: ${FUNC_COMBO} / noise_${NOISE_LEVEL} / seed_${SEED}"\
echo "k = $NUM_CLASSES"\
echo "Output: $OUTPUT_FILE"\
echo ""\
\
# Run R clustering using single-file wrapper script\
SINGLE_R_SCRIPT="${SCRIPT_DIR}/run_single_r_method.R"\
\
Rscript "$SINGLE_R_SCRIPT" "$method" "$TRAJ_FILE" "$NUM_CLASSES"\
\
# Check success\
if [ -f "$OUTPUT_FILE" ]; then\
    NUM_LINES=$(wc -l < "$OUTPUT_FILE")\
    echo "SUCCESS: Created $OUTPUT_FILE ($NUM_LINES lines)"\
    exit 0\
else\
    echo "FAILED: Output file not created"\
    exit 1\
fi' "$script"

    echo "Fixed $script"
done

echo "All scripts fixed!"
