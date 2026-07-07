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
- Used ~MILLS 1000G standard~ hapmap
- human genome vb37
- 
![[Tumor.sorted.realigned.report.pdf]]
![[Control.sorted.realigned.report.pdf]]

Used custom .Renviron for compatibility of R 4.0 with GATK3 (used R 3).

# Deduplication
GAtk3 picard


# Somatic copy number calling
VARSCAN and CNVKIT

Somatic single-nucleotide variants and indels were called using two algorithmically distinct approaches, VarScan2 and Strelka2, chosen specifically because their different underlying models (heuristic read-count thresholding versus probabilistic realignment-based scoring) tend to fail in largely uncorrelated ways, making agreement between them a meaningful indicator of call quality. During analysis it became apparent that Strelka2's default Empirical Variant Score filter, a machine-learning confidence model trained on coverage and variant-density distributions typical of deep whole-exome or whole-genome data, was miscalibrated for this small targeted panel and was rejecting the large majority of candidate calls (2,784 of 2,837) under a single filter tag, LowEVS. Rather than accept this filtering at face value or discard it outright, each rejected call was examined against Strelka's own normal-sample genotype classification and basic depth/allele-frequency criteria, which showed that most LowEVS-filtered sites were in fact germline in origin (correctly excluded) while a smaller subset shared the genotype profile of Strelka's confidently-called somatic variants and were only lost to the miscalibrated confidence score rather than any genuine lack of support. This subset was recovered and stratified by internal statistical support (QSS) into a tier suitable for automated inclusion and a lower-confidence tier reserved for manual or hotspot-driven review. Somatic variants were then merged across callers using allele-aware comparison (following normalization of variant representation) rather than simple genomic coordinate overlap, producing a high-confidence tier supported by both callers and a secondary tier of single-caller candidates restricted to variants with existing pathogenicity evidence, in order to balance sensitivity and specificity appropriately for downstream mutation and mutational-signature analysis.



# Annotation
