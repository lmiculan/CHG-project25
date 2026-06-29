# Script for managing PCR duplicate reads in BAM files using Picard tools.
JAVA8=/usr/lib/jvm/java-8-openjdk/bin/java
REF=data/annotations/human_g1k_v37.fasta
BAMS=data/bamprocessing/*.recal.bam
PICARD=~/bin/picard.jar

mkdir -p data/bamprocessing/dedup

for bam in $BAMS; do
    base=$(basename $bam .recal.bam)
    echo "Processing $base"
    $JAVA8 -jar /usr/share/java/picard.jar MarkDuplicates \
        I=$bam \
        O=data/bamprocessing/dedup/$base.dedup.bam \
        M=data/bamprocessing/dedup/$base.metrics.txt \
        REMOVE_DUPLICATES=true \
        ASSUME_SORTED=true
done