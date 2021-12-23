#!/bin/bash -e

source ../run-expt.sh "${0}"

. ./cmd.sh
. ./path.sh

corpus_weight="0.05"
# corpus="lp"
corpus="lp-web-dsp"
morf_name="morfessor-${corpus}-w${corpus_weight}"
lm="ngram/${corpus}-${morf_name}.arpa.gz"
dict=data/local/dict_lm_${corpus}-${morf_name}

local/prepare_dict_morph_from_lm.sh \
    "$lm" \
    "$dict" 
