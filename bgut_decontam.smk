#Author: Olfat Khannous Lleiffe
#Contact email: olfat.khannous@bsc.es
#Barcelona, Comparative Genomics Lab (Gabaldon Lab)
#Date:2024-08-21

import os
from datetime import datetime
import sys

date1 = str(datetime.now())
tmp = date1.replace(" ", ".")
tmp2 = tmp.replace(":", "")
date = tmp2.replace("-", "")

# Global directories (where the genomes are located and where you want to store the results), this should be changed according to your data:
genomes_dir = "/gpfs/projects/bsc40/current/okhannous/Decontamination_fungal_database/Example_genomes"
out_dir = "/gpfs/projects/bsc40/current/okhannous/Decontamination_fungal_database/OUT_cluster"

# Creation of subfolders within the output folder
tiara_out = os.path.join(out_dir, "tiara")
tiara_logs = os.path.join(tiara_out, "logs")
cleaning_out = os.path.join(out_dir, "Cleaned_after_tiara")
kraken_out = os.path.join(out_dir, "kraken_after_tiara")
gc_out = os.path.join(out_dir, "gc_content")
to_remove = os.path.join(out_dir, "Genomes_to_remove")

# Ensure that the directories exist
for directory in [tiara_out, tiara_logs, cleaning_out, kraken_out, gc_out, to_remove]:
    if not os.path.exists(directory):
        os.makedirs(directory)

# Define the wildcards (for processing multiple genome files)
GENOME_SUFFIX = "_Genome.fasta" #Change with the extension of the genome files
PREFIX = "renamedFungiDB-58_" #In case you have any prefix (in this case the genomes where renamed for kraken2)

# List all input genomes
genomes = glob_wildcards(f"{genomes_dir}/{PREFIX}{{sample}}{GENOME_SUFFIX}").sample

rule all:
    input:
        expand(f"{tiara_out}/{{sample}}.txt",sample=genomes),
        expand(f"{tiara_logs}/log_{{sample}}.txt", sample=genomes),
        expand(f"{cleaning_out}/{PREFIX}{{sample}}{GENOME_SUFFIX}", sample=genomes),
        expand(f"{kraken_out}/{{sample}}.report.txt", sample=genomes),
        expand(f"{gc_out}/{{sample}}.txt", sample=genomes),
        df_summary_kraken2 = f"{kraken_out}/df_kraken2_summary.csv",
        df_gc_diptest = f"{gc_out}/df_gc_diptest.csv",
        biom_file = f"{kraken_out}/total_kraken2.biom",
        genome_to_remove = f"{to_remove}/genomes_to_remove.rds"

#1. Rule to run tiara to classify contigs and supercontigs using deep learning 
rule run_tiara:
    input:
        fasta = f"{genomes_dir}/{PREFIX}{{sample}}{GENOME_SUFFIX}"
    output:
        tiara_output = f"{tiara_out}/{{sample}}.txt",
        log_report = f"{tiara_out}/log_{{sample}}.txt"
    singularity:
        "/gpfs/projects/bsc40/current/okhannous/Decontamination_fungal_database/my_singularity.sif"
    shell:
        """
        tiara -i {input.fasta} -o {output.tiara_output}
        """
#2. Rule to move the log files created by tiara to a new folder in order to not have problems for the rest of the rules
rule move_tiara_logs:
    input:
        log_report = f"{tiara_out}/log_{{sample}}.txt"
    output:
        log_output = f"{tiara_logs}/log_{{sample}}.txt"
    singularity:
        "/gpfs/projects/bsc40/current/okhannous/Decontamination_fungal_database/my_singularity.sif"
    shell:
        """
        mv {input.log_report} {output.log_output}
        """

#3. Rule to run an R script that creates fasta files containing only the contigs that are classified to eukarya or organelle
rule clean_fasta:
    input:
        fasta = rules.run_tiara.input.fasta,
        tiara_output = f"{tiara_out}/{{sample}}.txt"
    output:
        cleaned_fasta = f"{cleaning_out}/{PREFIX}{{sample}}{GENOME_SUFFIX}"
    singularity:
        "/gpfs/projects/bsc40/current/okhannous/Decontamination_fungal_database/my_singularity.sif"
    shell:
        r"""
        Rscript Clean_fasta.R {input.fasta} {input.tiara_output} {output.cleaned_fasta}
        """
#4. Rule to run kraken2 taxonomy assignment tool using the standard database
rule kraken2_assign:
    input:
        cleaned_fasta = rules.clean_fasta.output.cleaned_fasta
    output:
        kraken2_report = f"{kraken_out}/{{sample}}.report.txt"
    singularity:
        "/gpfs/projects/bsc40/current/okhannous/Decontamination_fungal_database/my_singularity.sif"
    shell:
        r"""
        kraken2 --db /gpfs/projects/bsc40/project/pipelines/WGS/KRAKEN2_DB/KRAKEN2_DB_COMPLETE {input.cleaned_fasta} --report {output.kraken2_report}
        """

#5. Rule to calculate the GC content
rule gc_content:
    input:
        cleaned_fasta = rules.clean_fasta.output.cleaned_fasta
    output:
        gc_report = f"{gc_out}/{{sample}}.txt"
    singularity:
        "/gpfs/projects/bsc40/current/okhannous/Decontamination_fungal_database/my_singularity.sif"
    shell:
        """
        seqkit fx2tab --name --gc {input.cleaned_fasta} > {output.gc_report}
        """
#6. Rule to extract the % of bacteria (among others, such as the fungal, human, unclassified) found in each of the cleaned genome fasta files
rule parse_kraken2_reports:
    input:
        kraken2_in = expand(f"{kraken_out}/{{sample}}.report.txt", sample=genomes), #To make it depend on the rest
        kraken2_reports_path = kraken_out 
    output:
        df_summary_kraken2 = f"{kraken_out}/df_kraken2_summary.csv"
    singularity:
        "/gpfs/projects/bsc40/current/okhannous/Decontamination_fungal_database/my_singularity.sif"
    shell:
        """
        Rscript Parsing_kraken2_reports.R {input.kraken2_reports_path} {output.df_summary_kraken2}
        """
#7. Rule to assess the gc content distribution, and run the dip test to indicate if this are significant multimodal distributions
rule gc_diptest: 
    input:
        gc_content_in = expand(f"{gc_out}/{{sample}}.txt", sample=genomes), #To make it depend on the rest
        gc_content_dir = gc_out
    output:
        df_gc_diptest = f"{gc_out}/df_gc_diptest.csv"
    singularity:
        "/gpfs/projects/bsc40/current/okhannous/Decontamination_fungal_database/my_singularity.sif"
    shell:
        """
        Rscript Assessment_gc_distribution.R {input.gc_content_dir} {output.df_gc_diptest}
        """
#8. Rule to convert the Kraken2 report to biom format. 
rule convert_biom:
    input:
        kraken2_in = expand(f"{kraken_out}/{{sample}}.report.txt", sample=genomes), #To make it depend on the rest
        reports_path = kraken_out
    output:
        biom_file = f"{kraken_out}/total_kraken2.biom"
    singularity:
        "/gpfs/projects/bsc40/current/okhannous/Decontamination_fungal_database/my_singularity.sif"
    shell:
        "kraken-biom {input.reports_path}/*.report.txt -o {output.biom_file} --fmt json" 

#9. Rule to apply a final filter based on kraken2 whole bacterial %, the gc content distribution and the % of the majoritary bacteria, to create an rds list of potentially contaminated genomes to be removed
#The genomes that will be listed will be the ones with more then 5% of bacteria and multimodal gc content distribution in which the majoritary bacteria is of more than 5% of the total amount of bacteria

rule create_rds_to_discard:
    input:
        df_bacteria = rules.parse_kraken2_reports.output.df_summary_kraken2,
        df_gc_diptest = rules.gc_diptest.output.df_gc_diptest,
        biom_file_all = rules.convert_biom.output.biom_file
    output:
        genome_to_remove = f"{to_remove}/genomes_to_remove.rds"
    singularity:
        "/gpfs/projects/bsc40/current/okhannous/Decontamination_fungal_database/my_singularity.sif"
    shell:
        "Rscript Final_decision_kraken2_and_gc_content.R {input.df_bacteria} {input.df_gc_diptest} {input.biom_file_all} {output.genome_to_remove}"