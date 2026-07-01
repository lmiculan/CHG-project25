#### Somatic point mutations

### preparing pileups
samtools mpileup -q 1 -f ../../../../../annotations/human_g1k_v37.fasta ../04_deduplication/Control.sorted.realigned.recalibrated.dedup.bam > Control.pileup
samtools mpileup -q 1 -f ../../../../../annotations/human_g1k_v37.fasta ../04_deduplication/Tumor.sorted.realigned.recalibrated.dedup.bam > Tumor.pileup

### running Varscan2
java -jar ../../../../../tools/VarScan.v2.3.9.jar somatic Control.pileup Tumor.pileup --output-snp somatic.pm --output-indel somatic.indel --output-vcf 1
# gave me 0 hits, stopped here :(

## Annotation
java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar Annotate ../../../../../annotations/hapmap_3.3.b37.vcf  somatic.pm.vcf > somatic.pm.vcf.hapmap_ann.vcf

## Filtering vcf
cat somatic.pm.vcf.hapmap_ann.vcf | java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar filter "(POS = 1896100)"
cat somatic.pm.vcf.hapmap_ann.vcf | java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar filter "(exists ID) & ( ID =~ 'rs' )" > somatic.pm.onlySNPs.vcf
cat somatic.pm.vcf.hapmap_ann.vcf | java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar filter "!(exists ID) & !( ID =~ 'rs' )" > somatic.pm.noSNPs.vcf









