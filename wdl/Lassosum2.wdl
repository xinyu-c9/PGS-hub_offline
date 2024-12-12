# Author: Xingyu Chen
# File: Lassosum2.wdl
# Version: 1.0

workflow Lassosum2{
	File summary_statistic_2 
	String use_ref_ld_1_value
	Array[String] resultname_1_value
	String ldref_0
	Array[String] delta_1_value
	Array[String] nlambda_1_value
	
	call adjustformat { input: gwas=summary_statistic_2 }
	if (use_ref_ld_1_value == "1") {
		call lassosum_cache_cal { input: resultname=resultname_1_value, gwas=adjustformat.out, ld_ref=ldref_0, delta=delta_1_value, nlambda=nlambda_1_value}
		call zip as zip_cache { input: in_PRS_result=lassosum_cache_cal.out}
	}
	if (use_ref_ld_1_value == "0") {
		call lassosum_cal { input: resultname=resultname_1_value, gwas=adjustformat.out, ld_ref=ldref_0, delta=delta_1_value, nlambda=nlambda_1_value}
		call zip as zip_normal { input: in_PRS_result=lassosum_cal.out}
	}
}

task adjustformat{
	File gwas
	command { 
		source ~/.bashrc
		Rscript $PRSHUB_PATH/utils/Lassosum2/Lassosum2_adjustformat.R -i ${gwas} -o output_adjustformat.ext 
	}
	output { File out = "output_adjustformat.ext" }
}

task lassosum_cal{
	File gwas
	String ld_ref
	Array[String] resultname
	Array[String] delta
	Array[String] nlambda 
	command {
		source ~/.bashrc
		Rscript $PRSHUB_PATH/utils/Lassosum2/Lassosum2_1.2.R \
		-o ${sep="" resultname}_result \
		-g ${gwas} \
		-p ${ld_ref}/Lassosum2/chr#. \
		-d ${sep="," delta} \
		-l ${sep="" nlambda} \
		-a $PRSHUB_PATH/utils/LDpred2/geneticmap
	}
	output { Array[File] out = glob("*result*") }
}

task lassosum_cache_cal{
	File gwas
	String ld_ref
	Array[String] resultname
	Array[String] delta
	Array[String] nlambda
	command {
		source ~/.bashrc
		Rscript $PRSHUB_PATH/utils/Lassosum2/Lassosum2LDCaches_1.2.R \
		-o ${sep="" resultname}_result \
		-g ${gwas} \
		-p ${ld_ref}/Lassosum2/chr#. \
		-d ${sep="," delta} \
		-l ${sep="" nlambda} \
		-a $PRSHUB_PATH/utils/LDpred2/geneticmap
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
		less tempfile_name | tr -s "\n" " " | xargs tar czvf result_lassosum.tar.gz -C $IN_DIR
		rm tempfile_name
	}
	output { File out = "result_lassosum.tar.gz" }
}