# mxampseq development milestones

Planning checkpoint: 2026-11-24, based on local history through `d348f63`.

The immediate priority is learning and establishing pipeline development routines.
Feature implementation is deferred. This document records the history, proposed
learning milestones, agreed feature scope and unresolved decisions.

## Historical milestones

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

Inspect a milestone with `git show <commit>` from the pipeline directory.
Do not treat the existence of a test or snapshot as evidence that it passes now.

## Development routines first

### R1: Understand the checkout and contribution cycle

- Explain the roles of the entry point, workflow, subworkflows, modules, schemas
  and configuration using the existing demultiplexing-to-consensus path.
- Distinguish source, test fixtures, published results and Nextflow work files.
- Practise one small change on a topic branch based on `dev`, followed by diff
  review and a pull request to `dev`. Do not commit feature work directly to `dev`.
- Explain the release branch and `TEMPLATE` branch before changing either.
- Decide conventions-only alignment versus formal Sanger ToL membership before
  changing hosting, branding or branch names.

Completion: the developer can trace an existing process and describe the full
edit, validate, review and merge cycle.

### R2: Establish a reproducible development environment

- Identify existing environments before installing anything.
- Record how to activate the tools and which versions match CI.
- Use isolated test output/work directories; do not change shared system tools.
- Learn the distinction between the Nextflow runtime and tools inside containers.
- Select a local container engine and explain how its validation relates to CI.

Observed in this session's shell: Nextflow and Singularity are on `PATH`.
`nf-test`, `nf-core`, `prek`, `pre-commit` and Docker were not found on `PATH`.
They may exist in inactive environments; no installation or version execution
has been attempted.

Completion: the developer can activate the intended toolchain and run a bounded
validation command without depending on an undocumented shell state.

### R3: Establish the baseline before adding features

- Run formatting/hook checks, nf-core lint, focused existing module tests and
  the minimal pipeline test as separate layers.
- Classify failures as environment problems, template leftovers, implementation
  bugs or outdated expectations.
- Keep fixes small and explain each failure before correcting it.
- Check actual output shapes, sequence identities and counts, not only exit status.
- Regenerate snapshots only after understanding an intentional output change.

Known items to investigate:

- The default pipeline test references a software-version filename different
  from the filename assembled by the workflow.
- The full-test profile still uses unrelated viralrecon input and reference
  settings rather than an mxampseq dataset.
- Usage documentation describes paired-end input and repeated sample rows,
  whereas the current input schema expects unique sample IDs and one gzipped
  reads file per sample.
- Module metadata, environments, stubs and test coverage are uneven.
- CI includes nf-core-specific runner/integration assumptions. Its ability to
  run in the current personal repository has not been verified.
- Existing lint exclusions need justification, not automatic removal or expansion.

Completion: a reproducible minimal baseline with understood failures resolved
or explicitly recorded. Historical commits are not a substitute for this baseline.

### R4: Practise a small end-to-end change

Choose a bounded baseline correction together, preferably one that demonstrates
configuration, an observable result and a focused test.

Routine:

- Define the intended behaviour and acceptance check.
- Trace the existing implementation and identify the smallest change.
- Write or adjust a focused test that exposes the problem.
- Implement, validate and review the diff.
- Update directly related documentation and changelog where appropriate.
- Commit one logical change and submit a reviewable PR.

Completion: the developer understands both the change and the evidence that it
works. Assistance should explain the reasoning rather than implement the feature
roadmap without the developer's participation.

### R5: Evaluate standards and release routines

Compare technical conventions with the additional requirements for formal
Sanger ToL hosting: organisation ownership, branding, MIT copyright,
`main`/`dev`/`TEMPLATE`, website documentation, public small test data and
farm/Seqera integration.

Retain local analysis modules, but align their interfaces, arguments, naming,
environments, version reporting and tests with nf-core conventions.
MultiQC and FastQC are not required for the initial scope.

Completion: an explicit alignment decision and a small, prioritised standards
backlog. Do not combine all standards work with scientific feature additions.

## Validation ladder

Candidate commands from the existing project conventions, to confirm once the
toolchain is active, run from the pipeline directory:

```bash
git status --short --branch
git diff
prek run --all-files
nf-core pipelines lint .
nf-test test modules/local/cutadapt/demux/tests/main.nf.test --profile +singularity
nf-test test modules/local/vsearch/dereplicate/tests/main.nf.test --profile +singularity
nf-test test tests/default.nf.test --profile +singularity
```

These commands have not been executed in this planning session.
Start with the smallest check covering the change. Escalate to pipeline tests
and broader checks when the change or results require them. Run an appropriate
Docker validation in CI before claiming Docker support.

## Deferred feature scope

- ONT only, with VSEARCH and Savont alternatives.
- Multiple supported sequences with abundances; no forced single barcode.
- Per-target consensus method and taxonomy settings in `analysis_setup`.
- Savont supports independent sample-by-target and pooled-per-target inference.
  Independent inference may use per-target export to consolidate identical
  sequences across samples; this is not pooled inference.
- Sample-level Porechop_ABI followed by Chopper, enabled by default with
  independent skip flags, before Cutadapt target separation/primer trimming.
- Report and skip low-read/empty samples and targets; fail if no usable data
  remain. Actual tool errors must not silently become skipped results.
- Optional taxonomy with user-supplied, prepared SINTAX FASTA per target.
- TSV summaries first; no MultiQC requirement.

## Deferred implementation order

| Stage | Scope | Acceptance |
| --- | --- | --- |
| F1 | Target schema and shared interfaces. | Validate method-specific combinations and route mixed-method targets correctly. |
| F2 | ONT preprocessing subworkflow. | Preserve metadata; test all four skip combinations and agreed low-read handling. |
| F3 | Savont inference/export subworkflow. | Both inference modes work without cross-target pooling or export. |
| F4 | SINTAX taxonomy subworkflow. | Correct target/database pairing, confidence/provenance output and visible unclassified sequences. |
| F5 | Reporting, documentation and release validation. | Consistent sequence/abundance outputs, explicit sample-by-target status, small CI and representative full-data tests. |

Preserve existing VSEARCH behaviour unless a scientific change is explicitly
agreed. Standardising output representation does not make VSEARCH consensuses
and Savont ASVs scientifically equivalent.

## Open feature questions

- How should sample-level Chopper defaults relate to target-specific quality
  and length filters? Should existing `fastqfilter_params` affect both methods?
  Savont requires FASTQ, so it cannot consume the current VSEARCH FASTA output.
- What are minimum sample/target read counts and retained-sequence abundances?
- What chimera filtering does the selected Savont version perform? Retain the
  VSEARCH UCHIME3 path; do not add duplicate Savont filtering without evidence.
- What are the SINTAX cutoff, rank mapping and database version/checksum rules?
- What is the sequence-ID scope and common abundance-table format?
- Should taxonomy classify unique sequences once per target, with sample
  membership retained in the abundance table?
- Which raw/intermediate files should be published versus retained only in work?

## Reference material

- [Contribution guide](docs/CONTRIBUTING.md)
- [Local hooks](.pre-commit-config.yaml)
- [nf-test configuration](nf-test.config)
- [nf-core module standards](https://nf-co.re/docs/specifications/components/modules/general)
- [Sanger ToL review guidance](https://pipelines.tol.sanger.ac.uk/docs/contributing/review_checklist)
- [Sanger ToL pipeline creation](https://pipelines.tol.sanger.ac.uk/docs/contributing/create-pipeline)
- [Sanger ToL testing guidance](https://pipelines.tol.sanger.ac.uk/docs/contributing/testing)
