import sys

def get_common_snps(files):
    snp_sets = []
    file_contents = {}
    
    # For each file, extract the SNP values and store in a set.
    for file in files:
        with open(file, 'r') as f:
            content = f.readlines()
            file_contents[file] = content
            snps = {line.split()[0] for line in content[1:]}  # excluding header
            snp_sets.append(snps)
    
    # Get common SNP values
    common_snps = set.intersection(*snp_sets)
    
    # Write common SNP values back to the files
    for file, content in file_contents.items():
        with open(file, 'w') as f:
            f.write(content[0])  # header
            for line in content[1:]:
                if line.split()[0] in common_snps:
                    f.write(line)

if __name__ == "__main__":
    file_string = sys.argv[1]
    files = file_string.split(',')
    if not files:
        print("Please provide files as arguments, separated by commas.")
        sys.exit(1)
    get_common_snps(files)
    print(f"Processed {len(files)} files. Only common SNPs have been retained.")
