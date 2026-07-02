from SigProfilerAssignment import Analyzer as Analyze

Analyze.cosmic_fit("results/svc_varscan/SigProfilerInput", "results/svc_varscan/Somatic.snp.sigprofiler_output", input_type="vcf", context_type="96",
                   collapse_to_SBS96=True, cosmic_version=3.5, exome=False,
                   genome_build="GRCh37", signature_database=None,
                   exclude_signature_subgroups=None, export_probabilities=False,
                   export_probabilities_per_mutation=False, make_plots=True,
                   sample_reconstruction_plots=False, verbose=False)