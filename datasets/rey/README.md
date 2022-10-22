# Example dataset: Rey at al. 2020. Considerations for metabarcoding-based port biological baseline surveys aimed at marine nonindigenous species monitoring and risk assessments

- [Paper](https://onlinelibrary.wiley.com/doi/epdf/10.1002/ece3.6071)
- [BioProject](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA515494/)

## Samples

- [SRA Run Selector](https://www.ncbi.nlm.nih.gov/Traces/study/?query_key=2&WebEnv=MCID_633ac4b714d02054a52de0c0&f=barcode_sam_ss%3An%3Acoi%3Ac&o=acc_s%3Aa#)

## Scripts

- [scripts/prepare_data.R](prepare_data.R): downloads raw data from SRA, prepare CSV files for the pipeline
- [scripts/create_subset.R](create_subset.R): creates a subset of raw reads based on the full dataset results, to be used for faster demonstration run of the pipeline
