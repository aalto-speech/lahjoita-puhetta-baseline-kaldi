#!/bin/bash -e

source ../run-expt.sh "${0}"

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module load sox
module load flac
module list

. ./cmd.sh
. ./path.sh

stage=0
extract_feats=false
extract_ivecs=false
. ./utils/parse_options.sh

cd "${EXPT_SCRIPT_DIR}"

decode_sets="lp-dev"

dir=exp/chain/tdnn7q_sp

corpus_weight="0.05"
corpus="lp"
# corpus="lp-web-dsp"
morf_name="morfessor-${corpus}-w${corpus_weight}"
# vocab=_word_lp_web_dsp_nosp
vocab="_lm_${corpus}-${morf_name}"
test_lang="data/lang_test$vocab"

for decode_set in $decode_sets; do
    if $extract_feats; then
        utils/copy_data_dir.sh \
            data/$decode_set \
            data/${decode_set}_hires

        steps/make_mfcc.sh --nj 17 --mfcc-config conf/mfcc_hires.conf \
            --cmd "$train_cmd" \
            data/${decode_set}_hires

        steps/compute_cmvn_stats.sh \
            data/${decode_set}_hires
        
        utils/fix_data_dir.sh \
            data/${decode_set}_hires
    fi
    if $extract_ivecs; then
        steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj 17 \
            data/${decode_set}_hires \
            exp/nnet3${nnet3_affix}/extractor \
            exp/nnet3${nnet3_affix}/ivectors_${decode_set}_hires
    fi

    steps/nnet3/decode.sh --nj 30 --cmd "$decode_cmd" \
        --stage 3 \
        --acwt 1.0 \
        --post-decode-acwt 10.0 \
        --online-ivector-dir exp/nnet3${nnet3_affix}/ivectors_${decode_set}_hires \
        $dir/graph${vocab} \
        data/${decode_set}_hires \
        $dir/decode_${decode_set}${vocab}
done
