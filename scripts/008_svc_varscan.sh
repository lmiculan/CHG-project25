#!/bin/bash
set -e

NORMAL=data/bamprocessing/realign/Control.sorted.realigned.bam 
TUMOR=data/bamprocessing/realign/Tumor.sorted.realigned.bam

REF=data/annotations/human_g1k_v37.fasta
REF1=data/annotations/hapmap_3.3.b37.vcf
VARSCAN=~/bin/VarScan.v2.3.9.jar
OUTDIR=results/svc_varscan
SNPSIFT=/home/miculanl/bin/snpEff/SnpSift.jar

mkdir -p $OUTDIR

# # Usa samtools con -B e dichiara prima NORMAL e poi TUMOR
# samtools mpileup -B -q 1 \
#   -f "$REF" \
#   "$NORMAL" \
#   "$TUMOR" \
#   -l data/ogdata/Captured_Regions.bed \
#   | java -jar "$VARSCAN" somatic \
#   --output-snp $OUTDIR/Somatic.snp.vcf \
#   --output-indel $OUTDIR/Somatic.indel.vcf \
#   --mpileup 1 \
#   --output-vcf 1 \
#   --min-coverage 5 \
#   --min-var-freq 0.05 \
#   --somatic-p-value 0.1 \
#   --min-coverage-normal 5 \
#   --min-coverage-tumor 5

# # Step 2: processSomatic
# java -jar $VARSCAN processSomatic $OUTDIR/Somatic.snp.vcf \
#   --min-tumor-freq 0.10 \
#   --max-normal-freq 0.05 \
#   --p-value 0.05

# java -jar $VARSCAN processSomatic $OUTDIR/Somatic.indel.vcf \
#   --min-tumor-freq 0.10 \
#   --max-normal-freq 0.05 \
#   --p-value 0.05

# # Step 3: vcftools depth filtering
# vcftools --max-meanDP 200 --min-meanDP 5 --remove-indels \
#   --vcf $OUTDIR/Somatic.snp.Somatic.vcf \
#   --out $OUTDIR/Somatic.snp.filtered --recode --recode-INFO-all

# vcftools --max-meanDP 200 --min-meanDP 5 --keep-only-indels \
#   --vcf $OUTDIR/Somatic.indel.Somatic.vcf \
#   --out $OUTDIR/Somatic.indel.filtered --recode --recode-INFO-all

# Annotation of somatic variants with snpEff

## Annotation
#java -Xmx4g -jar $SNPSIFT Annotate $REF1 $OUTDIR/Somatic.snp.filtered.recode.vcf  > $OUTDIR/Somatic.snp.hapmap_ann.vcf

## Passing to SigProfilerAssignement
# Move target vcfs to input directory
mkdir -p $OUTDIR/SigProfilerInput
#mv $OUTDIR/Somatic.snp.hapmap_ann.vcf $OUTDIR/SigProfilerInput/Somatic.snp.hapmap_ann.vcf
python3 scripts/SigProfiler.py