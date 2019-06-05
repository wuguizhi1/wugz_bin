#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-
from matplotlib import pyplot as plt
#from matplotlib_venn import venn2
#from matplotlib_venn import venn3

def read_f(filename):
	f_all=[]
	with open(filename) as f:
		for line in f:
			f_all.append(line)
	return(f_all)




#venn2(subsets=[set([1,2,3]), set(2,3,4)],set_labels=('set1','set2'),set_colors=('r', 'g'))
plot.show()

#venn3(subsets=[set([1,2,3,7]), set(2,3,4,6,7), set([4,5,6,7])],set_labels=('set1','set2','set3'),set_colors=('r', 'g', 'b'))
plot.show()


