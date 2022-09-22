#!/bin/bash

. ./cmd.sh
. ./path.sh

datadir="lp-train-complete"

mkdir -p log
local/prepare_train_dict.sh \
    "data/${datadir}/text" | tee "log/prepare_train_dict.log"
