#!/bin/bash

source ../run-expt.sh "${0}"

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module load sox
module load flac
module list

. ./cmd.sh
. ./path.sh

nj=100
train_set="lp-train-complete"
test_sets="lp-dev lp-test"

# low-resolution features and alignments,
if [ -f data/${train_set}_sp/feats.scp ] ; then
  echo "$0: data/${train_set}_sp/feats.scp already exists.  Refusing to overwrite the features "
  echo " to avoid wasting time.  Please remove the file and continue if you really mean this."
  exit 1;
fi

echo "$0: preparing directory for low-resolution speed-perturbed data (for alignment)"
utils/data/perturb_data_dir_speed_3way.sh \
  data/${train_set} \
  data/${train_set}_sp

echo "$0: making MFCC features for low-resolution speed-perturbed data (needed for alignments)"
steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" \
  data/${train_set}_sp

steps/compute_cmvn_stats.sh \
  data/${train_set}_sp

echo "$0: fixing input data-dir to remove nonexistent features, in case some "
echo ".. speed-perturbed segments were too short."
utils/fix_data_dir.sh \
  data/${train_set}_sp

# high-resolution features and i-vector extractor,
if [ -f data/${train_set}_sp_hires/feats.scp ]; then
  echo "$0: data/${train_set}_sp_hires/feats.scp already exists."
  echo " ... Please either remove it, or rerun this script with stage > 2."
  exit 1
fi

echo "$0: creating high-resolution MFCC features"
mfccdir=data/${train_set}_sp_hires/data

for datadir in ${train_set}_sp ${test_sets}; do
  utils/copy_data_dir.sh \
    data/$datadir \
    data/${datadir}_hires
done

# do volume-perturbation on the training data prior to extracting hires
# features; this helps make trained nnets more invariant to test data volume.
utils/data/perturb_data_dir_volume.sh \
  data/${train_set}_sp_hires

for datadir in ${train_set}_sp ${test_sets}; do
  steps/make_mfcc.sh --nj $nj --mfcc-config conf/mfcc_hires.conf \
    --cmd "$train_cmd" \
    data/${datadir}_hires

  steps/compute_cmvn_stats.sh \
    data/${datadir}_hires
    
  utils/fix_data_dir.sh \
    data/${datadir}_hires
done