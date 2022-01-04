# Kaldi recipe for the Lahjoita puhetta data

A training recipe for a hybrid HMM/DNN speech recognition system, using the Lahjoita puhetta speech corpus.

## Dependencies
- This system is trained using the Kaldi version [5968b4c](https://github.com/kaldi-asr/kaldi/tree/5968b4cc03f9deccfd566962d3bba96bad8ce522)
- Audio is processed using the toolkits [flac](https://xiph.org/flac/documentation_tools_flac.html) and [SoX](http://sox.sourceforge.net/)
- Language models are trained using [SRILM](http://www.speech.sri.com/projects/srilm/)
- Subword segmentation uses the [Morfessor](https://morfessor.readthedocs.io/en/latest/) toolkit
- the data needs to be downloaded and placed in a folder called `data/`

## Structure
- the scripts numbered 01 to 16 contain an ASR training recipe that is similar to the Kaldi WSJ (GMM/HMM system) and SWBD (DNN/HMM) recipies, with minor modifications
- `large-gmm.sh` trains a GMM/HMM system with more parameters and `large-gmm-tdnn-swbd-sp.sh` uses this GMM/HMM system alignments to train a DNN/HMM system
- files numbered 9x train and utilise a subword-based language model
- the folder `local/` contains some utility scripts that are (mostly) specific to the Lahjoita puhetta data
- `conf/` contains the MFCC parameters
