#!/bin/bash

# Display help information
function display_help() {
    echo "Usage: $0 -p <pgen_file_path> -c <cohort>"
    echo
    echo "Options:"
    echo "  -p    Absolute path to the pgen file (excluding .tar.gz extension)"
    echo "  -c    Cohort name (e.g., EUR, EAS)"
    echo "  -h    Show this help message and exit"
    echo
    echo "Example:"
    echo "  $0 -p /absolute/path/to/pgen_file -c EUR"
    exit 0
}

# Check for required options
PGEN=""
COHORT=""

# Parse options
while getopts ":p:c:h" option; do
    case "$option" in
        p)
            PGEN=$OPTARG
            ;;
        c)
            COHORT=$OPTARG
            ;;
        h)
            display_help
            ;;
        *)
            echo "Invalid option: -$OPTARG"
            echo "Use -h or --help for usage information."
            exit 1
            ;;
    esac
done

# Verify mandatory options are provided
if [ -z "$PGEN" ] || [ -z "$COHORT" ]; then
    echo "Error: Both -p and -c options are required."
    echo "Use -h or --help for usage information."
    exit 1
fi

# Verify that the specified PGEN file exists
if [ ! -f "${PGEN}.tar.gz" ]; then
    echo "Error: PGEN file ${PGEN}.tar.gz does not exist."
    exit 1
fi

# Main script logic begins here
echo "Processing PGEN file: $PGEN"
echo "Using cohort: $COHORT"


###Creat basic plink bed file in tempdir. 
OUTDIR=`dirname $PGEN`
tar -zxvf ${PGEN}.tar.gz -C `dirname ${PGEN}`
PGENNAME=`find ${OUTDIR}/*.pgen -maxdepth 1 | xargs -I % basename % .pgen`
if [ ! -e ${OUTDIR}/plink_temp ]; then mkdir ${OUTDIR}/plink_temp ;fi
$PRSHUB_PATH/utils/LDref/plink2 --pfile ${OUTDIR}/${PGENNAME} --make-bed --out ${OUTDIR}/plink_temp/plink
for i in `seq 22`
do
    $PRSHUB_PATH/utils/LDref/plink2 --bfile ${OUTDIR}/plink_temp/plink --chr $i --make-bed --out ${OUTDIR}/plink_temp/chr$i
    $PRSHUB_PATH/utils/LDref/plink2 --bfile ${OUTDIR}/plink_temp/plink --chr $i --freq --out ${OUTDIR}/plink_temp/freq$i
done

###Generate P+T LD
if [ ! -e ${OUTDIR}/P_T ]; then mkdir ${OUTDIR}/P_T ;fi
cp ${OUTDIR}/plink_temp/plink* ${OUTDIR}/P_T

###Generate PRSCS LD
export HDF5_USE_FILE_LOCKING='FALSE'
if [ ! -e ${OUTDIR}/PRSCS ]; then mkdir ${OUTDIR}/PRSCS ;fi
cp ${OUTDIR}/plink_temp/plink* ${OUTDIR}/PRSCS
bash $PRSHUB_PATH/utils/LDref/PRSCS_SNP_list_LD_matrix_generate.sh $PRSHUB_PATH/utils/LDref/ldblock${COHORT}_hg38 ${OUTDIR}/PRSCS/plink
python $PRSHUB_PATH/utils/LDref/PRSCS_write_ldblk.py --INPUT ${OUTDIR}/PRSCS/chr_snplist_ldblockfile --OUTDIR ${OUTDIR}/PRSCS
rm -r `find ${OUTDIR}/PRSCS/* | grep -v ".hdf5"`
for i in `seq 22`
do
    less ${OUTDIR}/plink_temp/chr$i.bim | cut -f 1,2,4,5,6 > ${OUTDIR}/PRSCS/temp1chr$i
    less ${OUTDIR}/plink_temp/freq$i.afreq | sed '1d' | cut -f 6 > ${OUTDIR}/PRSCS/temp2chr$i
    paste ${OUTDIR}/PRSCS/temp1chr$i ${OUTDIR}/PRSCS/temp2chr$i >>${OUTDIR}/PRSCS/temp
done

python $PRSHUB_PATH/utils/LDref/get_snplist_of_PRSCS_LD.py ${OUTDIR}/PRSCS ${OUTDIR}/PRSCS/output.txt
less ${OUTDIR}/PRSCS/output.txt | awk -vFS="'" -vOFS="\t" '{print $2}' | grep -wFf - ${OUTDIR}/PRSCS/temp | sed  '1i CHR\tSNP\tBP\tA1\tA2\tMAF' > ${OUTDIR}/PRSCS/snpinfo_1kg_hm3
cp ${OUTDIR}/plink_temp/plink.bim ${OUTDIR}/PRSCS/
rm -rf ${OUTDIR}/PRSCS/temp*

###Generate SBayesR LD
#Generate shrunk LD
if [ ! -e ${OUTDIR}/SBayesR ]; then mkdir ${OUTDIR}/SBayesR ;fi
    for i in `seq 22`
    do
        $PRSHUB_PATH/utils/SBayesR/gctb --make-shrunk-ldm \
        --bfile ${OUTDIR}/plink_temp/chr$i \
        --out ${OUTDIR}/SBayesR/SBayesR_chr$i
    done
#Generate shrunk LD list
if [ ! -e ${OUTDIR}/SBayesR/mldm_list.mldmlist ]
then 
    for i in `seq 22`
    do
        echo "$OUTDIR/SBayesR/SBayesR_chr$i.ldm.shrunk" >> ${OUTDIR}/SBayesR/mldm_list.mldmlist 
    done
else 
    rm ${OUTDIR}/SBayesR/mldm_list.mldmlist
    for i in `seq 22`
    do
    echo "$OUTDIR/SBayesR/SBayesR_chr$i.ldm.shrunk" >> ${OUTDIR}/SBayesR/mldm_list.mldmlist
    done
fi

###Generate LDpred2 LD
if [ ! -e ${OUTDIR}/LDpred2 ]; then mkdir ${OUTDIR}/LDpred2 ;fi
cp ${OUTDIR}/plink_temp/chr* ${OUTDIR}/LDpred2

###Generate Lassosum2 LD
if [ ! -e ${OUTDIR}/Lassosum2 ]; then mkdir ${OUTDIR}/Lassosum2 ;fi
cp ${OUTDIR}/plink_temp/chr* ${OUTDIR}/Lassosum2

###Generate SDPR LD
if [ ! -e ${OUTDIR}/SDPR ]; then mkdir ${OUTDIR}/SDPR ;fi
export export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PRSHUB_PATH/utils/SDPR/SDPR-0.9.1/gsl/lib/:$PRSHUB_PATH/utils/SDPR/SDPR-0.9.1/MKL/lib/
for i in `seq 22`
do
    $PRSHUB_PATH/utils/SDPR/SDPR-0.9.1/SDPR -make_ref \
    -ref_prefix ${OUTDIR}/plink_temp/chr$i \
    -chr $i \
    -ref_dir ${OUTDIR}/SDPR
done

###Generate SBLUP LD
if [ ! -e ${OUTDIR}/SBLUP ]; then mkdir ${OUTDIR}/SBLUP ;fi
cp ${OUTDIR}/P_T/plink* ${OUTDIR}/SBLUP


###Generate megaPRS LD
if [ ! -e ${OUTDIR}/megaPRS ]; then mkdir ${OUTDIR}/megaPRS ;fi
if [ ! -e ${OUTDIR}/megaPRS/h2 ]; then mkdir ${OUTDIR}/megaPRS/h2 ;fi
cp ${OUTDIR}/P_T/plink* ${OUTDIR}/megaPRS
cp -r $PRSHUB_PATH/utils/megaPRS/highld ${OUTDIR}/megaPRS/
#calculate correlation matrix
for i in {1..22}
do
    $PRSHUB_PATH/utils/megaPRS/ldak5.2.linux --calc-cors ${OUTDIR}/megaPRS/cors$i --bfile ${OUTDIR}/plink_temp/chr$i --window-kb 3000 --chr $i
done
rm ${OUTDIR}/megaPRS/list.txt
for i in {1..22}
do
        echo "${OUTDIR}/megaPRS/cors$i" >> ${OUTDIR}/megaPRS/list.txt
done
$PRSHUB_PATH/utils/megaPRS/ldak5.2.linux --join-cors ${OUTDIR}/megaPRS/cors --corslist ${OUTDIR}/megaPRS/list.txt
#prepared for h2 model
$PRSHUB_PATH/utils/megaPRS/ldak5.2.linux --cut-weights ${OUTDIR}/megaPRS/h2 --bfile ${OUTDIR}/megaPRS/plink
$PRSHUB_PATH/utils/megaPRS/ldak5.2.linux --calc-weights-all ${OUTDIR}/megaPRS/h2 --bfile ${OUTDIR}/megaPRS/plink
$PRSHUB_PATH/utils/megaPRS/ldak5.2.linux --calc-tagging ${OUTDIR}/megaPRS/h2/LDAK --bfile ${OUTDIR}/megaPRS/plink --weights ${OUTDIR}/megaPRS/h2/weights.short --power -.25 --window-kb 1000 --save-matrix YES
$PRSHUB_PATH/utils/megaPRS/ldak5.2.linux --calc-tagging ${OUTDIR}/megaPRS/h2/gcta --bfile ${OUTDIR}/megaPRS/plink --ignore-weights YES --power -1 --window-kb 1000 --save-matrix YES

