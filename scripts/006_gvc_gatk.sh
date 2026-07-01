# Germline variant calling with GATK
JAVA8=/usr/lib/jvm/java-8-openjdk/bin/java
GATK=~/bin/GenomeAnalysisTK.jar
BAMS=data/bamprocessing/dedup/*.dedup.bam
REF=data/annotations/human_g1k_v37.fasta
OUTDIR=results/gcv_gatk

mkdir -p $OUTDIR

#SCV with GATK UnifiedGenotyper

for BAM in $BAMS; do
    basename=$(basename $BAM .sorted.realigned.recal.dedup.bam)
    echo "Processing $basename"

    $JAVA8 -Xmx4g -jar $GATK \
        -T UnifiedGenotyper \
        -R $REF \
        -I $BAM \
        -o $OUTDIR/{$basename}_GVC.vcf \
        --genotype_likelihoods_model BOTH \
        --output_mode EMIT_VARIANTS_ONLY

    # Filtering out low quality variants with vcftools
    vcftools --minQ 20 \
             --max-meanDP 2000 \
             --min-meanDP 5 \
             --remove-indels \
             --vcf  $OUTDIR/$basename\_GVC.vcf \
             --out $OUTDIR/$basename\_GVC_filtered_snps.bcf \
             --recode \
             --recode-INFO-all

    vcftools --minQ 20 \
             --max-meanDP 2000 \
             --min-meanDP 5 \
             --keep-only-indels \
             --vcf  $OUTDIR/$basename\_GVC.vcf \
             --out $OUTDIR/$basename\_GVC_filtered_indels.bcf \
             --recode \
             --recode-INFO-all
done

# Comparing VCFs to check for common variants across samples
echo "Comparing VCFs to check for common variants across samples"

vcftools --vcf $OUTDIR/Control_GVC_filtered.bcf.recode.vcf \
         --diff $OUTDIR/Tumor_GVC_filtered.bcf.recode.vcf \
         --out $OUTDIR/Common_Variants.vcf \
         --chr 1 --chr 2 --chr 3 --chr 5 --chr 6 --chr 7 --chr 8 --chr 9 \
         --chr 10 --chr 11 --chr 12 --chr 14 --chr 15 --chr 16 --chr 17 \
         --chr 18 --chr 19 --chr 20 --chr 21 --chr 22 --chr X --chr Y \
         --diff-site \


