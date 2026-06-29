# View files
DATA_DIR=data/ogdata
OUT_DIR=data/bamprocessing
RESULTS_DIR=data/results/initialqc

BAMS=$(ls $DATA_DIR/*.bam)

for bam in $BAMS; do
    basename=$(basename $bam .bam)
    # echo "Processing $basename.bam..."
    # samtools view -H -f 4 -F 8 $basename  | head -n 20

    # ## Sorting and indexing
    # echo "Sorting and indexing $basename.bam..."
    # samtools sort -o $OUT_DIR/$basename.sorted.bam -T $OUT_DIR/$basename.tmp -@ 4 $DATA_DIR/$basename.bam
    # samtools index $OUT_DIR/$basename.sorted.bam

    # Summary statistics
    echo "Generating summary statistics for $basename.bam..."
    samtools flagstat $OUT_DIR/$basename.sorted.bam > $RESULTS_DIR/$basename.flagstat.txt

    ## Single base depth and coverage
    echo "Calculating single base coverage for $basename.bam..."
    samtools bedcov $DATA_DIR/Captured_Regions.bed $OUT_DIR/$basename.sorted.bam > $RESULTS_DIR/$basename.bedcov.txt
    samtools depth  $DATA_DIR/Captured_Regions.bed $OUT_DIR/$basename.sorted.bam > $RESULTS_DIR/$basename.beddepth.txt
done

