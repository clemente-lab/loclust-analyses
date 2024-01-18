#!/bin/bash
# Generate file structure necessary for a comparison of longitudinal
# clustering tools

# Example user options:
#BASE_DIR=/sc/arion/projects/clemej05a/hilary/testdir
#USER_ID=monach01
#LOCLUST_DIR=/sc/arion/projects/clemej05a/hilary/repos/loclust
#LOCLUST_ENV=loclust3pt8

usage() {
  echo "Usage: $0 [-b BASE_DIR] [-u USER_ID] [-l LOCLUST_DIR] [-e LOCLUST_ENV]" 1>&2
}

exit_abnormal() {
  usage
  exit 1
}

# Interpret user arguments 
while getopts ":b:u:l:e:" options; do
  case "${options}" in 
    b)
      BASE_DIR=${OPTARG}
      ;;
    u)
      USER_ID=${OPTARG}
      ;;
    l)
      LOCLUST_DIR=${OPTARG}
      ;;
    e)
      LOCLUST_ENV=${OPTARG}
      ;;
    *)
      usage
      exit_abnormal
      ;;
  esac
done


# Original dataset variables
O_BASE_DIR=/sc/arion/projects/clemej05a/hilary/loclust_tool_comp
O_INPUTS=$O_BASE_DIR/input_trajs

# Make the necessary directories
mkdir $BASE_DIR -p
chmod -R 777 $BASE_DIR
chmod -R 777 $LOCLUST_DIR/analysis_scripts

## Add input files and update permissions
#TODO: input trajs should probably live in the repository rather than a specific location on minerva.
cp -r $O_INPUTS $BASE_DIR
INPUT_DIR=$BASE_DIR/input_trajs
chmod -R 777 $INPUT_DIR


## Make jobs folders
mkdir $BASE_DIR/jobs -p
cd $BASE_DIR/jobs 
mkdir stderr -p
mkdir stdout -p
cd ..

## Make output folders
for FOLDER in loclust_outputs dtw_outputs dbaGak_outputs kml_outputs kmlShape_outputs traj_outputs pic_outputs
do 
  mkdir $BASE_DIR/$FOLDER -p
  mkdir $BASE_DIR/$FOLDER/8 -p
  mkdir $BASE_DIR/$FOLDER/8/3 -p
  mkdir $BASE_DIR/$FOLDER/8/6 -p
  mkdir $BASE_DIR/$FOLDER/8/9 -p
done

# Making loclust functions accessible
ml anaconda3
#ml python/3.8.11
source activate $LOCLUST_ENV
cd $LOCLUST_DIR
#python setup.py install

# Generate the list of Rtools function calls
cd analysis_scripts 
python sc_create_j_clust_input.py -b $BASE_DIR -s $LOCLUST_DIR/Rscripts -e $LOCLUST_ENV-R

# Generate the job files
# python generate_lsf_cluster_tool.py -c Rtool_commands_for_jobs.txt -u $USER_ID -M 8000 -o $BASE_DIR/jobs -e $LOCLUST_ENV-R --submit
python generate_lsf_cluster_tool.py -c Rtool_commands_for_jobs.txt -u $USER_ID -M 8000 -o $BASE_DIR/jobs -e $LOCLUST_ENV-R

# Direct the user on next steps
#bsub < $BASE_DIR/jobs/*. 

