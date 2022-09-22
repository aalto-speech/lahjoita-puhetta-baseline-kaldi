#!/bin/bash
#SBATCH --partition batch
#SBATCH --time=4:00:00
#SBATCH --mem=2G

module purge
module load Morfessor
module list

dampening="ones"
corpus_weight="0.05"
random_seed="1"
trancript_file="data/lp-train-complete/text"
trancript_file_plain="${trancript_file}.plain"

if [ ! -f "${trancript_file_plain}" ]
then
    local/trn2plain.py --remove-nonwords --remove-dashes \
        "${trancript_file_plain%.plain}" \
        "${trancript_file_plain}"
fi

dsp_file="data/lm-train/dsp.txt"
web_file="data/lm-train/web.txt"
TRAIN_FILES=("${web_file}" "${dsp_file}" "${trancript_file_plain}")
# TRAIN_FILES=("${trancript_file_plain}")
declare -a extra_args
for file in "${TRAIN_FILES[@]}"
do
    extra_args+=(--traindata "${file}")
done

model_file="morfessor/morfessor-lp-web-dsp-w${corpus_weight}.model"
# model_file="morfessor/morfessor-lp-w${corpus_weight}.model"

mkdir -p "morfessor"
echo "${model_file}"
(set -x; morfessor \
    "${extra_args[@]}" \
    --encoding 'UTF-8' \
    --dampening "${dampening}" \
    --corpusweight "${corpus_weight}" \
    --randseed "${random_seed}" \
    --save "${model_file}" )

rm -f "${model_file}.gz"
gzip "${model_file}"
echo "train_morfessor finished."
