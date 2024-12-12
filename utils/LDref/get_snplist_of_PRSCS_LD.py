import h5py
import numpy as np
import argparse

def extract_snp_info(file_path, output_filename):
    chr_list = []
    flag = 0

    for i in range(1, 23):
        hdf5_file_chr_file = f"{file_path}/ldblk_1kg_chr{i}.hdf5"
        chr_list.append(hdf5_file_chr_file)

    finalresult = None
    for j in chr_list:
        hdf5_file = h5py.File(j, "r")
        blkname = list(hdf5_file.keys())
        print(j)
        for blk in blkname:
            flag += 1
            snplist = hdf5_file[blk + '/snplist']
            if flag == 1:
                finalresult = snplist[:]
            else:
                finalresult = np.concatenate((finalresult, snplist[:]))

    np.savetxt(output_filename, finalresult, fmt="%s")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract SNP information from PRSCS LD reference files.")
    parser.add_argument("file_path", type=str, help="The path to the PRSCS LD reference folder.")
    parser.add_argument("output_filename", type=str, help="The filename for the output file.")
    
    args = parser.parse_args()
    
    extract_snp_info(args.file_path, args.output_filename)
