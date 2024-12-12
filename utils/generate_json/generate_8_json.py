import json
import argparse
import os

def generate_json_configs(input_file, output_dir, cojo_sblup_value, sdpr_n_value, ldref_value):
    # 检查 PRSHUB_PATH 环境变量
    prshub_path = os.getenv("PRSHUB_PATH")
    if not prshub_path:
        raise EnvironmentError("The environment variable $PRSHUB_PATH is not set.")

    # 检查输出目录是否存在
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # 配置字典
    configs = {
        "P_T": {
            'Range_1_value': [1, 0.5, 0.05, 0.0005, 0.000005, 0.00000005],
            'R2_1_value': [0.2, 0.4, 0.6, 0.8],
        },
        "LDpred2": {
            'LDpred2.resultname_1_value': ["result"],
            'LDpred2.pvalue_1_value': ["0.0001", "0.00018", "0.00032", "0.00056", "0.001"],
            'LDpred2.h2_1_value': ["0.7", "1", "1.4"],
            'LDpred2.use_ref_ld_1_value': "1",
        },
        "SBLUP": {
            "SBLUP.resultname_1_value": "result",
            "SBLUP.cojo_wind_1_value": ["200"],
        },
        "SDPR": {
            "SDPR.resultname_1_value": "result",
        },
        "Lassosum2": {
            "Lassosum2.resultname_1_value": ["result"],
            "Lassosum2.delta_1_value": ["1", "0.1", "0.01", "0.001"],
            "Lassosum2.nlambda_1_value": ["30"],
            "Lassosum2.use_ref_ld_1_value": "1",
        },
        "SBayesR": {
            "SBayesR.pi_1_value": [0.95, 0.03, 0.01, 0.01],
            "SBayesR.gamma_1_value": [0, 0.01, 0.1, 1],
            "SBayesR.chain_length_1_value": [10000],
            "SBayesR.burn_in_1_value": [2000],
            "SBayesR.out_freq_1_value": [10],
            "SBayesR.resultname_1_value": "SBayesR",
        },
        "PRScs": {
            "PRScs.param_A_1_value": [1],
            "PRScs.param_B_1_value": [0.5],
        },
        "megaPRS": {
            "megaPRS.window_kb_1_value": "1000",
            "megaPRS.model_1_value": "mega",
            "megaPRS.h2_mode_1_value": "LDAK",
            "megaPRS.output_all_model_1_value": "true",
        },
    }

    # 为每个算法生成 JSON 配置
    for algorithm, config in configs.items():
        config_path = os.path.join(output_dir, f"{algorithm}_configuration.json")

        # 特殊处理 P_T 方法，所有参数前缀改为 PandT.
        if algorithm == "P_T":
            updated_config = {f"PandT.{key}": value for key, value in config.items()}
            updated_config["PandT.summary_statistic_2"] = input_file
            updated_config["PandT.ldref_0"] = ldref_value
            config = updated_config
        else:
            config[f"{algorithm}.summary_statistic_2"] = input_file
            config[f"{algorithm}.ldref_0"] = ldref_value

        # 额外处理特殊参数
        if algorithm == "SBLUP":
            config["SBLUP.cojo_sblup_1_value"] = [cojo_sblup_value]
        elif algorithm == "SDPR":
            config["SDPR.n_1_value"] = [sdpr_n_value]
        elif algorithm == "PRScs":
            config["PRScs.n_gwas_1_value"] = [sdpr_n_value]

        # 写入 JSON 文件
        with open(config_path, 'w') as f:
            json.dump(config, f, indent=4)
        print(f"Generated {config_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate JSON configs for multiple algorithms.")
    parser.add_argument("-i", "--input", required=True, help="Path to the summary statistic file")
    parser.add_argument("-o", "--output", required=True, help="Directory to save the generated JSON files")
    parser.add_argument("--cojo_sblup", required=True, type=str, help="Value for SBLUP.cojo_sblup_1_value")
    parser.add_argument("--samplesize", required=True, type=int, help="Value for SDPR.n_1_value and PRScs")
    parser.add_argument("--ldref", required=True, help="Value for ldref_0 for all algorithms")
    args = parser.parse_args()

    input_file = args.input.strip()
    output_dir = args.output.strip()

    # 检查输入文件是否存在
    if not os.path.isfile(input_file):
        raise FileNotFoundError(f"The input file {input_file} does not exist.")
    
    generate_json_configs(input_file, output_dir, args.cojo_sblup, args.samplesize, args.ldref)