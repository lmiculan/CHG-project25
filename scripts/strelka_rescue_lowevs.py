#!/usr/bin/env python3
"""
strelka_rescue_lowevs.py

Rationale
---------
Strelka2's SomaticEVS score is a random-forest confidence score trained on
feature distributions from deep, roughly genome/exome-scale tumor/normal
pairs. On a small targeted panel the coverage, tier-ratio and variant-density
features it relies on can fall well outside that training distribution, and
the model responds by uniformly suppressing confidence -- including for
variants that are otherwise well supported (near-zero normal VAF, decent
tumor VAF, decent depth, good mapping quality).

Analysis of this project's Strelka output showed that the great majority of
LowEVS-filtered records also carry NT=het/hom/conflict, meaning Strelka's own
genotype model had already flagged the normal sample as carrying the allele
too -- i.e. these are germline/artifactual, and EVS is not the reason they
were excluded. Restricting to NT=ref (the same genotype class as the PASS
calls) and applying a simple depth/VAF sanity filter recovers a meaningful
number of additional plausible somatic candidates that were only lost to the
EVS threshold.

This script re-implements that logic as a reusable, parameterised filter and
splits a Strelka somatic SNV or indel VCF (post depth-filtering, pre PASS-only
filtering) into three tiers:

  pass          FILTER == PASS (Strelka's own high-confidence calls)
  rescued_strong  NT=ref, FILTER contains LowEVS only (not LowDepth), passes
                  the VAF/depth sanity filter, AND has QSS/QSI at or above
                  --min-qss (default 10) -- suitable to merge into the main
                  high-confidence set alongside PASS calls.
  rescued_weak    Same as above but QSS/QSI below --min-qss -- kept for
                  manual / hotspot-driven review only, NOT merged into the
                  automatic high-confidence set (many of these carry QSS=1,
                  i.e. minimal statistical support, and should not be trusted
                  without corroboration from the other caller or a strong
                  prior such as a ClinVar pathogenic annotation).

Everything else (NT=het/hom/conflict, or NT=ref but failing the VAF/depth
sanity filter, or LowDepth) is written to `excluded` purely for bookkeeping /
QC and is not used downstream.

Works on both SNV VCFs (FORMAT has AU/CU/GU/TU) and indel VCFs (FORMAT has
TAR/TIR/TOR), auto-detected per file.
"""

import argparse
import gzip
import sys


def openf(path, mode="rt"):
    return gzip.open(path, mode) if path.endswith(".gz") else open(path, mode)


def parse_info(info_str):
    d = {}
    for kv in info_str.split(";"):
        if "=" in kv:
            k, v = kv.split("=", 1)
            d[k] = v
        else:
            d[kv] = True
    return d


def tier1(value_str):
    """Return the tier-1 (first) integer from a comma-separated FORMAT value."""
    return int(value_str.split(",")[0])


def compute_vaf(fmt_keys, sample_vals, ref, alt, is_indel):
    d = dict(zip(fmt_keys, sample_vals))
    if is_indel:
        tir = tier1(d["TIR"]) if "TIR" in d else 0
        tar = tier1(d["TAR"]) if "TAR" in d else 0
        dp = tir + tar
        vaf = tir / dp if dp > 0 else 0.0
        return vaf, dp
    else:
        dp = int(d.get("DP", 0))
        alt_key = alt.upper() + "U"
        alt_count = tier1(d[alt_key]) if alt_key in d else 0
        vaf = alt_count / dp if dp > 0 else 0.0
        return vaf, dp


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                  formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--input", required=True, help="Strelka somatic SNV or indel VCF (depth-filtered, pre-PASS-only)")
    ap.add_argument("--out-pass", required=True)
    ap.add_argument("--out-rescued-strong", required=True)
    ap.add_argument("--out-rescued-weak", required=True)
    ap.add_argument("--out-excluded", required=True)
    ap.add_argument("--min-tumor-vaf", type=float, default=0.05)
    ap.add_argument("--max-normal-vaf", type=float, default=0.02)
    ap.add_argument("--min-tumor-dp", type=int, default=20)
    ap.add_argument("--min-qss", type=int, default=10,
                     help="QSS/QSI threshold separating rescued_strong from rescued_weak")
    args = ap.parse_args()

    header_lines = []
    out = {
        "pass": [],
        "rescued_strong": [],
        "rescued_weak": [],
        "excluded": [],
    }
    counts = {k: 0 for k in out}

    with openf(args.input) as fh:
        for line in fh:
            if line.startswith("#"):
                header_lines.append(line)
                continue

            fields = line.rstrip("\n").split("\t")
            chrom, pos, vid, ref, alt, qual, filt, info, fmt = fields[:9]
            normal_s, tumor_s = fields[9], fields[10]

            info_d = parse_info(info)
            nt = info_d.get("NT", "?")
            qss = int(info_d.get("QSS", info_d.get("QSI", 0)))

            fmt_keys = fmt.split(":")
            is_indel = "TIR" in fmt_keys

            tum_vaf, tum_dp = compute_vaf(fmt_keys, tumor_s.split(":"), ref, alt, is_indel)
            nor_vaf, _ = compute_vaf(fmt_keys, normal_s.split(":"), ref, alt, is_indel)

            filters = set(filt.split(";"))

            if filt == "PASS":
                bucket = "pass"
            elif nt == "ref" and filters == {"LowEVS"} and \
                    tum_vaf > args.min_tumor_vaf and nor_vaf < args.max_normal_vaf and \
                    tum_dp >= args.min_tumor_dp:
                bucket = "rescued_strong" if qss >= args.min_qss else "rescued_weak"
            else:
                bucket = "excluded"

            counts[bucket] += 1
            out[bucket].append(line)

    dests = {
        "pass": args.out_pass,
        "rescued_strong": args.out_rescued_strong,
        "rescued_weak": args.out_rescued_weak,
        "excluded": args.out_excluded,
    }
    for bucket, path in dests.items():
        with open(path, "w") as fh:
            fh.writelines(header_lines)
            fh.writelines(out[bucket])

    sys.stderr.write(
        "strelka_rescue_lowevs.py summary for {}\n"
        "  PASS:            {}\n"
        "  rescued_strong:  {} (QSS/QSI >= {})\n"
        "  rescued_weak:    {} (QSS/QSI <  {}, manual/hotspot review only)\n"
        "  excluded:        {} (NT het/hom/conflict, LowDepth, or fails VAF/DP sanity check)\n".format(
            args.input, counts["pass"], counts["rescued_strong"], args.min_qss,
            counts["rescued_weak"], args.min_qss, counts["excluded"]
        )
    )


if __name__ == "__main__":
    main()