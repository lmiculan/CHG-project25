# pileup
bcftools mpileup -Ou -a DP -f ../../../../../annotations/human_g1k_v37.fasta ../04_deduplication/Control.sorted.realigned.recalibrated.dedup.bam | bcftools call -Ov -c -v > Normal.BCF.vcf

# take the data i want
#grep -E "(^#|0/1)" Normal.BCF.vcf > Normal.het.vcf
bcftools view -v snps -m2 -M2 -g het Normal.BCF.vcf -Ov -o Normal.het.vcf

# calculate allelic imbalance at specific positions, the output are csv used to run clonet!
java -jar ../../../../../tools/GenomeAnalysisTK.jar -T ASEReadCounter -R ../../../../../annotations/human_g1k_v37.fasta -o Control.csv -I ../04_deduplication/Control.sorted.realigned.recalibrated.dedup.bam -sites Normal.het.vcf -U ALLOW_N_CIGAR_READS -minDepth 20 --minMappingQuality 20 --minBaseQuality 20
java -jar ../../../../../tools/GenomeAnalysisTK.jar -T ASEReadCounter -R ../../../../../annotations/human_g1k_v37.fasta -o Tumor.csv -I ../04_deduplication/Tumor.sorted.realigned.recalibrated.dedup.bam -sites Normal.het.vcf -U ALLOW_N_CIGAR_READS -minDepth 20 --minMappingQuality 20 --minBaseQuality 20



