cd Data

#### Somatic point mutations

### preparing pileups
samtools mpileup -q 1 -f ../../../annotations/human_g1k_v37.fasta Normal_chr13_chr20.sorted.bam > Normal_chr13_chr20.sorted.pileup
samtools mpileup -q 1 -f ../../../annotations/human_g1k_v37.fasta Tumor_chr13_chr20.sorted.bam > Tumor_chr13_chr20.sorted.pileup

### running Varscan2
java -jar ../../../tools/VarScan.v2.3.9.jar somatic Normal_chr13_chr20.sorted.pileup Tumor_chr13_chr20.sorted.pileup --output-snp somatic.pm --output-indel somatic.indel --output-vcf 1

## Annotation
java -Xmx4g -jar ../../../tools/snpEff/SnpSift.jar Annotate ../../../annotations/hapmap_3.3.b37.vcf  somatic.pm.vcf > somatic.pm.vcf.hapmap_ann.vcf

## Filtering vcf
cat somatic.pm.vcf.hapmap_ann.vcf | java -Xmx4g -jar ../../../tools/snpEff/SnpSift.jar filter "(POS = 1896100)"
cat somatic.pm.vcf.hapmap_ann.vcf | java -Xmx4g -jar ../../../tools/snpEff/SnpSift.jar filter "(exists ID) & ( ID =~ 'rs' )" > somatic.pm.onlySNPs.vcf
cat somatic.pm.vcf.hapmap_ann.vcf | java -Xmx4g -jar ../../../tools/snpEff/SnpSift.jar filter "!(exists ID) & !( ID =~ 'rs' )" > somatic.pm.noSNPs.vcf









