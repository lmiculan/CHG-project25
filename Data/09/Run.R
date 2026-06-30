# does ethnicity annotation
library(EthSEQ)

ethseq.Analysis(
  target.vcf = "./1000GP_Genotypes100s.vcf",
  out.dir = "./100s",
  model.gds = "./ReferenceModel.gds",
  cores=1,
  verbose=TRUE,
  composite.model.call.rate = 0.99,
  space="3D")

# the next code does it with only 16 [] to be faster
ethseq.Analysis(
  target.vcf = "./1000GP_Genotypes16s.vcf",
  out.dir = "./16s",
  model.gds = "./ReferenceModel.gds",
  cores=1,
  verbose=TRUE,
  composite.model.call.rate = 0.99,
  space="3D")

# the results: pop is population, type is inside (no significant evidence of recent multi-continental admixture) or closest (the sample falls outside the strict boundaries of all reference populations. This usually indicates that the individual has an admixed background (ancestral roots from more than one continent). EthSeq assigns them to the population they are mathematically closest to.). contribution is the quantification of the ancestries