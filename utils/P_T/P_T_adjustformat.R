'
adjust format, and export the result into file. require docopt

Notes:
  * The GWAS summary must has the following columns:
        CHR,SNP,POSITION,A1,A2,A1_FREQ,BETA,SE,P,N_MISSING,N_OBSERVATION

Usage:
  adjustformat.R -i inputfile -o outputname

Options:
  -i input     inputfile
  -o output    outputname
' -> doc

library(docopt)
opts <- docopt(doc)
input_file <- opts$i
outputname <- opts$o
dat <- read.table(gzfile(input_file), header=T)
write.table(dat, outputname, quote=F, row.names=F, sep='\t', col.names=T)

