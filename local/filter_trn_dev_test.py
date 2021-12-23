#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse
import re

parser = argparse.ArgumentParser(description='Filter speech transcripts')
parser.add_argument('input_trn', type=str,
                    help='path to the input transcript file')
parser.add_argument('output_trn', type=str,
                    help='path to the output file')
args = parser.parse_args()

with open(args.input_trn, 'r', encoding='utf-8') as f:
    trn = f.read()

def filter_lp(text):
    errors =  [
        ('.brsitten', '.br sitten'),
        ('.be', '.br'),
        ('*br', '.br'),
        ('-br', '.br'),
        ('.rb', '.br'),
        ('br.', '.br'),
        ('.bh', '.br'),
        ('.bt', '.br'),
        ('.breath ', '.br '),
        ('.brreath ', '.br '),
        ('.brr ', '.br '),
        ('.b ', '.br '),
        ('mahollistafp.', 'mahollista .fp'),
        ('itku-.fp', 'itku- .fp'),
        ('.fp.fp', '.fp'),
        ('.fp.', '.fp'),
        ('.fb', '.fp'),
        ('.fd', '.fp'),
        ('.fo', '.fp'),
        ('.fr', '.fp'),
        ('.ft', '.fp'),
        ('fp.', '.fp'),
        ('.pf', '.fp'),
        (' fp ', ' .fp '),
        ('-fp', '.fp'),
        ('2018', 'kaksituhattakahdeksantoista'),
        ('.ja', 'ja'),
        ('ja.', 'ja'),
        ('.cr', '.ct'),
        ('ct.', '.ct'),
        ('.laughh', '.laugh'),
        ('﻿', ''),
        ('?', ''),
        ('', ''),
        ('Puhuja 1', ''),
        ('Puhuja1', ''),
        ('Puhuja', ''),
        ('Haastattelija 1', ''),
        ('[', ''),
        (']', ''),
        (':', ''),
        (',',''),
        ("'",''),
        ('¨',''),
        ('´',' '),
        ('§', ''),
        ('. ', ''),
        ('.\n', '\n'),
        ('kohti..ensimmäiseksi', 'kohti ensimmäiseksi'),
        ('youre', 'jor'),
        ('your', 'jor'),
        ('you','juu'),
        ('could', 'kud'),
        ('Corona', 'korona'),
        ('rock', 'rok'),
        ('OECD', 'oo ee see dee')
    ]
    n_lines = len(text)
    text = '\n'.join(text)
    for e in errors:
        text = text.replace(e[0], e[1])

    text = text.lower()

    # regex filters:
    # numbers
    text =  re.sub("[0-9]+", '', text)
    # missing space before/after .fp
    text = re.sub(r'([a-zA-ZÄÖäö])(\.fp)', r'\1 \2', text)
    text = re.sub(r'(\.fp)([a-zA-ZÄÖäö])', r'\1 \2', text)
    
    new_text = []
    for line in text.split('\n'):
        new_text.append(' '.join([word.strip() for word in line.split() if word.strip()]))

    assert n_lines == len(new_text)
    return new_text

def separate_uttids(text):
    uttids = []
    trns = []
    for line in text:
        tokens = line.split()
        uttids.append(tokens[0])
        trns.append(' '.join(tokens[1:]))
    return trns, uttids

def main():
    with open(args.input_trn, 'r') as f:
        text = f.readlines()
    trns, uttids = separate_uttids(text)
    filtered = filter_lp(trns)
    with open(args.output_trn, 'w') as f:
        for uttid, trn in zip(uttids, filtered):
            f.write('{} {}\n'.format(uttid, trn))

main()