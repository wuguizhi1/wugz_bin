# -*- coding:utf-8 -*-
#!/usr/bin/env python

import getopt
import sys

def usage():
	print ("=======")
	print ("Usage:")
	print ("python args[0] -i:127.0.0.1 -p:8888 66 88 or python args[0] --ip=127.0.0.1 --port=8888 66 88")
	print ("=======")
	exit()

def main():
	"""
	getopt 模块的用法
	"""
	options, args = getopt.getopt(sys.argv[1:], 'hp:i:', ['help', 'port=', 'ip='])

	for name, value in options:
		if name in ('-h', '--help'):
			usage()
		if name in ('-p', '--port'):
			print ('1value: {0}'.format(value))
		if name in ('-i', '--ip'):
			print ('2value: {0}'.format(value))
		for name in args:
		# name 的值就是 上边参数实例里边的66和88
			print ("3name: {0}".format(name))


if __name__ == "__main__":
	main()

