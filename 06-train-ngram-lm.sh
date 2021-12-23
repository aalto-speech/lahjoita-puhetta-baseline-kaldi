#!/bin/bash -e
#SBATCH --time=12:00:00
#SBATCH --mem=16G

# word-based LM training -- not used, use subwods instead

source ../run-expt.sh "${0}"

module purge
module load srilm
module load speech-scripts
module list

. ./cmd.sh
. ./path.sh

stage=0

trancript_file="data/lp-train-complete/text.plain"

if [ ! -f "${trancript_file}" ]
then
    local/trn2plain.py --remove-nonwords --remove-dashes \
		"${trancript_file%.plain}" 
		"${trancript_file}"
fi

TRAIN_FILES=("/scratch/work/moisioa3/conv_lm/data/lm-train/dsp.txt"
			"/scratch/work/moisioa3/conv_lm/data/lm-train/web-unique.txt"
			"${trancript_file}")
model_file_name="lp-web-dsp"

# for smaller LM:
# TRAIN_FILES=("${trancript_file}")
# model_file_name="lp"

concatenate_corpora () {
	if [ -n "${1}" ]
	then
		declare -a train_files=("${!1}")
	else
		declare -a train_files=("${TRAIN_FILES[@]}")
	fi

	[ -n "${SENTENCE_LIMIT}" ] || SENTENCE_LIMIT="-0"

	# head will make gzip return a non-zero exit code.
	gzip --stdout --decompress --force "${train_files[@]}" |
		grep -v '######' |
		head --lines="${SENTENCE_LIMIT}" || true

	return 0
}

estimate_srilm () {
	# Output language model file.
	local model_file="${1}"
	shift

	# Vocabulary file contains one word per line. Any text following the word
	# such as counts will be ignored.
	local vocab_file="${1}"
	shift

	local ngram_order="${NGRAM_ORDER:-4}"
	declare -a args=(-order "${ngram_order}")
	if [ "${OPEN_VOCABULARY_NGRAM}" ]
	then
		args+=(-unk)
	else
		args+=(-limit-vocab)
	fi
    # interpolate all n-gram orders
	args+=(-interpolate1 -interpolate2 -interpolate3 -interpolate4 -interpolate5 -interpolate6)
    # minimum count of n-grams that are included in the LM
	args+=(-gt4min 2 -gt5min 2 -gt6min 2)
    # N-gram counts from text file
	args+=(-text -)
	args+=(-lm "${model_file}")
	args+=("${@}")

	echo ngram-count "${args[@]}" -vocab "<(cut -f1 ${vocab_file})"
	ngram-count "${args[@]}" -vocab <(cut -f1 "${vocab_file}")
}

if [ $stage -le 1 ]; then
	# create vocab
	mkdir -p ngram
	vocab_file="ngram/${model_file_name}.vocab"
	concatenate_corpora |
		ngram-count -order 1 -text - -no-sos -no-eos -write-vocab - |
		egrep -v '(-pau-|<s>|</s>|<unk>)' \
		>"${vocab_file}"
fi

if [ $stage -le 2 ]; then
	model_file="ngram/${model_file_name}.arpa.gz"
	echo "${model_file} :: ${TRAIN_FILES[@]}"
	declare -a discounting=(-kndiscount1 -kndiscount2 -kndiscount3 -kndiscount4 -kndiscount5 -kndiscount6)
	concatenate_corpora |
		estimate_srilm "${model_file}" "${vocab_file}" "${discounting[@]}"
fi
