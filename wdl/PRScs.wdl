# Author: Xingyu Chen
# File: PRScs.wdl
# Version: 1.0

workflow PRScs{
	File summary_statistic_2 
	String ldref_0
	Array[Int] n_gwas_1_value
	String? phi_1_value
	Array[Float] param_A_1_value = [1]
	Array[Float] param_B_1_value = [0.5]

	call adjustformat { input: in=summary_statistic_2 }
	call PRS { input: cohort_0=ldref_0, sst_file=adjustformat.out, n_gwas=n_gwas_1_value, phi=phi_1_value, param_A=param_A_1_value, param_B=param_B_1_value } 
	call zip { input: in_PRS_result=PRS.out }
}

task adjustformat{
	File in
	command { 
		source ~/.bashrc
		Rscript $PRSHUB_PATH/utils/PRScs/PRScs_adjustformat.R -i ${in} -o output_adjustformat.ext 
	}
	output { File out = "output_adjustformat.ext" }
}

task PRS{
	String cohort_0
	File sst_file
	Array[Int] n_gwas
	String? phi
	Array[Float] param_A
	Array[Float] param_B
	command {
		source ~/.bashrc
		bash $PRSHUB_PATH/utils/PRScs/delete_multiple_A1A2_line.sh -i ${sst_file} -a 2 -b 3 -o gwasfile
		sed -i '1i\SNP\tA1\tA2\tBETA\tP\t' gwasfile
		export HDF5_USE_FILE_LOCKING=FALSE
		PYTHONPATH=$PRSHUB_PATH/utils/PRScs
        if [ -z "${phi}" ]; then
            echo `pwd`"/result" | xargs -I '%' python $PRSHUB_PATH/utils/PRScs/PRScs.py \
            --ref_dir=${cohort_0}/PRSCS \
            --bim_prefix=${cohort_0}/plink_temp/plink \
            --sst_file=gwasfile \
            --n_gwas=${sep="" n_gwas} \
            --a=${sep="" param_A} \
            --b=${sep="" param_B} \
            --out_dir=%
        else
            for i in ${sep=" " phi}; do
                echo `pwd`"/result_$i" | xargs -I '%' python $PRSHUB_PATH/utils/PRScs/PRScs.py \
                --ref_dir=${cohort_0}/PRSCS \
                --bim_prefix=${cohort_0}/plink_temp/plink \
                --sst_file=gwasfile \
                --n_gwas=${sep="" n_gwas} \
                --phi=$i \
                --a=${sep="" param_A} \
                --b=${sep="" param_B} \
                --out_dir=%
            done
        fi
	}
	output { Array[File] out = glob("*.txt") }
}

task zip{
	Array[File] in_PRS_result
	command { 
		IN_DIR=$(dirname ${in_PRS_result[1]})
		for i in ${sep=" " in_PRS_result}
		do
			basename $i >> tempfile_name
		done
		less tempfile_name | tr -s "\n" " " | xargs tar -czvf result_PRScs.tar.gz -C $IN_DIR
		rm tempfile_name
	}
	output { File out = "result_PRScs.tar.gz" }
}