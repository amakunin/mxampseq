# mxampseq: agent guidance

## Read first

At the start of each session, fetch and read the
[official nf-core pipeline agent guidance](https://github.com/nf-core/agents/blob/main/resources/pipeline/AGENTS.md)
([raw file](https://raw.githubusercontent.com/nf-core/agents/main/resources/pipeline/AGENTS.md)).
Use it for pipeline architecture, tooling, testing and contribution routines.
If it cannot be retrieved, report the failure and agree how to proceed.

Also read these sources when the task involves their scope:

- [Sanger ToL component agent guidance](https://github.com/sanger-tol/nf-core-modules/blob/main/AGENTS.md)
  for module and subworkflow interfaces, environments, metadata, stubs and tests.
  This governs the shared component repository, not this pipeline's branch policy.
- [Sanger ToL pipeline review guidance](https://pipelines.tol.sanger.ac.uk/docs/contributing/review_checklist),
  [module guidelines](https://pipelines.tol.sanger.ac.uk/docs/contributing/modules)
  and [testing guidance](https://pipelines.tol.sanger.ac.uk/docs/contributing/testing)
  for pipeline-level standards.
- [nf-core AI contribution policy](https://nf-co.re/blog/2026/statement-on-ai):
  the human contributor must understand and review submitted code.
- [Local contribution guide](docs/CONTRIBUTING.md) and
  [development milestones](MILESTONES.md) for project context.

Upstream guidance can change. Surface consequential changes or conflicts before
acting. Apply repository-specific rules below rather than importing shared
component repository instructions verbatim.

## Learning workflow

Pipeline development is a learning exercise for the developer.

- Explain the existing behaviour, proposed objective, affected files and why
  each is needed, and acceptance check. Obtain approval before editing.
- Pause for approval if additional files or a broader change become necessary.
- After editing, present the diff and validation evidence for review before
  proceeding to the next change. Explain individual statements and their
  Nextflow/channel implications on request.
- Work on the step the user selected. Do not implement the deferred feature
  roadmap autonomously.
- Explain relevant commands and their results. Distinguish observed evidence
  from assumptions and proposed validation.
- Keep changes focused and reviewable. Avoid incidental refactoring.
- Update directly related documentation and tests alongside behaviour changes.
- Ask before making scientific, architectural or release-policy decisions.
- Changes to this agent guide follow the same proposal, approval, edit and
  review cycle. Do not broaden agent permissions autonomously.
- Routine exceptions require explicit agreement with a defined scope. Do not
  infer permission from repeated approvals.

## Manual edits and coordination

- Before editing, inspect the working-tree diff and reread relevant files.
  Compare with the last inspected state where available; committed manual edits
  may not appear in the working-tree diff.
- User notification of manual edits is helpful, but not required. Do not assume
  that unannounced changes are safe to overwrite or that all unfamiliar changes
  were made by the user.
- Trace affected channel interfaces, configuration, schemas and tests. Discuss
  and obtain approval for dependent changes before implementing them.
- If concurrent edits overlap the intended change, pause and reconcile the
  current content with the developer. Preserve unrelated changes.

## Project structure and scope

mxampseq currently separates reads by target with Cutadapt and generates
sample-by-target consensuses with VSEARCH, followed by UCHIME3 chimera filtering.
Savont, ONT preprocessing and SINTAX are planned, not implemented features.

- `main.nf`: entry point and initialisation/completion wiring.
- `workflows/mxampseq.nf`: pipeline orchestration and target routing.
- `subworkflows/local/`: pipeline-specific stages and input handling.
- `modules/local/`: local analysis processes.
- `subworkflows/nf-core/`: vendored template utilities.
- `conf/modules.config`: tool arguments and output publishing.
- `assets/schema_input.json` and `assets/schema_analysis.json`: input contracts.
- `nextflow_schema.json`: pipeline parameter documentation and validation.
- `tests/` and local component test directories: validation.

Inspect code and schemas before relying on template documentation.
Run artefacts such as `work/`, `.nextflow/`, `.nf-test/` and result directories
are not source or evidence of a passing current baseline.

## Local conventions and upstream exceptions

- Keep analysis modules local, while following nf-core naming and interface
  conventions for easier future replacement.
- Preserve metadata through channel operations. Keep tool wrappers generic;
  resolve target-specific settings in workflow logic and configuration.
- Use `ext.args` and `ext.prefix`, standard resource labels, pinned environments
  and containers, version reporting, metadata files, stubs and focused tests.
- Use nf-core tools for scaffolding and schema maintenance. Do not silently
  replace failed generator commands with handwritten generated files.
- Preserve the current publishing convention unless a migration is requested.
- Do not modify vendored utilities without an explicit maintenance plan.
- Never edit snapshots manually, including version strings. Regenerate only
  after understanding the change, on the CI CPU architecture.
- Do not change template base resource configuration without discussing the
  need and its maintenance implications.
- Do not apply the shared-module guide's PR target of `master` to this pipeline.
  Use topic branches based on `dev`, with PRs targeting `dev`.
- Do not commit feature work directly to `dev` or the release branch, and do not
  switch to or modify `TEMPLATE`.
- Formal Sanger ToL hosting and branding remain undecided. Do not change
  ownership, branding, branch names or website integration without agreement.
- MultiQC and FastQC are not requirements for the current scope.
- Use British English and concise comments explaining non-obvious constraints.

## Environment and validation routine

This may be a shared compute environment. Locate existing development
environments before installing tools. Do not modify shared installations.
Use isolated output/work directories and appropriate compute resources.

- Full-scale pipeline tests are user-only. The agent may prepare commands and
  analyse user-provided results, but must not launch these tests.
- Read-only inspection does not authorise execution of tests or modifying tools.
  Agree permissions for other execution explicitly, including bounded tests.
- Before executing commands with uncertain resource costs or side effects,
  explain them and obtain approval. This includes formatters, hooks,
  installations, downloads, snapshot updates, job submission and Git mutations.
- Do not assume that lint or test commands are harmless. If a validation scope
  is unclear, clarify it before execution.

Check tool versions against the repository's CI and template configuration.
Commands below are starting points, not claims of successful validation.
They do not grant execution permission. Run approved commands from the pipeline
directory with the intended environment activated.

```bash
# Inspect the checkout before editing.
git status --short --branch
git diff

# Run the focused test relevant to the change, for example:
nf-test test modules/local/cutadapt/demux/tests/main.nf.test --profile +singularity

# Escalate to the minimal pipeline test when needed.
nf-test test tests/default.nf.test --profile +singularity

# Run repository checks before submission.
nf-core pipelines lint .
prek run --all-files
```

Use a supported container profile available in the environment. Local
Singularity validation alone does not establish Docker support.
For Nextflow changes, also follow upstream formatting guidance.
Before pushing, require pipeline lint and appropriate pipeline-test evidence;
use release lint when preparing a release. The developer may perform required
validation. Record who ran it, the command, revision and result, and distinguish
user-reported evidence from agent-observed results. Execution boundaries above
take precedence over upstream instructions to run checks.

Report missing tools and baseline failures explicitly. Do not broaden lint
exclusions or regenerate snapshots just to obtain a passing result.
Check required output shapes, identities and counts, not only successful exits.
Documentation-only changes do not require pipeline execution.

## Review and submission

- Review the complete diff and validation results with the developer.
- Before committing, obtain approval to stage and commit only agreed files,
  and require hook-check evidence within the execution permissions above.
- Keep each commit to one logical change with a concise imperative title.
- Obtain permission before pushing or opening a PR.
- Follow the PR template, include relevant changelog/citation updates and wait
  for human review and required CI checks.
- Follow upstream disclosure guidance for substantial agent-generated code.
- Never revert unrelated user changes or include run outputs in commits.
