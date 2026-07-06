library(EthSEQ)

#Create file of list bam files
writeLines("data/bamprocessing/dedup/Control.sorted.realigned.recal.dedup.bam", "BAMs_List.txt")

out.dir <- "results/ethseq_analysis"

ethseq.Analysis(
  bam.list         = "BAMs_List.txt",
  out.dir          = out.dir,
  model.available  = "Gencode.Exome",     
  model.assembly   = "hg19",
  model.pop        = "All",
  model.folder     = out.dir,
  run.genotype     = TRUE,
  aseq.path        = out.dir,
  bam.chr.encoding = FALSE,
  mbq = 20, mrq = 20, mdc = 10,
  space = "3D",
  cores = 4,
  verbose = TRUE
)

