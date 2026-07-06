#!/bin/bash

# Set gatk function
BAMS=data/bamprocessing/dedup2/*.bam
REF=data/annotations/human_g1k_v37.fasta
KNOWN_SITES=data/annotations/hapmap_3.3.b37.vcf
#KNOWN_SITES=data/annotations/Mills_and_1000G_gold_standard.indels.b37.vcf
JAVA8=/usr/lib/jvm/java-8-openjdk/bin/java
OUTDIR=results/recal2
DATADIR=data/bamprocessing/recal2

mkdir -p $DATADIR
mkdir -p $OUTDIR

# # Recalibration

for bam in $BAMS; do
    base=$(basename "$bam" .bam)
    recal_table="$DATADIR/${base}.recal.table"
    recal_table_after="$DATADIR/${base}.recal_after.table"
    recal_bam="$DATADIR/${base}.recal.bam"

#     $JAVA8 -Xmx4g -jar ~/bin/GenomeAnalysisTK.jar \
#         -T BaseRecalibrator \
#         -R "$REF" \
#         -I "$bam" \
#         --knownSites "$KNOWN_SITES" \
#         -o "$recal_table"

#     $JAVA8 -Xmx4g -jar ~/bin/GenomeAnalysisTK.jar \
#         -T PrintReads \
#         -R "$REF" \
#         -I "$bam" \
#         -BQSR "$recal_table" \
#         -o "$recal_bam"

#     $JAVA8 -Xmx4g -jar ~/bin/GenomeAnalysisTK.jar \
#         -T BaseRecalibrator \
#         -R "$REF" \
#         -I "$recal_bam" \
#         --knownSites "$KNOWN_SITES" \
#         -o "$recal_table_after"

    $JAVA8 -Xmx4g -jar ~/bin/GenomeAnalysisTK.jar \
        -l DEBUG \
        -T AnalyzeCovariates \
        -R "$REF" \
        -before "$recal_table" \
        -after "$recal_table_after" \
        -plots "results/recal/${base}.report.pdf" \
        -csv "results/recal/${base}.report.csv"
done
