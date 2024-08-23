# Load necessary packages
library(phylotools)

# Snakemake provides paths for the original genome, tiara output, and cleaned output, as arguments (the two first are for input, and the third one corresponds to output)
args <- commandArgs(TRUE)


path_original_genome <- args[1]
tiara_result <- args[2]
out_path <- args[3]


# Load the genome and Tiara results
genome_data <- read.fasta(path_original_genome)
tiara_data <- read.delim(tiara_result)

# Extract the file name (without prefix and suffix)
file_name <- basename(path_original_genome)
file_name_renamed <- gsub("renamedFungiDB-58_", "", file_name)
file_name_renamed <- gsub("_Genome.fasta", "", file_name_renamed)

file_tiara_renamed <- gsub(".txt", "", basename(tiara_result))

if (file_name_renamed == file_tiara_renamed) {
  
  # Filter the Tiara output for eukaryotic or organelle contigs
  tiara_subset <- subset(tiara_data, tiara_data$class_fst_stage == "eukarya" | tiara_data$class_fst_stage == "organelle")
  
  # Get contig IDs to keep
  contig_ids <- tiara_subset$sequence_id
  
  # Filter the original genome for the selected contigs
  genome_subset <- subset(genome_data, genome_data$seq.name %in% contig_ids)
  
  # Save the filtered genome to a new FASTA file
  dat2fasta(genome_subset, out_path)
}

