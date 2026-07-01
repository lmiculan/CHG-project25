# the annotations i wrote are actually for example1.R in the CLONET folder

library(data.table)
library(CLONETv2)
library(TPES)

#setwd("../../10_PurityPloidyEstimation/")

normal = fread("Control.csv",data.table=F)
normal$af = normal$altCount/normal$totalCount
tumor = fread("Tumor.csv",data.table=F)
tumor$af = tumor$altCount/tumor$totalCount

pileup.normal = normal[,c(1,2,4,5,14,8)]
colnames(pileup.normal) = c("chr","pos","ref","alt","af","cov")

pileup.tumor = tumor[,c(1,2,4,5,14,8)]
colnames(pileup.tumor) = c("chr","pos","ref","alt","af","cov")
# this files have indications about SNPs (and others? not sure)

# segmentation data
seg.tb <- fread("../05_segmentation/SCNA.copynumber.called.seg",data.table=F)
# it's a segmentation file, coming from somatic copy number calling analysis. This represents different segments in our data.
# sample, chromosome, coordinates, index of segment, mean of segment (gives indication if there's a copy number change, positive
# means more copies and negative means less, and the magnitude indicates how big is the phenomenon)
hist(seg.tb$seg.mean, breaks=100)
# ones around 0 have no alterations, the other peak is what we care about: there's a loss.
# we can say it's relevant because it's the tallest one (=there are a lot of segments that have that value).
# it's at -0.5, but you can't lose half a copy. We can conclude it's the result of a purity shift.

# computing beta table, so we are annotating the segments with informations about samples (coverage(least interesting), beta and number of SNPs).
# i'm taking the pileup data and putting it into its context. 
# Beta is a metric of allelic imbalance (from 0 (all copies of one allele) to 1 (same n. copies for each allele)
bt <- compute_beta_table(seg.tb, pileup.tumor, pileup.normal)

# let's visualize it
hist(bt$beta, breaks=100)
# we can see that the alleles are balanced. There's some values around 0.6, meaning: the sample is not 100% pure.

## Compute ploidy table with default parameters
pl.table <- compute_ploidy(bt)
# output = ploidy of the sample. In this case, perfectly dyploid sample.

# compute adminixture table
adm.table <- compute_dna_admixture(beta_table = bt, ploidy_table = pl.table)
# adminixture = 1-purity = number of cells that are contaminating the sample.
# this function also computes minimum and maximum

allele_specific_cna_table <- compute_allele_specific_scna_table(beta_table = bt,
                                                                ploidy_table = pl.table, 
                                                                admixture_table = adm.table)


check.plot <- check_ploidy_and_admixture(beta_table = bt, ploidy_table = pl.table,
                                         admixture_table = adm.table)
print(check.plot)
# exam question!! this plot represents different regions, each black dot is a segment. We're plotting log2R and beta of segments.
# we had slides about this with demichelis. The regions (red dots) that are scattered around can be used to calculate the purity.
# get good at interpreting all these points since they care about this.

# here you can use a command like compute adminixture clonality or something

# 2 0 represent a copy-neutral LOH.
# how often does copy-neutral LOH happen? you lose one copy and then you have a duplication of the remaining one.
# happens in tumor with whole-genome doubling (especially if the genome is polyploid)

# TPES
# tool to estimate purity of sample, this tool is orthogonal to the other.
# sometimes you have samples that don't have copy number alterations.
# you look at the allelic fraction of the mutations. If the mutations resides on one allele, the expected AF is 0.5.
# since we're dealing with tumors, and the mutation is present only in 80% of the cells, the AF will be different.
snv.reads = fread("../08_somatic_variant/somatic.pm.vcf",data.table=F)
snv.reads = snv.reads[which(snv.reads$somatic_status=="Somatic"),]
snv.reads = snv.reads[,c("chrom","position","position","tumor_reads1","tumor_reads2")]
colnames(snv.reads) = c("chr","start","end","ref.count","alt.count")
snv.reads$sample = "Sample.1"

# we need the segmentation file because of reasons
TPES_purity(ID = "Sample.1", SEGfile = seg.tb,
            SNVsReadCountsFile = snv.reads,
            ploidy = pl.table,
            RMB = 0.47, maxAF = 0.6, minCov = 10, minAltReads = 10, minSNVs = 1)

TPES_report(ID = "Sample.1", SEGfile = seg.tb,
            SNVsReadCountsFile = snv.reads,
            ploidy = pl.table,
            RMB = 0.47, maxAF = 0.6, minCov = 10, minAltReads = 10, minSNVs = 1)
