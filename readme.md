# Kaldi recipe for the Lahjoita puhetta data

A training recipe for a hybrid HMM/DNN speech recognition system, using the Lahjoita puhetta speech corpus. The data and the ASR systems are described in the paper [Lahjoita puhetta: a large-scale corpus of spoken Finnish with some benchmarks](https://doi.org/10.1007/s10579-022-09606-3)

# Dependencies
- Kaldi version [5968b4c](https://github.com/kaldi-asr/kaldi/tree/5968b4cc03f9deccfd566962d3bba96bad8ce522)
- audio is processed using the toolkits [flac](https://xiph.org/flac/documentation_tools_flac.html) and [SoX](http://sox.sourceforge.net/)
- language models are trained using [SRILM](http://www.speech.sri.com/projects/srilm/)
- subword segmentation uses the [Morfessor](https://morfessor.readthedocs.io/en/latest/) toolkit
- trained models can be downloaded from [Zenodo](https://doi.org/10.5281/zenodo.7101543)
- to replicate training the models, download the dataset from [Kielipankki](https://www.kielipankki.fi/corpora/puhelahjat/) and place in a folder named `data/`

# Structure
- the scripts numbered 01 to 16 contain an ASR training recipe that is similar to the Kaldi WSJ (GMM/HMM system) and SWBD (DNN/HMM) recipies, with minor modifications
- the script numbered 17 is for training the semi-supervised system 
- `large-gmm.sh` trains a GMM/HMM system with more parameters and `large-gmm-tdnn-swbd-sp.sh` uses this GMM/HMM system alignments to train a DNN/HMM system
- files numbered 9x train and utilise a subword-based language model
- the folder `local/` contains some utility scripts that are (mostly) specific to the Lahjoita puhetta data
- `conf/` contains the MFCC parameters

# Usage
## Speech-to-text without word alignments
- install SoX to process audio (and flac if audio is in flac format)
- install Kaldi and set the `KALDI_ROOT` variable
- add the `kaldi/egs/wsj/s5/utils/` dir to your PATH (see path.sh for an example)
- link or copy the `kaldi/egs/wsj/s5/steps/` dir to this folder
- set the `decode_cmd` variable (see `cmd.sh` for an example)
- download and unzip the acoustic model and move to correct folders:
```
wget https://zenodo.org/record/6539429/files/lp_baseline_1600h.zip
unzip lp_baseline_1600h.zip
rm lp_baseline_1600h.zip
mkdir -p exp/nnet3/extractor
mv lp_baseline_1600h/extractor/* exp/nnet3/extractor/
mkdir -p exp/swbd/chain/tdnn7q_sp
mv lp_baseline_1600h/* exp/swbd/chain/tdnn7q_sp/
```
- download the subword-based decoding graph (slightly better results than word-based)
```
wget https://zenodo.org/record/6539429/files/graph_morfessor_lp_web_dsp.zip
unzip graph_morfessor_lp_web_dsp.zip
rm graph_morfessor_lp_web_dsp.zip
```
- create the Kaldi files for your data and place in a subfolder of `data`:
    - wav.scp
    - utt2skp
    - spk2utt
    - text (if you don't have transcripts, just list utterance ids here)
- run the decoding script 16-tdnn-decode.sh, e.g.
```
./16-tdnn-decode.sh --decode-set kielipankki-eg \
    --extract-feats true --extract-ivecs true
```
## Word alignments
The subword-kaldi does not support alignment script ATM, so to generate alignments use the word-based graph
- install dependencies and download acoustic model same way as above
- download the word-based graph
```
wget https://zenodo.org/record/6539429/files/graph_word_lp_web_dsp.zip
unzip graph_word_lp_web_dsp.zip
rm graph_word_lp_web_dsp.zip
```
- run decoding as above, but using the word-based graph
- run the alignment script 18-word-alignments.sh, e.g.:
```
./18-word-alignments.sh --decode-set kielipankki-eg \
    --textgrids true --ctms true
```
