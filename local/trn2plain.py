#!/usr/bin/env python3
import sys
import argparse

parser = argparse.ArgumentParser(description='Remove uttId from text')
parser.add_argument('input_trn', type=str,
                    help='path to the transcript')
parser.add_argument('output_file', type=str,
                    help='path to the output file')
parser.add_argument('--remove-nonwords', action='store_true', 
                    help='remove non-word symbols ".laugh" etc.')
parser.add_argument('--remove-dashes', action='store_true', 
                    help='remove dashes (-)')
args = parser.parse_args()

with open(args.input_trn, 'r', encoding='utf-8') as f:
    trn = f.read()

if args.remove_nonwords:
    trn = trn.replace('.fp', '').replace('.br', '').replace('.ct', '').replace('.cough', '')
    trn = trn.replace('.laugh', '').replace('.yawn', '').replace('.sigh', '')

if args.remove_dashes:
    trn = trn.replace('-', ' ')

new = []
for line in trn.splitlines():
    words = line.split()
    id = words[0]
    utt = words[1:]
    new.append(' '.join(utt))

with open(args.output_file, 'w', encoding='utf-8') as f:
    for line in new:
        f.write(line + '\n')
