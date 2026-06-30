# i didn't listen when he was explaining the code accurately :( but it shouldnt be complex
# in the final project we will start with a bam file and will use all these preprocessing steps and follow the protocol

# Deduplication without preprocessing using Picard/GATK
samtools sort Sample.bam > Sample.sorted.bam
samtools index Sample.sorted.bam 
java -jar ../../Tools/picard.jar MarkDuplicates I=Sample.sorted.bam O=Sample.sorted.dedup.bam REMOVE_DUPLICATES=true TMP_DIR=/tmp METRICS_FILE=Sample.picard.log ASSUME_SORTED=true
samtools index Sample.sorted.dedup.bam


# Deduplication without preprocessing using samtools (requires fixmate)
samtools sort -n Sample.bam > Sample.nsorted.bam
samtools fixmate -m Sample.nsorted.bam Sample.nsorted.fixed.bam
samtools sort Sample.nsorted.fixed.bam > Sample.nsorted.fixed.sorted.bam
samtools markdup -sr Sample.nsorted.fixed.sorted.bam Sample.nsorted.fixed.sorted.dedup.bam


# Deduplication with preprocessing using Picard/GATK
java -jar ../../Tools/GenomeAnalysisTK.jar -T RealignerTargetCreator -R ../../Annotations/human_g1k_v37.fasta -I Sample.sorted.bam -o realigner.intervals
java -jar ../../Tools/GenomeAnalysisTK.jar -T IndelRealigner -R ../../Annotations/human_g1k_v37.fasta -I Sample.sorted.bam -targetIntervals realigner.intervals -o Sample.sorted.realigned.bam
java -jar ../../Tools/GenomeAnalysisTK.jar -T BaseRecalibrator -R ../../Annotations/human_g1k_v37.fasta -I Sample.sorted.realigned.bam -knownSites ../../Annotations/hapmap_3.3.b37.vcf -o recal.table
java -jar ../../Tools/GenomeAnalysisTK.jar -T PrintReads -R ../../Annotations/human_g1k_v37.fasta -I Sample.sorted.realigned.bam -BQSR recal.table -o Sample.sorted.realigned.recalibrated.bam --emit_original_quals

# This for the project: i already did the things before 
java -jar ../../../../../tools/picard.jar MarkDuplicates I=../03_recalibration/Control.sorted.realigned.recalibrated.bam O=Control.sorted.realigned.recalibrated.dedup.bam REMOVE_DUPLICATES=true TMP_DIR=/tmp METRICS_FILE=Control.sorted.realigned.recalibrated.picard.log ASSUME_SORTED=true
java -jar ../../../../../tools/picard.jar MarkDuplicates I=../03_recalibration/Tumor.sorted.realigned.recalibrated.bam O=Tumor.sorted.realigned.recalibrated.dedup.bam REMOVE_DUPLICATES=true TMP_DIR=/tmp METRICS_FILE=Tumor.sorted.realigned.recalibrated.picard.log ASSUME_SORTED=true
samtools index Control.sorted.realigned.recalibrated.dedup.bam
samtools index Tumor.sorted.realigned.recalibrated.dedup.bam


# Comparing results between the two methods (i didn't do this for the project)
samtools index Control.sorted.dedup.bam
samtools index Sample.nsorted.fixed.sorted.dedup.bam

samtools flagstat Control.sorted.dedup.bam
samtools flagstat Sample.nsorted.fixed.sorted.dedup.bam
samtools flagstat Sample.sorted.realigned.recalibrated.dedup.bam

samtools mpileup -r 19:496546-496566 Sample.sorted.dedup.bam
samtools mpileup -r 19:496546-496566 Sample.nsorted.fixed.sorted.dedup.bam
samtools mpileup -r 19:496546-496566 Sample.sorted.realigned.recalibrated.dedup.bam



##### GATK4 version
gatk MarkDuplicates -I in.bam -O marked.bam -M metrics.txt




