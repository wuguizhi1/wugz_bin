args = commandArgs(T)
min = as.numeric(args[1])
max = as.numeric(args[2])
cffdnafile = args[3]
indir = args[4]
infile = args[5]
outfile = args[6]
data = read.table(infile, header = F, sep = "\t", stringsAsFactors = FALSE)
percent <- function(data=NA, max=0, min=0){
	data1 = data[which(data$V2 >= min & data$V2 < max),]
	total = tapply(data$V2,data$V1,sum)
	part = tapply(data1$V2,data1$V1,sum)
	per = round(part/total, 6)
	re = rbind(total, part, per)
	re = as.data.frame(re)
	typ = paste0(min,"_",max)
	rownames(re) = c("total", "part", typ)
	adjustRatio = c()
	for (i in 1:ncol(re)){
		each = colnames(re)[i]
		cffdnadata = read.table(cffdnafile, header = T, sep = "\t", stringsAsFactors = FALSE)
		cffdnaeach = cffdnadata[which(cffdnadata$Sample == each), 4]
		ratiofile = paste0(indir,"/statistic/06.variant_result/",each,".fusion.final.txt")
		if( file.exists(ratiofile) ){
			ratiodata = read.table(ratiofile, header = T, sep = "\t", stringsAsFactors = FALSE)
			seaM = ratiodata[which(ratiodata$Break1 == "chr16,215395,A"), 4]
			seaT = ratiodata[which(ratiodata$Break1 == "chr16,215395,A"), 5]
			ratioeach = round( seaM/seaT, 6)
			percff = round( per[i]+ 0.8*cffdnaeach/100 , 6)
			adjust1 = round( ratioeach - (-0.3095*per[i]+0.1138) , 6)
			adjust2 = round( ratioeach - (-0.2469*percff + 0.104) , 6)
			adjustRatio = rbind(adjustRatio, c(each, "SEA", seaT, seaM, ratioeach, adjust2, cffdnaeach, per[i]) )
		}
	}
	#adjustRatio = as.data.frame(adjustRatio)
	colnames(adjustRatio) = c("SampleName", "ID", "N", "b", "f", "adjust2f", "cffDNA", "intersize200_1000")
	print( adjustRatio )
	write.table(adjustRatio, file =outfile, row.names = F, col.names = T, quote = F, sep = "\t")
	return(re)
}

if( !file.exists(infile) ){
	print(  paste0("file not exists! ", infile)  )
}else if( !file.exists(cffdnafile) ){
	print(  paste0("file not exists! ", cffdnafile)  )
}else{
	data = read.table(infile, header = F, sep = "\t", stringsAsFactors = FALSE)
	per = percent(data=data,min=min,max=max)
}
