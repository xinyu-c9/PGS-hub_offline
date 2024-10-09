# Author: Xingyu Chen
# File: megaPRS.wdl
# Version: 1.0

workflow megaPRS{
	input {
		File summary_statistic_2 
		String ldref_0 
		String model_1_value = "bayesr"
		String window_kb_1_value = "1000"
		String h2_mode_1_value = "LDAK"
		Boolean output_all_model_1_value = false
	}

	call adjustformat { input: in=summary_statistic_2 }
	call cal_tagging { input: ldref_0=ldref_0, sst_file=adjustformat.out, h2_filename=h2_mode_1_value } 
	if (output_all_model_1_value) {
		call cal_eff_allmodel { input: ldref_0=ldref_0, sst_file=adjustformat.out, ind_her=cal_tagging.out_her, snplist=cal_tagging.out_snplist, model=model_1_value, window_kb=window_kb_1_value }
		call zip as zip_allmodel { input: in_PRS_result=cal_eff_allmodel.out}
	}
	if (!output_all_model_1_value) {
		call cal_eff { input: ldref_0=ldref_0, sst_file=adjustformat.out, ind_her=cal_tagging.out_her, snplist=cal_tagging.out_snplist, model=model_1_value, window_kb=window_kb_1_value }
		call zip { input: in_PRS_result=cal_eff.out}
	}
}

task adjustformat{
	File in
	command { Rscript $PRSHUB_PATH/utils/megaPRS/megaPRS_adjustformat.R -i ${in} -o output_adjustformat.ext }
	output { File out = "output_adjustformat.ext" }
}

task cal_tagging{
	String ldref_0
	File sst_file
	String h2_filename
	command {
		less ${sst_file} | cut -f 1 | grep -wFf - ${ldref_0}/megaPRS/plink.bim | cut -f 2 > snplist
		$PRSHUB_PATH/utils/megaPRS/ldak5.2.linux \
			--sum-hers ./${h2_filename} \
			--tagfile ${ldref_0}/megaPRS/h2/${h2_filename}.tagging \
			--summary ${sst_file} \
			--matrix ${ldref_0}/megaPRS/h2/${h2_filename}.matrix \
			--extract ./snplist
	}
	output { 
		File out_her = "~{h2_filename}.ind.hers" 
		File out_snplist = "snplist"
	}
}

task cal_eff{
	String ldref_0
	File sst_file
	File ind_her
	File snplist
	String model 
	String window_kb 
	command {
		$PRSHUB_PATH/utils/megaPRS/ldak5.2.linux \
			--mega-prs ./result \
			--model ${model} \
			--ind-hers ${ind_her} \
			--summary ${sst_file} \
			--cors ${ldref_0}/megaPRS/cors \
			--cv-proportion .1 \
			--high-LD ${ldref_0}/megaPRS/highld/highld_hg38.txt \
			--window-kb ${window_kb} \
			--extract ${snplist}
	}
	output { Array[File] out = glob("result*") }
}

task cal_eff_allmodel{
	String ldref_0
	File sst_file
	File ind_her
	File snplist
	String model 
	String window_kb 
	command {
		$PRSHUB_PATH/utils/megaPRS/ldak5.2.linux \
			--mega-prs ./result \
			--model ${model} \
			--ind-hers ${ind_her} \
			--summary ${sst_file} \
			--cors ${ldref_0}/megaPRS/cors \
			--skip-cv YES \
			--window-kb ${window_kb} \
			--extract ${snplist}
	}
	output { Array[File] out = glob("result*") }
}

task zip{
	Array[File] in_PRS_result
	command { 
		IN_DIR=$(dirname ${in_PRS_result[1]})
		for i in ${sep=" " in_PRS_result}
			do
			basename $i >> tempfile_name
			done
		less tempfile_name | tr -s "\n" " " | xargs tar -czvf result_megaPRS.tar.gz -C $IN_DIR
		rm tempfile_name
	}
	output { File out = "result_megaPRS.tar.gz" }
}