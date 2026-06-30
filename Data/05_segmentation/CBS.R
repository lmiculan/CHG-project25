library(DNAcopy)
#folder = "~/Human_Genomics_2026/lessons/05_SomaticCopyNumberCalling/Data/"
cn <- read.table("SCNA.copynumber.called",header=T)

pdf("SegPlot.pdf")

plot(cn$raw_ratio,pch=".",ylim=c(-2.5,2.5))
plot(cn$adjusted_log_ratio,pch=".",ylim=c(-2.5,2.5))
CNA.object <-CNA(genomdat = cn$adjusted_log_ratio, 
                 chrom = cn$chrom,
                 maploc = cn$chr_start, data.type = 'logratio')
CNA.smoothed <- smooth.CNA(CNA.object)
segs <- segment(CNA.smoothed, min.width=2,
                undo.splits="sdundo", #undoes splits that are not at least this many SDs apart.
                undo.SD=3,verbose=1)

plot(segs,plot.type="w")

# every plot before this line is inserted in the pdf
dev.off()

segs2 = segs$output
write.table(segs2, file="SCNA.copynumber.called.seg", row.names=F, col.names=T, quote=F, sep="\t")

# if you get "null device 1" as the output, it's ok. The pdf created should have 3 plots, check it.
