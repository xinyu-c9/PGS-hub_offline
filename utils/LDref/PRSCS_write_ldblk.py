"""
Input OUTDIR and input file with 3 column, chr, snplist, blockname, -h for help


Usage:
python write_ldblk.py --OUTDIR=outpath --INPUT=input_file -h help


 - OUTDIR: outpath.

 - INPUT: input_file.


"""


import os
import sys
import getopt
import scipy as sp
import h5py
import csv


def parse_param():
    long_opts_list = ['INPUT=', 'OUTDIR=']

    param_dict = {'INPUT': None, 'OUTDIR': None}

    print('\n')

    if len(sys.argv) > 1:
        try:
            opts, args = getopt.getopt(sys.argv[1:], "h", long_opts_list)          
        except:
            print('Option not recognized.')
            sys.exit(2)

        for opt, arg in opts:
            if opt == "-h" or opt == "--help":
                print(__doc__)
                sys.exit(0)
            elif opt == "--INPUT": param_dict['INPUT'] = arg
            elif opt == "--OUTDIR": param_dict['OUTDIR'] = arg
    else:
        print(__doc__)
        sys.exit(0)


    for key in param_dict:
        print('--%s=%s' % (key, param_dict[key]))

    print('\n')
    return param_dict

param_dict = parse_param()

INPUT_FILE = param_dict['INPUT']
OUTPATH = param_dict['OUTDIR']  
WORKDIR, full_file_name = os.path.split(INPUT_FILE)

with open(INPUT_FILE,'r') as tsv:
    blk_chr = [line.strip().split('\t') for line in tsv]

n_blk=0

for i in range(len(blk_chr)):
    n_blk = n_blk+1

n_chr = int(blk_chr[-1][0])

for chrom in range(1,n_chr+1):
    print('... parse chomosome %d ...' % chrom)
    chr_name = OUTPATH + '/ldblk_1kg_chr' + str(chrom) + '.hdf5'
    hdf_chr = h5py.File(chr_name, 'w')
    blk_cnt = 0
    for blk in range(n_blk):
        if int(blk_chr[blk][0]) == chrom:
            if int(blk_chr[blk][3]) > 0:
                blk_file = WORKDIR + '/ldblk_cal/ldmat' + str(blk+1) + '.ld'
                with open(blk_file) as ff:
                    ld = [[float(val) for val in (line.strip()).split()] for line in ff]
                print('blk %d size %s' % (blk+1, sp.shape(ld)))
                snp_file = WORKDIR + '/ldblk' + str(blk+1)
                with open(snp_file) as ff:
                    snplist = [line.strip() for line in ff]
            else:
                ld = []; snplist = []
            blk_cnt += 1
            hdf_blk = hdf_chr.create_group('blk_%d' % blk_cnt)
            hdf_blk.create_dataset('ldblk', data=sp.array(ld), compression="gzip", compression_opts=9)
            snplist = [tmp.encode('utf8') for tmp in snplist]
            hdf_blk.create_dataset('snplist', data=snplist, compression="gzip", compression_opts=9)