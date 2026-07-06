# #!/bin/bash
set -e

#NORMAL=data/bamprocessing/realign/Control.sorted.realigned.bam 
#TUMOR=data/bamprocessing/realign/Tumor.sorted.realigned.bam

NORMAL=data/bamprocessing/recal2/Control.sorted.realigned.dedup.recal.bam
TUMOR=data/bamprocessing/recal2/Tumor.sorted.realigned.dedup.recal.bam

REF=data/annotations/human_g1k_v37.fasta
REF1=data/annotations/hapmap_3.3.b37.vcf
REF2=data/annotations/clinvar_Pathogenic.vcf
VARSCAN=~/bin/VarScan.v2.3.9.jar
OUTDIR=results/svc2/svc_varscan
OUTDIR2=results/svc2/svc_strelka2
RESDIR=results/svc2
SNPSIFT=/home/miculanl/bin/snpEff/SnpSift.jar
STRELKADIR=/home/miculanl/bin/strelka-2.9.10
JAVA8=/usr/lib/jvm/java-8-openjdk/bin/java

mkdir -p $OUTDIR
mkdir -p $OUTDIR2
mkdir -p $RESDIR

# # Usa samtools con -B e dichiara prima NORMAL e poi TUMOR
# samtools mpileup -B -q 1 \
#   -f "$REF" \
#   "$NORMAL" \
#   "$TUMOR" \
#   -l data/ogdata/Captured_Regions.bed.gz \
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

# # Annotation with hapmap and clinvar
java -Xmx4g -jar $SNPSIFT Annotate $REF1 $OUTDIR/Somatic.snp.filtered.recode.vcf  > $OUTDIR/Somatic.snp.hapmap_ann.vcf
java -Xmx4g -jar $SNPSIFT Annotate $REF1 $OUTDIR/Somatic.indel.filtered.recode.vcf  > $OUTDIR/Somatic.indel.hapmap_ann.vcf

java -Xmx4g -jar $SNPSIFT Annotate $REF2 $OUTDIR/Somatic.snp.hapmap_ann.vcf  > $OUTDIR/Somatic.snp.hapmap_clinvar_ann.vcf
java -Xmx4g -jar $SNPSIFT Annotate $REF2 $OUTDIR/Somatic.indel.filtered.recode.vcf > $OUTDIR/Somatic.indels.hapmap_clinvar_ann.vcf


# # Additional SVC with Strelka2
# python2 $STRELKADIR/bin/configureStrelkaSomaticWorkflow.py \
#   --normalBam $NORMAL \
#   --tumorBam $TUMOR \
#   --referenceFasta $REF \
#   --runDir $OUTDIR2 \
#   --callRegions data/ogdata/Captured_Regions.bed.gz \
#   --exome

#   $OUTDIR2/runWorkflow.py -m local -j 4

# #Step 3: vcftools depth filtering
# vcftools --max-meanDP 200 --min-meanDP 5 \
#   --gzvcf $OUTDIR2/results/variants/somatic.snvs.vcf.gz \
#   --out $OUTDIR2/results/variants/somatic.snvs.filtered.vcf --recode --recode-INFO-all

# vcftools --max-meanDP 200 --min-meanDP 5 \
#   --gzvcf $OUTDIR2/results/variants/somatic.indels.vcf.gz \
#   --out $OUTDIR2/results/variants/somatic.indels.filtered.vcf --recode --recode-INFO-all

# Step4: filter PASS filtering
# vcftools --vcf $OUTDIR2/results/variants/somatic.snvs.filtered.vcf.recode.vcf \
#   --out $OUTDIR2/results/variants/somatic.snvs.filtered.vcf.recode.pass.vcf \
#   --recode --recode-INFO-all --remove-filtered-all

# vcftools --vcf $OUTDIR2/results/variants/somatic.indels.filtered.vcf.recode.vcf \
#   --out $OUTDIR2/results/variants/somatic.indels.filtered.vcf.recode.pass.vcf \
#   --recode --recode-INFO-all --remove-filtered-all

# #Annotation of somatic variants with snpEff

# java -Xmx4g -jar $SNPSIFT Annotate $REF1 $OUTDIR2/results/variants/somatic.snvs.filtered.vcf  > $OUTDIR2/Somatic.snp.hapmap_ann.vcf
# java -Xmx4g -jar $SNPSIFT Annotate $REF1 $OUTDIR2/results/variants/somatic.indels.filtered.vcf  > $OUTDIR2/Somatic.indels.hapmap_ann.vcf
echo "Annotation with hapmap and clinvar"
#java -Xmx4g -jar $SNPSIFT Annotate $REF2 $OUTDIR2/results/variants/somatic.snvs.filtered.vcf.recode.pass.vcf.recode.vcf  > $OUTDIR2/Somatic.snp.hapmap_clinvar_ann.vcf
#java -Xmx4g -jar $SNPSIFT Annotate $REF2 $OUTDIR2/results/variants/somatic.indels.filtered.vcf.recode.pass.vcf.recode.vcf  > $OUTDIR2/Somatic.indels.hapmap_clinvar_ann.vcf

# # Intersection between VarScan and Strelka2 results
echo "Intersection between VarScan and Strelka2 results"
bedtools intersect -a results/svc2/svc_strelka2/Somatic.snp.hapmap_clinvar_ann.vcf  -b results/svc2/svc_varscan/Somatic.snp.hapmap_clinvar_ann.vcf -header > $RESDIR/somatic.snvs.intersect.vcf
bedtools intersect -a results/svc2/svc_varscan/Somatic.indels.hapmap_clinvar_ann.vcf -b results/svc2/svc_strelka2/Somatic.indels.hapmap_clinvar_ann.vcf -header > $RESDIR/somatic.indels.intersect.vcf


