#!/bin/bash -e

source ../run-expt.sh "${0}"

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module load sox
module load flac
module list

. ./cmd.sh
. ./path.sh

cd "${EXPT_SCRIPT_DIR}"

for set_name in lp-{train-complete,dev,test}
do
	data_dir="data/${set_name}"
	echo "${data_dir}"

	(set -x; steps/make_mfcc.sh --nj 60 --cmd "${train_cmd}" \
	  "${data_dir}" \
	  "log/mfcc-${set_name}" \
	  "mfcc-${set_name}")

	(set -x; steps/compute_cmvn_stats.sh \
	  "${data_dir}" \
	  "log/mfcc-${set_name}" \
	  "mfcc-${set_name}")
done
