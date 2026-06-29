# Tools used
## Quality control
- Samtools 1.21
- GATK 3.8

## SNV/SNP calling
- VarScan.v2.3.9
- snpEff 4.3t
- Vcftools-v0.1.17-1

## CNV
- CNVkit

## Tumor heterogenity
- Clonet2 2.2.1

## Ancestry analysis?
- Ethseq 3.0.2

# Pipeline
## Samtools
- sorting via samtools sort
- indexing via samtools index

# Realignment
Gatk3 pipeline: RealignerTargetCreator -> IndelRealigner

# Recalibration
GATK3:
- Used MILLS 1000G standard
![[Tumor.sorted.realigned.report.pdf]]
![[Control.sorted.realigned.report.pdf]]

Used custom .Renviron for compatibility of R 4.0 with GATK3 (used R 3).



# Annotation
