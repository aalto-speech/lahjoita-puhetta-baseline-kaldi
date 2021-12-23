#!/bin/bash
# previously called "tune-gmm-wsj-a.sh"

source ../run-expt.sh "${0}"

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module list

. ./cmd.sh
. ./path.sh

datadir=data/lp-train-complete
expt_name=wsj-a
stage=0

. ./utils/parse_options.sh

if [ $stage -le 0 ]; then
    n_utts=10
    . ./utils/parse_options.sh

    utils/subset_data_dir.sh --shortest \
        ${datadir} \
        ${n_utts}000 \
        ${datadir}-${n_utts}kshort

    steps/train_mono.sh --nj 50 --cmd "$train_cmd" \
        --boost-silence 1.25 \
        ${datadir}-${n_utts}kshort \
        data/lang_nosp \
        exp/mono0-${n_utts}kshort_bs1.25
fi

if [ $stage -le 1 ]; then
    mkdir -p exp/$expt_name
  
    # tri1
    n_utts=20
    if [ ! -d "${datadir}-${n_utts}kshort" ]; then
        utils/subset_data_dir.sh --shortest \
            ${datadir} \
            ${n_utts}000 \
            ${datadir}-${n_utts}kshort
    fi

    # align speaker-independent model
    steps/align_si.sh --nj 50 --cmd "$train_cmd" \
        ${datadir}-${n_utts}kshort \
        data/lang_nosp \
        exp/mono0-10kshort_bs1.25 \
        exp/${expt_name}/mono0_ali || exit 1;

    # deltas
    steps/train_deltas.sh --cmd "$train_cmd" \
        --stage 10 \
        4200 40000 \
        ${datadir}-${n_utts}kshort \
        data/lang_nosp \
        exp/${expt_name}/mono0_ali \
        exp/${expt_name}/tri1 || exit 1;
fi

if [ $stage -le 2 ]; then
    # tri2
    n_utts=50
    if [ ! -d "${datadir}-${n_utts}k" ]; then
        utils/subset_data_dir.sh \
            ${datadir} \
            ${n_utts}000 \
            ${datadir}-${n_utts}k
    fi

    steps/align_si.sh --nj 50 --cmd "$train_cmd" \
        ${datadir}-${n_utts}k \
        data/lang_nosp \
        exp/${expt_name}/tri1 \
        exp/${expt_name}/tri1_ali || exit 1;

    steps/train_lda_mllt.sh --cmd "$train_cmd" \
        --splice-opts "--left-context=3 --right-context=3" \
        8000 100000 \
        ${datadir}-${n_utts}k \
        data/lang_nosp \
        exp/${expt_name}/tri1_ali \
        exp/${expt_name}/tri2b || exit 1;
fi

if [ $stage -le 3 ]; then
    # alternative tri3b: this one is different from WSJ example
    steps/align_fmllr.sh  --nj 50 --cmd "$train_cmd" \
        ${datadir} \
        data/lang_nosp \
        exp/${expt_name}/tri2b \
        exp/${expt_name}/tri2b_ali  || exit 1; 

    steps/train_sat.sh --cmd "$train_cmd" \
        15000 200000 \
        ${datadir} \
        data/lang_nosp \
        exp/${expt_name}/tri2b_ali \
        exp/${expt_name}/tri3b || exit 1;
fi

if [ $stage -le 4 ]; then
    # Silprob for normal lexicon.
    steps/get_prons.sh --cmd "$train_cmd" \
        $datadir \
        data/lang_nosp \
        exp/${expt_name}/tri3b || exit 1;

    utils/dict_dir_add_pronprobs.sh \
        --max-normalize true \
        data/local/dict_train_nosp \
        exp/${expt_name}/tri3b/pron_counts_nowb.txt \
        exp/${expt_name}/tri3b/sil_counts_nowb.txt \
        exp/${expt_name}/tri3b/pron_bigram_counts_nowb.txt \
        data/local/${expt_name}/dict_train || exit 1

    utils/prepare_lang.sh \
        data/local/${expt_name}/dict_train \
        ".oov" \
        data/local/${expt_name}/lang_tmp \
        data/${expt_name}/lang || exit 1;
fi

if [ $stage -le 5 ]; then
    # MMI training starting from the LDA+MLLT+SAT systems on all the  data.
    steps/align_fmllr.sh --nj 200 --cmd "$train_cmd" \
        $datadir \
        data/${expt_name}/lang \
        exp/${expt_name}/tri3b \
        exp/${expt_name}/tri3b_ali || exit 1;

    steps/make_denlats.sh --nj 200 --sub-split 30 --cmd "$decode_cmd" \
        --transform-dir exp/${expt_name}/tri3b_ali \
        $datadir \
        data/${expt_name}/lang \
        exp/${expt_name}/tri3b \
        exp/${expt_name}/tri3b_denlats || exit 1;

    # 4 iterations of MMI seems to work well overall. The number of iterations is
    # used as an explicit argument even though train_mmi.sh will use 4 iterations by
    # default.
    num_mmi_iters=4
    steps/train_mmi.sh --cmd "$decode_cmd" \
        --boost 0.1 \
        --num-iters $num_mmi_iters \
        $datadir \
        data/${expt_name}/lang \
        exp/${expt_name}/tri3b_{ali,denlats} \
        exp/${expt_name}/tri3b_mmi_b0.1
fi
