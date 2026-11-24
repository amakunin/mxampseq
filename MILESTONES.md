# mxampseq development milestones

This is an active roadmap and handoff, not a development log. Headings describe
areas rather than execution order. Remove resolved notes alongside completed work.
Use Git history for past changes and [AGENTS.md](AGENTS.md) for working practices.

## Development routines and environment

### Goal and agreed decisions

- Establish an understandable, reproducible development and review cycle.

### Remaining work

- Establish the remaining focused module/pipeline-test baselines under the
  permissions in the agent guide.
- Learn the distinctions between runtime tools, process containers, test
  fixtures, work directories and published results.

### Observations and open questions

- Passing pipeline-test baselines and Docker support have not been established.
- Local pipeline inputs in `tests/data/` remain ignored and absent from Git;
  establish reproducible pipeline fixtures.
- Valid initialisation tests warn about `modules_testdata_base_path`, injected
  by `tests/nextflow.config` but absent from the parameter schema. Review this
  test-only setting separately rather than broadening validation exclusions.

## nf-core / Sanger ToL alignment

### Goal and agreed decisions

- Align with nf-core and applicable Sanger ToL conventions while retaining local
  analysis modules for easier future replacement.
- Formal Sanger ToL hosting and branding remain undecided.
- MultiQC and FastQC are not requirements for the initial scope.

### Remaining work

- Evaluate hosting, branding, MIT copyright, release branches, website
  documentation, public small test data and farm/Seqera integration.
- Audit local module interfaces, arguments, environments, pinned containers,
  version reporting, metadata, stubs and focused tests.
- Replace template documentation and test profiles with mxampseq-specific
  content; establish small CI and representative full-data validation.
- Review lint exclusions and CI assumptions individually.
- Revisit the temporary `results_test/` exclusion after establishing isolated
  end-to-end test outputs.

### Observations and open questions

- [Usage documentation](docs/usage.md) describes paired-end input and repeated
  sample rows, but [the input schema](assets/schema_input.json) requires unique
  sample IDs and one gzipped reads file per sample.
- [The full-test profile](conf/test_full.config) still references unrelated
  viralrecon inputs/reference settings.
- Module metadata, environments, stubs and test coverage are uneven.
- CI includes nf-core-specific runner/integration assumptions. Execution in the
  current personal repository has not been verified.
- User-supplied nf-core 4.1.0 lint reported unused `paramsHelp`, missing
  `meta.yml` for both local subworkflows, template TODOs/placeholder DOI and
  vendored utility update notices. These remain to be reviewed; update notices
  do not automatically require upgrades.
- The explicit `results_test/` exclusion protects early-run outputs. Reconsider
  it once isolated end-to-end test output handling is established.

## ONT preprocessing

### Goal and agreed decisions

- Add sample-level Porechop_ABI followed by Chopper before Cutadapt target
  separation and primer trimming, borrowing from ampliseq.
- Enable both steps by default, with independent skip flags.
- Report and skip low-read/empty samples and targets; fail if no usable data
  remain. Actual tool errors must not silently become skipped results.

### Remaining work

- Agree filtering defaults and eligibility thresholds before implementation.
- Add a metadata-preserving subworkflow and counts/status reporting.
- Validate all four skip combinations and the agreed low-read behaviour.

### Observations and open questions

- How should sample-level Chopper defaults relate to target-specific quality
  and length filters? Should existing `fastqfilter_params` affect both methods?
- What are the minimum sample/target read counts?

## Per-target consensus: existing VSEARCH and alternative Savont

### Goal and agreed decisions

- ONT only, with a per-target method selected in `analysis_setup`.
- Produce multiple supported sequences with abundances; no forced single barcode.
- Preserve existing VSEARCH behaviour unless a scientific change is agreed.
- Support independent sample-by-target and pooled-per-target Savont inference.
  Per-target export after independent inference may consolidate identical
  sequences across samples; this is not pooled inference.
- Standardised representation does not make VSEARCH consensuses and Savont ASVs
  scientifically equivalent.

### Remaining work

- Extend method-specific target configuration and validation.
- Adapt ampliseq's Savont inference/export logic without cross-target mixing.
- Produce common representative-sequence and abundance outputs; verify both
  inference modes.

### Observations and open questions

- Savont requires FASTQ, so it cannot consume the current VSEARCH FASTA output.
- What is the minimum supporting abundance for retained sequences?
- What chimera filtering does the selected Savont version perform? Retain
  VSEARCH UCHIME3; do not add duplicate Savont filtering without evidence.
- Pooled-target failures must distinguish no usable input from actual tool errors.

## Per-target SINTAX taxonomy

### Goal and agreed decisions

- Add optional taxonomy using user-supplied, prepared SINTAX FASTA per target.
- Borrow from ampliseq, adapting its run-wide database assumptions to targets.
- Preserve sequence identity, confidence, database provenance and unclassified
  results.

### Remaining work

- Extend target taxonomy settings and validate supplied references.
- Add target-aware classification and result formatting.
- Verify target/database pairing and visible unclassified sequences.

### Observations and open questions

- What are the default cutoff, rank mapping and database version/checksum rules?
- Should taxonomy classify unique sequences once per target, with sample
  membership retained in the abundance table?

## Cross-cutting interfaces and reporting

### Goal and agreed decisions

- Keep sample and target identity distinct from filenames.
- Put method and taxonomy settings in `analysis_setup`.
- Provide TSV summaries first, including empty/skipped sample-by-target outcomes.
- Establish shared interfaces before adding downstream feature subworkflows.

### Remaining work

- Define sequence-ID scope and the common abundance-table format.
- Validate mixed-method targets and method-specific setting combinations.
- Agree published outputs versus work-only intermediates.
- Complete reporting, usage/output documentation and tool citations.
- Review the software-version output contract and its test expectations.

### Observations and open questions

- [The workflow](workflows/mxampseq.nf) already collects version-topic records and
  workflow/runtime information into
  `pipeline_info/nf_core_mxampseq_software_versions.yml`. This implementation has
  not been verified in a current pipeline run.
- The returned `ch_collated_versions` channel is unused; removing the entire
  operator chain would remove file collection. No change was made.
- The workflow emits the empty `ch_versions` channel rather than the collected
  file. Decide the intended downstream interface before changing this.
- [The pipeline test](tests/default.nf.test) expects
  `nf_core_mxampseq_software_mqc_versions.yml`, which differs from the workflow
  filename. Resolve the contract and test together.
- Which raw/intermediate files should be published rather than retained in work?
