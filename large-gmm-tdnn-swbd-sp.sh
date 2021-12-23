#!/bin/bash

source ../run-expt.sh "${0}"

module purge
module load kaldi-2020/5968b4c-GCC-6.4.0-2.28-OPENBLAS
module list

. ./cmd.sh
. ./path.sh

stage=0
expt_name="swbd"
nj=150
train_set="lp-train-complete"

# this is the source gmm-dir that we'll use for alignments
suffix=_sp
gmm_dir=exp/wsj-a/tri3b_mmi_b0.1
ali_dir=${gmm_dir}_ali_${train_set}${suffix}
lats_dir=${gmm_dir}_lats${suffix}
treedir=exp/${expt_name}/chain/tri3b_mmi_tree${suffix}
lang=data/${expt_name}/lang_chain

. ./utils/parse_options.sh

mkdir -p exp/${expt_name}
mkdir -p data/${expt_name}

if [ $stage -le 1 ]; then
    if [ -f $ali_dir/ali.1.gz ]; then
        echo "$0: alignments in $ali_dir appear to already exist.  Please either remove them "
        echo " ... or use a later --stage option."
        exit 1
    fi
    echo "$0: aligning with the low-resolution data"
    steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" \
        data/${train_set}${suffix} \
        data/wsj-a/lang \
        $gmm_dir \
        $ali_dir

    # Create a version of the lang/ directory that has one state per phone in the
    # topo file. [note, it really has two states.. the first one is only repeated
    # once, the second one has zero or more repeats.]
    rm -rf $lang
    cp -r data/wsj-a/lang $lang
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
    # if [ -f ${lats_dir}/lat.1.gz ]; then
    #     echo "$0: lats in ${lats_dir} appear to already exist. Please either remove them "
    #     echo " ... or use a later --stage option."
    #     exit 1
    # else
        # use the same num-jobs as the alignments
        nj=$(cat $ali_dir/num_jobs) || exit 1;
        steps/align_fmllr_lats.sh --nj $nj --cmd "$train_cmd" \
            --stage 3 \
            data/${train_set}${suffix} \
            data/wsj-a/lang \
            ${gmm_dir} \
            ${lats_dir}
        rm ${lats_dir}/fsts.*.gz # save space
    # fi
fi

ivectordir=exp/nnet3${nnet3_affix}/ivectors_${train_set}${suffix}_hires

# tdnn

# configs for 'chain'
train_stage=1223
get_egs_stage=-10
speed_perturb=true
affix=7q
dir=exp/${expt_name}/chain/tdnn${affix}${suffix}
mkdir -p exp/${expt_name}/chain

# training options
frames_per_eg=150,110,100
remove_egs=false
common_egs_dir=
xent_regularize=0.1
dropout_schedule='0,0@0.20,0.5@0.50,0'

if [ $stage -le 3 ]; then
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
    --feat.online-ivector-dir $ivectordir \
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
    --feat-dir data/${train_set}${suffix}_hires \
    --tree-dir $treedir \
    --lat-dir $lats_dir \
    --dir $dir  || exit 1;
fi
