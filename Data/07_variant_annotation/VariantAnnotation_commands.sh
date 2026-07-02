# i only used the code at the end of the file, the rest is just for reference.

####### Annotating variants from bcf

java -Xmx4g -jar ../../../tools/snpEff/snpEff.jar -v hg19kg ../../06_VariantCalling/Data/Sample.BCF.recode.vcf -s Sample.BCF.recode.ann.html > Sample.BCF.recode.ann.vcf
java -Xmx4g -jar ../../../tools/snpEff/SnpSift.jar Annotate ../../../annotations/hapmap_3.3.b37.vcf  Sample.BCF.recode.ann.vcf > Sample.BCF.recode.ann2.vcf
java -Xmx4g -jar ../../../tools/snpEff/SnpSift.jar Annotate ../../../annotations/clinvar_Pathogenic.vcf Sample.BCF.recode.ann2.vcf > Sample.BCF.recode.ann3.vcf


####### Annotating variants from GATK

java -Xmx4g -jar ../../Tools/snpEff/snpEff.jar -v hg19kg ../../06_VariantCalling/Data/Sample.GATK.recode.vcf -s Sample.GATK.recode.ann.html > Sample.GATK.recode.ann.vcf
java -Xmx4g -jar ../../Tools/snpEff/SnpSift.jar Annotate ../../Annotations/hapmap_3.3.b37.vcf  Sample.GATK.recode.ann.vcf > Sample.GATK.recode.ann2.vcf
java -Xmx4g -jar ../../Tools/snpEff/SnpSift.jar Annotate ../../Annotations/clinvar_Pathogenic.vcf Sample.GATK.recode.ann2.vcf > Sample.GATK.recode.ann3.vcf


####### Filtering .vcf files
# if it crashes just change -Xmx4g (gigabytes of ram used) to bigger values
# these commands just print the result, if you want to save the outputs just append > filtered_output.vcf
# i created the two outputs and saw that we only have 2 genetic variants for the first code and only 1 for the second one
cat Sample.BCF.recode.ann3.vcf | java -Xmx4g -jar ../../../tools/snpEff/SnpSift.jar filter "(ANN[ANY].IMPACT = 'HIGH') & (DP > 20) & (exists ID)" 
#cat Sample.GATK.recode.ann3.vcf | java -Xmx4g -jar ../../../tools/snpEff/SnpSift.jar filter "(ANN[ANY].IMPACT = 'HIGH') & (DP > 20) & (exists ID)" 

cat Sample.BCF.recode.ann3.vcf | java -Xmx4g -jar ../../../tools/snpEff/SnpSift.jar filter "(exists CLNSIG)"
#cat Sample.GATK.recode.ann3.vcf | java -Xmx4g -jar ../../../tools/snpEff/SnpSift.jar filter "(exists CLNSIG)"


# what i used
java -Xmx4g -jar ../../../../../tools/snpEff/snpEff.jar -v hg19kg ../06_variant_calling/results/Control_SCV_filtered.recode.vcf -s Control.snp.ann.html > Control.snp.ann.vcf
java -Xmx4g -jar ../../../../../tools/snpEff/snpEff.jar -v hg19kg ../06_variant_calling/results/Tumor_SCV_filtered.recode.vcf -s Tumor.snp.ann.html > Tumor.snp.ann.vcf

cat Control.snp.ann.vcf | java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar filter "(ANN[ANY].IMPACT = 'HIGH') & (DP > 20) & (exists ID)"
cat Control.snp.ann.vcf | java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar filter "(exists CLNSIG)"
cat Tumor.snp.ann.vcf | java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar filter "(ANN[ANY].IMPACT = 'HIGH') & (DP > 20) & (exists ID)"
cat Tumor.snp.ann.vcf | java -Xmx4g -jar ../../../../../tools/snpEff/SnpSift.jar filter "(exists CLNSIG)"