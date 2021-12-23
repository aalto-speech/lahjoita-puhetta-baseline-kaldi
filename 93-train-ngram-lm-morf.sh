#!/bin/bash -e
#SBATCH --time=12:00:00
#SBATCH --mem=8G

source ../run-expt.sh "${0}"

module purge
module load srilm
module load speech-scripts
module list

segmented_corpus_dir="data/segmented-texts"
corpus_weight="0.05"
corpus="-lp-web-dsp-"

morfessor_name="morfessor${corpus}w${corpus_weight}"
train_file="${segmented_corpus_dir}/train-complete-${morfessor_name}.txt"
dsp_file="${segmented_corpus_dir}/dsp-${morfessor_name}.txt"
web_file="${segmented_corpus_dir}/web-${morfessor_name}.txt"

train_files=("${dsp_file}" "${web_file}" "${train_file}")
# train_files=("${train_file}")

concatenate_corpora () {
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

for train_file in "${train_files[@]}"
do
	if [ ! -f "${train_file}" ]
	then
		echo "Do gunzip $train_file"
		gunzip "${train_file}.gz"
	fi
done

# create vocab
vocab_file="ngram/dsp-web-lp-${morfessor_name}.vocab"
mkdir -p "ngram"
concatenate_corpora |
	ngram-count -order 1 -text - -no-sos -no-eos -write-vocab - |
	egrep -v '(-pau-|<s>|</s>|<unk>)' \
	>"${vocab_file}"

# train LM
model_file="ngram/dsp-web-lp-${morfessor_name}.arpa.gz"
echo "${model_file} :: ${train_files[@]}"
declare -a discounting=(-kndiscount1 -kndiscount2 -kndiscount3 -kndiscount4 -kndiscount5 -kndiscount6)
concatenate_corpora |
	estimate_srilm "${model_file}" "${vocab_file}" "${discounting[@]}"
