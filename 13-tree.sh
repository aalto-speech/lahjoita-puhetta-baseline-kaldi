#!/bin/bash

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module list

. ./cmd.sh
. ./path.sh

cd "${EXPT_SCRIPT_DIR}"
set -e -o pipefail

nj=80
speed_perturb=true
affix=7q
stage=2

. ./utils/parse_options.sh

echo "$0 $@"  # Print the command line for logging

suffix=
$speed_perturb && suffix=_sp
dir=exp/chain/tdnn${affix}${suffix}

# The iVector-extraction and feature-dumping parts are the same as the standard
# nnet3 setup, and you can skip them by setting "--stage 8" if you have already
# run those things.

train_set="lp-train-complete"

# this is the source gmm-dir that we'll use for alignments
gmm_dir=exp/tri3b_mmi_b0.1
ali_dir=${gmm_dir}_ali_${train_set}${suffix}
lats_dir=${gmm_dir}_lats${suffix}
treedir=exp/chain/tri3b_mmi_tree${suffix}
lang=data/lang_chain


if [ $stage -le 1 ]; then
  if [ -f $ali_dir/ali.1.gz ]; then
    echo "$0: alignments in $ali_dir appear to already exist.  Please either remove them "
    echo " ... or use a later --stage option."
    exit 1
  fi
  echo "$0: aligning with the perturbed low-resolution data"
  steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" \
    data/${train_set}_sp \
    data/lang \
    $gmm_dir \
    $ali_dir

  # Create a version of the lang/ directory that has one state per phone in the
  # topo file. [note, it really has two states.. the first one is only repeated
  # once, the second one has zero or more repeats.]
  rm -rf $lang
  cp -r data/lang $lang
  silphonelist=$(cat $lang/phones/silence.csl) || exit 1;
  nonsilphonelist=$(cat $lang/phones/nonsilence.csl) || exit 1;
  # Use our special topology... note that later on may have to tune this
  # topology.
  steps/nnet3/chain/gen_topo.py \
    $nonsilphonelist \
    $silphonelist \
    >$lang/topo

  # Build a tree using our new topology. This is the critically different
  # step compared with other recipes.
  steps/nnet3/chain/build_tree.sh --frame-subsampling-factor 3 \
      --context-opts "--context-width=2 --central-position=1" \
      --cmd "$train_cmd" \
      7000 \
      data/${train_set}${suffix} \
      $lang \
      $ali_dir \
      $treedir
fi

if [ $stage -le 2 ]; then
  # Get the alignments as lattices for DNN training (gives the LF-MMI more freedom).
  if [ -f ${lats_dir}/lat.1.gz ]; then
    echo "$0: lats in ${lats_dir} appear to already exist. Please either remove them "
    echo " ... or use a later --stage option."
    exit 1
  else
    # use the same num-jobs as the alignments
    nj=$(cat $ali_dir/num_jobs) || exit 1;
    steps/align_fmllr_lats.sh --nj $nj --cmd "$train_cmd" \
      data/${train_set}${suffix} \
      data/lang \
      ${gmm_dir} \
      ${lats_dir}
    rm ${lats_dir}/fsts.*.gz # save space
  fi
fi