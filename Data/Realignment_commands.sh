samtools sort Control.bam > Control.sorted.bam
samtools sort Tumor.bam > Tumor.sorted.bam

samtools index Control.sorted.bam
samtools index Tumor.sorted.bam

java -jar ../../../../tools/GenomeAnalysisTK.jar -T RealignerTargetCreator -R ../../../../annotations/human_g1k_v37.fasta -I Control.sorted.bam -o Control.realigner.intervals
java -jar ../../../../tools/GenomeAnalysisTK.jar -T RealignerTargetCreator -R ../../../../annotations/human_g1k_v37.fasta -I Tumor.sorted.bam -o Tumor.realigner.intervals

java -jar ../../../../tools/GenomeAnalysisTK.jar -T IndelRealigner -R ../../../../annotations/human_g1k_v37.fasta -I Control.sorted.bam -targetIntervals Control.realigner.intervals -o Control.sorted.realigned.bam
java -jar ../../../../tools/GenomeAnalysisTK.jar -T IndelRealigner -R ../../../../annotations/human_g1k_v37.fasta -I Tumor.sorted.bam -targetIntervals Tumor.realigner.intervals -o Tumor.sorted.realigned.bam

samtools view Control.sorted.realigned.bam | grep OC | wc -l
# output: 9090
samtools view Tumor.sorted.realigned.bam | grep OC | wc -l
# output:7195