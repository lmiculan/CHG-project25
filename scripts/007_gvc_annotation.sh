# Annotation of germline variants with snpEff
set -e
VCFs=results/gcv_gatk/*_GVC_filtered_snps.bcf.recode.vcf
OUTDIR=results/gvc_annotation
REF1=data/annotations/hapmap_3.3.b37.vcf
REF2=data/annotations/clinvar_Pathogenic.vcf
snpEff=/home/miculanl/bin/snpEff/snpEff.jar
snpSift=/home/miculanl/bin/snpEff/SnpSift.jar

mkdir -p $OUTDIR

for VCF in $VCFs; do
    basename=$(basename $VCF _GVC_filtered_snps.bcf.recode.vcf)
    echo "Processing $basename"

    java -Xmx4g -jar $snpEff \
        -v GRCh37.75 \
        $VCF \
        -s $OUTDIR/$basename\_GVC_annotated.html > $OUTDIR/$basename\_GVC_annotated.vcf \

    java -jar $snpSift annotate $REF2 $OUTDIR/$basename\_GVC_annotated.vcf > $OUTDIR/$basename\_GVC_annotated_clinvar.vcf
    java -jar $snpSift annotate $REF1 $OUTDIR/$basename\_GVC_annotated_clinvar.vcf > $OUTDIR/$basename\_GVC_annotated_clinvar_hapmap.vcf
    
    # Filter for pathogenic variants using ClinVar and HapMap annotations
    java -jar $snpSift filter "(ANN[ANY].IMPACT = 'HIGH') & (DP > 20) & (exists ID)" $OUTDIR/$basename\_GVC_annotated_clinvar_hapmap.vcf > $OUTDIR/$basename\_GVC_annotated_clinvar_hapmap_filtered.vcf
    java -jar $snpSift filter "(exists CLNSIG)" $OUTDIR/$basename\_GVC_annotated_clinvar_hapmap_filtered.vcf > $OUTDIR/$basename\_GVC_annotated_clinvar_hapmap_final.vcf        
done