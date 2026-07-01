# Somatic variant calling with GATK
GATK=../../../../../tools/GenomeAnalysisTK.jar
BAMS=../04_deduplication/*.dedup.bam
REF=../../../../../annotations/human_g1k_v37.fasta
OUTDIR=results

mkdir -p $OUTDIR

# SCV with GATK UnifiedGenotyper
for BAM in $BAMS; do
    basename=$(basename $BAM .sorted.realigned.recal.dedup.bam)
    echo "Processing $basename"


    # $JAVA8 -Xmx4g -jar $GATK \
    #     -T UnifiedGenotyper \
    #     -R $REF \
    #     -I $BAM \
    #     -o $OUTDIR/{$basename}_SCV.vcf \
    #     --genotype_likelihoods_model BOTH \
    #     --output_mode EMIT_VARIANTS_ONLY

    # Filtering variants with vcftools
    vcftools --minQ 20 \
             --max-meanDP 2000 \
             --min-meanDP 5 \
             --remove-indels \
             --vcf  $OUTDIR/$basename\_SCV.vcf \
             --out $OUTDIR/$basename\_SCV_filtered.bcf \
             --recode \
             --recode-INFO-all
done