#!/bin/bash -e
#SBATCH --partition batch
#SBATCH --time=8:00:00
#SBATCH --mem=6G

source ../run-expt.sh "${0}"

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module list

. ./cmd.sh
. ./path.sh

# training lang dir
training_lang=data/lang_nosp
# LM
# lm=ngram/lp.arpa.gz
lm=ngram/lp-web-dsp.arpa.gz
# new lang dir used for decoding
# dir=data/lang_test_word_nosp
dir=data/lang_test_word_lp_web_dsp_nosp


# create lang dir for decoding with grammar G.fst
echo "${dir}"
mkdir -p "${dir}"
cp -r "${EXPT_WORK_DIR}/$training_lang/"* "${dir}/"

tmpdir="${EXPT_WORK_DIR}/lm_tmp"
mkdir -p "${tmpdir}"
echo "${tmpdir}/oovs.txt :: ${lm} ${dir}/words.txt"
# find_arpa_oovs.pl will close the input early and cause a SIGPIPE.
zcat "${lm}" |
	"${UTILS_DIR}/find_arpa_oovs.pl" "${dir}/words.txt" \
	>"${tmpdir}/oovs.txt" || true

echo "${dir}/G.fst :: ${lm}"
zcat "${lm}" |
	arpa2fst - |
	fstprint |
	"${UTILS_DIR}/remove_oovs.pl" "${tmpdir}/oovs.txt" |
	"${UTILS_DIR}/eps2disambig.pl" |
	"${UTILS_DIR}/s2eps.pl" |
	fstcompile --isymbols="${dir}/words.txt" \
				--osymbols="${dir}/words.txt" --keep_isymbols=false --keep_osymbols=false |
	fstrmepsilon |
	fstarcsort --sort_type=ilabel \
	>"${dir}/G.fst"

utils/validate_lang.pl --skip-determinization-check "${dir}"

rm -rf "${tmpdir}"
    