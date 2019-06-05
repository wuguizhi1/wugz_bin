# -*- coding:utf-8 -*-
#!/usr/bin/env python

import getopt
import sys
import xlrd

def usage():
	print ("=======")
	print ("Usage:")
	print ("python "+sys.argv[0]+" -c /data/bioit/biodata/wugz/codes/wugz_bin/bin/meiyin_jiyin/config_pre/config.acmg -x /data/bioit/biodata/wugz/meiyin/dataIn1/final.cancers.xlsx     66 88 ");
	print ("or")
	print ("python "+sys.argv[0]+" --config=/data/bioit/biodata/wugz/codes/wugz_bin/bin/meiyin_jiyin/config_pre/config.acmg --xls=/data/bioit/biodata/wugz/meiyin/dataIn1/final.cancers.xlsx 66 88")
	print ("args length are regular!")
	print ("=======")
	exit()

def read_tab_filein(filename='/data/bioit/biodata/wugz/codes/wugz_bin/bin/meiyin_jiyin/config_pre/config.acmg'):
	dic_config = {}
	with open(filename,"r",encoding="utf-8") as f:
		for line in f:
			line_each = line.split('\t')
			if len(line_each[4]) > len(line_each[3]) :
				dic_config[line_each[8]]['D'][line_each[3]+':'+line_each[4]] = line_each
	return(dic_config)

def read_xls(filename='/data/bioit/biodata/wugz/meiyin/dataIn1/final.cancers.xlsx'):
	dic_dis_genefunc = {}
	dic_dis_descrip = {}
	dic_dis_refs = {}
	book = xlrd.open_workbook(filename)
	sheet1 = book.sheets()[0]
	sheet2 = book.sheets()[1]
	for i in range(sheet1.nrows):
		dic_dis_genefunc[sheet1.cell(i,0).value][sheet1.cell(i,1).value][sheet1.cell(i,2).value] = [sheet1.cell(i,3).value]
	for i in range(sheet2.nrows):
		dic_dis_descrip[sheet2.cell(i,0).value] = sheet2.cell(i,1).value
		dic_dis_refs[sheet2.cell(i,0).value] = sheet2.cell(i,2).value
	return(dic_dis_genefunc, dic_dis_descrip, dic_dis_refs)

def main():
	"""
	getopt 模块的用法
	"""
	options, args = getopt.getopt(sys.argv[1:], 'hc:x:', ['help', 'config=', 'xls='])
	if len(options) != 2 :
		print("options numbers incorrect!")
		usage()
	if len(args)!= 2 :
		print("args length incorrect!")
		usage()

	for name, value in options:
		if name in ('-h', '--help'):
			usage()
		if name in ('-c', '--config'):
			config=value
			#print ('p value: {0}'.format(value))
			#print ("p value: " + value)
		if name in ('-x', '--xls'):
			xls=value
			#print ('ip value: {0}'.format(value))
	#for name in args:
		#print ("more value: {0}".format(name))

	print config
	print xls
	print args


if __name__ == "__main__":
	main()

