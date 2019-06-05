#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-
from matplotlib import pyplot as plt
from matplotlib_venn import venn2
from matplotlib_venn import venn3
import time
import sys
import getopt

def usage():
	print ("=======")
	print ("Usage:")
	print ("python args[0] -o outpng V1label:V1file V2label:V2file V3label:V3file\n")
	print ("Attention: test in 10.0.0.9")
	print ("Venn2, 2 inputs forced")
	print ("Venn3, 3 inputs forced")
	print ("=======")
	exit()

def read_f_list(filename):
	f=open(filename,'r')
	listL = f.readlines()
	f.close()
	localtime = time.asctime( time.localtime(time.time()) )
	print("reading finish: "+filename)
	print("本地时间为 :"+ localtime)
	return(listL)

def main():
	options, args = getopt.getopt(sys.argv[1:], 'ho:', ['help','outpng'])
	
	outpng = "temp.png"
	for name, value in options:
		if name in ('-h', '--help'):
			usage()
		if name in ('-o', '--outpng'):
			outpng = value
	setlabel = []
	setnumber = []
	for name in args:
		(label, filename) = name.split(':')
		listf=read_f_list(filename)
		setlabel.append( label )
		setnumber.append( set(listf) )

	#venn3([set3, set5, set35], ('Set3', 'Set5', 'Set35'))
	if len(setlabel) == 2 :
		venn2(setnumber, tuple(setlabel))
	elif  len(setlabel) == 3 :
		venn3(setnumber, tuple(setlabel))
	else:
		usage()	

	plt.savefig(outpng)
	localtime = time.asctime( time.localtime(time.time()) )
	print("plot finish : "+ localtime)

if __name__ == "__main__":
	main()

