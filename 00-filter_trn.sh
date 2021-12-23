#!/bin/bash

# copy data, and filter text file

datadir="/scratch/work/moisioa3/data/"

for subset in lp-train-no100h
do
    mkdir -p data/${subset}
    cp $datadir/${subset}/{text-unfiltered,wav.scp,utt2spk,spk2utt} data/${subset}/
    cp -r $datadir/scratch/work/moisioa3/data/${subset} data/
done

local/filter_trn.py data/lp-train-complete/text-unfiltered data/lp-train-complete/text
local/filter_trn_dev_test.py data/lp-dev/text-unfiltered data/lp-dev/text
local/filter_trn_dev_test.py data/lp-test/text-unfiltered data/lp-test/text
