#!/bin/bash -e

module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module load sox
module load flac
module list

# TextGrid format requires the python package textgrid.
# Word alignment does not support graphs generated by subword-kaldi.

. ./cmd.sh
. ./path.sh

decode_set="lp-dev"
vocab="_word_lp_web_dsp_nosp"
am="exp/swbd/chain/tdnn7q_sp"
textgrids=false
ctms=true
nj=1
. ./utils/parse_options.sh

if $ctms; then
    steps/get_ctm.sh --cmd "$decode_cmd" \
        --frame-shift "0.03" \
        --use-segments false \
        "data/${decode_set}_hires" \
        "$am/graph${vocab}" \
        "$am/decode_${decode_set}${vocab}" || exit 1;
fi

if $textgrids; then
    cp "$am/decode_${decode_set}${vocab}/ctm" \
        "$am/decode_${decode_set}${vocab}/word.1.ctm"

    python3 local/alignments/ctm2textgrid.py \
        "1" \
        "$am/decode_${decode_set}${vocab}" \
        "$am/decode_${decode_set}${vocab}_textgrid" \
        "$am/graph${vocab}/words.txt" \
        "$am/phones.txt" \
        "data/${decode_set}_hires/utt2dur" || exit 1;
fi