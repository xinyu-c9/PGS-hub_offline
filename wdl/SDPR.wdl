# Author: Xingyu Chen
# File: SDPR.wdl
# Version: 1.0

workflow SDPR{
	File summary_statistic_2 
	String ldref_0 
	Array[Int] n_1_value
	String resultname_1_value

	call adjustformat { input: gwas=summary_statistic_2 }
	call SDPR_cal { input: gwas=adjustformat.out, ldref=ldref_0, n_gwas=n_1_value, resultname=resultname_1_value } 
	call zip { input: in_PRS_result=SDPR_cal.out}
}

task adjustformat{
	File gwas
	command { 
		source ~/.bashrc
		Rscript $PRSHUB_PATH/utils/SDPR/SDPR_adjustformat.R -i ${gwas} -o output_adjustformat.ext 
	}
	output { File out = "output_adjustformat.ext" }
}

task SDPR_cal{
	File gwas
	String ldref
	Array[Int] n_gwas
	String resultname 
	command {
		source ~/.bashrc
		export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PRSHUB_PATH/utils/SDPR/SDPR-0.9.1/gsl/lib/:$PRSHUB_PATH/utils/SDPR/SDPR-0.9.1/MKL/lib/
		for i in `seq 22`
		do
			$PRSHUB_PATH/utils/SDPR/SDPR-0.9.1/SDPR -mcmc \
			-ref_dir ${ldref}/SDPR/ \
			-ss ${gwas} \
			-N ${sep="" n_gwas} \
			-chr $i \
			-out result_${resultname}_chr$i \
			-n_threads 8
		done
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
		less tempfile_name | tr -s "\n" " " | xargs tar czvf result_SDPR.tar.gz -C $IN_DIR
		rm tempfile_name
	}
	output { File out = "result_SDPR.tar.gz" }
}