REF=data/annotations/human_g1k_v37.fasta
NORMAL=data/bamprocessing/realign/Control.sorted.realigned.bam
TUMOR=data/bamprocessing/realign/Tumor.sorted.realigned.bam
OUTDIR=data/clonet_data
GATK=~/bin/GenomeAnalysisTK.jar

mkdir -p $OUTDIR

# pileup
# bcftools mpileup -Ou -a DP -f ${REF} ${NORMAL} | bcftools call -Ov -c -v > ${OUTDIR}/Normal.BCF.vcf

# Filtering heterozygous data
# bcftools view -v snps -m2 -M2 -g het ${OUTDIR}/Normal.BCF.vcf -Ov -o ${OUTDIR}/Normal.het.vcf

# calculate allelic imbalance at specific positions, the output are csv used to run clonet
# java -jar ${GATK} -T ASEReadCounter -R $REF -o ${OUTDIR}/Control.csv -I ${NORMAL} -sites ${OUTDIR}/Normal.het.vcf -U ALLOW_N_CIGAR_READS -minDepth 20 --minMappingQuality 20 --minBaseQuality 20
# java -jar ${GATK} -T ASEReadCounter -R $REF -o ${OUTDIR}/Tumor.csv -I ${TUMOR} -sites ${OUTDIR}/Normal.het.vcf -U ALLOW_N_CIGAR_READS -minDepth 20 --minMappingQuality 20 --minBaseQuality 20

/usr/bin/Rscript scripts/clonet_purity_ploidy.r