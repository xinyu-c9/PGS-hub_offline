'
Adjust format, and export the result into file. require docopt

Notes:
  * The GWAS summary must has the following columns:
        CHR,SNP,POSITION,A1,A2,A1_FREQ,BETA,SE,P,N_MISSING,N_OBSERVATION

Usage:
  SDPR_adjustformat.R -i inputfile -o outputname

Options:
  -i input     inputfile
  -o output    outputname
' -> doc

library(docopt)
opts <- docopt(doc)
input_file <- opts$i
outputname <- opts$o
dat <- read.table(gzfile(input_file), header=T)
dat <- dat[nchar(dat$A1) <= 1 & nchar(dat$A2) <= 1, ]
dat$Z <- dat$BETA / dat$SE
res <- dat[, c("SNP", "A1", "A2", "N", "Z")]
res <- res[!is.na(res$Z), ]
colnames(res) <- c("Predictor", "A1", "A2", "n", "Z")
write.table(res, outputname, quote=F, row.names=F, sep='\t', col.names=T)

