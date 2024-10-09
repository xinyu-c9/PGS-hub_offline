#getopts
if [ $# -lt 1 ]; then
    echo "no arguments"
    echo "Usage: delete_multiple_A1A2_line.sh -i input file -a A1column -b A2column -o output name"
    echo "    -i    input file."
    echo "    -a    A1column number, start from 1."
    echo "    -b    A2column number, start from 1."
    echo "    -o    output file name."
    exit 1
fi
#parameter
while getopts i:a:b:o: option
do
    case "$option" in
        i)
            inputfile=$OPTARG
            ;;
        a)
            A1col=$OPTARG
            ;;
        b)
            A2col=$OPTARG
            ;;
        o)
            outputname=$OPTARG
            ;;
        ?)
            echo "Usage: delete_multiple_A1A2_line.sh -i input file -a A1column -b A2column -o output name"
            echo "    -i    input file."
            echo "    -a    A1column number, start from 1."
            echo "    -b    A2column number, start from 1."
            echo "    -o    output file name."
            exit 1
            ;;
    esac
done

less ${inputfile} |  awk '{if(length($"'$A1col'")==1) {print $0}}' | awk '{if(length($"'$A2col'")==1) {print $0}}' > ${outputname}