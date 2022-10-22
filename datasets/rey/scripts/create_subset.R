library(microseq)
library(dplyr)
library(stringr)
library(purrr)
library(glue)

samples <- c("SAMN10847335", "SAMN10847336")
runs <- c("SRR8760009", "SRR8760010")

# get read / ASV mapping

mapping <- map(samples, function(sample) {
  read.csv(glue("pipeline_results/{sample}_mapping.txt"), sep = "\t", na.strings = "") %>%
    mutate(sample = sample)
}) %>%
  bind_rows() %>%
  arrange(asv)

# get occurrences

occurrence <- read.csv("pipeline_results/Occurence_table.csv", sep = "\t", na.strings = "") %>%
  mutate(
    sample = sub(".+_", "", occurrenceID),
    asv = sub("_.*", "", occurrenceID)
  )

# per dataset and species, only keep the ASV with the highest read count

occ_subset <- occurrence %>%
  filter(taxonRank == "species") %>%
  arrange(sample, scientificName, desc(organismQuantity)) %>%
  select(sample, scientificName, asv, organismQuantity) %>% 
  group_by(sample, scientificName) %>% 
  slice_head(n = 1)

# ASVs to keep

asvs <- unique(occ_subset$asv)

# create subsets

extract_id <- function(headers) {
  headers %>%
    str_extract(pattern = ".+?\\s") %>%
    trimws()
}

for (i in 1:length(samples)) {
  reads <- mapping %>%
    filter(asv %in% asvs & sample == samples[i]) %>%
    group_by(asv) %>%
    slice_head(n = 100)
  
  forward <- readFastq(glue("raw_data/{runs[i]}_1.fastq.gz")) %>%
    mutate(id = extract_id(Header)) %>%
    filter(id %in% reads$read)
  
  reverse <- readFastq(glue("raw_data/{runs[i]}_2.fastq.gz")) %>%
    mutate(id = extract_id(Header)) %>%
    filter(id %in% reads$read)
  
  writeFastq(forward, glue("subset/{runs[i]}_1.fastq.gz"))
  writeFastq(reverse, glue("subset/{runs[i]}_2.fastq.gz"))
}

