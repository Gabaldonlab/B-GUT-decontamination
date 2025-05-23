# B-GUT-decontamination
Snakemake pipeline to decontaminate genomes to be included in a kraken2 database.



Example of the pipeline run in a folder containing 4 genomes [An example of one of these genomes is provided in the folder "Example_genomes"]

![bgutdecontam_schema](https://github.com/user-attachments/assets/adf75fe3-8712-4e2c-baa2-56bd1a64e328)


## Installation: Singularity image

1. Marenostrum5

  You will find the .sif file at ~/current/okhannous/Decontamination_fungal_database/my_singularity.sif

2. Local use

You will need to build and deploy the Singularity image.
First you have to download Singularity. Details of how to do it: [HERE](https://github.com/sylabs/singularity/releases/tag/v4.1.5)

Using the provided Dockerfile and Makefile files (present in the current github resources) run:

```bash
make singularity-image
```

This will create the "my_singularity.sif", ready to be used with our snakemake pipeline.

## How to run the pipeline using the Singularity image

Here there is an example of command to run the pipeline. 


In High-Performance Computing (HPC) environments such as marenostrum5, you may need to bind folders when using containerization tools like Singularity to ensure that your container can access the necessary files and directories that exist outside of the container's file system that is why we add the flag -B.

```bash
snakemake --use-singularity --singularity-args '-B /path_to_our_group_folder/bscXX' -s ~/current/okhannous/Decontamination_fungal_database/bgut_decontam.smk all --cores 48
```
In the .smk file there is indicated the path to the .sif image.

You can find a template job to run the pipeline in the cluster: "bgut_decontam.job"

Note that the pipeline is fast but requires high mem nodes because of the kraken2 step. You can have a debug interaction session and run it there by:

```bash
salloc -A bsc40 -q gp_debug --exclusive --constraint=highmem
snakemake --use-singularity --singularity-args '-B /path_to_our_group_folder/bscXX' -s ~/current/okhannous/Decontamination_fungal_database/bgut_decontam.smk all --cores 48
```

## Changes you might need to do in the pipeline:

IMPORTANT: 
In the pipeline you might want to change some of the parameters (This will be addressed with a config file in future versions):

From the bgut_decontam.smk file:

** Global directories (where the genomes are located and where you want to store the results), this should be changed according to your data:
```bash
genomes_dir = "~/current/okhannous/current/okhannous/Decontamination_fungal_database/Example_genomes"
out_dir = "~/current/okhannous/current/okhannous/Decontamination_fungal_database/OUT_cluster"
```
** Define the wildcards (for processing multiple genome files)
```bash
GENOME_SUFFIX = "_Genome.fasta" #Change with the extension of the genome files
PREFIX = "renamedFungiDB-58_" #In case you have any prefix (in this case the genomes where renamed for kraken2)
```
In the R scripts there are also some strings that you might change to not have errors, that depend in the genome names you have:

1. Clean_fasta.R: Change in the suffix and prefix

```bash
file_name_renamed <- gsub("renamedFungiDB-58_", "", file_name)
file_name_renamed <- gsub("_Genome.fasta", "", file_name_renamed)
```
2. Parsing_kraken2_reports.R

```bash
name <- gsub("gpfs/.*/","",i) --> This is specific for marenostrum5
```
3. Assessment_gc_distribution.R --> all ok

4. Final_decision_kraken2_and_gc_content.R --> The path corresponds to marenostrum5
```bash
df_multimodality$X <-   gsub("~/current/okhannous/Decontamination_fungal_database/OUT_cluster/gc_content/","",df_multimodality$X)
```
## Citations / Acknowledgments

### Snakemake

Mölder, F., Jablonski, K. P., Letcher, B., Hall, M. B., Tomkins-Tinch, C. H., Sochat, V., Forster, J., Lee, S., Twardziok, S. O., Kanitz, A., Wilm, A., Holtgrewe, M., Rahmann, S., Nahnsen, S., & Köster, J. (2021). Sustainable data analysis with Snakemake. F1000Research, 10, 33. https://doi.org/10.12688/f1000research.29032.2

### Kraken2

Wood, D. E., Lu, J., & Langmead, B. (2019). Improved metagenomic analysis with Kraken 2. Genome biology, 20(1), 257. https://doi.org/10.1186/s13059-019-1891-0

### Tiara

Karlicki, M., Antonowicz, S., & Karnkowska, A. (2022). Tiara: deep learning-based classification system for eukaryotic sequences. Bioinformatics (Oxford, England), 38(2), 344–350. https://doi.org/10.1093/bioinformatics/btab672

### Seqkit
Shen, W., Sipos, B., & Zhao, L. (2024). SeqKit2: A Swiss army knife for sequence and alignment processing. iMeta, 3(3), e191. https://doi.org/10.1002/imt2.191

