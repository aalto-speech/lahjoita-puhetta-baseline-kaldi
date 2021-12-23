#!/bin/bash -e
#SBATCH --partition batch
#SBATCH --time=4:00:00
#SBATCH --mem=3G

source ../run-expt.sh "${0}"

module purge
module load Morfessor
module load srilm
module list

train_file="data/lp-train-complete/text.plain"
dsp_file="/scratch/work/moisioa3/lahjoita-puhetta-kaldi/baseline/data/lm-train/dsp.txt"
web_file="/scratch/work/moisioa3/lahjoita-puhetta-kaldi/baseline/data/lm-train/web.txt"

# input_files=("${train_file}")

# large LM
input_files=("${train_file}" "${web_file}" "${dsp_file}")

segment_text () {
	local in_file="${1}"
	local out_file="${2}"
	local segment_file="${3}"

	echo "${out_file} :: ${in_file}"
	grep -v '^\s*$' "${in_file}" |
	  # modified segment-text.py script, original had some utf8/ascii problem
	  "local/segment-text.py" <(zcat "${segment_file}") |
	  gzip \
	  >"${out_file}"
}

corpus_weights="0.05"
# for corpus in -lp-
for corpus in -lp-web-dsp-
do
	for corpus_weight in $corpus_weights
	# for corpus_weight in 0.05
	do
		model_name="morfessor${corpus}w${corpus_weight}"
		model_file="morfessor/${model_name}.model.gz"
		vocab_file="morfessor/${model_name}-lp.vocab"
		if [ ! -s "${vocab_file}" ]
		then
			echo "${vocab_file}"
			cat "${input_files[@]}" |
				ngram-count -order 1 -text - -no-sos -no-eos -write-vocab - |
				egrep -v '(-pau-|<s>|</s>|<unk>)' \
				>"${vocab_file}"
		fi

		segment_file="morfessor/${model_name}.segment"
		echo "${segment_file}"
		morfessor-segment \
			--load <(zcat "${model_file}") \
			--encoding 'UTF-8' \
			--output "${segment_file}" \
			--verbose 3 \
			<(cut -f 1 "${vocab_file}")
		echo "morfessor-segment returned"

		rm -f "${segment_file}.gz"
		gzip "${segment_file}"
		echo "segment_vocabulary finished."

		out_dir="data/segmented-texts"
		mkdir -p "${out_dir}"

		segment_text "${train_file}" \
			"${out_dir}/train-complete-${model_name}.txt.gz" "${segment_file}"
		segment_text "${dsp_file}" \
			"${out_dir}/dsp-${model_name}.txt.gz" "${segment_file}"
		segment_text "${web_file}" \
			"${out_dir}/web-${model_name}.txt.gz" "${segment_file}"

		echo "segment_data finished."
	done
done
