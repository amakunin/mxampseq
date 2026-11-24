# mxampseq development milestones

Planning checkpoint: 2026-11-24, based on local history through `66c683b`
and the uncommitted `chore/nextflow26-setup` revision.

The immediate priority is learning and establishing pipeline development routines.
Feature implementation is deferred. Headings describe development areas, not
execution order. Each area records agreed scope, remaining work and observations.
Working practices and execution permissions are maintained in [AGENTS.md](AGENTS.md).
Completed pieces of work are recorded by focused commits, not individual agent
turns. Record validation separately from implementation completion.

## Development history

These entries describe committed implementation, not independently verified
scientific results or passing CI. Dates are commit dates from local Git history.

| Date | Commit | Milestone | Evidence |
| --- | --- | --- | --- |
| 2026-10-06 | `af57090` | Generate the nf-core 4.1.0 template. | Entry point, initialisation/completion utilities, schemas, documentation, hooks, CI and pipeline test scaffold. |
| 2026-10-06 | `1d37d7b` | Make initial template adjustments. | Citation/output template cleanup and module manifest changes. |
| 2026-10-07 | `6cf3364` | Introduce core tool modules and module tests. | Local Cutadapt demultiplexing; SeqKit conversion and VSEARCH clustering/dereplication modules, tests and snapshots. |
| 2026-10-07 | `d15414a` | Wire target demultiplexing into the workflow. | Target analysis schema, primer handling, samplesheet changes, target metadata and workflow wiring. |
| 2026-10-14 | `4f42c71` | Add target-specific filtering and a consensus subworkflow. | Local VSEARCH FASTQ filtering and clustering; `TARGET_CONSENSUS`; per-target filtering settings. |
| 2026-10-15 | `3cfe30b` | Correct parameter propagation and use local analysis modules. | Metadata/configuration fixes, empty-read handling, local dereplication and removal of superseded vendored analysis modules. |
| 2026-11-24 | `d348f63` | Refine clustering outputs and introduce chimera filtering. | Consensus/UC output configuration, UCHIME3 module and consensus-subworkflow wiring. |
| 2026-11-24 | `66c683b` | Establish initial agent guidance and development plan. | Root agent guide and milestone document. |

Inspect a milestone with `git show <commit>` from the pipeline directory.
Do not treat the existence of a test or snapshot as evidence that it passes now.

### Current revision, not yet committed

- Refine agent guidance for approval checkpoints, manual-edit coordination,
  user-only Git writes and full-scale tests, and the Nextflow 26 baseline.
- Change the runtime minimum, README badge and pinned nf-test CI runtime to
  26.04.0; keep the latest-runtime CI check.
- Rename three unused closure parameters across the target-consensus and main
  workflows. Leave version collection unchanged.
- Reorganise this document and record the evidence and deferred findings below.

## Development routines and environment

### Goal and agreed decisions

- Establish an understandable, reproducible development and review cycle.
- Use Nextflow 26.04.0 with strict syntax as the initial baseline; Nextflow 25
  compatibility is not required.
- Use the existing farm environment without modifying shared installations.
  Environment selection is machine-specific, not a universal installation rule.

### Remaining work

- Complete a focused branch review and commit cycle with validation evidence.
- Recheck lint after the parameter renames, subject to execution approval.
- Establish nf-core lint, hook checks and focused module/pipeline-test baselines
  under the permissions in the agent guide.
- Learn the distinctions between runtime tools, process containers, test
  fixtures, work directories and published results.

### Observations and open questions

Agent-observed environment verification on 2026-11-24 used:

```bash
conda activate /software/treeoflife/conda/users/envs/tol/nf-core_4.1
```

Activation unloads the farm's default Nextflow module, selects the environment's
Java and sets the shared Singularity library directory. User-terminal activation
was not inherited by the agent shell; activation was repeated per command shell.
No runtime or legacy-parser override was present after activation.

| Tool | Observed version | Comparison at verification |
| --- | --- | --- |
| Nextflow | 26.04.0 | Matches the new development baseline. |
| Java | OpenJDK 23.0.2 | Selected by full Conda activation. |
| nf-core | 4.1.0 | Matches the template/CI tooling version. |
| nf-test | 0.9.5 | CI currently selects 0.9.4; difference remains unresolved. |
| prek | 0.4.12 | Available in the activated environment. |

Agent-observed syntax check on 2026-11-24, on `66c683b` plus the pending
guide/runtime-reference edits, before the parameter renames:

```bash
NXF_SYNTAX_PARSER=v2 nextflow lint .
```

Result: 22 files checked with no errors; four warnings in two files. Three
warnings concerned unused closure parameters, subsequently renamed. The fourth
concerned the unused version-collection return channel, retained for discussion
under reporting. Lint has not been rerun after the renames.
The correct help command was `nextflow help lint`.

Read-only diff/whitespace checks passed after the code edits. No formatting,
hook checks, nf-core lint or pipeline/module tests have been run in this session.
Syntax success does not establish runtime correctness or Docker support.

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

### Observations and open questions

- [Usage documentation](docs/usage.md) describes paired-end input and repeated
  sample rows, but [the input schema](assets/schema_input.json) requires unique
  sample IDs and one gzipped reads file per sample.
- [The full-test profile](conf/test_full.config) still references unrelated
  viralrecon inputs/reference settings.
- Module metadata, environments, stubs and test coverage are uneven.
- CI includes nf-core-specific runner/integration assumptions. Execution in the
  current personal repository has not been verified.
- Inspect [RO-Crate metadata](ro-crate-metadata.json) to distinguish historical
  provenance from stale current requirements; old snapshot versions alone do
  not justify regeneration.

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

## References

- [Contribution guide](docs/CONTRIBUTING.md)
- [Local hooks](.pre-commit-config.yaml)
- [nf-test configuration](nf-test.config)
- [nf-core module standards](https://nf-co.re/docs/specifications/components/modules/general)
- [Sanger ToL review guidance](https://pipelines.tol.sanger.ac.uk/docs/contributing/review_checklist)
- [Sanger ToL pipeline creation](https://pipelines.tol.sanger.ac.uk/docs/contributing/create-pipeline)
- [Sanger ToL testing guidance](https://pipelines.tol.sanger.ac.uk/docs/contributing/testing)
