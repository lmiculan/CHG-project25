#### Somatic point mutations

### preparing pileups
samtools mpileup -q 1 -f ../../../../../annotations/human_g1k_v37.fasta ../04_deduplication/Control.sorted.realigned.recalibrated.dedup.bam > Control.pileup
samtools mpileup -q 1 -f ../../../../../annotations/human_g1k_v37.fasta ../04_deduplication/Tumor.sorted.realigned.recalibrated.dedup.bam > Tumor.pileup

### running Varscan2
java -jar ../../../../../tools/VarScan.v2.3.9.jar somatic Control.pileup Tumor.pileup --output-snp somatic.pm --output-indel somatic.indel --output-vcf 1 --strand-filter 0
# 91429661 positions in tumor
# 91190946 positions shared in normal
# 18222265 had sufficient coverage for comparison
# 18194018 were called Reference
# 0 were mixed SNP-indel calls and filtered
# 2518 were removed by the strand filter
# 23481 were called Germline
# 4187 were called LOH
# 465 were called Somatic
# 114 were called Unknown
# 0 were called Variant

## Annotation
java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar Annotate ../../../../../annotations/hapmap_3.3.b37.vcf  somatic.pm.vcf > somatic.pm.vcf.hapmap_ann.vcf

## Filtering vcf
#cat somatic.pm.vcf.hapmap_ann.vcf | java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar filter "(POS = 1896100)"
#cat somatic.pm.vcf.hapmap_ann.vcf | java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar filter "(exists ID) & ( ID =~ 'rs' )" > somatic.pm.onlySNPs.vcf
#cat somatic.pm.vcf.hapmap_ann.vcf | java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar filter "!(exists ID) & !( ID =~ 'rs' )" > somatic.pm.noSNPs.vcf
cat somatic.pm.vcf.hapmap_ann.vcf | java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar filter "(ANN[ANY].IMPACT = 'HIGH') & (DP > 20) & (exists ID)" > somatic.pm.high_impact.vcf
cat somatic.pm.vcf.hapmap_ann.vcf | java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar filter "(exists CLNSIG)" > somatic.pm.clnsig.vcf

