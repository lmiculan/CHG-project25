#go to the end of the file to see the code i used for the project, the rest is just for reference.

cd Data

# first takes the sorted bam and transforms it into pileup format (no compression (-Ou) since you do the next step immediately), then does the
# variant calling and outputs (-Ov) a human readable VCF with only the variants (-v)
#bcftools mpileup -Ou -a DP -f ../../../../../annotations/human_g1k_v37.fasta Sample.sorted.bam | bcftools call -Ov -c -v > Sample.BCF.vcf

# this does the same thing but with GATK3 (NOT USEFUL, although you can limit the interval using a bed file)
#java -jar ../../../../../tools/GenomeAnalysisTK.jar -T UnifiedGenotyper -R ../../../../../annotations/human_g1k_v37.fasta -I Sample.sorted.bam -o Sample.GATK.vcf -L chr20.bed

samtools mpileup -q 1 -f ../../../../../annotations/human_g1k_v37.fasta ../04_deduplication/Control.sorted.realigned.recalibrated.dedup.bam ../04_deduplication/Tumor.sorted.realigned.recalibrated.dedup.bam | java -jar ../../../../../tools/VarScan.v2.3.9.jar somatic --output-snp Somatic.snp.vcf --output-indel Somatic.indel.vcf --mpileup 1 --output-vcf 1
# 4754325 positions in mpileup file
# 694941 had sufficient coverage for comparison
# 694311 were called Reference
# 0 were mixed SNP-indel calls and filtered
# 50 were removed by the strand filter
# 461 were called Germline
# 118 were called LOH
# 1 were called Somatic
# 0 were called Unknown
# 0 were called Variant

# this "cleans" the data to get rid of noise. --minQ 20 = filters out all quality scores less than 20 (20 means 99% accuracy).
# min depth = 5 (short fragments are not trustable) and sets max depth = 200 (avoid repetitive regions and mapping errors, they could be false positives)
# removes indels to work only on SNPs. With recode you create an output, and recode-INFO-all puts all info from the input in the output.
#vcftools --minQ 20 --max-meanDP 200 --min-meanDP 5 --remove-indels --vcf Sample.BCF.vcf --out Sample.BCF --recode --recode-INFO-all

# code for GATK3 (NOT USEFUL)
#vcftools --minQ 20 --max-meanDP 200 --min-meanDP 5 --remove-indels --vcf Sample.GATK.vcf --out Sample.GATK --recode --recode-INFO-all

# Filter SNPs
#vcftools --minQ 20 --max-meanDP 200 --min-meanDP 5 --remove-indels --vcf Somatic.snp.vcf --out Somatic.snp.filtered --recode --recode-INFO-all

# Filter indels (keep indels this time, remove SNPs)
#vcftools --minQ 20 --max-meanDP 200 --min-meanDP 5 --keep-only-indels --vcf Somatic.indel.vcf --out Somatic.indel.filtered --recode --recode-INFO-all

# for snps
# Step 1: somatic filtering using VarScan's own logic (replaces --minQ)
java -jar ../../../../../tools/VarScan.v2.3.9.jar processSomatic Somatic.snp.vcf \
  --min-tumor-freq 0.10 \
  --max-normal-freq 0.05 \
  --p-value 0.05

# Step 2: depth filtering with vcftools (on the somatic output)
vcftools --max-meanDP 200 --min-meanDP 5 --remove-indels \
  --vcf Somatic.snp.Somatic.vcf \
  --out Somatic.snp.filtered --recode --recode-INFO-all

# for indels
# Step 1: somatic filtering
java -jar ../../../../../tools/VarScan.v2.3.9.jar processSomatic Somatic.indel.vcf \
  --min-tumor-freq 0.10 \
  --max-normal-freq 0.05 \
  --p-value 0.05

# Step 2: depth filtering with vcftools
vcftools --max-meanDP 200 --min-meanDP 5 --keep-only-indels \
  --vcf Somatic.indel.Somatic.vcf \
  --out Somatic.indel.filtered --recode --recode-INFO-all

# you can also check for the difference between the two outputs
#vcftools --vcf Sample.BCF.recode.vcf --diff Sample.GATK.recode.vcf --diff-site



# for the exercise i also did
#vcftools --minQ 20 --max-meanDP 200 --min-meanDP 20 --remove-indels --vcf Sample.BCF.vcf --out Sample.BCF.2 --recode --recode-INFO-all

# and afterwards, to compare:
#vcftools --vcf Sample.BCF.recode.vcf --diff Sample.BCF.2.recode.vcf --diff-site
# i saw this output:
#Found 2370 sites common to both files.
#Found 5494 sites only in main file.
#Found 0 sites only in second file.
#Found 0 non-matching overlapping sites.
#After filtering, kept 7864 out of a possible 7864 Sites
# and i also got an output file named "out.diff.sites_in_files"


# this is the code i actually used
samtools mpileup -q 1 \
  -f ../../../../../annotations/human_g1k_v37.fasta \
  -l ../Captured_Regions.bed \
  ../04_deduplication/Control.sorted.realigned.recalibrated.dedup.bam \
  ../04_deduplication/Tumor.sorted.realigned.recalibrated.dedup.bam \
  | java -jar ../../../../../tools/VarScan.v2.3.9.jar somatic \
  --output-snp Somatic.snp.vcf \
  --output-indel Somatic.indel.vcf \
  --mpileup 1 \
  --output-vcf 1 \
  --min-coverage 5 \
  --min-var-freq 0.05 \
  --somatic-p-value 0.1 \
  --min-coverage-normal 5 \
  --min-coverage-tumor 5

# Step 2: processSomatic
java -jar ../../../../../tools/VarScan.v2.3.9.jar processSomatic Somatic.snp.vcf \
  --min-tumor-freq 0.10 \
  --max-normal-freq 0.05 \
  --p-value 0.05
# 246 VarScan calls processed
# 3 were Somatic (0 high confidence)
# 211 were Germline (139 high confidence)
# 32 were LOH (30 high confidence)

java -jar ../../../../../tools/VarScan.v2.3.9.jar processSomatic Somatic.indel.vcf \
  --min-tumor-freq 0.10 \
  --max-normal-freq 0.05 \
  --p-value 0.05
# 26 VarScan calls processed
# 0 were Somatic (0 high confidence)
# 23 were Germline (15 high confidence)
# 1 were LOH (1 high confidence)

# Step 3: vcftools depth filtering
vcftools --max-meanDP 200 --min-meanDP 5 --remove-indels \
  --vcf Somatic.snp.Somatic.vcf \
  --out Somatic.snp.filtered --recode --recode-INFO-all

vcftools --max-meanDP 200 --min-meanDP 5 --keep-only-indels \
  --vcf Somatic.indel.Somatic.vcf \
  --out Somatic.indel.filtered --recode --recode-INFO-all

# Step 4: bedtools intersect with DNA repair genes
bedtools intersect \
  -a Somatic.snp.filtered.recode.vcf \
  -b ../DNA_Repair_Genes.bed \
  -header -wa \
  > Somatic.snp.dna_repair.vcf

bedtools intersect \
  -a Somatic.indel.filtered.recode.vcf \
  -b ../DNA_Repair_Genes.bed \
  -header -wa \
  > Somatic.indel.dna_repair.vcf