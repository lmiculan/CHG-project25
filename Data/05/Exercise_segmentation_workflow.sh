## Somatic copy number

cd Data

samtools mpileup -q 1 -f ../../Annotations/human_g1k_v37.fasta Normal_chr13_chr20.sorted.bam Tumor_chr13_chr20.sorted.bam | java -jar ../../Tools/VarScan.v2.3.9.jar copynumber --output-file SCNA --mpileup 1
# gives this output:
# 5815128 positions in mpileup
# 3004087 had sufficient coverage for comparison
# 36764 raw copynumber segments with size > 10
# 36734 good copynumber segments with depth > 10
# This command is a classic bioinformatics pipeline used to detect Somatic Copy Number Alterations (SCNA) — essentially finding where
# a tumor has gained or lost chunks of its genome compared to a healthy "normal" sample.
# samtools mpileup "piles up" the sequences at every genomic position, and varscan analyses to look for copy number changes.

java -jar ../../Tools/VarScan.v2.3.9.jar copyCaller SCNA.copynumber --output-file SCNA.copynumber.called
# this copyCaller command takes as input the copy number alterations and tries to determine which changes are biologically significant.
# It then outputs a file with these important columns: log2_ratio (0, positive=gain, negative=loss) and copy_number (predicted absolute copy number)

## Run R script with DNAcopy segmentation

Rscript CBS.R
