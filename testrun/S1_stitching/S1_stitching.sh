#!/bin/bash
# 
# If your /tmp directory is on a filesystem with less than 10 GB of space, you can set the TMPDIR variable
# in your environment before calling this script, for example, to use your /opt for all file access:
#
#   TMPDIR=/opt/tmp ./examples/demo_tiny.sh /opt/demo

DIR=$(cd "$(dirname "$0")"; pwd)
BASEDIR=$(realpath $DIR/..)

# The temporary directory needs to have 10 GB to store large Docker images
export TMPDIR="${TMPDIR:-/data/sternsonlab/Mingxiao/pipeline_test}"
export SINGULARITY_TMPDIR="${SINGULARITY_TMPDIR:-$TMPDIR}"
export SINGULARITY_CACHEDIR="${SINGULARITY_CACHEDIR:-$TMPDIR/singularity}"
mkdir -p $TMPDIR
mkdir -p $SINGULARITY_TMPDIR
mkdir -p $SINGULARITY_CACHEDIR

datadir="/data/sternsonlab/Zhenggang/2acq/output/M28C_LHA_S1"

#
# Memory Considerations
# =====================
# 
# The value of workers*worker_cores*gb_per_core determines the total Spark memory for each acquisition registration. 
# For the demo, two of these need to fit in main memory. The settings below work for a 40 core machine with 128 GB RAM.
#
# Reducing the gb_per_core to 2 reduces total memory consumption but doubles processing time.
#

/home/m5wei/multifish/main.nf \
    -params-file "/home/m5wei/multifish/testrun/S1_stitching/S1_stitching.json" \
    --runtime_opts "-B $datadir -B $TMPDIR" \
    --shared_work_dir "$datadir" "$@"
