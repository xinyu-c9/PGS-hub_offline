'
Adjust format, and export the result into file. require docopt

Notes:
  * The GWAS summary must has the following columns:
        CHR,SNP,POSITION,A1,A2,A1_FREQ,BETA,SE,P,N_MISSING,N_OBSERVATION

Usage:
  SBLUP_adjustformat.R -i inputfile -o outputname

Options:
  -i input     inputfile
  -o output    outputname
' -> doc

library(docopt)
opts <- docopt(doc)
input_file <- opts$i
outputname <- opts$o
dat <- read.table(gzfile(input_file), header=T)
res <- cbind(dat$SNP,dat$A1,dat$A2,dat$A1_FREQ,dat$BETA,dat$SE,dat$P,dat$N)
colnames(res) <- c("SNP", "A1", "A2", "freq", "b", "se", "p", "N")
write.table(res, outputname, quote=F, row.names=F, sep='\t', col.names=T)


