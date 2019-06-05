#!/share/software/software/R-3.0_install/R-3.0.1/bin/Rscript
library(getopt)
library(VennDiagram)

#+--------------------
#get options
#+--------------------
spec <- matrix(c(
     'help',     'h',    0, "logical",   "help, 'VennDiagram' used to do the job.",
     'inputs',   'i',    1, "character", "input files, (t1.txt,t2.txt,t3.txt or t1.txt:t2.txt:t3.txt), forced.",
     'labels',   'l',    1, "character", "input labels, (T1,T2,T3 or T1:T2:T3), forced.",
     'outfile',  'o',    1, "character", "out png file name, forced."
), byrow = TRUE, ncol = 5)

opt <- getopt(spec)
#+--------------------
# check options
#+--------------------
if ( !is.null(opt$help) | is.null(opt$input) | is.null(opt$labels) | is.null(opt$outfile) ) {
    cat(getopt(spec, usage=TRUE))
    q(status=1)
}

#+--------------------
# main
#+--------------------
today<-Sys.time()
print(today)

files=unlist(strsplit(opt$input,"[:,]"))
labels=unlist(strsplit(opt$labels,"[:,]"))
listVenn = list()
for (i in 1:length(files) ){
    data = read.csv(files[i], header = F, stringsAsFactors = F)
    listVenn[labels[i]] = list(data$V1)
}

venn.diagram( x=listVenn, filename = opt$outfile,
	height = 450, width = 450,resolution =300, imagetype="png", col ="transparent",
	fill = rainbow(length(files)), alpha = 0.5, cex = 0.45, cat.cex = 0.45 )

today<-Sys.time()
print(today)

