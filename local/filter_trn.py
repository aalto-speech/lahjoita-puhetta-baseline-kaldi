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
        ('..br', '.br'),
        ('.baier', 'baier'),
        ('.bar', '.br'),
        ('.bfp', '.fp'),
        ('.bri', '.br'),
        ('.brj', '.br'),
        ('.brt', '.br'),
        ('.brvoit', '.br voit'),
        ('*br', '.br'),
        ('-br', '.br'),
        ('.rb', '.br'),
        ('br.', '.br'),
        ('.lbr', '.br'),
        ('.breath ', '.br '),
        ('.brreath ', '.br '),
        ('.brr ', '.br '),
        ('.b ', '.br '),
        ('mahollistafp.', 'mahollista .fp'),
        ('itku-.fp', 'itku- .fp'),
        ('.fp.fp', '.fp'),
        ('.fp.', '.fp'),
        ('fp.', '.fp'),
        (' fp ', ' .fp '),
        ('.f ', '.fp '),
        ('.p ', '.fp '),
        ('-fp', '.fp'),
        ('.pf', '.fp'),
        ('.pfp', '.fp'),
        ('.fb', '.fp'),
        ('2018', 'kaksituhattakahdeksantoista'),
        ('.ja', 'ja'),
        ('ja.', 'ja'),
        ('.cr', '.ct'),
        ('ct.', '.ct'),
        ('.cauch', '.cough'),
        ('.caugh', '.cough'),
        ('.cauhg', '.cough'),
        ('.ciough', '.cough'),
        ('.coughs', '.cough'),
        ('.cought', '.cough'),
        ('.couhg', '.cough'),
        ('.laughh', '.laugh'),
        ('.alugh', '.laugh'),
        ('.laaugh', '.laugh'),
        ('.laguh', '.laugh'),
        ('.laug', '.laugh'),
        ('.laugh', '.laugh'),
        ('.laughss', '.laugh'),
        ('.laught', '.laugh'),
        ('.lauhg', '.laugh'),
        ('.lauhgh', '.laugh'),
        ('.lsugh', '.laugh'),
        ('.laughh', '.laugh'),
        ('.laughhss', '.laugh'),
        ('.laughht', '.laugh'),
        ('.laughss', '.laugh'),
        ('.laught', '.laugh'),
        ('.sight', '.sigh'),
        ('.sign', '.sigh'),
        ('.sihg', '.sigh'),
        ('.sitte', 'sitte'),
        ('.sneeze', '.fp'),
        ('.sniff', '.fp'),
        ('.luokattomista', 'luokattomista'),
        ('.irti', 'irti'),
        ('.jossain', 'jossain'),
        ('.tai', 'tai'),
        ('.tosin', 'tosin'),
        ('.tällä', 'tällä'),
        ('.viis', 'viis'),
        ('.äh', 'äh'),
        ('.äää', 'äää'),
        ('.öm', 'öm'),
        ('.öö', 'öö'),
        ('.mm', 'mm'),
        ('.esineitä', 'esineitä'),
        ('.piti', 'piti'),
        ('.seurata', 'seurata'),
        ('.shout', 'shout'),
        ('.sienessäki', 'sienessäki'),
        ('.oishan', 'oishan'),
        ('.on', 'on'),
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
        (';', ''),
        (',',''),
        ("'",''),
        ('¨',''),
        ('´',' '),
        ('§', ''),
        ('--', '-'),
        ('...........', ''),
        ('..........', ''),
        ('.........', ''),
        ('........', ''),
        ('.......', ''),
        ('......', ''),
        ('.....', ''),
        ('....', ''),
        ('...', ''),
        ('.. ', ' '),
        ('. ', ' '),
        ('.\n', '\n'),
        ('kohti..ensimmäiseksi', 'kohti ensimmäiseksi'),
        ('youre', 'jor'),
        ('your', 'jor'),
        ('you', 'juu'),
        ('You', 'juu'),
        ('york', 'jork'),
        ('York', 'jork'),
        ('could', 'kud'),
        ('OECD', 'oo ee see dee'),
        ('name of recording' ,''),
        ('length of recording', ''),
        ('lahjoita_puhetta_1_227.flac', ''),
        ('lahjoita_puhetta_1_342.flac', ''),
        ('client', ''),
        ('lahjoitapuhetta@spoken.fi', ''),
        ('no_words_recognized', ''),
        ('..brfp', '.br'),
        ('..fp', '.fp'),
        ('..br', '.br'),
        ('he.-', 'he'),
        (' - ', ' '),
        (' -\n', ' \n'),
        ('­', '') # some invisible char
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
    text = re.sub(r'([a-zA-ZÄÖäö\-])(\.fp)', r'\1 \2', text)
    text = re.sub(r'(\.fp)([a-zA-ZÄÖäö\-])', r'\1 \2', text)
    text = re.sub(r'([a-zA-ZÄÖäö\-])(\.br)', r'\1 \2', text)
    text = re.sub(r'(\.br)([a-zA-ZÄÖäö\-])', r'\1 \2', text)
    text = re.sub(r'([a-zA-ZÄÖäö\-])(\.ct)', r'\1 \2', text)
    text = re.sub(r'(\.ct)([a-zA-ZÄÖäö\-])', r'\1 \2', text)
    # e.g. .dp --> .fp
    text = re.sub(r'(\.[^f]p) ', '.fp ', text)
    text = re.sub(r'(\.f[^p]) ', '.fp ', text)
    text = re.sub(r'(\.[^b]r) ', '.br ', text)
    text = re.sub(r'(\.b[^r]) ', '.br ', text)
    text = re.sub(r'(\.[^c]t) ', '.ct ', text)
    text = re.sub(r'(\.c[^t]) ', '.ct ', text)

    text = text.replace(' - ', ' ')

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