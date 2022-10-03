library(dplyr)
library(glue)

# read run table from
# https://www.ncbi.nlm.nih.gov/Traces/study/?query_key=2&WebEnv=MCID_633ac4b714d02054a52de0c0&f=barcode_sam_ss%3An%3Acoi%3Ac&o=acc_s%3Aa

runs <- read.csv("SraRunTable.txt") %>%
  filter(
    BARCODE == "COI" &
    Replicate == 1 &
    samp_collect_device %in% c("settlement plates", "filtered water") &
    Depth %in% c("7m", "surface") &
    Site %in% c("site 1", "site 3", "site 4")
  )

table(runs$Site, runs$Depth)
table(runs$Site, runs$samp_collect_device)

# download data (requires SRA toolkit)

for (run in runs$Run) {
  message(run)
  system(glue("cd raw_data && prefetch -v {run}"))
  system(glue("cd raw_data && fasterq-dump --verbose --split-files {run}"))
  system(glue("cd raw_data && gzip {run}_1.fastq"))
  system(glue("cd raw_data && gzip {run}_2.fastq"))
  system(glue("cd raw_data && rm -r {run}"))
}

# create manifest file

manifest <- bind_rows(
  runs %>% mutate("sample-id" = BioSample, "file-path" = paste0("data/rey/", Run, "_1.fastq.gz"), direction = "forward"),
  runs %>% mutate("sample-id" = BioSample, "file-path" = paste0("data/rey/", Run, "_2.fastq.gz"), direction = "reverse")
) %>%
  select("sample-id", "file-path", direction) %>%
  arrange(`sample-id`, `file-path`)

write.csv(manifest, "raw_data/manifest_rey.csv", row.names = FALSE, quote = FALSE)

# create sample data template

samples <- runs %>%
  select("sample-id" = BioSample, eventID = BioSample, materialSampleID = BioSample, eventRemarks = samp_collect_device, verbatimCoordinates = Lat_Lon, locality = geo_loc_name, verbatimDepth = Depth, eventDate = Collection_Date) %>%
  mutate(occurrenceStatus = "present")

write.csv(samples, "raw_data/sample_data_template_rey.csv", row.names = FALSE, quote = FALSE)
