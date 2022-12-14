library(Biostrings)
library(msa)

sequences <- DNAStringSet(c(
  raw = "GGAACAGGTTGAACTGTATATCCTCCACTTTCAGGCTCTGCTGGTTCACCAGGTATGGGAATGGACTTAGCAATATTTTCACTTCATCTGGCTGGTGCATCTTCAATATTAGGAGCTGCCAATTTTATCACAACGATTTTTAATATGCGTGCCCCTGGGATGACACTTCATAAAATGCCATTGTTTGTTTGGGCCATGTTAGTTACAGTTTTCTTATTGTTATTAGCCATACCCGTATTAGCAGGCGCAATAACAATGCTTCTCCAAGGTACAAACTTTGGAACAAGCTTCTTTATTCCAA",
  trimmed = "GGAACAGGTTGAACTGTATATCCTCCACTTTCAGGCTCTGCTGGTTCACCAGGTATGGGAATGGACTTAGCAATATTTTCACTTCATCTGGCTGGTGCATCTTCAATATTAGGAGCTGCCAATTTTATCACAACGATTTTTAATATGCGTGCCCCTGGGATGACACTTCATAAAATGCCATTGTTTGTTTGGGCCATGTTAGTTACAGTTTTCTTATTGTTATTAGCCATACCCGTATTAGCAGGCGCA",
  cutadapt = "ACTTTCAGGCTCTGCTGGTTCACCAGGTATGGGAATGGACTTAGCAATATTTTCACTTCATCTGGCTGGTGCATCTTCAATATTAGGAGCTGCCAATTTTATCACAACGATTTTTAATATGCGTGCCCCTGGGATGACACTTCATAAAATGCCATTGTTTGTTTGGGCCATGTTAGTTACAGTTTTCTTATTGTTATTAGCCATACCCGTATTAGCAGGCGCA"
))

aligned <- as(msa(sequences), "DNAStringSet")
aligned[c("raw", "trimmed", "cutadapt"),]
