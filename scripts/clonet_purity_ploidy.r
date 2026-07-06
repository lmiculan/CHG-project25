library(data.table)
library(CLONETv2)
library(TPES)
library(ggplot2)

normal = fread("data/clonet_data/Control.csv",data.table=F)
normal$af = normal$altCount/normal$totalCount
tumor = fread("data/clonet_data/Tumor.csv",data.table=F)
tumor$af = tumor$altCount/tumor$totalCount

pileup.normal = normal[,c(1,2,4,5,14,8)]
colnames(pileup.normal) = c("chr","pos","ref","alt","af","cov")

pileup.tumor = tumor[,c(1,2,4,5,14,8)]
colnames(pileup.tumor) = c("chr","pos","ref","alt","af","cov")

seg.tb <- fread("results/scnv_varscan/SCNA.copynumber.called.segmented.seg",data.table=F)

pdf("results/clonet_pp/Segmentation_mean_histograms.pdf", width=10, height=5)
hist(seg.tb$seg.mean, breaks=100)
dev.off()

bt <- compute_beta_table(seg.tb, pileup.tumor, pileup.normal)

pdf("results/clonet_pp/Beta_table_histogram.pdf", width=10, height=5)
hist(bt$beta, breaks=100)
dev.off()

# Samples seems to have some kind of impurity, the beta distribution is not centered around 0.5, but has spikes at 0.6 and 1. This means that the tumor sample is contaminated with normal cells.

## Compute ploidy table with default parameters
pl.table <- compute_ploidy(bt)

# compute adminixture table
adm.table <- compute_dna_admixture(beta_table = bt, ploidy_table = pl.table)
# adminixture = 1-purity = number of cells that are contaminating the sample.
allele_specific_cna_table <- compute_allele_specific_scna_table(beta_table = bt,
                                                                ploidy_table = pl.table, 
                                                                admixture_table = adm.table)


check.plot <- check_ploidy_and_admixture(beta_table = bt, ploidy_table = pl.table,
                                         admixture_table = adm.table)
print(check.plot)
ggsave("results/clonet_pp/Clonet_PP.pdf", dpi=450) 
# exam question!! this plot represents different regions, each black dot is a segment. We're plotting log2R and beta of segments.
# The regions (red dots) that are scattered around can be used to calculate the purity.

# 2 0 represent a copy-neutral LOH.
# how often does copy-neutral LOH happen? you lose one copy and then you have a duplication of the remaining one.
# happens in tumor with whole-genome doubling (especially if the genome is polyploid)

# TPES
# tool to estimate purity of sample, this tool is orthogonal to the other.
# sometimes you have samples that don't have copy number alterations.
# you look at the allelic fraction of the mutations. If the mutations resides on one allele, the expected AF is 0.5.
# since we're dealing with tumors, and the mutation is present only in 80% of the cells, the AF will be different.
snv.reads = fread("results/svc_varscan/SigProfilerInput/Somatic.snp.hapmap_ann.vcf", data.table=F)
colnames(snv.reads)[1] = "CHROM"          # drop the '#'

# keep somatic sites only (SS=2 in the INFO field)
snv.reads$SS = sub(".*SS=([0-9]+).*", "\\1", snv.reads$INFO)
snv.reads = snv.reads[snv.reads$SS == "2", ]

# decode RD (ref) and AD (alt) from the TUMOR column using the FORMAT keys
tumor_vals = strsplit(snv.reads$TUMOR,  ":")
fmt_keys   = strsplit(snv.reads$FORMAT, ":")
get_field = function(vals, keys, name) as.numeric(vals[match(name, keys)])

snv.reads = data.frame(
  chr       = snv.reads$CHROM,
  start     = snv.reads$POS,
  end       = snv.reads$POS,
  ref.count = mapply(get_field, tumor_vals, fmt_keys, MoreArgs=list(name="RD")),
  alt.count = mapply(get_field, tumor_vals, fmt_keys, MoreArgs=list(name="AD")),
  sample    = "Sample.1",
  stringsAsFactors = FALSE
)

seg.tb$ID <- "Sample.1"
pl.table$sample <- "Sample.1"

# we need the segmentation file because of reasons
TPES_purity(ID = "Sample.1", SEGfile = seg.tb,
            SNVsReadCountsFile = snv.reads,
            ploidy = pl.table,
            RMB = 0.47, maxAF = 0.6, minCov = 10, minAltReads = 10, minSNVs = 1)

TPES_report(ID = "Sample.1", SEGfile = seg.tb,
            SNVsReadCountsFile = snv.reads,
            ploidy = pl.table,
            RMB = 0.47, maxAF = 0.6, minCov = 10, minAltReads = 10, minSNVs = 1)
