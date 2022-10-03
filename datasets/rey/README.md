# Example dataset: Rey at al.

- https://onlinelibrary.wiley.com/doi/epdf/10.1002/ece3.6071
- https://www.ncbi.nlm.nih.gov/bioproject/PRJNA515494/

## Samples

- SRA Run Selector: https://www.ncbi.nlm.nih.gov/Traces/study/?query_key=2&WebEnv=MCID_633ac4b714d02054a52de0c0&f=barcode_sam_ss%3An%3Acoi%3Ac&o=acc_s%3Aa#

## Scripts

- <prepare_data.R>: downloads raw data from SRA, prepare CSV files for the pipeline
- <create_subset.R>: creates a subset of raw reads based on the full dataset results, to be used for faster demonstration run of the pipeline
