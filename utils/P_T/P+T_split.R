'
split P+T clumping result by P, created by Xingyu Chen

Notes:
  * split one file for one run

Usage:
  P+T_split.R [(--rangelist <rangelist>) [<rangelist>...]] -i input -o output

Options:
  -i input                    inputfile
  -o output                   outputfile
  --rangelist                 rangelist
' -> doc

library(docopt)
opts <- docopt(doc)
input_file <- opts$i
output_file <- opts$o
range_list <- opts$rangelist

range_list <- unlist(split(range_list, " "))
range_list <- as.numeric(range_list)
row_data <- read.table(input_file, header = T)
 row_data <- as.data.frame(row_data)
 for (i in range_list){
   out <- row_data[which(row_data$P < i),]
   write.table(out, file = paste0(i, ".", output_file, "_result"), sep = "\t", row.names = F, col.names = T, quote = F)
 }