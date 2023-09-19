# Author: Jingwei Li
# Date: 14/09/2023

library(vcd)

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Get the input filename and output filename
inputFilename <- args[1]
outputFilename <- args[2]

input_data <- readLines(inputFilename)
A <- unlist(strsplit(input_data[which(input_data == 'Category_A') + 1], ','))
B <- unlist(strsplit(input_data[which(input_data == 'Category_B') + 1], ','))

data <- data.frame(
  Category_A = A,
  Category_B = B
)

contingency_table <- table(data$Category_A, data$Category_B)
cramer_v <- assocstats(contingency_table)$cramer

cramer_v
write(cramer_v, file = outputFilename)