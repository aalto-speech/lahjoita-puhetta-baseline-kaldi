#!/bin/bash -e

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module load sox
module load flac
module list

. ./cmd.sh
. ./path.sh

decode_set="lp-dev"
extract_feats=false
extract_ivecs=false
nj=1
dir="exp/swbd/chain/tdnn7q_sp"
vocab="_word_lp_web_dsp_nosp"
# vocab="_lm_lp-web-dsp-morfessor-lp-web-dsp-w0.05"
. ./utils/parse_options.sh


if $extract_feats; then
    utils/copy_data_dir.sh \
        data/$decode_set \
        data/${decode_set}_hires

    steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
        --cmd "$train_cmd" \
        data/${decode_set}_hires

    steps/compute_cmvn_stats.sh \
        data/${decode_set}_hires
    
    utils/fix_data_dir.sh \
        data/${decode_set}_hires
fi
if $extract_ivecs; then
    steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
        data/${decode_set}_hires \
        exp/nnet3${nnet3_affix}/extractor \
        exp/nnet3${nnet3_affix}/ivectors_${decode_set}_hires
fi

steps/nnet3/decode.sh --nj $nj --cmd "$decode_cmd" \
    --acwt 1.0 \
    --post-decode-acwt 10.0 \
    --online-ivector-dir exp/nnet3${nnet3_affix}/ivectors_${decode_set}_hires \
    $dir/graph${vocab} \
    data/${decode_set}_hires \
    $dir/decode_${decode_set}${vocab}
