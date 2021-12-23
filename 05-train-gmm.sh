#!/bin/bash

source ../run-expt.sh "${0}"

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module list

. ./cmd.sh
. ./path.sh

datadir=data/lp-train-complete
stage=0

. ./utils/parse_options.sh

if [ $stage -le 0 ]; then
    n_utts=10

    utils/subset_data_dir.sh --shortest \
        ${datadir} \
        ${n_utts}000 \
        ${datadir}-${n_utts}kshort

    steps/train_mono.sh --nj 50 --cmd "$train_cmd" \
        --boost-silence 1.25 \
        ${datadir}-${n_utts}kshort \
        data/lang_nosp \
        exp/mono0
fi

if [ $stage -le 1 ]; then
    # tri1
    n_utts=20
    utils/subset_data_dir.sh --shortest \
        ${datadir} \
        ${n_utts}000 \
        ${datadir}-${n_utts}k

    # align speaker-independent model
    steps/align_si.sh --nj 50 --cmd "$train_cmd" \
        ${datadir}-${n_utts}k \
        data/lang_nosp \
        exp/mono0 \
        exp/mono0_ali || exit 1;

    # deltas
    steps/train_deltas.sh --cmd "$train_cmd" \
        2000 10000 \
        ${datadir}-${n_utts}k \
        data/lang_nosp \
        exp/mono0_ali \
        exp/tri1 || exit 1;
fi

if [ $stage -le 2 ]; then
    # tri2
    # Take a subset of 40000 utterances.
    n_utts=40
    utils/subset_data_dir.sh --shortest \
        ${datadir} \
        ${n_utts}000 \
        ${datadir}-${n_utts}k

    steps/align_si.sh --nj 50 --cmd "$train_cmd" \
        ${datadir}-${n_utts}k \
        data/lang_nosp \
        exp/tri1 \
        exp/tri1_ali || exit 1;

    steps/train_lda_mllt.sh --cmd "$train_cmd" \
        --splice-opts "--left-context=3 --right-context=3" \
        2500 15000 \
        ${datadir}-${n_utts}k \
        data/lang_nosp \
        exp/tri1_ali \
        exp/tri2b || exit 1;
fi

if [ $stage -le 3 ]; then
    # alternative tri3b: this one is different from WSJ example
    steps/align_fmllr.sh  --nj 50 --cmd "$train_cmd" \
        ${datadir} \
        data/lang_nosp \
        exp/tri2b \
        exp/tri2b_ali  || exit 1; 

    steps/train_sat.sh --cmd "$train_cmd" \
        4200 40000 \
        ${datadir} \
        data/lang_nosp \
        exp/tri2b_ali \
        exp/tri3b || exit 1;
fi

if [ $stage -le 4 ]; then
    # Silprob for normal lexicon.
    steps/get_prons.sh --cmd "$train_cmd" \
        $datadir \
        data/lang_nosp \
        exp/tri3b || exit 1;

    utils/dict_dir_add_pronprobs.sh \
        --max-normalize true \
        data/local/dict_train_nosp \
        exp/tri3b/pron_counts_nowb.txt \
        exp/tri3b/sil_counts_nowb.txt \
        exp/tri3b/pron_bigram_counts_nowb.txt \
        data/local/dict_train || exit 1

    utils/prepare_lang.sh \
        data/local/dict_train \
        ".oov" \
        data/local/lang_tmp \
        data/lang || exit 1;
fi

if [ $stage -le 5 ]; then
    # MMI training starting from the LDA+MLLT+SAT systems on all the  data.
    steps/align_fmllr.sh --nj 30 --cmd "$train_cmd" \
        $datadir \
        data/lang \
        exp/tri3b \
        exp/tri3b_ali || exit 1;

    steps/make_denlats.sh --nj 30 --sub-split 30 --cmd "$decode_cmd" \
        --transform-dir exp/tri3b_ali \
        $datadir \
        data/lang \
        exp/tri3b \
        exp/tri3b_denlats || exit 1;

    # 4 iterations of MMI seems to work well overall. The number of iterations is
    # used as an explicit argument even though train_mmi.sh will use 4 iterations by
    # default.
    num_mmi_iters=4
    steps/train_mmi.sh --cmd "$decode_cmd" \
        --boost 0.1 \
        --num-iters $num_mmi_iters \
        $datadir \
        data/lang \
        exp/tri3b_{ali,denlats} \
        exp/tri3b_mmi_b0.1
fi
