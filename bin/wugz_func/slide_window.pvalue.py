# -*- coding:utf-8 -*-
#!/usr/bin/env python

import getopt
import sys
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from scipy.interpolate import spline


def usage():
	print ("=======")
	print ("Usage:")
	print ("python "+sys.argv[0]+" -i[--infile]  -o[--outfile]")
	print ("=======")
	exit()

def comupte_slide_window(filename, pcut):
	pos = []
	with open(filename,"r") as f:
		for line in f:
			line_each = line.split('\t')
			if( line_each[6] < pcut ):
				pos.append(line_each[0])
	return(pos)

def pcut_pvalues(filename, pcut):
	df = pd.read_csv("https://github.com/selva86/datasets/raw/master/mpg_ggplot2.csv")

def main():
	options, args = getopt.getopt(sys.argv[1:], 'hi:o:', ['help', 'infile=', 'outfile='])

	if len(options)<2 :
		usage()
	for name, value in options:
		if name in ('-h', '--help'):
			usage()
		if name in ('-i', '--infile'):
			infile = value
		if name in ('-o', '--outfile'):
			outfile = value

if __name__ == "__main__":
	main()

