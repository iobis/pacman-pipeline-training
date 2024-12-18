# PacMAN bioinformatics pipeline tutorial

:warning: For up-to-date documentation, refer to the [pipeline README](https://github.com/iobis/pacman-pipeline).

Contents:

- [Pipeline architecture](#pipeline-architecture)
- [Pipeline steps](#pipeline-steps)
  - [Quality control](#quality-control)
  - [Trimming](#trimming)
  - [Removing primer sequences](#removing-primer-sequences)
  - [DADA2](#dada2)
  - [Taxonomic annotation](#taxonomic-annotation)
  - [Report](#report)
- [Running the pipeline](#running-the-pipeline)
  - [Installation instructions for Windows](#installation-instructions-for-windows)
  - [Configure and run the pipeline](#configure-and-run-the-pipeline)
- [Analysis of the pipeline results](#analysis-of-the-pipeline-results)

---

The PacMAN bioinformatics pipeline has been developed as an open source project at https://github.com/iobis/PacMAN-pipeline. The pipeline takes raw CO1 reads as input and converts them to Darwin Core aligned species occurrence tables ready for ingestion into OBIS.

In this tutorial we will use the PacMAN pipeline to analyze sequence data from Rey et al. 2020 ([Considerations for metabarcoding-based port biological baseline surveys aimed at marine nonindigenous species monitoring and risk assessments](https://doi.org/10.1002/ece3.6071)). In this study, zooplankton, water, sediment, and biofouling samples have been collected from four sites in the port of Bilbao (Spain) for metabarcoding. Additional water samples have been collected in Vigo and A Coruña. The protocols used to collect and analyze the samples are similar to those used in the PacMAN project.

## Pipeline architecture

The PacMAN bioinformatics pipeline consists of a sequence of data processing steps, which can be either scripts or commands for executing existing software tools.

The pipeline steps are orchestrated using [Snakemake](https://snakemake.github.io/), which is a Python based workflow management system. A snakemake workflow if defined by a set of *rules*, where each rules defines how the step is executed, and what the input and output files are. Snakemake uses these input and output file specifications to determine in which order the steps needs to be executed. In data engineering this is often referred to as a [directed acyclic graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph) (DAG). The rules are defined in a text file called the Snakefile.

To make workflows portable and reproducible, Snakemake can execute each step in an isolated [conda](https://docs.conda.io/en/latest/) environment. Conda is a package manager which was originally developed for Python, but it is now used for distributing packages for other languages as well, including R. Using conda environments ensures that the steps use the exact same versions of software dependencies, whereever they are run.

Here's an example of one of the steps in the pipeline Snakefile:

```python
rule fast_qc:
    """
    Runs QC on raw reads
    """
    input:
        r1 = "results/{PROJECT}/samples/{samples}/rawdata/forward_reads/fw.fastq.gz",
        r2 = "results/{PROJECT}/samples/{samples}/rawdata/reverse_reads/rv.fastq.gz"
    output:
        o1 = "results/{PROJECT}/samples/{samples}/qc/fw_fastqc.html",
        o2 = "results/{PROJECT}/samples/{samples}/qc/rv_fastqc.html",
        s1 = "results/{PROJECT}/samples/{samples}/qc/fw_fastqc.zip",
        s2 = "results/{PROJECT}/samples/{samples}/qc/rv_fastqc.zip"
    conda:
        "envs/qc.yaml"
    shell:
        "fastqc {input.r1} {input.r2} -o results/{wildcards.PROJECT}/samples/{wildcards.samples}/qc/"
```

So this rule has two input files, four output files, a reference to a Conda environment which is defined in a yaml file, and a shell command. Notice that the file names and shell command use curly braces (`{}`) to access variables defined elsewhere in the Snakefile. Some of these variables come from a config file which is specified at the top of the Snakefile.

Before diving into the pipeline code, let's take a quick look at the main steps of the pipeline.

## Pipeline steps

A schematic overview of the PacMAN pipeline and the files it generates is available [here](https://github.com/iobis/PacMAN-pipeline/raw/master/documentation/diagram.png).

![](https://github.com/iobis/PacMAN-pipeline/raw/master/documentation/diagram.png)

### Quality control

[FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) is used to perform an initial quality control step of the raw sequence data. It allows us to spot any obvious quality issues in the source data at a glance. FastQC generates a quality report for each sample which includes a graph of the [Phred quality score](https://en.wikipedia.org/wiki/Phred_quality_score) as a function of base pair position. Phred quality scores can be interpreted as follows:

|Phred Quality Score|Probability of incorrect base call|Base call accuracy|
|--- |--- |--- |
|10|1 in 10|90%|
|20|1 in 100|99%|
|30|1 in 1000|99.9%|
|40|1 in 10,000|99.99%|
|50|1 in 100,000|99.999%|
|60|1 in 1,000,000|99.9999%|

The quality graph below shows how the signal quality degrades as strands are being sequenced:

![](images/fastqc.png)

Next we use [MultiQC](https://multiqc.info/) to aggregate the quality information generated by FastQC. The MultiQC report includes a graph showing the mean quality score for each sample.

![](images/multiqc.png)

### Trimming

In this step we use [Trimmomatic](https://github.com/usadellab/Trimmomatic) to trim our raw reads. This includes the removal of adapters which have been added during library preparation (parameter `ILLUMINACLIP`), and of bases at the start (parameter `LEADING`) and the end (parameter `TRAILING`) of the reads which are of insufficient quality. The appropriate adapter sequences need to be provided in a FASTA file. Trimmomatic will also perform "adaptive quality trimming" (parameter `MAXINFO`).

![trimmomatic](images/trimmomatic.png)  

Image from Metagenomics for Software Carpentry[^1].

### Removing primer sequences

[Cutadapt](https://github.com/marcelm/cutadapt) is used to remove the primer sequences. Forward and reverse primer sequences need to be configured in the config file.

Let's take a look at one of the reads from the example dataset as it is processed with Trimmomatic and Cutadapt. Notice how the first step has trimmed the low quality nucleotides at the end of the sequence, while the primer sequence `GGWACWGGWTGAACWGTWTAYCCYCC` has been remove from the start of the read in the second step:

![msa](images/msa.png)  

### DADA2

In this step, we will use the [DADA2](https://benjjneb.github.io/dada2/) software package to infer exact amplicon sequence variants from our paired end reads. DADA2 models sequencing errors introduced during Illumina sequencing to be able to differentiate between errors and actual biological variation[^2]. This approach offers a number of advantages over the classic approach of deriving Operational Taxonomic Units (OTUs), such as a finer taxonomic resolution.

#### Filtering and trimming

Although we have already cleaned up our reads a bit, we also use DADA2 [filterAndTrim](https://rdrr.io/bioc/dada2/man/filterAndTrim.html) to truncate the reads at a specified length or quality threshold, and filter out reads which do not meet the required length after trimming.

DADA2 will generate sample based and aggregate quality profiles. Let's take a look at the aggregate quality profile of the paired reads before and after trimming (note the shorter sequence length and decrease in the total number of reads):

![](images/dada2_quality.png)  

#### ASV inference

In the next step, ASVs are inferred from the cleaned up raw reads. This involves training the error model, dereplication, sample inference, and merging the forward and reverse reads to obtain the full sequences. This step also removes chimeric sequences (artifact sequences formed from two or more biological sequences, for example during PCR).

### Taxonomic annotation

In this step we assign taxonomy by aligning our sequences with sequences in the reference database. This will be done using [Bowtie2](https://bowtie-bio.sourceforge.net/bowtie2/index.shtml), which uses Burrows-Wheeler indexing to create a fast and memory efficient aligner.

#### Bowtie2

In the PacMAN pipeline, a Bowtie2 database can either be provided, or provisioned by a dedicated build step. In this case we build a database based on the [MIDORI2 reference database](http://www.reference-midori.info/)[^3]. MIDORI2 is built from GenBank and contains curated sequences of thirteen protein-coding and two ribosomal RNA mitochondrial genes. MIDORI2 covers all eukaryotes, including fungi, green algae and land plants, other multicellular algal groups, and diverse protist lineages. The database is updated approximately every two months with version numbers corresponding to each new GenBank release.

![](images/midori.jpeg)  

Figure from Leray et al. 2022[^3].

By default, the pipeline is configured so that Bowtie2 uses the `--very-sensitive` preset (slow but more accurate) and finds up to 100 distinct alignments. The alignments are exported as Sequence Alignment Map (SAM) files.

#### BLCA

In this step, a Bayesian Least Common Ancestor (BLCA) algorithm is used to infer taxonomy from the best distinct alignments provided by Bowtie2.

An additional filter step removes any assignments that have a likelihood level below the configured cutoff, to ensure reliable assigments.

#### BLAST and LCA

In this optional step, BLASTn is used against a local copy of the full NCBI nt (nucleotide) database to attempt to further annotate unclassified sequences.

[BASTA](https://github.com/timkahlke/BASTA) is used to assign taxonomies based on the Last Common Ancestor (LCA) of the best hits.

#### LSIDs

During this step, taxon names are matched with the [World Register of Marine Species](https://www.marinespecies.org/) (WoRMS).

### Darwin Core

In this step, Darwin Core aligned data tables are generated from the pipeline results. This includes a [Occurrence](https://rs.gbif.org/core/dwc_occurrence_2022-02-02.xml) table (which also has some sampling event related metadata), and a [DNADerivedData](https://rs.gbif.org/extension/gbif/1.0/dna_derived_data_2022-02-23.xml) table which contains many terms from the GSC's [MIxS standard](https://github.com/GenomicsStandardsConsortium/mixs). These tables can be bundled into a Darwin Core Archive for submission to OBIS.

Results are also exported as a phyloseq object `phyloseq_object.rds` which can easily be read into R for analysis.

### Report

In the final step, a HTML report summarizing all steps is generated.

## Running the pipeline

For running the pipeline we will need the following ingredients:

- Windows Subsystem for Linux
- conda
- Snakemake
- the pipeline code
- a reference database
- some raw reads

If you are participating in the on-site training, WSL should be configured for you. You can skip to the conda installation step after checking the WSL installation with `wsl -l -v`.

### Installation instructions for Windows

To be able to run the pipeline on Windows systems, we'll need to install the Windows Subsystem for Linux (WSL 2).

#### Enable Windows Subsystem for Linux (WSL 2)

Open `Apps and features` from the Windows start menu. Go to `Programs and Features` and `Turn Windows features on or off`. Ensure that the following features have been enabled:

- Windows Subsystem for Linux
- Virtual Machine Platform

Set the default WSL version to 2 by opening `Command Prompt` and typing:

```
wsl --set-default-version 2
```

#### Install Ubuntu

Now install Ubuntu in WSL and verify that Ubuntu is running with WSL 2:

```
wsl --install -d Ubuntu
wsl -l -v
```

You may get a message to install the Linux kernel update package, follow the instructions.

If the WSL version is still listed as 1, convert to WSL 2 like this:

```
wsl --set-version Ubuntu-22.04 2
```

#### Install conda

Now open the Ubuntu terminal from the start menu and run the commands below to download and install Miniconda. If Ubuntu is not available in your start menu, just type `wsl` in `Command Prompt`. You will be asked first to create an user account on Ubuntu.

```
sudo apt-get update
sudo apt-get install wget
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Linux-x86_64.sh
chmod +x Miniconda3-py39_4.12.0-Linux-x86_64.sh
./Miniconda3-py39_4.12.0-Linux-x86_64.sh
```

:fire: At the end of the installation procedure, enter `yes` when asked to run `conda init`.

After installing Miniconda, close the terminal and start a new one.

We will also install [Mamba](https://mamba.readthedocs.io/en/latest/), which is a faster drop-in replacement for conda:

```
conda init
conda install -n base -c conda-forge mamba
```

Enter `y` if confirmation is asked.

#### Install Snakemake

Next, install Snakemake using Mamba:

```
mamba create -c conda-forge -c bioconda -n snakemake snakemake
```

#### Install and start Visual Studio Code

Download Visual Studio Code from <https://code.visualstudio.com/Download>, install, and start. In Visual Studio Code, open the Desktop folder (`File` > `Open Folder`). If prompted, select `Yes, I trust the authors`.

Then open the terminal panel (`Terminal` > `New Terminal`). Use the `+` button in the terminal panel to open a new `Ubuntu (WSL)`

#### Download the pipeline

Still in the WSL terminal, use git to clone the pipeline repository on GitHub to your machine. Git is a version control system, and downloading the pipeline using git will allow you to easily update to the pipeline to the latest version (`git pull`), revert any changes you have made (`git reset --hard`), or even contribute to the codebase.

```
git clone https://github.com/iobis/PacMAN-pipeline.git
```

Now open the pipeline folder with `File` > `Open Folder`.

#### Download the reference database

Download and extract the following files from the MIDORI website to `data/databases/midori` (create if necessary):

- http://www.reference-midori.info/forceDownload.php?fName=download/Databases/GenBank246/QIIME_sp/uniq/MIDORI_UNIQ_SP_NUC_GB246_CO1_QIIME.fasta.gz
- http://www.reference-midori.info/forceDownload.php?fName=download/Databases/GenBank246/QIIME_sp/uniq/MIDORI_UNIQ_SP_NUC_GB246_CO1_QIIME.taxon.gz

In case the fasta file is not available from the source above, download it [here](https://datasets.obis.org/shared/midori.fasta.zip).

:fire: Optionally download the prebuilt Bowtie2 database. This is the preferred option for the on-site training course because building the Bowtie2 database quite takes a bit of time. Download and extract the following file to `resources/bowtie2_dbs`:

- https://datasets.obis.org/shared/MIDORI_UNIQ_GB246_CO1.zip

### Configure and run the pipeline

#### Directory structure

The pipeline project has the following directory structure:

- `config`: this contains config files, sample data templates, and manifests.
- `data`: this contains source files, including raw reads and reference databases.
  - `data/databases`: reference databases such as MIDORI and NCBI NT.
- `resources`: this contains adapter files and Bowtie2 reference databases.
- `results`: this is where the pipeline results go.
- `workflow`: this is the main pipeline code.
  - `workflow/envs`: conda environments.
  - `workflow/scripts`: scripts used in the pipeline.
  - `workflow/Snakefile`: the Snakemake file which has the pipeline definition.

#### Download the raw reads

First we need to download our raw reads. Data files for two samples are included in this repository, download these data files to `data/rey` (create if necessary):

- https://github.com/iobis/pacman-pipeline-training/blob/master/datasets/rey/raw_data/SRR8759981_1.fastq.gz?raw=true
- https://github.com/iobis/pacman-pipeline-training/blob/master/datasets/rey/raw_data/SRR8759981_2.fastq.gz?raw=true
- https://github.com/iobis/pacman-pipeline-training/blob/master/datasets/rey/raw_data/SRR8760137_1.fastq.gz?raw=true
- https://github.com/iobis/pacman-pipeline-training/blob/master/datasets/rey/raw_data/SRR8760137_2.fastq.gz?raw=true

Alternatively, you can download the files directly from NCBI using [datasets/rey/scripts/prepare_data.R](datasets/rey/scripts/prepare_data.R). This script also prepares manifest and sample data template files (see pipeline configuration below).

#### Configure the pipeline
##### Config file

A config file `config/config_rey_noblast_2samples.yaml` is included with the pipeline and has the necessary configuration to analyze the two samples from the example dataset. Nothing needs to be changed for now, but some options will need adjustment in case you want to analyze other datasets. A few notable options are:

- `PROJECT`: this will be used in the results file path.
- `RUN`: this will be used in the results file path.
- `meta.sampling.sample_data_file`: this is the sample data template which we will discuss below.
- `meta.sequencing`: this has the target gene and primer configuration.
- `SAMPLE_SET`: this is the sample manifest.
- `DATABASE`: this is the reference database configuration.

##### Manifest

The manifest file `config/manifest_rey_2samples.csv` lists the forward and reverse reads files for each sample. This should correspond to the data files you have downloaded in one of the previous steps.

##### Sample data template

The sample data template file `config/sample_data_template_rey_2samples.csv` contains sample metadata which will be used in the Darwin Core files generated by the pipeline. A limited set of Darwin Core fields has been populated, but more can be added.

#### Run the pipeline

Dry run the pipeline using the following commands:

```
conda activate snakemake
snakemake --use-conda --configfile ./config/config_rey_noblast_2samples.yaml --rerun-incomplete --printshellcmds --cores 1 --dryrun
```

This has the following flags:

- `--use-conda`: this means that each step will be run within an isolated Conda environment.
- `--configfile` points to the configuration file.
- `--rerun-incomplete`: this reruns potentially incomplete steps after something has gone wrong.
- `--printshellcmds`: prints the shell commands that will be executed.
- `--cores`: use at most this many cores.
- `--dryrun`: only list the pipeline steps without running anything.

To actually run the pipeline, execute again without `--dryrun`.

## Analysis of the pipeline results

Continue to [Metabarcoding data analysis](https://iobis.github.io/pacman-pipeline-training/rey_analysis.html).

[^1]: Nelly Sélem Mojica; Diego Garfias Gallegos; Claudia Zirión Martínez; Jesús Abraham Avelar Rivas; Aaron Jaime Espinosa; Abel Lovaco Flores; Tania Vanessa Arellano Fernandez (2022, Jan). Metagenomics for Software Carpentry lesson, Jan 2022. Zenodo. <https://doi.org/10.5281/zenodo.4285900>

[^2]: Callahan, B., McMurdie, P., Rosen, M. et al. DADA2: High-resolution sample inference from Illumina amplicon data. Nat Methods 13, 581–583 (2016). <https://doi.org/10.1038/nmeth.3869>

[^3]: Leray, M., Knowlton, N., Machida R. J. 2022. MIDORI2: A collection of quality controlled, preformatted, and regularly updated reference databases for taxonomic assignment of eukaryotic mitochondrial sequences. Environmental DNA Volume 4, Issue 4, Pages 894-907. <https://doi.org/10.1002/edn3.303>
