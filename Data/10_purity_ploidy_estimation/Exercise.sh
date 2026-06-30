# pileup
bcftools mpileup -Ou -a DP -f ../../annotations/human_g1k_v37.fasta Normal_chr13_chr20.sorted.bam | bcftools call -Ov -c -v > Normal.BCF.vcf

# take the data i want
grep -E "(^#|0/1)" Normal.BCF.vcf > Normal.het.vcf

# calculate allelic imbalance at specific positions, the output are csv used to run clonet!
java -jar ../../tools/GenomeAnalysisTK.jar -T ASEReadCounter -R ../../annotations/human_g1k_v37.fasta -o Normal.csv -I Normal_chr13_chr20.sorted.bam -sites Normal.het.vcf -U ALLOW_N_CIGAR_READS -minDepth 20 --minMappingQuality 20 --minBaseQuality 20
java -jar ../../tools/GenomeAnalysisTK.jar -T ASEReadCounter -R ../../annotations/human_g1k_v37.fasta -o Tumor.csv -I Tumor_chr13_chr20.sorted.bam -sites Normal.het.vcf -U ALLOW_N_CIGAR_READS -minDepth 20 --minMappingQuality 20 --minBaseQuality 20



