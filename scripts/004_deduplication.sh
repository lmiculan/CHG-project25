set -e

# Script for managing PCR duplicate reads in BAM files using Picard tools.
REF=data/annotations/human_g1k_v37.fasta
BAMS=data/bamprocessing/recal/Tumor.*.recal.bam
PICARD=~/bin/picard.jar
OUTDIR=data/bamprocessing/dedup

mkdir -p $OUTDIR

for bam in $BAMS; do
    base=$(basename $bam .bam)
    echo "Processing $base"
    java -jar $PICARD MarkDuplicates \
        I=$bam \
        O=$OUTDIR/$base.dedup.bam \
        M=$OUTDIR/$base.dedup.metrics.txt \
        REMOVE_DUPLICATES=true \
        ASSUME_SORTED=true

    samtools index $OUTDIR/$base.dedup.bam
done