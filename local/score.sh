#!/bin/bash
# WER, CER scores

[ -f ./path.sh ] && . ./path.sh

# begin configuration section.
cmd=run.pl
stage=0
decode_mbr=false
stats=true
beam=6
word_ins_penalty=0.0,0.5,1.0
min_lmwt=7
max_lmwt=17
iter=final
trn_number="no"
cer=true
#end configuration section.

echo "$0 $@"  # Print the command line for logging
[ -f ./path.sh ] && . ./path.sh
. parse_options.sh || exit 1;

if [ $# -ne 3 ]; then
  echo "Usage: $0 [--cmd (run.pl|queue.pl...)] <data-dir> <lang-dir|graph-dir> <decode-dir>"
  echo " Options:"
  echo "    --cmd (run.pl|queue.pl...)      # specify how to run the sub-processes."
  echo "    --cer (true|false)              # compute character error rate"
  exit 1;
fi

data=$1
lang_or_graph=$2
dir=$3

steps/scoring/score_kaldi_wer.sh --cmd "$cmd" \
  --trn-number ${trn_number} --min-lmwt $min_lmwt \
  --max-lmwt $max_lmwt --beam $beam \
  --decode-mbr $decode_mbr --word-ins-penalty $word_ins_penalty \
  $data \
  $lang_or_graph $dir

if $cer; then
  steps/scoring/score_kaldi_cer.sh --cmd "$cmd" \
    --trn-number ${trn_number} --min-lmwt $min_lmwt \
    --max-lmwt $max_lmwt --beam $beam \
    --decode-mbr $decode_mbr --word-ins-penalty $word_ins_penalty \
    $data \
    $lang_or_graph $dir
fi 
