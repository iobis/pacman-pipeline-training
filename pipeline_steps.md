# Pipeline steps

## Quality control

## Trimming

In this step we use [Trimmomatic](https://github.com/usadellab/Trimmomatic) to trim our raw reads. This includes the removal of adapters (parameter `ILLUMINACLIP`), and of bases at the start (parameter `LEADING`) and the end (parameter `TRAILING`) of the reads which are of insufficient quality. Trimmomatic will also perform "adaptive quality trimming" (parameter `MAXINFO`).

![trimmomatic](images/trimmomatic.png)  

Image from Metagenomics for Software Carpentry[^1].

## Removing primer sequences

[Cutadapt](https://github.com/marcelm/cutadapt) is used to remove the primer sequences.

## DADA2
### Filtering and trimming

DADA2 [filterAndTrim](https://rdrr.io/bioc/dada2/man/filterAndTrim.html) is used to truncate the reads at a specified length or quality threshold.

### ASV inference

## Bowtie2

## BLAST

## BLCA

## Darwin Core

[^1]: Nelly Sélem Mojica; Diego Garfias Gallegos; Claudia Zirión Martínez; Jesús Abraham Avelar Rivas; Aaron Jaime Espinosa; Abel Lovaco Flores; Tania Vanessa Arellano Fernandez (2022, Jan). Metagenomics for Software Carpentry lesson, Jan 2022. Zenodo. https://doi.org/10.5281/zenodo.4285900
