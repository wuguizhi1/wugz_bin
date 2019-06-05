#!/share/software/software/R-3.0_install/R-3.0.1/bin/Rscript
library(getopt)
#+--------------------
# get options
#第一列：参数的longname，多个字符。
#第二列：参数的shortname，一个字符。
#第三列：参数是必须的，还是可选的，数字：0代表不接参数 ；1代表必须有参数；2代表参数可选。
#第四列：参数的类型。logical；integer；double；complex；character；numeric
#第五列：注释信息，可选。
#+--------------------
spec <- matrix(c(	
     'help',     'h',    0, "logical",   "help",
     'input',    'i',    1, "character", "input sample.hotspots.result file, forced.",
     'cffdna',   'c',    1, "character", "input cffdna of this sample, forced.",
     'outfile',  'o',    1, "character", "outfile of sample.EM.xls with fetalDNA and genotyping info, forced."
), byrow = TRUE, ncol = 5)

opt <- getopt(spec)
#+--------------------
# check options
#+--------------------
if ( !is.null(opt$help) | is.null(opt$input) | is.null(opt$cffdna) | is.null(opt$outfile) ) {
    cat(getopt(spec, usage=TRUE))
    q(status=1)
}

#+--------------------
# some default options
#+--------------------
f (is.null(opt$annocol)) opt$annocol <- 5

#+--------------------
# EM - settings
#+--------------------

#+--------------------
# Main
#+--------------------


warnings()

