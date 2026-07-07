#!/bin/bash
set -euo pipefail

### --- paths ---------------------------------------
NORMAL=data/bamprocessing/recal2/Control.sorted.realigned.dedup.recal.bam
TUMOR=data/bamprocessing/recal2/Tumor.sorted.realigned.dedup.recal.bam

REF=data/annotations/human_g1k_v37.fasta
HAPMAP=data/annotations/hapmap_3.3.b37.vcf
CLINVAR=data/annotations/clinvar_20260627.vcf.gz
CAPTURE_BED=data/ogdata/Captured_Regions.bed.gz
HOTSPOT_GENES=data/annotations/hotspot_genes.txt
VARSCAN=~/bin/VarScan.v2.3.9.jar
STRELKADIR=~/bin/strelka-2.9.10
SNPSIFT=~/bin/snpEff/SnpSift.jar
RESCUE_SCRIPT=scripts/strelka_rescue_lowevs.py   # companion python script

RESDIR=results/svc2
VSDIR=$RESDIR/svc_varscan
STDIR=$RESDIR/svc_strelka2
VSANNOT=$VSDIR/annotation
STANNOT=$STDIR/annotation
TIER1=$RESDIR/tier1_highconfidence
TIER2=$RESDIR/tier2_manual_review

mkdir -p "$VSDIR" "$STDIR" "$VSANNOT" "$STANNOT" "$TIER1" "$TIER2"

# ### === STEP 1: VarScan2 =======================================================
# echo "[1/8] Calling somatic variants with VarScan2"

# samtools mpileup -B -q 1 \
#   -f "$REF" \
#   "$NORMAL" "$TUMOR" \
#   -l "$CAPTURE_BED" \
# | java -jar "$VARSCAN" somatic \
#   --output-snp "$VSDIR/Somatic.snp.vcf" \
#   --output-indel "$VSDIR/Somatic.indel.vcf" \
#   --mpileup 1 \
#   --output-vcf 1 \
#   --min-coverage 5 \
#   --min-var-freq 0.05 \
#   --somatic-p-value 0.1 \
#   --min-coverage-normal 5 \
#   --min-coverage-tumor 5

# java -jar "$VARSCAN" processSomatic "$VSDIR/Somatic.snp.vcf" \
#   --min-tumor-freq 0.10 --max-normal-freq 0.05 --p-value 0.05
# java -jar "$VARSCAN" processSomatic "$VSDIR/Somatic.indel.vcf" \
#   --min-tumor-freq 0.10 --max-normal-freq 0.05 --p-value 0.05

# vcftools --max-meanDP 200 --min-meanDP 5 --remove-indels \
#   --vcf "$VSDIR/Somatic.snp.Somatic.vcf" \
#   --out "$VSDIR/Somatic.snp.filtered" --recode --recode-INFO-all
# vcftools --max-meanDP 200 --min-meanDP 5 --keep-only-indels \
#   --vcf "$VSDIR/Somatic.indel.Somatic.vcf" \
#   --out "$VSDIR/Somatic.indel.filtered" --recode --recode-INFO-all

# ### === STEP 2: Strelka2 =======================================================
# echo "[2/8] Calling somatic variants with Strelka2"

# python2 "$STRELKADIR/bin/configureStrelkaSomaticWorkflow.py" \
#   --normalBam "$NORMAL" \
#   --tumorBam "$TUMOR" \
#   --referenceFasta "$REF" \
#   --runDir "$STDIR" \
#   --callRegions "$CAPTURE_BED" \
#   --exome

# "$STDIR/runWorkflow.py" -m local -j 4

# vcftools --max-meanDP 200 --min-meanDP 5 \
#   --gzvcf "$STDIR/results/variants/somatic.snvs.vcf.gz" \
#   --out "$STDIR/results/variants/somatic.snvs.filtered" --recode --recode-INFO-all
# vcftools --max-meanDP 200 --min-meanDP 5 \
#   --gzvcf "$STDIR/results/variants/somatic.indels.vcf.gz" \
#   --out "$STDIR/results/variants/somatic.indels.filtered" --recode --recode-INFO-all

### === STEP 3: Strelka tiered confidence rescue (replaces plain PASS-only filtering) ==
echo "[3/8] Splitting Strelka calls into pass / rescued_strong / rescued_weak / excluded"

for VTYPE in snvs indels; do
  python3 "$RESCUE_SCRIPT" \
    --input "$STDIR/results/variants/somatic.${VTYPE}.filtered.recode.vcf" \
    --out-pass "$STDIR/results/variants/${VTYPE}.pass.vcf" \
    --out-rescued-strong "$STDIR/results/variants/${VTYPE}.rescued_strong.vcf" \
    --out-rescued-weak "$STDIR/results/variants/${VTYPE}.rescued_weak.vcf" \
    --out-excluded "$STDIR/results/variants/${VTYPE}.excluded.vcf" \
    --min-tumor-vaf 0.05 --max-normal-vaf 0.02 --min-tumor-dp 20 --min-qss 10
done

# Strelka's automatic high-confidence set = PASS + rescued_strong
for VTYPE in snvs indels; do
  for f in pass rescued_strong; do
    bgzip -f -c "$STDIR/results/variants/${VTYPE}.${f}.vcf" > "$STDIR/results/variants/${VTYPE}.${f}.vcf.gz"
    tabix -f -p vcf "$STDIR/results/variants/${VTYPE}.${f}.vcf.gz"
  done
  bcftools concat -a \
    "$STDIR/results/variants/${VTYPE}.pass.vcf.gz" \
    "$STDIR/results/variants/${VTYPE}.rescued_strong.vcf.gz" \
  | bcftools sort -O z -o "$STDIR/results/variants/${VTYPE}.highconf.vcf.gz"
  tabix -f -p vcf "$STDIR/results/variants/${VTYPE}.highconf.vcf.gz"
done

### === STEP 4: Normalize both callers before comparing alleles ================
echo "[4/8] Normalizing variant representation (left-align, split multiallelics)"

bgzip -f -c "$VSDIR/Somatic.snp.filtered.recode.vcf"   > "$VSDIR/Somatic.snp.filtered.recode.vcf.gz"
bgzip -f -c "$VSDIR/Somatic.indel.filtered.recode.vcf" > "$VSDIR/Somatic.indel.filtered.recode.vcf.gz"
tabix -f -p vcf "$VSDIR/Somatic.snp.filtered.recode.vcf.gz"
tabix -f -p vcf "$VSDIR/Somatic.indel.filtered.recode.vcf.gz"

bcftools norm -f "$REF" -m -both "$VSDIR/Somatic.snp.filtered.recode.vcf.gz"   -O z -o "$VSDIR/Somatic.snp.norm.vcf.gz"
bcftools norm -f "$REF" -m -both "$VSDIR/Somatic.indel.filtered.recode.vcf.gz" -O z -o "$VSDIR/Somatic.indel.norm.vcf.gz"
tabix -f -p vcf "$VSDIR/Somatic.snp.norm.vcf.gz"
tabix -f -p vcf "$VSDIR/Somatic.indel.norm.vcf.gz"

bcftools norm -f "$REF" -m -both "$STDIR/results/variants/snvs.highconf.vcf.gz"   -O z -o "$STDIR/results/variants/snvs.highconf.norm.vcf.gz"
bcftools norm -f "$REF" -m -both "$STDIR/results/variants/indels.highconf.vcf.gz" -O z -o "$STDIR/results/variants/indels.highconf.norm.vcf.gz"
tabix -f -p vcf "$STDIR/results/variants/snvs.highconf.norm.vcf.gz"
tabix -f -p vcf "$STDIR/results/variants/indels.highconf.norm.vcf.gz"

### === STEP 5: Tier1 -- allele-aware intersection between callers =============
echo "[5/8] Building tier1 (both-caller) high-confidence set"

bcftools isec -n=2 -w1 -O z \
  "$VSDIR/Somatic.snp.norm.vcf.gz" "$STDIR/results/variants/snvs.highconf.norm.vcf.gz" \
  -p "$TIER1/isec_snvs"
bcftools isec -n=2 -w1 -O z \
  "$VSDIR/Somatic.indel.norm.vcf.gz" "$STDIR/results/variants/indels.highconf.norm.vcf.gz" \
  -p "$TIER1/isec_indels"

cp "$TIER1/isec_snvs/0000.vcf.gz"   "$TIER1/somatic.snvs.tier1.vcf.gz"
cp "$TIER1/isec_indels/0000.vcf.gz" "$TIER1/somatic.indels.tier1.vcf.gz"
tabix -f -p vcf "$TIER1/somatic.snvs.tier1.vcf.gz"
tabix -f -p vcf "$TIER1/somatic.indels.tier1.vcf.gz"

### === STEP 6: Tier2 -- single-caller candidates, restricted to plausible pathogenic hits ==
echo "[6/8] Building tier2 (single-caller, manual-review) candidate set"

# Variants private to VarScan (not corroborated by Strelka's high-confidence set)
bcftools isec -n=1 -w1 -O z \
  "$VSDIR/Somatic.snp.norm.vcf.gz" "$STDIR/results/variants/snvs.highconf.norm.vcf.gz" \
  -p "$TIER2/varscan_only_snvs"
bcftools isec -n=1 -w1 -O z \
  "$VSDIR/Somatic.indel.norm.vcf.gz" "$STDIR/results/variants/indels.highconf.norm.vcf.gz" \
  -p "$TIER2/varscan_only_indels"

# Strelka rescued_weak calls (low QSS) are ONLY ever eligible for tier2, never tier1
bgzip -f -c "$STDIR/results/variants/snvs.rescued_weak.vcf"   > "$STDIR/results/variants/snvs.rescued_weak.vcf.gz"
bgzip -f -c "$STDIR/results/variants/indels.rescued_weak.vcf" > "$STDIR/results/variants/indels.rescued_weak.vcf.gz"
tabix -f -p vcf "$STDIR/results/variants/snvs.rescued_weak.vcf.gz"
tabix -f -p vcf "$STDIR/results/variants/indels.rescued_weak.vcf.gz"

bcftools concat -a \
  "$TIER2/varscan_only_snvs/0000.vcf.gz" \
  "$STDIR/results/variants/snvs.rescued_weak.vcf.gz" \
| bcftools sort -O z -o "$TIER2/somatic.snvs.tier2_candidates.vcf.gz"
bcftools concat -a \
  "$TIER2/varscan_only_indels/0000.vcf.gz" \
  "$STDIR/results/variants/indels.rescued_weak.vcf.gz" \
| bcftools sort -O z -o "$TIER2/somatic.indels.tier2_candidates.vcf.gz"
tabix -f -p vcf "$TIER2/somatic.snvs.tier2_candidates.vcf.gz"
tabix -f -p vcf "$TIER2/somatic.indels.tier2_candidates.vcf.gz"

### === STEP 7: Annotation (hapmap + ClinVar) for both tiers ===================
echo "[7/8] Annotating tier1 and tier2 with hapmap + ClinVar"

annotate () {
  local IN=$1 OUT_PREFIX=$2
  java -Xmx4g -jar "$SNPSIFT" Annotate "$HAPMAP"  "$IN" > "${OUT_PREFIX}.ann_hapmap.vcf"
  java -Xmx4g -jar "$SNPSIFT" Annotate "$CLINVAR" "${OUT_PREFIX}.ann_hapmap.vcf" > "${OUT_PREFIX}.ann_hapmap_clinvar.vcf"
}

for VTYPE in snvs indels; do
  bcftools view "$TIER1/somatic.${VTYPE}.tier1.vcf.gz" > "$TIER1/somatic.${VTYPE}.tier1.vcf"
  annotate "$TIER1/somatic.${VTYPE}.tier1.vcf" "$TIER1/somatic.${VTYPE}.tier1"

  bcftools view "$TIER2/somatic.${VTYPE}.tier2_candidates.vcf.gz" > "$TIER2/somatic.${VTYPE}.tier2.vcf"
  annotate "$TIER2/somatic.${VTYPE}.tier2.vcf" "$TIER2/somatic.${VTYPE}.tier2"
done

# Tier1 report: keep everything (this is the trusted set -- also the one to
# feed into downstream mutational signature / VAF-based analyses).
# Tier2 report: restrict to plausible pathogenic hits only, since this tier
# has single-caller support and should not be reported wholesale -- flag for
# manual review (IGV, orthogonal validation) rather than auto-accept.
HOTSPOT_FILTER=""
if [ -f "$HOTSPOT_GENES" ]; then
  GENES=$(paste -sd'|' "$HOTSPOT_GENES")
  HOTSPOT_FILTER=" | (ANN[*].GENE =~ '${GENES}')"
fi

for VTYPE in snvs indels; do
  java -jar "$SNPSIFT" filter \
    "((ANN[*].IMPACT = 'HIGH') | (ANN[*].IMPACT = 'MODERATE')) & ((INFO.CLNSIG =~ 'Pathogenic') | (INFO.CLNSIG =~ 'Likely_pathogenic')${HOTSPOT_FILTER})" \
    "$TIER2/somatic.${VTYPE}.tier2.ann_hapmap_clinvar.vcf" \
    > "$TIER2/somatic.${VTYPE}.tier2.review_candidates.vcf"
done

### === STEP 8: Merge, extract clinical summary TSVs ============================
echo "[8/8] Merging SNVs+indels per tier and extracting summary TSVs"

for vcf in "$TIER1/somatic.snvs.tier1.ann_hapmap_clinvar.vcf" "$TIER1/somatic.indels.tier1.ann_hapmap_clinvar.vcf"; do
  bgzip -f -c "$vcf" > "${vcf}.gz"; tabix -f -p vcf "${vcf}.gz"
done
bcftools concat -a \
  "$TIER1/somatic.snvs.tier1.ann_hapmap_clinvar.vcf.gz" \
  "$TIER1/somatic.indels.tier1.ann_hapmap_clinvar.vcf.gz" \
| bcftools sort -O z -o "$RESDIR/somatic.tier1_highconfidence.final.vcf.gz"
tabix -f -p vcf "$RESDIR/somatic.tier1_highconfidence.final.vcf.gz"

for vcf in "$TIER2/somatic.snvs.tier2.review_candidates.vcf" "$TIER2/somatic.indels.tier2.review_candidates.vcf"; do
  bgzip -f -c "$vcf" > "${vcf}.gz"; tabix -f -p vcf "${vcf}.gz"
done
bcftools concat -a \
  "$TIER2/somatic.snvs.tier2.review_candidates.vcf.gz" \
  "$TIER2/somatic.indels.tier2.review_candidates.vcf.gz" \
| bcftools sort -O z -o "$RESDIR/somatic.tier2_manual_review.final.vcf.gz"
tabix -f -p vcf "$RESDIR/somatic.tier2_manual_review.final.vcf.gz"

bcftools query -f 'TIER1\t%CHROM\t%POS\t%REF\t%ALT\t%INFO/GENEINFO\t%INFO/CLNSIG\n' \
  "$RESDIR/somatic.tier1_highconfidence.final.vcf.gz" | sed 's/:[0-9]*//g' \
  > "$RESDIR/somatic.clinical_summary.tsv"
bcftools query -f 'TIER2\t%CHROM\t%POS\t%REF\t%ALT\t%INFO/GENEINFO\t%INFO/CLNSIG\n' \
  "$RESDIR/somatic.tier2_manual_review.final.vcf.gz" | sed 's/:[0-9]*//g' \
  >> "$RESDIR/somatic.clinical_summary.tsv"

echo "Done."
echo "  Tier1 (high confidence, both callers agree):   $RESDIR/somatic.tier1_highconfidence.final.vcf.gz"
echo "  Tier2 (single-caller, manual review needed):    $RESDIR/somatic.tier2_manual_review.final.vcf.gz"
echo "  Combined clinical summary TSV:                  $RESDIR/somatic.clinical_summary.tsv"
echo ""
echo "NOTE: for mutational signature analysis and purity/ploidy work, use ONLY"
echo "tier1 -- tier2 is single-caller-supported and not suitable for spectrum-"
echo "based analyses."