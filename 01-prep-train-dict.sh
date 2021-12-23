#!/bin/bash

source ../run-expt.sh "${0}"

module purge
module load speech-scripts
module load srilm
module list

. ./cmd.sh
. ./path.sh

datadir="lp-train-complete"

mkdir -p log
local/prepare_train_dict.sh \
    "data/${datadir}/text" | tee "log/prepare_train_dict.log"
