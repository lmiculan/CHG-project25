#!/bin/bash

# Set gatk function
BAMS=data/bamprocessing/*.sorted.bam
REF=data/annotations/human_g1k_v37.fasta
JAVA8=/usr/lib/jvm/java-8-openjdk/bin/java

mkdir -p data/realign


# Indel realignment
for bam in $BAMS; do
    echo $bam
    # $JAVA8 -jar ~/bin/GenomeAnalysisTK.jar -version
    # base=$(basename "$bam" .bam)
    # intervals="data/realign/${base}.intervals"
    # realigned="data/realign/${base}.realigned.bam"

    # $JAVA8 -Xmx4g -jar ~/bin/GenomeAnalysisTK.jar \
    #     -T RealignerTargetCreator \
    #     -R "$REF" \
    #     -I "$bam" \
    #     -o "$intervals"

    # $JAVA8 -Xmx4g -jar ~/bin/GenomeAnalysisTK.jar \
    #     -T IndelRealigner \
    #     -R "$REF" \
    #     -I "$bam" \
    #     -targetIntervals "$intervals" \
    #     -o "$realigned"
done
