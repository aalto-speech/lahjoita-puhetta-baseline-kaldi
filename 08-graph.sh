#!/bin/bash -e
#SBATCH --time=1:00:00
#SBATCH --mem=14G

source ../run-expt.sh "${0}"
cd "${EXPT_SCRIPT_DIR}"

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module list

. ./cmd.sh
. ./path.sh

# lang dir used for decoding
vocab=_word_nosp
lang=data/lang_test${vocab}

# AM
model=exp/wsj-a/tri3b_mmi_b0.1

. ./utils/parse_options.sh

# check that train and decode phones are the same
utils/lang/check_phones_compatible.sh \
    data/lang_nosp/phones.txt \
    $lang/phones.txt

utils/mkgraph.sh \
    ${lang} \
    ${model} \
    ${model}/graph${vocab}
