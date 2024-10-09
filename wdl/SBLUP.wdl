# Author: Xingyu Chen
# File: SBLUP.wdl
# Version: 1.0

workflow SBLUP{
	File summary_statistic_2 
	String ldref_0 
	Array[String] cojo_sblup_1_value
	Array[String] cojo_wind_1_value
	String resultname_1_value

	call adjustformat { input: gwas=summary_statistic_2 }
	call SBLUP_cal { input: gwas=adjustformat.out, ldref=ldref_0, resultname=resultname_1_value, cojo_sblup=cojo_sblup_1_value, cojo_wind=cojo_wind_1_value } 
	call zip { input: in_PRS_result=SBLUP_cal.out}
}

task adjustformat{
	File gwas
	command { Rscript $PRSHUB_PATH/utils/SBLUP/SBLUP_adjustformat.R -i ${gwas} -o output_adjustformat.ext }
	output { File out = "output_adjustformat.ext" }
}

task SBLUP_cal{
	File gwas
	String ldref
	Array[String] cojo_sblup
	Array[String] cojo_wind
	String resultname 
	command {
		$PRSHUB_PATH/utils/SBLUP/gcta-1.94.1 \
			--bfile ${ldref}/SBLUP/plink \
			--cojo-file ${gwas} \
			--cojo-sblup ${sep="" cojo_sblup} \
			--cojo-wind ${sep="" cojo_wind} \
			--thread-num 8 \
			--out ./result_${resultname}
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
		less tempfile_name | tr -s "\n" " " | xargs tar czvf result_SBLUP.tar.gz -C $IN_DIR
		rm tempfile_name
	}
	output { File out = "result_SBLUP.tar.gz" }
}