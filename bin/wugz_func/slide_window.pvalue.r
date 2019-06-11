#!/share/software/software/R-3.0_install/R-3.0.1/bin/Rscript
library(getopt)
#+--------------------
# get options
#+--------------------
spec <- matrix(c(	
     'help',     'h',    0, "logical",   "help",
     'input',    'i',    1, "character", "input p-value file, forced.",
	 'outfile',  'o',    1, "character", "outfile of slide_window.pvalue plot figure, forced.",
	 'window',	 'w',	 2, "character", "input count window size, [2001]",
     'cut',      'c',    2, "character", "input p-cut, [0.01]"
), byrow = TRUE, ncol = 5)

opt <- getopt(spec)
#+--------------------
# check options
#+--------------------
if ( !is.null(opt$help) | is.null(opt$input) | is.null(opt$outfile) ) {
    cat(getopt(spec, usage=TRUE))
    q(status=1)
}

#+--------------------
# some default options
#+--------------------
if (is.null(opt$cut)) opt$cut <- 0.01
if (is.null(opt$window)) opt$window <- 2001
options(scipen = 200)
#+--------------------
# Main
#+--------------------
f = read.csv(opt$input, sep='\t', header = F, stringsAsFactors = F)
slidewind = c()
for ( i in 1:nrow(f) ){
	prefer_N = 0
	count_N = 0
	pos =  as.numeric( f[i,1] ) 
	window_half = ( as.numeric( opt$window ) - 1)/2
	min = pos-window_half
	max = pos+window_half
	#print( c(pos, nrow(f), i, window_half, f[i,1]) )
	indexmin = i-window_half
	indexmax = i+window_half
	if( i-window_half < 1 )	{		indexmin = 1	}
	if( i+window_half > nrow(f) ){	indexmax = nrow(f)	}
	for ( j in indexmin:indexmax ){
		if( as.numeric(f[j,1]) < max && as.numeric(f[j,1]) > min ){
			count_N = count_N + 1
			if( as.numeric(f[j,7]) > opt$cut ){
				prefer_N = prefer_N + 1
				#print(c(pos, f[j,1], j, f[j,7]))
			}
		}
	}
	slidewind[i] = prefer_N/count_N
}
colnames(f) = c('pos','preferN','sum','len','mean','p','padjust')
f$slidew = slidewind

p <- ggplot(f,aes(x=pos,y=slidew)) + geom_point() + geom_smooth(method="lm")
ggsave(filename = opt$outfile, plot = p)

warnings()

