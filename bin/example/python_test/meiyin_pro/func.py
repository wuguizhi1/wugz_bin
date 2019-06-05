
import xlrd

dic_config = {}

def read_tab_filein(filename='/data/bioit/biodata/wugz/codes/wugz_bin/bin/meiyin_jiyin/config_pre/config.acmg'):
	line_all = []
	with open(filename,"r",encoding="utf-8") as f:
		for line in f:
			line_each = line.split('\t')
			if len(line_each[4]) > len(line_each[3]) :
				dic_config[line_each[8]]['D'][line_each[3]+':'+line_each[4]] = line_each
			line_all.append(line_each)
		
	return(line_all)

def read_xls(filename='/data/bioit/biodata/wugz/meiyin/dataIn1/final.cancers.xlsx'):
	book = xlrd.open_workbook(filename)
	sheet1 = book.sheets()[0]
	nrows = sheet1.nrows
	ncols = sheet1.ncols
	row3_values = sheet1.row_values(2)
	col3_values = sheet1.col_values(2)
	cell_3_3 = sheet1.cell(2,2).value
	print(nrows,ncols,cell_3_3)
	print(row3_values)
	print(col3_values)


lll=read_xls()

