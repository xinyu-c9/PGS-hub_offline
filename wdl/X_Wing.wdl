# Author: Xingyu Chen
# File: X_Wing.wdl
# Version: 1.0

workflow X_Wing{
	input {
		Array[File] summary_statistic_2 
		String ldref_0
		Array[String] pop_0
		Array[Int] n_gwas_1_value
		Array[String] phi_1_value = ["1e-2"]
		String target_pop_1_value
		Int n_topregion_1_value = 1000
		Int n_iter_1_value = 2000
		Int n_burnin_1_value = 1000
		Int thin_1_value = 5
		String resultname_1_value
	}

	call X_Wing_adjustformat { input: in=summary_statistic_2 }
	call LOGODetect { input:  in1=X_Wing_adjustformat.out0, in2=X_Wing_adjustformat.out1, ref_dir=ldref_0, cohort_1=pop_0, n_gwas=n_gwas_1_value, target_pop=target_pop_1_value, n_topregion=n_topregion_1_value } 
	call run_PANTHER { input: in1=X_Wing_adjustformat.out0, in2=X_Wing_adjustformat.out1, ref_dir=ldref_0, cohort_1=pop_0, n_gwas=n_gwas_1_value, target_pop=target_pop_1_value, phi=phi_1_value, resultname=resultname_1_value, n_iter=n_iter_1_value, n_burnin=n_burnin_1_value, thin=thin_1_value, anno0=LOGODetect.out0, anno1=LOGODetect.out1 }
	call zip { input: in_PRS_result=run_PANTHER.out }
}

task X_Wing_adjustformat {
	input {
		Array[File] in
	}
	command <<< 
		j=0
		for i in ~{sep=" " in}
		do
			j=`expr $j + 1`
			Rscript $PRSHUB_PATH/utils/X_Wing/X_Wing_adjustformat.R -i ${i} -o ${j}_out
		done
	>>>
	output { 
		File out0 = "1_out" 
		File out1 = "2_out"
	}
}

task LOGODetect{
	input {
		File in1
		File in2
		Array[Int] n_gwas
		String ref_dir
		Array[String] cohort_1
		String target_pop
		Int n_topregion
	}
	command <<< 
		Rscript $PRSHUB_PATH/utils/X_Wing/LOGODetect.R \
		--sumstats ~{in1},~{in2} \
		--n_gwas ~{sep="," n_gwas} \
		--ref_dir ~{ref_dir}/X_Wing/Anno \
		--pop ~{sep="," cohort_1} \
		--block_partition ~{ref_dir}/ldblockEUR_hg38 \
		--gc_snp ~{ref_dir}/X_Wing/PRScs_hg38_sortedid_snplist \
		--out_dir . \
		--n_cores 8 \
		--target_pop ~{target_pop} \
		--n_topregion ~{n_topregion}
	>>>
	output { 
		File out0 = "annot_${cohort_1[0]}.txt" 
		File out1 = "annot_${cohort_1[1]}.txt"
	}
}

task run_PANTHER{
	input {
		File in1
		File in2
		String ref_dir
		Array[String] cohort_1
		String target_pop
		Array[Int] n_gwas
		Array[String] phi
		String resultname
		Int n_iter
		Int n_burnin
		Int thin
		File anno0
		File anno1
	}
	command <<< 
		export N_THREADS=8
		export MKL_NUM_THREADS=$N_THREADS
		export NUMEXPR_NUM_THREADS=$N_THREADS
		export OMP_NUM_THREADS=$N_THREADS
		for i in ~{sep=" " phi}
		do
			python $PRSHUB_PATH/utils/X_Wing/PANTHER.py \
				--ref_dir ~{ref_dir}/X_Wing/PANTHER \
				--bim_prefix ~{ref_dir}/X_Wing/PANTHER/~{target_pop}.bim \
				--sumstats ~{in1},~{in2} \
				--n_gwas ~{sep="," n_gwas} \
				--anno_file ~{anno0},~{anno1} \
				--pop ~{sep="," cohort_1} \
				--target_pop ~{target_pop} \
				--pst_pop ~{target_pop} \
				--out_name result \
				--out_dir . \
				--phi ${i} \
				--n_iter ~{n_iter} \
				--n_burnin ~{n_burnin} \
				--thin ~{thin} 
		done
	>>>
	output { Array[File] out = glob("*.txt") }
}

task zip{
	input {
		Array[File] in_PRS_result
	}
	command { 
		IN_DIR=$(dirname ${in_PRS_result[1]})
		for i in ${sep=" " in_PRS_result}
			do
			basename $i >> tempfile_name
			done
		less tempfile_name | tr -s "\n" " " | xargs tar czvf result_X_Wing.tar.gz -C $IN_DIR
		rm tempfile_name
	}
	output { File out = "result_X_Wing.tar.gz" }
}