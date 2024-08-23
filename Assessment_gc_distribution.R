##For all the genomes see if the gc content is following a multi-model or uni-model distribution: 
library(diptest)

args <- commandArgs(TRUE)

#The directory where the gc content windows are calculated, indicated by the first argument in the snakemake rule
dir_gc <- args[1]
list_files <- list.files(dir_gc, pattern = ".txt", full.names = TRUE)

#Excel file where to store the results of genomes with multimodal distribution
df <- data.frame(row.names = list_files)
df$pvalue <- "buit"
for (e in list_files) {
  filef <-   read.delim(e, header=FALSE)
  gc_content <- filef[,2]
  dip_test <- dip.test(gc_content)
  pvalue <- dip_test$p.value
  rm(filef)
  if (pvalue < 0.05) {
    df[e,"pvalue"] <- pvalue #A p-value smaller than 0.05 indicates significant multimodality
  }

}

df$pvalue <- gsub("buit","Unimodal",df$pvalue)
write.csv(df, args[2])


