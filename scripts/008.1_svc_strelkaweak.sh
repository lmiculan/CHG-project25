#!/bin/bash
set -euo pipefail

################################################################################
# strelka_weak_varscan_crosscheck.sh
#
# Rationale: Strelka's rescued_weak tier (NT=ref, LowEVS, passes basic VAF/
# depth sanity checks, but QSS/QSI below the strong-tier threshold) is
# currently only ever unioned into tier2 alongside VarScan-only calls, which
# means a rescued_weak variant that VarScan ALSO independently called never
# gets credit for that agreement -- it's treated the same as a single-caller
# candidate even when two statistically independent models actually agree on
# it. Two callers agreeing is stronger evidence than either caller's own
# internal confidence score, low QSS included, so this script specifically
# checks rescued_weak against VarScan's candidate set (allele-aware, after
# normalization) and produces an expanded, still-corroborated variant set
# suitable for signature / VAF-spectrum analysis -- separate from, and in
# addition to, the original tier1.
#
# This does NOT touch tier2 (the pathogenicity-filtered, single-caller,
# manual-review tier) -- that logic is unchanged. This only builds a bigger,
# still-cross-validated pool for signature work specifically.
#
# Run this after somatic_variant_pipeline.sh has completed (it reuses that
# script's intermediate files).
################################################################################

REF=data/annotations/human_g1k_v37.fasta

RESDIR=results/svc2
VSDIR=$RESDIR/svc_varscan
STDIR=$RESDIR/svc_strelka2
TIER1=$RESDIR/tier1_highconfidence
CROSSDIR=$RESDIR/tier1_expanded_signature

mkdir -p "$CROSSDIR"

### === STEP 1: normalize the rescued_weak calls =============================
echo "[1/3] Normalizing Strelka rescued_weak calls (snvs + indels)"

for VTYPE in snvs indels; do
  bgzip -f -c "$STDIR/results/variants/${VTYPE}.rescued_weak.vcf" \
    > "$STDIR/results/variants/${VTYPE}.rescued_weak.vcf.gz"
  tabix -f -p vcf "$STDIR/results/variants/${VTYPE}.rescued_weak.vcf.gz"

  bcftools norm -f "$REF" -m -both \
    "$STDIR/results/variants/${VTYPE}.rescued_weak.vcf.gz" \
    -O z -o "$STDIR/results/variants/${VTYPE}.rescued_weak.norm.vcf.gz"
  tabix -f -p vcf "$STDIR/results/variants/${VTYPE}.rescued_weak.norm.vcf.gz"
done

### === STEP 2: intersect rescued_weak against VarScan's candidate set =======
echo "[2/3] Intersecting rescued_weak against VarScan (allele-aware)"

# Reuses the same normalized VarScan files built for tier1
# ($VSDIR/Somatic.snp.norm.vcf.gz / Somatic.indel.norm.vcf.gz)

bcftools isec -n=2 -w1 -O z \
  "$STDIR/results/variants/snvs.rescued_weak.norm.vcf.gz" \
  "$VSDIR/Somatic.snp.norm.vcf.gz" \
  -p "$CROSSDIR/isec_snvs_weak_vs_varscan"

bcftools isec -n=2 -w1 -O z \
  "$STDIR/results/variants/indels.rescued_weak.norm.vcf.gz" \
  "$VSDIR/Somatic.indel.norm.vcf.gz" \
  -p "$CROSSDIR/isec_indels_weak_vs_varscan"

cp "$CROSSDIR/isec_snvs_weak_vs_varscan/0000.vcf.gz"   "$CROSSDIR/snvs.weak_corroborated.vcf.gz"
cp "$CROSSDIR/isec_indels_weak_vs_varscan/0000.vcf.gz" "$CROSSDIR/indels.weak_corroborated.vcf.gz"
tabix -f -p vcf "$CROSSDIR/snvs.weak_corroborated.vcf.gz"
tabix -f -p vcf "$CROSSDIR/indels.weak_corroborated.vcf.gz"

N_SNVS=$(bcftools view -H "$CROSSDIR/snvs.weak_corroborated.vcf.gz" | wc -l)
N_INDELS=$(bcftools view -H "$CROSSDIR/indels.weak_corroborated.vcf.gz" | wc -l)
echo "  rescued_weak SNVs corroborated by VarScan:   $N_SNVS"
echo "  rescued_weak indels corroborated by VarScan: $N_INDELS"

### === STEP 3: merge into an expanded, still-corroborated signature set =====
echo "[3/3] Building tier1_expanded_signature (tier1 + weak-but-corroborated)"

bcftools concat -a \
  "$TIER1/somatic.snvs.tier1.vcf.gz" \
  "$CROSSDIR/snvs.weak_corroborated.vcf.gz" \
| bcftools sort -O z -o "$CROSSDIR/somatic.snvs.tier1_expanded.vcf.gz"
tabix -f -p vcf "$CROSSDIR/somatic.snvs.tier1_expanded.vcf.gz"

bcftools concat -a \
  "$TIER1/somatic.indels.tier1.vcf.gz" \
  "$CROSSDIR/indels.weak_corroborated.vcf.gz" \
| bcftools sort -O z -o "$CROSSDIR/somatic.indels.tier1_expanded.vcf.gz"
tabix -f -p vcf "$CROSSDIR/somatic.indels.tier1_expanded.vcf.gz"

N_ORIG=$(bcftools view -H "$TIER1/somatic.snvs.tier1.vcf.gz" | wc -l)
N_EXPANDED=$(bcftools view -H "$CROSSDIR/somatic.snvs.tier1_expanded.vcf.gz" | wc -l)

echo ""
echo "Done."
echo "  Original tier1 SNVs:                          $N_ORIG"
echo "  Expanded tier1 SNVs (tier1 + weak-corroborated): $N_EXPANDED"
echo "  -> $CROSSDIR/somatic.snvs.tier1_expanded.vcf.gz"
echo "  -> $CROSSDIR/somatic.indels.tier1_expanded.vcf.gz"
echo ""
echo "Use tier1_expanded (not tier2) as the input for mutational signature"
echo "refitting / VAF-spectrum work -- it stays restricted to variants with"
echo "cross-caller support and carries no pathogenicity-based selection bias,"
echo "unlike tier2."