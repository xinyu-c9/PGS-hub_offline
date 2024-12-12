version 1.0
# Author: Xingyu Chen
# File: SBayesR.wdl
# Version: 1.0

workflow SBayesR{
	input {
		File summary_statistic_2 
		String ldref_0 
		Array[Float] pi_1_value
		Array[Float] gamma_1_value
		String? ambiguous_snp_1_value = ""
		String? impute_n_1_value = ""
		Array[Int] chain_length_1_value																							
		Array[Int] burn_in_1_value
		Array[Int] out_freq_1_value
		String resultname_1_value
		String ambiguous_snp = if ambiguous_snp_1_value == "1" then "--ambiguous-snp" else ""
		String impute_n = if impute_n_1_value == "1" then "--impute-n" else ""
	}

	call adjustformat { input: gwas=summary_statistic_2 }
	call SBayesR_cal { input: gwas=adjustformat.out, mldmlist=ldref_0, pi=pi_1_value, gamma=gamma_1_value, ambiguous_snp=ambiguous_snp, impute_n=impute_n, chain_length=chain_length_1_value, burn_in=burn_in_1_value, out_freq=out_freq_1_value, resultname=resultname_1_value } 
	call zip { input: in_PRS_result=SBayesR_cal.out}
}

task adjustformat{
	input {
		File gwas
	}
	command <<< 
		source ~/.bashrc
		header=$(head -n 1 ~{gwas})
		less ~{gwas} | sed 1d | awk '{print > "chr" $1}'
		for i in {1..22}
		do
			echo "$header" | cat - chr$i > tmp_chr$i
			mv tmp_chr$i chr$i
			Rscript $PRSHUB_PATH/utils/SBayesR/SBayesR_adjustformat.R -i chr$i -o output_adjustformat_chr$i
		done
	>>>
	output { Array[File] out = glob("output_adjustformat_chr*") }
}

task SBayesR_cal{
	input {
		Array[File] gwas
		String mldmlist
		Array[Float] pi
		Array[Float] gamma
		String ambiguous_snp
		String impute_n
		Array[Int] chain_length
		Array[Int] burn_in
		Array[Int] out_freq
		String resultname 
	}
	command <<< 
		source ~/.bashrc
		for i in ~{sep=" " gwas}
		do
			for c in ~{sep=" " chain_length}
			do
				for b in ~{sep=" " burn_in}
				do
					f=`basename $i | sed -e 's/output_adjustformat_chr\(.*\)/\1/'`
					$PRSHUB_PATH/utils/SBayesR/gctb --sbayes R \
					--ldm ~{mldmlist}/SBayesR/SBayesR_chr$f.ldm.shrunk \
					--pi ~{sep="," pi} \
					--gamma ~{sep="," gamma} \
					--gwas-summary $i \
					--chain-length $c \
					--burn-in $b \
					--out-freq ~{sep="" out_freq} \
					--out result_~{resultname}_${c}_${b}_chr$f \
					~{ambiguous_snp} \
					~{impute_n}
				done
			done
		done
	>>>
	output { Array[File] out = glob("*result*") }
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
		less tempfile_name | tr -s "\n" " " | xargs tar czvf result_SBayesR.tar.gz -C $IN_DIR
		rm tempfile_name
	}
	output { File out = "result_SBayesR.tar.gz" }
}