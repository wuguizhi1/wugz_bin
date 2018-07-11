args = commandArgs(T)
min = as.numeric(args[1])
max = as.numeric(args[2])
infile = args[3]
outfile = args[4]
data = read.table(infile, header = F, sep = "\t", stringsAsFactors = FALSE)
percent <- function(data=NA, max=0, min=0){
	data1 = data[which(data$V2 >= min & data$V2 < max),]
	total = tapply(data$V2,data$V1,sum)
	part = tapply(data1$V2,data1$V1,sum)
	per = round(part/total, 5)
	re = rbind(total, part, per)
	re = as.data.frame(re)
	typ = paste0(min,"_",max)
	rownames(re) = c("total", "part", typ)
	symbol =  strsplit(colnames(re), "[.]")
	adjustRatio = c()
	for (i in 1:ncol(re)){
		each = unlist(symbol[i])
		eachi = substr(each[1],3,8)
		cffdnafile = paste0("/home/macx/workdir/ctDNA/cnv/",eachi,"_FC/gt/snp_indel/cffdna_EM.txt")
		cffdnadata = read.table(cffdnafile, header = T, sep = "\t", stringsAsFactors = FALSE)
		cffdnaeach = cffdnadata[which(cffdnadata$Sample == each[2]), 4]
		ratiofile = paste0("/data/bioit/biodata/duyp/Project/Thalassemia/PAGB_TMA_20",eachi,"/statistic/06.variant_result/",each[2],".fusion.final.txt")
		ratiodata = read.table(ratiofile, header = T, sep = "\t", stringsAsFactors = FALSE)
		ratioeach = ratiodata[which(ratiodata$Break1 == "chr16,215395,A"), 4]/ratiodata[which(ratiodata$Break1 == "chr16,215395,A"), 5]
		percff = per[i]+ 0.8*cffdnaeach/100
		adjust1 = ratioeach - (-0.3095*per[i]+0.1138)
		adjust2 = ratioeach - (-0.2469*percff + 0.104)
		adjustRatio = rbind(adjustRatio, c(each[2], ratioeach, adjust1, adjust2, cffdnaeach, per[i], percff) )
	}
	#adjustRatio = as.data.frame(adjustRatio)
	colnames(adjustRatio) = c("SampleName","Ratio","adjust1","adjust2","cffdna","intersize200_1000","intersizeadjust")
	print( adjustRatio )
	write.table(adjustRatio, file =outfile, row.names = F, col.names = T, quote = F, sep = "\t")
	return(re)
}
per = percent(data=data,min=min,max=max)


