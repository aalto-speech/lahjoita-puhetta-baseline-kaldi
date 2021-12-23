#!/bin/bash -e
#SBATCH --partition batch
#SBATCH --time=4:00:00
#SBATCH --mem=6G

source ../run-expt.sh "${0}"

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module list

. ./cmd.sh
. ./path.sh

corpus_weight="0.05"
# corpus="lp"
corpus="lp-web-dsp"
morf_name="morfessor-${corpus}-w${corpus_weight}"
lm="ngram/${corpus}-${morf_name}.arpa.gz"

dict=data/local/dict_lm_${corpus}-${morf_name}
lang_dir=data/lang_test_lm_${corpus}-${morf_name}

local/prepare_decode_lang_morph.sh \
    "$lm" \
    "$dict" \
    "$lang_dir"
