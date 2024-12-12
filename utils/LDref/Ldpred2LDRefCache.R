'
Create LD reference correlation caches for LDpred2 algorithm.

Notes:
  * The rsid is snpid, can be any unique text. GWAS and LDref should be match.
  * The LD reference panel were stored in separated chr, plink 1.0 bed/bim/fam format.

Usage:
  LDpred2.R -p bfile -d dir

Options:
  -p bfile      Plink bed/fam/bim file name template for LD reference, split by each chr.
                    eg. eur.ref.chr#.ref -> will be interpreted as: 
                        eur.ref.chr1.ref, eur.ref.chr2.ref ... eur.ref.chr22.ref
  -d dir        Directory containing genetic map for snp_asGeneticPos().
' -> doc

# Pipeline for running LDpred2. bigsnpr version >= 1.7.1, tested in 1.7.1
# https://choishingwan.github.io/PRS-Tutorial/ldpred/
# https://privefl.github.io/bigsnpr/articles/LDpred2.html

# Pipeline testing:
# /medpop/esp2/wallace/tools/conda_build/ldpred2/example

# update to auto-detect and install packages.
# https://stackoverflow.com/questions/4090169/elegant-way-to-check-for-missing-packages-and-install-them
# http://trinker.github.io/pacman/vignettes/Introduction_to_pacman.html
if (!require("pacman"))  install.packages("pacman")
if (!require("bigsnpr")) p_install_version(c("bigsnpr"),c("1.7.1"))
pacman::p_load(dplyr, docopt, rio, data.table, magrittr, bigsnpr,
    install = TRUE, update=FALSE)
# require and install the minimal version.
if (p_version(bigsnpr) < '1.7.1') p_install_version(c("bigsnpr"),c("1.7.1"))
# On some server, you might need to first use the following code in order to run LDpred with multi-thread
options(bigstatsr.check.parallel.blas = FALSE)
options(default.nproc.blas = NULL)

opts <- docopt(doc)
# what are the options? Note that stripped versions of the parameters are added to the returned list
# str(opts)
pref   = opts$p %>% strsplit(.,'#') %>% unlist
genetic_map_dir = opts$d
MSGE <- function(...) cat(sprintf(...), sep='', file=stderr())
# END parse parameter

# ***** Calculate the LD matrix *****
# Get maximum amount of cores, +1 to use all available cpus.
NCORES <- 8
# Open a temporary file
tmp <- tempfile(tmpdir = "tmp-data")
on.exit(file.remove(paste0(tmp, ".sbk")), add = TRUE)

# Initialize variables for storing the LD score and LD matrix
corr <- NULL
ld <- NULL
# We want to know the ordering of samples in the bed file 
info_snp <- NULL
for (chr in 1:22) {
    # preprocess the bed file (only need to do once for each data set)
    # Assuming the file naming is eur.ref.chr#.ref
    bed_file = paste0(pref[1],chr,pref[2],"bed")
    if(file.exists(bed_file) == FALSE){
        MSGE('WARN: no LD reference for chr: %d, no file found:%s \n',chr, bed_file)
        next
    }
    cat(sprintf('-------WORKING CHR: %d-------',chr))
    # If the object has been created, we just need re-attach, no not need recreate.
    # The snp_readBed will create the rds and bk files. One for meta info. one for genotype matrix.
    # https://privefl.github.io/bigsnpr/reference/snp_readBed.html
    genoCacheF = paste0(pref[1],chr,pref[2],"rds")
    corrCacheF = paste0(pref[1],chr,pref[2],'LDrefCaches',".rds")
    if(file.exists(genoCacheF) == FALSE){
        # snp_readBed(bed_file, ncores = NCORES)
        snp_readBed(bed_file)
    }
    # now attach the genotype object
    obj.bigSNP <- snp_attach(genoCacheF)

    # extract the SNP information from the genotype
    map <- obj.bigSNP$map[-3]
    names(map) <- c("chr", "rsid", "pos", "a1", "a0")
    #Make a fake GWAS Summary
    map$beta = 0
    # perform SNP matching
    # Here, we are creating correlation map caches, we will use all variants,
    # So we just match to itself.
    tmp_snp <- snp_match(map, map)
    info_snp <- rbind(info_snp, tmp_snp)
    # Assign the genotype to a variable for easier downstream analysis
    genotype <- obj.bigSNP$genotypes
    # Rename the data structures
    CHR <- map$chr
    POS <- map$pos
    # get the CM information from 1000 Genome
    # will download the 1000G file to the current directory (".")
    POS2 <- snp_asGeneticPos(CHR, POS, dir = genetic_map_dir)
    # calculate LD
    # Extract SNPs that are included in the chromosome
    ind.chr <- which(tmp_snp$chr == chr)
    ind.chr2 <- tmp_snp$`_NUM_ID_`[ind.chr]
    # Calculate the LD
    corr0 <- snp_cor(
            genotype,
            ind.col = ind.chr2,
            ncores = NCORES,
            infos.pos = POS2[ind.chr2],
            size = 3 / 1000
        )

    saveRDS(corr0, corrCacheF, version = 2)
    # if (chr == 1) {
    #     ld <- Matrix::colSums(corr0^2)
    #     corr <- as_SFBM(corr0, tmp)
    # } else {
    #     ld <- c(ld, Matrix::colSums(corr0^2))
    #     corr$add_columns(corr0, nrow(corr))
    # }
    # # We assume the fam order is the same across different chromosomes
    # if(is.null(fam.order)){
    #     fam.order <- as.data.table(obj.bigSNP$fam)
    # }
}