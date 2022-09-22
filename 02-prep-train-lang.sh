#!/bin/bash -e
#SBATCH --time=02:00:00
#SBATCH --mem=4G

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module list

. ./cmd.sh
. ./path.sh

# training lang dir
lang=lang_nosp

utils/prepare_lang.sh \
  data/local/dict_train_nosp \
  ".oov" \
  data/local/lang_tmp_nosp \
  data/$lang
