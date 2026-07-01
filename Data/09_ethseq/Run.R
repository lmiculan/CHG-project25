# does ethnicity annotation
#library(EthSEQ)

#ethseq.Analysis(
#  target.vcf = "./1000GP_Genotypes100s.vcf",
#  out.dir = "./100s",
#  model.gds = "./ReferenceModel.gds",
#  cores=1,
#  verbose=TRUE,
#  composite.model.call.rate = 0.99,
#  space="3D")

# the next code does it with only 16 [] to be faster
#ethseq.Analysis(
#  target.vcf = "./1000GP_Genotypes16s.vcf",
#  out.dir = "./16s",
#  model.gds = "./ReferenceModel.gds",
#  cores=1,
#  verbose=TRUE,
#  composite.model.call.rate = 0.99,
#  space="3D")

# the results: pop is population, type is inside (no significant evidence of recent multi-continental admixture) or closest (the sample falls outside the strict boundaries of all reference populations. This usually indicates that the individual has an admixed background (ancestral roots from more than one continent). EthSeq assigns them to the population they are mathematically closest to.). contribution is the quantification of the ancestries

library(EthSEQ)

out.dir <- "./EthSEQ_Results"
dir.create(out.dir, showWarnings = FALSE)

# a text file with one BAM path per line — here just the NORMAL/control BAM
writeLines("../04_deduplication/Control.sorted.realigned.recalibrated.dedup.bam", "BAMs_List.txt")

ethseq.Analysis(
  bam.list         = "BAMs_List.txt",
  out.dir          = out.dir,
  model.available  = "Gencode.Exome",     # or SS2 / SS4 / NimblegenV3 / HALO to match your capture kit
  model.assembly   = "hg19",       # MUST match your BAM's reference build
  model.pop        = "All",        # includes EUR/AFR/EAS/SAS/AMR
  model.folder     = out.dir,      # where the prebuilt model gets downloaded/cached
  run.genotype     = TRUE,         # run ASEQ pileup from the BAM
  aseq.path        = out.dir,      # folder for the ASEQ binary
  bam.chr.encoding = FALSE,         # TRUE if your BAM chromosomes are "chr1", FALSE if "1"
  mbq = 20, mrq = 20, mdc = 10,    # min base qual / read qual / depth for a genotype call
  space = "2D",
  cores = 4,
  verbose = TRUE
)