## Somatic copy number

cd Data

samtools mpileup -q 1 -f ../../../../../annotations/human_g1k_v37.fasta ../04_deduplication/Control.sorted.realigned.recalibrated.dedup.bam ../04_deduplication/Tumor.sorted.realigned.recalibrated.dedup.bam | java -jar ../../../../../tools/VarScan.v2.3.9.jar copynumber --output-file SCNA --mpileup 1
# This command is a classic bioinformatics pipeline used to detect Somatic Copy Number Alterations (SCNA) — essentially finding where
# a tumor has gained or lost chunks of its genome compared to a healthy "normal" sample.
# samtools mpileup "piles up" the sequences at every genomic position, and varscan analyses to look for copy number changes.
# Output:
# 219959625 positions in mpileup
# 19779690 had sufficient coverage for comparison
# 219787 raw copynumber segments with size > 10
# 219281 good copynumber segments with depth > 10

java -jar ../../../../../tools/VarScan.v2.3.9.jar copyCaller SCNA.copynumber --output-file SCNA.copynumber.called
# this copyCaller command takes as input the copy number alterations and tries to determine which changes are biologically significant.
# It then outputs a file with these important columns: log2_ratio (0, positive=gain, negative=loss) and copy_number (predicted absolute copy number)
# Output:
# 438562 raw regions parsed
# 155106 met min depth
# 155106 met min size
# 5070 regions (499379 bp) were called amplification (log2 > 0.25)
# 35951 regions (3563975 bp) were called neutral
# 114085 regions (11316495 bp) were called deletion (log2 <-0.25)
# 224 regions (20681 bp) were called homozygous deletion (normal cov >= 20 and tumor cov <= 5)

## Run R script with DNAcopy segmentation

Rscript CBS.R
