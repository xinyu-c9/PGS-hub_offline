j=0
OUTDIR=`dirname $2`
cat $1| sed '1d' |while read chr from to
do
	j=`expr $j + 1`
	if [ "`head -n 1 $2.bim | cut -c1-3`" != "chr" ]; then 
		chr=`echo $chr | sed 's/...//'`
	fi
	less $2.bim | awk '{if ($1==chr) print}' chr=$chr | awk '{if ($4>from) print}' from=$from | awk '{if ($4<=to) print $2}' to=$to | less > ${OUTDIR}/ldblk$j
	if [ -z "`less ${OUTDIR}/ldblk$j`" ];then 
		echo -e "$chr\tldblk$j\tldmat$j.ld\t0" >> ${OUTDIR}/chr_snplist_ldblockfile
	else
		echo -e "$chr\tldblk$j\tldmat$j.ld\t1" >> ${OUTDIR}/chr_snplist_ldblockfile
	fi
done

ldblk_num=`find ${OUTDIR}/ldblk* | wc -l`
if [ ! -e ${OUTDIR}/ldblk_cal ]; then mkdir ${OUTDIR}/ldblk_cal ;fi

for i in `seq $ldblk_num`
do
 	$PRSHUB_PATH/utils/LDref/plink \
 		--bfile $2 \
 		--keep-allele-order \
 		--extract ${OUTDIR}/ldblk$i \
 		--r square \
 		--out ${OUTDIR}/ldblk_cal/ldmat$i
done
