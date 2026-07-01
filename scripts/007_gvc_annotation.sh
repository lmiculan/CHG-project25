# Annotation of germline variants with snpEff
VCFs=results/gcv_gatk/*_GVC_filtered.bcf.recode.vcf
OUTDIR=results/gvc_annotation
REF1=data/annotations/hapmap_3.3.b37.vcf
REF2=data/annotations/clinvar_Pathogenic.vcf

mkdir -p $OUTDIR

for VCF in $VCFs; do
    basename=$(basename $VCF _GVC_filtered.bcf.recode.vcf)
    echo "Processing $basename"

    snpEff \
        -v GRCh37.75 \
        -no-downstream \
        -no-upstream \
        -no-intergenic \
        -no-intron \
        -no-utr \
        -no-regulation \
        -no-gtf \
        -no-stats \
        -o vcf \
        $VCF > $OUTDIR/${basename}_GVC_annotated.vcf
done