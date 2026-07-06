#!/bin/bash
set -e

NORMAL_old=data/bamprocessing/realign/Control.sorted.realigned.bam 
TUMOR_old=data/bamprocessing/realign/Tumor.sorted.realigned.bam

NORMAL=data/bamprocessing/recal2/Control.sorted.realigned.dedup.recal.bam
TUMOR=data/bamprocessing/recal2/Tumor.sorted.realigned.dedup.recal.bam

REF=data/annotations/human_g1k_v37.fasta
REF1=data/annotations/hapmap_3.3.b37.vcf
#REF2=data/annotations/clinvar_Pathogenic.vcf
REF2=data/annotations/clinvar_20260627.vcf.gz
VARSCAN=~/bin/VarScan.v2.3.9.jar

OUTDIR=results/svc2/svc_varscan
OUTDIR2=results/svc2/svc_strelka2

RESDIR=results/svc2

VSANNOT=$OUTDIR/annotation
STRELKANNOT=$OUTDIR2/annotation

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

#####

# Additional SVC with Strelka2
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
#   --out $OUTDIR2/results/variants/somatic.snvs.filtered --recode --recode-INFO-all

# vcftools --max-meanDP 200 --min-meanDP 5 \
#   --gzvcf $OUTDIR2/results/variants/somatic.indels.vcf.gz \
#   --out $OUTDIR2/results/variants/somatic.indels.filtered --recode --recode-INFO-all

# #Step4: filter PASS filtering
# vcftools --vcf $OUTDIR2/results/variants/somatic.snvs.filtered.vcf.recode.vcf \
#   --out $OUTDIR2/results/variants/somatic.snvs.filtered.pass \
#   --recode --recode-INFO-all --remove-filtered-all

# vcftools --vcf $OUTDIR2/results/variants/somatic.indels.filtered.vcf.recode.vcf \
#   --out $OUTDIR2/results/variants/somatic.indels.filtered.pass \
#   --recode --recode-INFO-all --remove-filtered-all

#####
# Annotation and filtering of callers results
# VarScan2
# mkdir -p $VSANNOT
# echo "Annotation of VarScan2 results"
# echo "Annotating SNVs"
# java -Xmx4g -jar $SNPSIFT Annotate $REF1 $OUTDIR/Somatic.snp.filtered.recode.vcf  > $VSANNOT/Somatic.snp.filtered.recode.ann_hapmap.vcf
# java -Xmx4g -jar $SNPSIFT Annotate $REF2 $VSANNOT/Somatic.snp.filtered.recode.ann_hapmap.vcf  > $VSANNOT/Somatic.snp.filtered.recode.ann_hapmap_clinvar.vcf

# echo "Annotating INDELs"
# java -Xmx4g -jar $SNPSIFT Annotate $REF1 $OUTDIR/Somatic.indel.filtered.recode.vcf  > $VSANNOT/Somatic.indel.filtered.recode.ann_hapmap.vcf
# java -Xmx4g -jar $SNPSIFT Annotate $REF2 $VSANNOT/Somatic.indel.filtered.recode.ann_hapmap.vcf  > $VSANNOT/Somatic.indel.filtered.recode.ann_hapmap_clinvar.vcf

# echo "Filtering VarScan2 results for variants having hapmap and clinvar annotations"
# echo "Filtering SNVs"
# java -jar $SNPSIFT filter \
#     "((exists CLNSIG))" \
#     $VSANNOT/Somatic.snp.filtered.recode.ann_hapmap_clinvar.vcf \
#     > $VSANNOT/Somatic.snp.filtered.recode.annfilter.vcf
# echo "Filtering INDELs"
# java -jar $SNPSIFT filter \
#     "((exists CLNSIG))" \
#     $VSANNOT/Somatic.indel.filtered.recode.ann_hapmap_clinvar.vcf \
#     > $VSANNOT/Somatic.indel.filtered.recode.annfilter.vcf

## strelka2
# mkdir -p $STRELKANNOT
# echo "Annotation of strelka2 results"
# echo "Annotating SNVs"
# java -Xmx4g -jar $SNPSIFT Annotate $REF1 $OUTDIR2/results/variants/somatic.snvs.filtered.pass.recode.vcf  > $STRELKANNOT/strelka.somatic.snvs.filtered.recode.ann_hapmap.vcf
# java -Xmx4g -jar $SNPSIFT Annotate $REF2 $STRELKANNOT/strelka.somatic.snvs.filtered.recode.ann_hapmap.vcf  > $STRELKANNOT/strelka.somatic.snvs.filtered.recode.ann_hapmap_clinvar.vcf

# echo "Annotating INDELs"
# java -Xmx4g -jar $SNPSIFT Annotate $REF1 $OUTDIR2/results/variants/somatic.indels.filtered.pass.recode.vcf  > $STRELKANNOT/strelka.somatic.indels.filtered.recode.ann_hapmap.vcf
# java -Xmx4g -jar $SNPSIFT Annotate $REF2 $STRELKANNOT/strelka.somatic.indels.filtered.recode.ann_hapmap.vcf  > $STRELKANNOT/strelka.somatic.indels.filtered.recode.ann_hapmap_clinvar.vcf

# echo "Filtering strelka2 results for variants having hapmap and clinvar annotations"
# echo "Filtering SNVs"
# java -jar $SNPSIFT filter \
#     "((exists CLNSIG))" \
#     $STRELKANNOT/strelka.somatic.snvs.filtered.recode.ann_hapmap_clinvar.vcf \
#     > $STRELKANNOT/strelka.somatic.snvs.filtered.recode.annfilter.vcf
# echo "Filtering INDELs"
# java -jar $SNPSIFT filter \
#     "((exists CLNSIG))" \
#     $STRELKANNOT/strelka.somatic.indels.filtered.recode.ann_hapmap_clinvar.vcf \
#     > $STRELKANNOT/strelka.somatic.indels.filtered.recode.annfilter.vcf


# # Intersection between VarScan and Strelka2 results
# echo "Intersection between VarScan and Strelka2 results"
# bedtools intersect -a results/svc2/svc_varscan/Somatic.snp.filtered.recode.vcf -b results/svc2/svc_strelka2/results/variants/somatic.snvs.filtered.vcf.recode.pass.vcf.recode.vcf  -header > $RESDIR/somatic.snvs.intersect.vcf
# bedtools intersect -a results/svc2/svc_varscan/Somatic.indel.filtered.recode.vcf -b results/svc2/svc_strelka2/results/variants/somatic.indels.filtered.vcf.recode.pass.vcf.recode.vcf -header > $RESDIR/somatic.indels.intersect.vcf


# # #Annotation of somatic variants with snpEff
# echo "Annotation with hapmap and clinvar"

# echo "Annotating SNVs"
# java -Xmx4g -jar $SNPSIFT Annotate $REF1 $RESDIR/somatic.snvs.intersect.vcf  > $RESDIR/somatic.snvs.intersect_ann_hapmap.vcf
# java -Xmx4g -jar $SNPSIFT Annotate $REF2 $RESDIR/somatic.snvs.intersect_ann_hapmap.vcf  > $RESDIR/somatic.snvs.intersect_ann_hapmap_clinvar.vcf

# echo "Annotating INDELs"
# java -Xmx4g -jar $SNPSIFT Annotate $REF1 $RESDIR/somatic.indels.intersect.vcf  > $RESDIR/somatic.indels.intersect_ann_hapmap.vcf
# java -Xmx4g -jar $SNPSIFT Annotate $REF2 $RESDIR/somatic.indels.intersect_ann_hapmap.vcf  > $RESDIR/somatic.indels.intersect_ann_hapmap_clinvar.vcf

# # Filtering intersection results for variants having hapmap and clinvar annotations
# echo "Filtering intersection results for hapmap and clinvar annotations"
# echo "Filtering SNVs"
# java -jar $SNPSIFT filter \
#     "((ANN[*].IMPACT = 'HIGH') | (ANN[*].IMPACT = 'MODERATE')) & ((INFO.CLNSIG =~ 'Pathogenic') | (INFO.CLNSIG =~ 'Likely_Pathogenic'))" \
#     results/svc2/somatic.snvs.intersect_ann_hapmap_clinvar.vcf \
#     > results/svc2/somatic.snvs.intersect_annfilter.vcf
# echo "Filtering INDELs"
# java -jar $SNPSIFT filter \
#     "((ANN[*].IMPACT = 'HIGH') | (ANN[*].IMPACT = 'MODERATE')) & ((INFO.CLNSIG =~ 'Pathogenic') | (INFO.CLNSIG =~ 'Likely_Pathogenic'))" \
#     results/svc2/somatic.indels.intersect_ann_hapmap_clinvar.vcf \
#     > results/svc2/somatic.indels.intersect_annfilter.vcf

# Merge SNVs and INDELs
echo "Merging SNVs and INDELs"
# Indexing
for vcf in \
  results/svc2/svc_varscan/annotation/Somatic.indel.filtered.recode.ann_hapmap_clinvar.vcf \
  results/svc2/svc_varscan/annotation/Somatic.snp.filtered.recode.ann_hapmap_clinvar.vcf \
  results/svc2/svc_strelka2/annotation/strelka.somatic.snvs.filtered.recode.annfilter.vcf \
  results/svc2/svc_strelka2/annotation/strelka.somatic.indels.filtered.recode.annfilter.vcf; do
    bgzip -c "$vcf" > "${vcf}.gz"
    tabix -p vcf "${vcf}.gz"
done

bcftools concat -a \
  results/svc2/svc_varscan/annotation/Somatic.snp.filtered.recode.ann_hapmap_clinvar.vcf.gz \
  results/svc2/svc_varscan/annotation/Somatic.indel.filtered.recode.ann_hapmap_clinvar.vcf.gz | \
  bcftools sort -O z -o results/svc2/svc_varscan/annotation/varscan.somatic.combined.vcf.gz

tabix -p vcf results/svc2/svc_varscan/annotation/varscan.somatic.combined.vcf.gz

bcftools concat -a \
  results/svc2/svc_strelka2/annotation/strelka.somatic.snvs.filtered.recode.annfilter.vcf.gz \
  results/svc2/svc_strelka2/annotation/strelka.somatic.indels.filtered.recode.annfilter.vcf.gz | \
  bcftools sort -O z -o results/svc2/svc_strelka2/annotation/strelka.somatic.combined.vcf.gz

tabix -p vcf results/svc2/svc_strelka2/annotation/strelka.somatic.combined.vcf.gz

bcftools concat -a -d all \
  results/svc2/svc_varscan/annotation/varscan.somatic.combined.vcf.gz \
  results/svc2/svc_strelka2/annotation/strelka.somatic.combined.vcf.gz \
  -O v -o results/svc2/somatic.final.unique.vcf

# Annotation of final unique somatic variants
echo "Annotation of final unique somatic variants"

java -Xmx4g -jar $SNPSIFT Annotate $REF1 results/svc2/somatic.final.unique.vcf  > results/svc2/somatic.final.unique_ann_hapmap.vcf
java -Xmx4g -jar $SNPSIFT Annotate $REF2 results/svc2/somatic.final.unique_ann_hapmap.vcf  > results/svc2/somatic.final.unique_ann_hapmap_clinvar.vcf

# Filtering final unique somatic variants for hapmap and clinvar annotations
echo "Filtering final unique somatic variants for hapmap and clinvar annotations"
java -jar $SNPSIFT filter \
    "(exists CLNSIG)" \
    results/svc2/somatic.final.unique_ann_hapmap_clinvar.vcf \
    > results/svc2/somatic.final.unique_annfilter.vcf

# Extract from VCF variants to TSV
echo "Extracting final unique somatic variants to TSV"
bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%INFO/GENEINFO\t%INFO/CLNSIG\n' \
    results/svc2/somatic.final.unique_annfilter.vcf \
    | sed 's/:[0-9]*//g' \
    > results/svc2/somatic.final.clinical_summary.tsv