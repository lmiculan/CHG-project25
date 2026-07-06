#SCNV with VarScan
#NORMAL=data/bamprocessing/dedup/Control.sorted.realigned.recal.bam
#TUMOR=data/bamprocessing/dedup/Tumor.sorted.realigned.recal.bam
NORMAL=data/bamprocessing/recal2/Control.sorted.realigned.dedup.recal.bam
TUMOR=data/bamprocessing/recal2/Tumor.sorted.realigned.dedup.recal.bam
REF=data/annotations/human_g1k_v37.fasta
VARSCAN=~/bin/VarScan.v2.3.9.jar
OUTDIR=results/scnv_varscan_cnvkit2

mkdir -p $OUTDIR

# echo "Processing bams"

# samtools mpileup -B -q 1 -f "$REF" "$NORMAL" "$TUMOR" | \
#     java -Xmx4g -jar $VARSCAN copynumber \
#     - \
#     "$OUTDIR/SCNA" \
#     --mpileup 1

# echo "Adjusting GC content variants with VarScan"

# java -jar $VARSCAN copyCaller $OUTDIR/SCNA.copynumber --output-file $OUTDIR/SCNA.copynumber.called

##CBS segmentation with CNVkit
echo "Segmenting with CNVkit"

# Correct formatted headers for CNVkit (replace first row names with 'chromosome', 'start', 'end', 'gene', 'log2')
# Putting . as gene name for now, since VarScan does not provide gene names in the output
awk 'BEGIN {FS="\t"; OFS="\t"; print "chromosome", "start", "end", "gene", "log2", "weight"}
    NR>1 {print $1, $2, $3, ".", $7, "1.0"}' $OUTDIR/SCNA.copynumber.called > $OUTDIR/SCNA.copynumber.called.formatted.cns

cnvkit.py segment $OUTDIR/SCNA.copynumber.called.formatted.cns -o $OUTDIR/SCNA.copynumber.called.segmented.cns

#Export to SEG format for downstream analysis
cnvkit.py export seg \
    $OUTDIR/SCNA.copynumber.called.segmented.cns \
    -o $OUTDIR/SCNA.copynumber.called.segmented.seg

#Plots
cnvkit.py scatter $OUTDIR/SCNA.copynumber.called.segmented.cns -o $OUTDIR/SCNA.copynumber.called.segmented.scatter.pdf
cnvkit.py diagram $OUTDIR/SCNA.copynumber.called.segmented.cns -o $OUTDIR/SCNA.copynumber.called.segmented.diagram.pdf