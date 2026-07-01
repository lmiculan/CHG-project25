#!bin/bash

# Main script to run the entire pipeline

# If any script fails, stop the execution of the main script
set -e
sh scripts/001_qc\&preprocess.sh
sh scripts/002_realignment.sh
sh scripts/003_recalibration.sh
sh scripts/004_deduplication.sh
sh scripts/005_scnv_varscan_cnvkit.sh
sh scripts/006_svc_varscan.sh
