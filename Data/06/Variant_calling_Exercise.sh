cd Data

# first takes the sorted bam and transforms it into pileup format (no compression (-Ou) since you do the next step immediately), then does the
# variant calling and outputs (-Ov) a human readable VCF with only the variants (-v)
bcftools mpileup -Ou -a DP -f ../../../annotations/human_g1k_v37.fasta Sample.sorted.bam | bcftools call -Ov -c -v > Sample.BCF.vcf

# this does the same thing but with GATK3 (NOT USEFUL, although you can limit the interval using a bed file)
java -jar ../../../tools/GenomeAnalysisTK.jar -T UnifiedGenotyper -R ../../../annotations/human_g1k_v37.fasta -I Sample.sorted.bam -o Sample.GATK.vcf -L chr20.bed

# this "cleans" the data to get rid of noise. --minQ 20 = filters out all quality scores less than 20 (20 means 99% accuracy).
# min depth = 5 (short fragments are not trustable) and sets max depth = 200 (avoid repetitive regions and mapping errors, they could be false positives)
# removes indels to work only on SNPs. With recode you create an output, and recode-INFO-all puts all info from the input in the output.
vcftools --minQ 20 --max-meanDP 200 --min-meanDP 5 --remove-indels --vcf Sample.BCF.vcf --out Sample.BCF --recode --recode-INFO-all

# code for GATK3 (NOT USEFUL)
vcftools --minQ 20 --max-meanDP 200 --min-meanDP 5 --remove-indels --vcf Sample.GATK.vcf --out Sample.GATK --recode --recode-INFO-all

# you can also check for the difference between the two outputs
vcftools --vcf Sample.BCF.recode.vcf --diff Sample.GATK.recode.vcf --diff-site



# for the exercise i also did
vcftools --minQ 20 --max-meanDP 200 --min-meanDP 20 --remove-indels --vcf Sample.BCF.vcf --out Sample.BCF.2 --recode --recode-INFO-all

# and afterwards, to compare:
vcftools --vcf Sample.BCF.recode.vcf --diff Sample.BCF.2.recode.vcf --diff-site
# i saw this output:
#Found 2370 sites common to both files.
#Found 5494 sites only in main file.
#Found 0 sites only in second file.
#Found 0 non-matching overlapping sites.
#After filtering, kept 7864 out of a possible 7864 Sites
# and i also got an output file named "out.diff.sites_in_files"
