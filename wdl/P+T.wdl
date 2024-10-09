# Author: Xingyu Chen
# File: P+T.wdl
# Version: 1.0

workflow PandT{
	File summary_statistic_2 
	String ldref_0 #dir of LD for each algrithom 
	Array[Float] R2_1_value #comma-seprated r2 value
	Array[Float] Range_1_value #comma-seprated P upper bounds

	call adjustformat { input: in=summary_statistic_2 }
	call clumping { input: in1_summary=adjustformat.out, in2_bfile=ldref_0, r2_value=R2_1_value } 
	call split { input: in_rangelist=Range_1_value, in_clumping_summary=clumping.out }
	call zip { input: in_split_result=split.out}
}

task adjustformat{
	File in
	command { Rscript $PRSHUB_PATH/utils/P_T/P_T_adjustformat.R -i ${in} -o output_adjustformat.ext}
	output { File out = "output_adjustformat.ext"}
}

task clumping{
	File in1_summary
	String in2_bfile
	Array[Float] r2_value
	command {
		for i in ${sep=" " r2_value}
		do
		$PRSHUB_PATH/utils/P_T/plink \
			--bfile ${in2_bfile}/P_T/plink  \
			--clump-p1 1 \
			--clump-r2 $i \
			--clump-kb 250 \
			--clump ${in1_summary} \
			--clump-snp-field SNP \
			--clump-field P \
			--out $i
		done
	}
	output { Array[File] out = glob("*.clumped") }
}

task split{
	Array[Float] in_rangelist
	Array[File] in_clumping_summary
	command { 
		for i in ${sep=" " in_clumping_summary}
		do
		Rscript $PRSHUB_PATH/utils/P_T/P+T_split.R -i $i -o $(basename $i) --rangelist ${sep=" " in_rangelist}
		done
	}
	output { Array[File] out = glob("*_result") }
}

task zip{
	Array[File] in_split_result
	command { 
		IN_DIR=$(dirname ${in_split_result[1]})
		for i in ${sep=" " in_split_result}
			do
			basename $i >> tempfile_name
			done
		less tempfile_name | tr -s "\n" " " | xargs tar czvf result_P+T.tar.gz -C $IN_DIR
		rm tempfile_name
	}
	output { File out = "result_P+T.tar.gz" }
}