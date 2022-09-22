#!/bin/bash -e
#SBATCH --partition batch
#SBATCH --time=4:00:00
#SBATCH --mem=48G

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module list

. ./cmd.sh
. ./path.sh

# dir="exp/chain/tdnn7q_sp"
# dir="exp/chain/tdnn7q_sp_4epochs"
# dir="exp/swbd-nosp/chain/tdnn_swbd-nosp"
dir="exp/swbd/chain/tdnn7q_sp"

# corpus_weight="0.05"
# corpus="-lp-"
# morf_name="morfessor${corpus}w${corpus_weight}"
# vocab="_lm_lp100h-${morf_name}"
# vocab="_word"
# vocab="_lm_lp-${morf_name}"
vocab=_word_lp_web_dsp_nosp
test_lang="data/lang_test$vocab"

train_lang="data/lang_chain"
utils/lang/check_phones_compatible.sh \
    "$train_lang/phones.txt" \
    "$test_lang/phones.txt"

utils/mkgraph.sh \
    --self-loop-scale 1.0 \
    $test_lang \
    $dir \
    ${dir}/graph$vocab|| exit 1;
