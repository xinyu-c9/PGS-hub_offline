version 1.0
# Author: Xingyu Chen
# File: PRScsx.wdl
# Version: 1.0

workflow PRScsx{
	input {
		Array[File] summary_statistic_2 
		String ldref_0
		Array[String] pop_0
		Array[Int] n_gwas_1_value
		Array[String] phi_1_value = ["1e-2"]
		Array[Float] param_A_1_value = [1]
		Array[Float] param_B_1_value = [0.5]
		String resultname_1_value
	}

	call adjustformatandPRS { input: in=summary_statistic_2, ref_dir=ldref_0, cohort_1=pop_0, n_gwas=n_gwas_1_value, phi=phi_1_value, param_A=param_A_1_value, param_B=param_B_1_value, resultname=resultname_1_value } 
	call zip { input: in_PRS_result=adjustformatandPRS.out }
}

task adjustformatandPRS{
	input {
		Array[File] in
		String ref_dir
		Array[String] cohort_1
		Array[Int] n_gwas
		Array[String] phi
		Array[Float] param_A
		Array[Float] param_B
		String resultname
	}
	command <<< 
		source ~/.bashrc
		export HDF5_USE_FILE_LOCKING='FALSE'
		PYTHONPATH=$PRSHUB_PATH/utils/PRScsx/
		j=0
		for i in ~{sep=" " in}
		do
			j=`expr $j + 1`
			for c in `seq 22`
			do
				less ${i} | sed 1d | awk '{print > "'"$j"'" "_chr" $1}'
				head -n 1 ${i} | sed -e '1r /dev/stdin' -e '1!b' ${j}_chr${c} > header_${j}_chr${c}
				mv header_${j}_chr${c} ${j}_chr${c}
				Rscript $PRSHUB_PATH/utils/PRScsx/PRScsx_adjustformat.R -i ${j}_chr${c} -o result_${j}_chr${c}
			done
		done
		
		gwasnum=`echo ~{sep=" " in} | wc -w`
		for ((chr=1; chr<=22; chr++))
		do
			result=""
			for ((i=1; i<=gwasnum; i++))
			do
				result+="result_${i}_chr${chr},"
			done
			result=$(echo "$result" | sed 's/.$//')
			echo $result >> gwas_name_list
		done 
		less gwas_name_list | while read line
		do
			for i in ~{sep=" " phi}
			do
				python $PRSHUB_PATH/utils/PRScsx/filter_snp.py ${line}
				chrnum=`echo ${line} | sed 's/.*chr\([0-9]*\).*/\1/'`
				pwd | xargs -I '%' python $PRSHUB_PATH/utils/PRScsx/PRScsx.py \
				--ref_dir=~{ref_dir}/PRSCSX \
				--bim_prefix=~{ref_dir}/PRSCSX/plink \
				--sst_file=${line} \
				--n_gwas=~{sep="," n_gwas} \
				--pop=~{sep="," cohort_1} \
				--phi=$i \
				--a=~{sep="" param_A} \
				--b=~{sep="" param_B} \
				--out_dir=% \
				--chrom=${chrnum} \
				--out_name=~{resultname}_chr${chrnum} 
			done
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
		less tempfile_name | tr -s "\n" " " | xargs tar czvf result_PRScsx.tar.gz -C $IN_DIR
		rm tempfile_name
	}
	output { File out = "result_PRScsx.tar.gz" }
}