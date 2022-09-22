#!/bin/bash

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module list

. ./cmd.sh
. ./path.sh

set -e -o pipefail

#  7q is as 7p but a modified topology with resnet-style skip connections, more layers,
#  skinnier bottlenecks, removing the 3-way splicing and skip-layer splicing,
#  and re-tuning the learning rate and l2 regularize.  The configs are
#  standardized and substantially simplified.  There isn't any advantage in WER
#  on this setup; the advantage of this style of config is that it also works
#  well on smaller datasets, and we adopt this style here also for consistency.

# local/chain/compare_wer_general.sh --rt03 tdnn7p_sp tdnn7q_sp
# System                tdnn7p_sp tdnn7q_sp
# WER on train_dev(tg)      11.80     11.79
# WER on train_dev(fg)      10.77     10.84
# WER on eval2000(tg)        14.4      14.3
# WER on eval2000(fg)        13.0      12.9
# WER on rt03(tg)            17.5      17.6
# WER on rt03(fg)            15.3      15.2
# Final train prob         -0.057    -0.058
# Final valid prob         -0.069    -0.073
# Final train prob (xent)        -0.886    -0.894
# Final valid prob (xent)       -0.9005   -0.9106
# Num-parameters               22865188  18702628

# configs for 'chain'
train_stage=-10
# train_stage=496
get_egs_stage=-10
speed_perturb=true
affix=7q

# training options
frames_per_eg=150,110,100
remove_egs=false
common_egs_dir=
xent_regularize=0.1
dropout_schedule='0,0@0.20,0.5@0.50,0'


nnet3_affix=    # affix for exp/nnet3 directory to put iVector stuff in (e.g.
                # in the tedlium recip it's _cleaned).

suffix=
$speed_perturb && suffix=_sp

train_set="lp-train-complete"

# model dir
dir=exp/chain/tdnn${affix}${suffix}

# features dir
feat_dir=data/${train_set}_sp_hires

# alignments from the GMM AM as lattices
lat_dir=exp/tri3b_mmi_b0.1_lats${suffix}

# phonetic decision tree dir
treedir=exp/chain/tri3b_mmi_tree${suffix}

# lang dir
lang=data/lang_chain

# i-vector dir
ivec_dir=exp/nnet3${nnet3_affix}/ivectors_${train_set}_sp_hires

. ./utils/parse_options.sh

# End configuration section.
echo "$0 $@"  # Print the command line for logging


if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

echo "$0: creating neural net configs using the xconfig parser";

num_targets=$(tree-info $treedir/tree |grep num-pdfs|awk '{print $2}')
learning_rate_factor=$(echo "print (0.5/$xent_regularize)" | python)
affine_opts="l2-regularize=0.01 dropout-proportion=0.0 dropout-per-dim=true dropout-per-dim-continuous=true"
tdnnf_opts="l2-regularize=0.01 dropout-proportion=0.0 bypass-scale=0.66"
linear_opts="l2-regularize=0.01 orthonormal-constraint=-1.0"
prefinal_opts="l2-regularize=0.01"
output_opts="l2-regularize=0.002"

mkdir -p $dir/configs

cat <<EOF > $dir/configs/network.xconfig
input dim=100 name=ivector
input dim=40 name=input

# please note that it is important to have input layer with the name=input
# as the layer immediately preceding the fixed-affine-layer to enable
# the use of short notation for the descriptor
fixed-affine-layer name=lda input=Append(-1,0,1,ReplaceIndex(ivector, t, 0)) affine-transform-file=$dir/configs/lda.mat

# the first splicing is moved before the lda layer, so no splicing here
relu-batchnorm-dropout-layer name=tdnn1 $affine_opts dim=1536
tdnnf-layer name=tdnnf2 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=1
tdnnf-layer name=tdnnf3 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=1
tdnnf-layer name=tdnnf4 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=1
tdnnf-layer name=tdnnf5 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=0
tdnnf-layer name=tdnnf6 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
tdnnf-layer name=tdnnf7 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
tdnnf-layer name=tdnnf8 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
tdnnf-layer name=tdnnf9 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
tdnnf-layer name=tdnnf10 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
tdnnf-layer name=tdnnf11 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
tdnnf-layer name=tdnnf12 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
tdnnf-layer name=tdnnf13 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
tdnnf-layer name=tdnnf14 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
tdnnf-layer name=tdnnf15 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
linear-component name=prefinal-l dim=256 $linear_opts

prefinal-layer name=prefinal-chain input=prefinal-l $prefinal_opts big-dim=1536 small-dim=256
output-layer name=output include-log-softmax=false dim=$num_targets $output_opts

prefinal-layer name=prefinal-xent input=prefinal-l $prefinal_opts big-dim=1536 small-dim=256
output-layer name=output-xent dim=$num_targets learning-rate-factor=$learning_rate_factor $output_opts
EOF
steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/

steps/nnet3/chain/train.py --stage $train_stage \
  --cmd "$train_cmd" \
  --feat.online-ivector-dir $ivec_dir \
  --feat.cmvn-opts "--norm-means=false --norm-vars=false" \
  --chain.xent-regularize $xent_regularize \
  --chain.leaky-hmm-coefficient 0.1 \
  --chain.l2-regularize 0.0 \
  --chain.apply-deriv-weights false \
  --chain.lm-opts="--num-extra-lm-states=2000" \
  --trainer.dropout-schedule $dropout_schedule \
  --trainer.add-option="--optimization.memory-compression-level=2" \
  --egs.dir "$common_egs_dir" \
  --egs.stage $get_egs_stage \
  --egs.opts "--frames-overlap-per-eg 0 --constrained false" \
  --egs.chunk-width $frames_per_eg \
  --trainer.num-chunk-per-minibatch 64 \
  --trainer.frames-per-iter 1500000 \
  --trainer.num-epochs 4 \
  --trainer.optimization.num-jobs-initial 3 \
  --trainer.optimization.num-jobs-final 16 \
  --trainer.optimization.initial-effective-lrate 0.00025 \
  --trainer.optimization.final-effective-lrate 0.000025 \
  --trainer.max-param-change 2.0 \
  --cleanup.remove-egs $remove_egs \
  --feat-dir $feat_dir \
  --tree-dir $treedir \
  --lat-dir $lat_dir \
  --dir $dir  || exit 1;
