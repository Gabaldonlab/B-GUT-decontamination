#Script to assess all the results of the complex filter (kraken2 bacteria, gc content modality and majoritary bacteria, and to make the decision if removing the genome or not)
library(phyloseq)
library(biomformat)

args <- commandArgs(TRUE)

#1. Open the csv with the % of bacteria, unclassified, fungi, human etc
out_per <- read.csv(args[1])

#2. Open the result of the gc content modality
df_multimodality <- read.csv(args[2])

#Make sure that the names of the genomes in kraken2 assignment and the ones in the modality of gc are the same (E.g substitute path, etc)
df_multimodality$X <-   gsub("/gpfs/projects/bsc40/current/okhannous/Decontamination_fungal_database/OUT_cluster/gc_content/","",df_multimodality$X)
df_multimodality$X <-   gsub(".txt","",df_multimodality$X)
rownames(df_multimodality) <- df_multimodality$X

#3. Create the phyloseq object with only bacteria to assess the majority bacterial species, in case the other metrics are TRUE. 
biomfilename = read_biom(args[3])
data_phyloseq  <- import_biom(biomfilename, parseFunction=parse_taxonomy_default)
#Restrict to bacteria and transform to relative abundances:
data_bacteria <- subset_taxa(data_phyloseq, Rank1  == "k__Bacteria")
data_bacteria_rel <- transform_sample_counts(data_bacteria, function(OTU) (OTU/sum(OTU)*100))
table_data_bacteria_rel <- as.data.frame(data_bacteria_rel@otu_table)
colnames(table_data_bacteria_rel) <- gsub(".report","",colnames(table_data_bacteria_rel))

out_per[is.na(out_per)] <- 0


#Assess both general % of bacteria and the gc content in conjunction and add in a list the genomes that are potentially contaminated and that should be removed:
list_to_remove <- list()
for (e in 1:nrow(out_per)) {
  bacterial_perc <- out_per[e,"Bacteria"]
  genome_id <- out_per[e, "X"]
  gc_modality <- df_multimodality[genome_id,"pvalue"]
  #If the % of bacteria is more than 5% and the gc content modality is not unimodal
  if (bacterial_perc > 5 && gc_modality != "Unimodal") {
   max_bac <- max(table_data_bacteria_rel[,genome_id])
   #If the majority bacteria is greater than 5%
    if (max_bac > 5) {
      #add the genome to be removed
      list_to_remove <- c(list_to_remove, genome_id)
    }
      }
}

saveRDS(list_to_remove, args[4])


