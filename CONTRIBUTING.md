# Contributing To CNN Workbench

CNN Workbench is designed to be easy to extend without forking the whole
project. The intended contribution model is:

- experiments are config-first
- Python owns orchestration
- C++ owns one resolved training job at a time
- deployment-targeted math changes live in shared code, not in experiment
  folders
- most experiment-only work lives in branches or forks by default
- upstream merges reusable code, docs, tests, maintained bases, and selected
  promoted experiments rather than every community experiment

This file explains how to contribute against that design and doubles as a
checksum for whether the project structure is actually contributor-friendly.

Planning update order now matters:

1. update the canonical register entry under `plans/registers/`
2. update the related ADR when rationale changed
3. update `plans/trace/trace.csv` and `plans/trace/coverage.md`
4. update the affected narrative docs
5. only then implement code

Canonical IDs: REQ-013, REQ-014, REQ-015, REQ-018, CON-005

## Current Repository State

Today this repository is still plan-first. The tracked source currently consists
of planning and reference documents, not the implemented Python/C++ codebase
described in [README.md](/Users/joe/GitHub/CNNWorkbench/README.md) and
[plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md).

That means:

- contributions right now are primarily to planning, documentation, and design
  clarity
- the command workflow below is the intended contribution workflow once the
  implementation lands
- if the repo contents and this file ever disagree, update the plan first, then
  update docs, then implement code

Canonical IDs: REQ-014, REQ-015, ASM-001, ASM-006

## Contribution Principles

- Prefer the smallest change surface that solves the problem.
- Do not fork behavior into per-experiment code paths when config or shared
  registries can express it.
- Keep training runtime selection separate from deployment target.
- Treat FPGA-targeted work as a first-class motivation without making the
  framework FPGA-only.
- Keep Python orchestration modular and keep the C++ trainer narrow.
- Make failures actionable. A contributor should get a clear next step instead
  of a low-context tool error.
- Do not design the contribution flow around maintainers reviewing every
  community experiment.

Canonical IDs: REQ-001, REQ-004, REQ-013, CON-002, CON-003

## Choose The Right Contribution Surface

Use the narrowest layer that fits the change.

- Change only experiment behavior under test:
  edit `experiment.toml` in a branch or fork-local experiment folder
- Add or modify reusable orchestration behavior:
  change Python under `src/cnn_workbench/`
- Add or modify reusable model/math behavior:
  change C++ under `cpp/`
- Add a new deployment-target default or durable experiment family:
  create a new base version instead of editing a finished base
- Add a curated upstream example or baseline after discussion:
  promote a finished experiment into upstream
- Update contributor expectations, workflow, or architecture wording:
  update docs first

Cost and iteration tradeoff:

- config changes are the lowest-cost contribution surface
- Python orchestration changes are the next-cheapest path because they do not
  require rebuilding the C++ trainer
- C++ model or math changes are the heaviest path because they require code
  changes, registry wiring where applicable, rebuild, and trainer-facing
  validation
- choose the heavier path only when the behavior truly belongs in the shared
  execution or low-level math layer

Use config when changing:

- training settings
- optimizer or scheduler selection
- stage-level model structure
- loss, train-loop, quantization, or deployment options already exposed in the
  schema

Use shared code when changing:

- a new reusable backbone, head, block, norm, activation, optimizer, scheduler,
  or train loop
- low-level arithmetic such as quantizers, shift activations, or FPGA-oriented
  normalization
- orchestration behavior shared across `check`, `resolve`, `run_local`, or
  `compare`

Boundary routing examples:

- data augmentation that belongs to dataset preparation or input shaping:
  Python under `src/cnn_workbench/datasets/`
- learning-rate behavior that changes trainer-time step logic:
  C++ scheduler or train-loop code
- learning-rate behavior that only affects launch-time selection or config
  assembly:
  Python resolution or orchestration
- metrics that require per-batch access inside the training loop:
  C++ trainer-side metrics code
- metrics that summarize finished artifacts across runs:
  Python compare/reporting code

## Upstream Curation And Fork Sharing

The upstream `experiments/` tree is curated project history, not a mirror of
every community fork.

Working rules:

- Do experiment-only work in your branch or fork by default.
- Share experiment work by linking the repo, commit, experiment folder, and
  compare or report output in Discord, GitHub Discussions, or issues.
- Open upstream pull requests mainly for reusable Python or C++ changes, docs,
  tests, new maintained bases, or explicitly requested promoted experiments.
- `new_experiment` allocates ids in the repo you are currently using. Fork-local
  ids are local and may be renumbered if an experiment is later promoted
  upstream.
- Use `metadata.owner` as a stable GitHub handle or organization label for
  experiments intended to be shared outside a private workspace.
- GitHub pull requests compare one branch against upstream. Other experiment
  branches can stay in your fork and do not have to be merged upstream.

Canonical IDs: REQ-013, ADR-0005, R5

## Intended Setup Flow

Once implementation lands, contributors should be able to bootstrap with one
obvious path.

1. Pick the right environment.
2. Run `doctor`.
3. Run `uv sync`.
4. Run `build` only if the environment supports training.
5. Use `check` and `resolve` before `run_local`.

Canonical commands:

```bash
uv run python -m cnn_workbench.cli.doctor
uv sync
uv run python -m cnn_workbench.cli.build
uv run python -m cnn_workbench.cli.check --experiment <id> --run-profile short
uv run python -m cnn_workbench.cli.resolve --experiment <id> --run-profile short --diff-from-parent
uv run python -m cnn_workbench.cli.run_local --experiment <id> --run-profile short
uv run python -m cnn_workbench.cli.compare --experiments <id> <id>
```

Environment intent:

- accelerated CUDA: Docker or Dev Container is the canonical path
- accelerated MPS: native macOS host
- CPU: native host, especially for short runs and one-image-at-a-time work
- authoring-only: may scaffold, check, resolve, compare, and prepare datasets,
  but must not build or launch training

Authoring-only contribution mode is first-class, not a fallback. Contributors
working on experiment definitions, schema rules, docs, dataset catalog logic,
comparison behavior, or resolution behavior should usually be able to make
progress without a full training-capable environment.

## Normal Contribution Workflow

For most feature or experiment work:

1. Start from the correct base in your current repo or fork.
2. Make the smallest config or shared-code change that expresses the idea.
3. Run `check`.
4. Run `resolve`.
5. Run a short batch first.
6. Commit experiment changes together with any shared-code change they require
   in your branch or fork.
7. If the change adds reusable project behavior, open an upstream PR with the
   reusable code, docs, and tests. Keep experiment-only history in the fork
   unless the experiment is being promoted.
8. Run the canonical full batch only from a clean tree unless an explicit dirty
   override is justified.

Why short runs matter:

- short runs are the intended fast-feedback loop for contributors
- they are the cheapest way to validate that a config change, shared-code
  change, or runtime-selection change behaves as expected
- they should be the default development path before any canonical full run

Use `resolve --diff-from-parent` as the primary inspection tool before launch.
It is the clearest way to verify what your authored experiment changed and what
the trainer will actually receive after inheritance, dataset metadata, and
run-profile expansion.

For documentation or planning work:

1. Update the plan if behavior or architecture is changing.
2. Update the README and contributor docs to match.
3. Avoid documenting behavior that the plan does not define.

For new experiments you plan to share or promote:

- keep `notes.md` meaningful, not boilerplate
- record the hypothesis, parent, fields under test, run plan, expected signal,
  and actual outcome
- treat `notes.md` as the human explanation paired with the machine-readable
  run artifacts
- set `metadata.owner` to the GitHub handle or organization label that should
  stay attached to the work

For promoted upstream experiments:

- promotion is explicit and selective, not the default fate of every experiment
- maintainers may assign a new upstream id in the same track before merge
- once promoted, the experiment becomes part of the curated immutable upstream
  history

For finished experiments and bases:

- do not edit a finished experiment or finished base in place if the correction
  would change runtime meaning
- create a successor experiment or base version and record why the old one was
  superseded
- use notes or reports to explain the correction rather than silently rewriting
  historical source-of-truth configs

Documentation-only clarifications that do not change runtime meaning may still
be added around finished work, but the original runtime-defining config should
remain intact.

For new dataset contributions:

1. add the dataset catalog entry in `configs/datasets.toml`
2. add the prepare helper under `src/cnn_workbench/datasets/`
3. ensure the helper writes `<dataset_root>/metadata.json`
4. verify `resolve` can read the dataset metadata
5. add tests for idempotent preparation and metadata validation

## Quality Bar

Every contribution should preserve these properties:

- one source of truth for runtime resolution
- no duplicate environment or launch policy logic across commands
- no silent mixing of run profiles, datasets, or deployment targets in compare
- no hidden defaults outside the documented config and artifact contracts
- no per-experiment forks of shared math or trainer behavior

Canonical IDs: REQ-001, REQ-011, CON-003, CON-005

Minimum test expectations for implementation contributions:

- validate the changed contract at the narrowest useful level
- add or update unit tests for schema, policy, or resolution rules
- add integration coverage for run orchestration or artifact behavior when the
  change crosses module boundaries
- keep CPU, accelerated, and FPGA-target labeling explicit where relevant

Additional expectations for C++ contributions:

- if a direct C++ unit or smoke-test harness exists for the changed component
  family, use it
- otherwise add the narrowest trainer-boundary smoke test possible using a tiny
  resolved-config fixture
- when adding a new registered component, test both successful selection and the
  failure mode for missing registration
- do not rely only on a full end-to-end run if a smaller targeted validation is
  possible

## Pull Request Checklist

Before opening a PR, confirm:

- the change is in the narrowest correct layer
- docs and plan still match each other
- if the PR contains an experiment folder, it is an explicitly requested
  promotion or a maintained example the project intends to own
- any new config behavior is documented
- any new shared component is reachable through the documented registry/config
  path
- any new dataset path is documented and writes the required metadata contract
- validation and error messages remain actionable
- tests cover the changed behavior or the missing coverage is called out
- experiment-only work the upstream project does not need to own remains in the
  fork
- if you added the second implementation in a registry family, you also proved
  the extension path is understandable through docs and tests

Also confirm:

- the affected canonical IDs still point at the right docs
- the trace and coverage files were updated when the planning contract changed

Canonical IDs: REQ-014, REQ-015, REQ-018

## Contribution Checksum

This project is easy to contribute to only if all of the following stay true:

- a contributor can tell where a change belongs without reading the whole repo
- the environment entrypoint is obvious and starts with `doctor`
- the path from authored experiment to resolved run is inspectable with
  `resolve`
- low-level math work has one shared home in C++
- orchestration behavior has one shared home in Python
- maintainers are not expected to review every community experiment
- the upstream experiment history remains curated instead of becoming a dump of
  all exploratory work
- deployment-targeted work does not require a second project or a forked
  training stack

If any of those stop being true, treat that as an architecture regression and
fix the design before adding more features.

Canonical IDs: REQ-013, CON-003, CON-005, R2, R5, R10
