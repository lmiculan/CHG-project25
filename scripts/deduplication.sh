# Script for managing PCR duplicate reads in BAM files using Picard tools.
REF=data/annotations/human_g1k_v37.fasta
BAMS=data/bamprocessing/recal/*.recal.bam
PICARD=~/bin/picard.jar

mkdir -p data/bamprocessing/dedup

for bam in $BAMS; do
    base=$(basename $bam .bam)
    echo "Processing $base"
    java -jar $PICARD MarkDuplicates \
        I=$bam \
        O=data/bamprocessing/dedup/$base.dedup.bam \
        M=data/bamprocessing/dedup/$base.metrics.txt \
        REMOVE_DUPLICATES=true \
        ASSUME_SORTED=true

    samtools index data/bamprocessing/dedup/$base.dedup.bam
done