#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import re
import io

sys.stderr.write('Reading word segmentations.')
line_number = 0

wsegf = open(sys.argv[1], encoding='utf-8')
wsegs = dict()
for line in wsegf:
    line_number += 1
    if line_number % 100000 == 0:
        sys.stderr.write('.')
    line = line.strip()
    if line.startswith('#'): continue
    line = re.sub('\d*', '', line)
    parts = line.split(r'+')
    if len(parts) < 2:
        parts = line.split(' ')
    parts = [re.sub(' ', '', x) for x in parts]
    word = ''
    for part in parts:
        word += part
    wsegs[word] = parts
wsegf.close()
sys.stderr.write('\n')


sys.stderr.write('Segmenting corpus.')
line_number = 0

input_stream = io.TextIOWrapper(sys.stdin.buffer, encoding='utf-8')
output_stream = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
for line in input_stream:
    line_number += 1
    if line_number % 100000 == 0:
        sys.stderr.write('.')

    if line.startswith('######'):
        output_stream.write(line)
        continue

    line = line.strip()
    words = line.split()

    output_stream.write('<s> ')
    for word in words:
        try:
            subwords = wsegs[word]
        except:
            sys.stderr.write('\n')
            sys.stderr.write('segment-text.py: Segmentation not found for word "%s" at input line %d.\n' % (word, line_number))
            # sys.exit(1)
            output_stream.write('%s ' % subwords[0])
        if len(subwords) < 2:
            output_stream.write('%s ' % subwords[0])
        else:
            for i, sw in enumerate(subwords):
                if i == 0:
                    output_stream.write('%s+ ' % sw)
                elif i < len(subwords) - 1:
                    output_stream.write('+%s+ ' % sw)
                else:
                    output_stream.write('+%s ' % sw)
    output_stream.write('</s>\n')

sys.stderr.write('\n')
