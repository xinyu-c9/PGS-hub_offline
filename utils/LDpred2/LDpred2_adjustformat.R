'
Adjust format, and export the result into file. require docopt

Notes:
  * The GWAS summary must has the following columns:
        CHR,SNP,POSITION,A1,A2,A1_FREQ,BETA,SE,P,N_MISSING,N_OBSERVATION

Usage:
  LDpred2_lassosum_adjustformat.R -i inputfile -o outputname

Options:
  -i input     inputfile
  -o output    outputname
' -> doc

library(docopt)
opts <- docopt(doc)
input_file <- opts$i
outputname <- opts$o
dat <- read.table(gzfile(input_file), header=T)
res <- cbind(dat$CHR,dat$POSITION,dat$SNP,dat$A2,dat$A1,dat$BETA,dat$SE,dat$N_EFF)
colnames(res) <- c("chr", "pos", "rsid", "a1", "a0", "beta", "beta_se", "n_eff")
write.table(res, outputname, quote=F, row.names=F, sep='\t', col.names=T)


