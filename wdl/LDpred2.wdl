# Author: Xingyu Chen
# File: LDpred2.wdl
# Version: 1.0

workflow LDpred2{
	File summary_statistic_2 
	String use_ref_ld_1_value
	Array[String] resultname_1_value
	String ldref_0
	Array[String] pvalue_1_value
	Array[String] h2_1_value
	
	call adjustformat { input: gwas=summary_statistic_2 }
	if (use_ref_ld_1_value == "1") {
		call LDpred2_cache_cal { input: resultname=resultname_1_value, gwas=adjustformat.out, ld_ref=ldref_0, pvalue=pvalue_1_value, h2=h2_1_value}
		call zip as zip_cache { input: in_PRS_result=LDpred2_cache_cal.out}
	}
	if (use_ref_ld_1_value == "0") {
		call LDpred2_cal { input: resultname=resultname_1_value, gwas=adjustformat.out, ld_ref=ldref_0, pvalue=pvalue_1_value, h2=h2_1_value}
		call zip as zip_normal { input: in_PRS_result=LDpred2_cal.out}
	}
}

task adjustformat{
	File gwas
	command { Rscript $PRSHUB_PATH/utils/LDpred2/LDpred2_adjustformat.R -i ${gwas} -o output_adjustformat.ext }
	output { File out = "output_adjustformat.ext" }
}

task LDpred2_cal{
	File gwas
	String ld_ref
	Array[String] resultname 
	Array[String] pvalue
	Array[String] h2
	command {
		Rscript $PRSHUB_PATH/utils/LDpred2/LDpred2_1.2.R \
		-o ${sep="" resultname}_result \
		-g ${gwas} \
		-p ${ld_ref} \
		-a ${sep="," pvalue} \
		-b ${sep="," h2} \
		-d $PRSHUB_PATH/utils/LDpred2/geneticmap
	}
	output { Array[File] out = glob("*result*") }
}

task LDpred2_cache_cal{
	File gwas
	String ld_ref
	Array[String] resultname
	Array[String] pvalue
	Array[String] h2
	command {
		Rscript $PRSHUB_PATH/utils/LDpred2/LDpred2LDCaches_1.2.R \
		-o ${sep="" resultname}_result \
		-g ${gwas} \
		-p ${ld_ref}/LDpred2/chr#. \
		-a ${sep="," pvalue} \
		-b ${sep="," h2} \
		-d $PRSHUB_PATH/utils/LDpred2/geneticmap
	}
	output { Array[File] out = glob("*result*") }
}

task zip{
	Array[File] in_PRS_result
	command { 
		IN_DIR=$(dirname ${in_PRS_result[1]})
		for i in ${sep=" " in_PRS_result}
			do
			basename $i >> tempfile_name
			done
		less tempfile_name | tr -s "\n" " " | xargs tar czvf result_LDpred2.tar.gz -C $IN_DIR
		rm tempfile_name
	}
	output { File out = "result_LDpred2.tar.gz" }
}