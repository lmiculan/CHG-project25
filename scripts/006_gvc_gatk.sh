# Germline variant calling with GATK
set -e
JAVA8=/usr/lib/jvm/java-8-openjdk/bin/java
GATK=~/bin/GenomeAnalysisTK.jar
BAMS=data/bamprocessing/dedup/Control.*.dedup.bam
REF=data/annotations/human_g1k_v37.fasta
BED=data/ogdata/Captured_Regions.bed
OUTDIR=results/gcv_gatk

mkdir -p $OUTDIR

#SCV with GATK UnifiedGenotyper FULL GENOME

# for BAM in $BAMS; do
#     basename=$(basename $BAM .sorted.realigned.recal.dedup.bam)
#     echo "Processing $basename"

#     $JAVA8 -Xmx4g -jar $GATK \
#         -T UnifiedGenotyper \
#         -R $REF \
#         -I $BAM \
#         -o $OUTDIR/$basename\_GVC.vcf \
#         --genotype_likelihoods_model BOTH \
#         --output_mode EMIT_VARIANTS_ONLY

#     # Filtering out low quality variants with vcftools
#     vcftools --minQ 20 \
#              --max-meanDP 2000 \
#              --min-meanDP 5 \
#              --remove-indels \
#              --vcf  $OUTDIR/$basename\_GVC.vcf \
#              --out $OUTDIR/$basename\_GVC_filtered_snps.bcf \
#              --recode \
#              --recode-INFO-all

#     vcftools --minQ 20 \
#              --max-meanDP 2000 \
#              --min-meanDP 5 \
#              --keep-only-indels \
#              --vcf  $OUTDIR/$basename\_GVC.vcf \
#              --out $OUTDIR/$basename\_GVC_filtered_indels.bcf \
#              --recode \
#              --recode-INFO-all
# done

# Checking not maching chromosomes between VCFs
# echo "Checking not maching chromosomes between VCFs"
# awk 'NR==FNR{a[$1];next} !($1 in a)' $OUTDIR/Control_GVC_filtered_snps.bcf.recode.vcf $OUTDIR/Tumor_GVC_filtered_snps.bcf.recode.vcf > $OUTDIR/Not_matching_chromosomes.txt
# awk 'NR==FNR{a[$1];next} !($1 in a)' $OUTDIR/Control_GVC_filtered_indels.bcf.recode.vcf $OUTDIR/Tumor_GVC_filtered_indels.bcf.recode.vcf > $OUTDIR/Not_matching_chromosomes_indels.txt


# # Comparing VCFs to check for common variants across samples
# echo "Comparing SNPs VCFs to check for common variants across samples"

# vcftools --vcf $OUTDIR/Control_GVC_filtered_snps.bcf.recode.vcf \
#          --diff $OUTDIR/Tumor_GVC_filtered_snps.bcf.recode.vcf \
#          --out $OUTDIR/Common_Variants \
#          --diff-site \
#          --not-chr 4 --not-chr 13 --not-chr GL000198.1 --not-chr GL000193.1

# # Comparing VCFs to check for common variants across samples
# echo "Comparing indel VCFs to check for common variants across samples"

# vcftools --vcf $OUTDIR/Control_GVC_filtered_indels.bcf.recode.vcf \
#          --diff $OUTDIR/Tumor_GVC_filtered_indels.bcf.recode.vcf \
#          --out $OUTDIR/Common_Indels \
#          --diff-site \
#          --not-chr 3 --not-chr GL000203.1

OUTDIR=results/gvc_gatk_bed

mkdir -p $OUTDIR

# Germline variant calling with GATK BED TARGETED
# for BAM in $BAMS; do
#     basename=$(basename $BAM .sorted.realigned.recal.dedup.bam)
#     echo "Processing $basename"

#     $JAVA8 -Xmx4g -jar $GATK \
#         -T UnifiedGenotyper \
#         -L $BED \
#         -R $REF \
#         -I $BAM \
#         -o $OUTDIR/$basename\_GVC.vcf \
#         --genotype_likelihoods_model BOTH \
#         --output_mode EMIT_VARIANTS_ONLY

#    # Filtering out low quality variants with vcftools
#     vcftools --minQ 20 \
#              --max-meanDP 2000 \
#              --min-meanDP 5 \
#              --remove-indels \
#              --vcf  $OUTDIR/$basename\_GVC.vcf \
#              --out $OUTDIR/$basename\_GVC_filtered_snps.bcf \
#              --recode \
#              --recode-INFO-all

#     vcftools --minQ 20 \
#              --max-meanDP 2000 \
#              --min-meanDP 5 \
#              --keep-only-indels \
#              --vcf  $OUTDIR/$basename\_GVC.vcf \
#              --out $OUTDIR/$basename\_GVC_filtered_indels.bcf \
#              --recode \
#              --recode-INFO-all
# done

#Checking not maching chromosomes between VCFs
echo "Checking not maching chromosomes between VCFs"
awk 'NR==FNR{a[$1];next} !($1 in a)' $OUTDIR/Control_GVC_filtered_snps.bcf.recode.vcf $OUTDIR/Tumor_GVC_filtered_snps.bcf.recode.vcf > $OUTDIR/Not_matching_chromosomes.txt
awk 'NR==FNR{a[$1];next} !($1 in a)' $OUTDIR/Control_GVC_filtered_indels.bcf.recode.vcf $OUTDIR/Tumor_GVC_filtered_indels.bcf.recode.vcf > $OUTDIR/Not_matching_chromosomes_indels.txt


# Comparing VCFs to check for common variants across samples
echo "Comparing SNPs VCFs to check for common variants across samples"

vcftools --vcf $OUTDIR/Control_GVC_filtered_snps.bcf.recode.vcf \
         --diff $OUTDIR/Tumor_GVC_filtered_snps.bcf.recode.vcf \
         --out $OUTDIR/Common_Variants \
         --diff-site

# Comparing VCFs to check for common variants across samples
echo "Comparing indel VCFs to check for common variants across samples"

vcftools --vcf $OUTDIR/Control_GVC_filtered_indels.bcf.recode.vcf \
         --diff $OUTDIR/Tumor_GVC_filtered_indels.bcf.recode.vcf \
         --out $OUTDIR/Common_Indels \
         --diff-site

