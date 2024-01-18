#!/bin/bash
# Generate file structure necessary for a comparison of longitudinal
# clustering tools

# User options
# BASE_DIR=/sc/arion/projects/clemej05a/hilary/loclust_tool_comp
BASE_DIR=$1

# USER_ID=monach01
USER_ID=$2

# LOCLUST_DIR=/sc/arion/projects/clemej05a/hilary/repos/loclust
LOCLUST_DIR=$3

# LOCLUST_ENV=loclust3pt8
LOCLUST_ENV=$4


usage() {
  echo "Usage: $0 [-b BASE_DIR] [-l LOCLUST_DIR] [-e LOCLUST_ENV]" 1>&2
}

exit_abnormal() {
  usage
  exit 1
}

# Interpret user arguments 
while getopts ":b:l:e:" options; do
  case "${options}" in 
    b)
      BASE_DIR=${OPTARG}
      ;;
    l)
      LOCLUST_DIR=${OPTARG}
      ;;
    e)
      LOCLUST_ENV=${OPTART}
      ;;
    *)
      usage
      exit_abnormal
      ;;
  esac
done

# Calculate V-measure for all available tools
python sc_calculate_v_measure.py -i $BASE_DIR

#ml R/4.1.0
# Generate plot of all available tool results
# NOTE: UPDATE the below script with the version of V-measure data to use
#Rscript ../Rscripts/sc_plot_v_measure_results.R -i $BASE_DIR


