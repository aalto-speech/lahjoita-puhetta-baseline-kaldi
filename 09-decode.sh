#!/bin/bash -e

source ../run-expt.sh "${0}"

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module list

. ./cmd.sh
. ./path.sh

datadir=lp-dev

# lang dir used for decoding
vocab=_word_nosp
lang=data/lang_test${vocab}

# AM
model=exp/tri3b_mmi_b0.1

steps/decode_fmllr.sh --nj 100 --cmd "$decode_cmd" \
    ${model}/graph${vocab} \
    data/$datadir \
    ${model}/decode_${datadir}${vocab} || exit 1;
