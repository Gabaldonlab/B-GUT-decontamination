# B-GUT-decontamination
Snakemake pipeline to potentially decontaminate genomes to be included in a kraken2 database

## Singularity image

1. Marenostrum5

  You will find the .sif file at gpfs/projects/bsc40/current/okhannous/Decontamination_fungal_database/my_singularity.sif

2. Local use

You will need to build and deploy the Singularity image.
First you have to download Singularity. Details of how to do it: [HERE](https://github.com/sylabs/singularity/releases/tag/v4.1.5)

Using the provided Dockerfile and Makefile files (present in the current github resources) run:

```bash
make singularity-image
```

This will create the "my_singularity.sif", ready to be used with our snakemake pipeline.

## How to run the pipeline using the Singularity image
