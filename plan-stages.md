# CNN Workbench Staged Delivery Plan

`plan.md` defines the full target system. This file defines the delivery order.

A stage is one level above a task: a bounded slice of work that can be built,
tested, reviewed, and accepted before later stages begin. A later stage may
depend on earlier stages, but every stage must stand on its own without
depending on unfinished later work.

## Working Rules

- Keep implementation in the final product folders such as
  `src/cnn_workbench/resolve/`, `src/cnn_workbench/datasets/`, `src/cnn_workbench/runs/`,
  and `cpp/`. Do not create runtime code folders named after stages.
- Use the matching file under `plans/stages/` for stage-specific execution
  planning. Keep this file as the compact sequencing and acceptance overview.
- Each stage must end with:
  - one operator-visible capability
  - explicit done criteria
  - automated tests for that stage's contracts
  - updated docs for any new command or contract
- Each stage should minimize cross-cutting edits. If a requirement can move to a
  later stage without weakening the current stage's acceptance gate, move it.

## Recommended Stage Order

1. Foundation And Contract Skeleton
2. Experiment Authoring And Resolution
3. Dataset Catalog And Preparation
4. Environment Detection And LibTorch Download
5. Trainer Build And Minimal Vertical Slice
6. Local Run Orchestration (Scratch Runs)
7. Resume And Fine-Tune Extension
8. Comparison And Matrix Workflows
9. FPGA-Targeted Deployment Extension

## Stage 1: Foundation And Contract Skeleton

Primary folders:

- `pyproject.toml`
- `src/cnn_workbench/cli/`
- `src/cnn_workbench/domain/`
- `src/cnn_workbench/artifacts/`
- `tests/`
- `experiments/`
- `configs/`

Goal:

- Create the repository skeleton, typed shared contracts, artifact version
  helpers, CLI entrypoint wiring, and test harness needed by every later stage.

In scope:

- Python package layout and dependency management
- initial CLI module wiring with help text and importable entrypoints
- typed models for `ExperimentConfig`, `ResolvedChildRun`, `BatchPlan`,
  `EnvironmentReport`, `LaunchVerdict`, `RunManifest`, and `CompareInput`
- artifact schema version constants and serializer helpers
- tracked seed content for `000_template`, `100_accelerated_base_v1`,
  `200_fpga_base_v1`, and `300_cpu_base_v1`
- baseline `Makefile` targets and CI placeholder wiring

Provisional model guidance:

- `ExperimentConfig` and `ResolvedChildRun` will be exercised immediately in
  Stage 2. Their shape should be treated as stable from Stage 1 onward.
- `EnvironmentReport`, `LaunchVerdict`, `RunManifest`, `BatchPlan`, and
  `CompareInput` are not consumed by real logic until Stages 4 through 8.
  Define the type stubs and validation here, but treat their field sets as
  provisional until the consumer stage validates the shape. Expect revision
  when each consumer stage starts.

Out of scope:

- experiment inheritance logic
- dataset download or metadata preparation
- environment detection
- C++ build or training
- local run orchestration

Done when:

- a fresh checkout can install the Python package and run the test suite
- CLI modules import cleanly and expose stable command names
- contract objects and artifact helpers exist in one place instead of ad hoc
  dicts
- seed experiments and config roots are present in tracked files

Independent test gate:

- import smoke tests for every planned CLI module
- unit tests for domain model validation and artifact version field injection
- repository layout tests asserting the tracked seed files exist

## Stage 2: Experiment Authoring And Resolution

Primary folders:

- `experiments/`
- `src/cnn_workbench/scaffold/`
- `src/cnn_workbench/check/`
- `src/cnn_workbench/resolve/`
- `src/cnn_workbench/policies/` for authoring-safe checks only
- `tests/`

Goal:

- Make the repo useful for authoring before training exists. A user should be
  able to scaffold an experiment, validate it, and preview the fully resolved
  child configs.

In scope:

- `new_experiment`
- experiment inheritance and merge semantics
- schema validation and error aggregation
- deployment-track inheritance rules
- separation of `runtime.train_runtime` from `track.deploy_target`
- `check --experiment`
- `resolve --run-profile full|short`
- `resolve --diff-from-parent`
- preview placeholders such as `batch_id = "preview"`
- short-run milestone expansion into explicit `eval_items`
- resolved runtime metadata such as requested training runtime, resolved backend,
  and fallback state

Design constraint:

- This stage should use fixture dataset metadata in tests so it does not depend
  on Stage 3.

Out of scope:

- real dataset preparation
- environment capability checks for training
- C++ trainer invocation
- run artifact folders under `runs/`

Done when:

- a new experiment can be scaffolded from a parent and checked into git
- `check` reports all blocking config issues in one pass
- `resolve` emits one fully materialized child config per dataset target
- short and full preview resolution behave differently where required
- authoring rules in `plan.md` are enforced without needing the trainer

Independent test gate:

- scaffolder tests for experiment id allocation, notes template creation, and
  commented override snippets
- resolution tests for inheritance, merge rules, and deployment-track
  restrictions
- resolution tests for `train_runtime` versus `deploy_target` separation
- validation tests for all documented authoring failures
- short-run expansion tests including Fibonacci schedule handling
- regression tests that pin the authoring-safe `policies/` surface so later
  stages (4, 5, 6) can only extend it additively without breaking Stage 2
  contracts

## Stage 3: Dataset Catalog And Preparation

Primary folders:

- `configs/datasets.toml`
- `src/cnn_workbench/datasets/`
- `datasets/`
- `tests/`

Goal:

- Introduce the real dataset contract so authoring and runtime flows can rely
  on discovered dataset metadata instead of fixtures.

In scope:

- dataset catalog parsing
- shared metadata loader interface
- `prepare_datasets`
- idempotent `ensure_dataset()`
- `numbers` and `fashion` dataset helpers
- `<dataset_root>/metadata.json` creation and validation
- `resolve --ensure-datasets`

Out of scope:

- local training
- environment build logic
- compare and matrix workflows

Done when:

- dataset metadata can be loaded from the catalog and copied into resolved child
  configs
- `prepare_datasets` can prepare both phase 1 datasets repeatedly without
  breaking existing outputs
- plain `resolve` remains pure and `resolve --ensure-datasets` opts into
  mutation

Independent test gate:

- unit tests for catalog parsing and metadata validation
- integration tests for idempotent dataset preparation on fixture roots
- tests proving `resolve` fails cleanly when metadata is missing
- tests proving `resolve --ensure-datasets` repairs the missing metadata path

## Stage 4: Environment Detection And LibTorch Download

Primary folders:

- `src/cnn_workbench/doctor/`
- `src/cnn_workbench/policies/`
- `src/cnn_workbench/bootstrap/` (LibTorch download only)
- `docker/`
- `.devcontainer/`
- `compose.yaml`
- `tests/`

Goal:

- Make supported and unsupported environments explicit, then provide the
  project-owned bootstrap path that downloads LibTorch and prepares the
  dependency tree. The actual CMake build step moves to Stage 5 alongside
  the C++ source code it compiles.

Design rationale:

- `build` cannot produce a meaningful binary until C++ source code exists in
  Stage 5. Splitting the concern keeps Stage 4 independently testable:
  environment detection and dependency download are real deliverables, while
  compilation requires the trainer code that Stage 5 introduces.

In scope:

- `doctor`
- shared launch policy evaluation
- environment classification for CUDA container, Dev Container, native macOS
  MPS, CPU-capable native host, compatible native host, and authoring-only host
- LibTorch download/bootstrap into `third_party/libtorch/<platform_tag>/`
- platform-tag selection and cache reuse logic
- canonical Docker and Dev Container definitions
- accelerated-to-CPU fallback policy evaluation for short/debug local runs

Out of scope:

- CMake configuration and `build` command (Stage 5)
- C++ source code
- full trainer feature set
- local batch execution
- comparison reports

Done when:

- `doctor` reports the detected environment, capabilities, blockers, and next
  actions
- `doctor` reports accelerated availability, CPU availability, resolved backend
  selection, and whether a short/debug accelerated request would fall back to
  CPU
- LibTorch download succeeds for the detected platform and is cached for reuse
- unsupported environments are refused with actionable diagnostics before any
  download attempt
- Docker and Dev Container definitions point at the same CUDA-path image or
  service

Independent test gate:

- unit tests for environment classification and policy verdict generation
- tests for supported versus authoring-only versus blocked command gating
- bootstrap tests for platform-tag selection and cache reuse behavior
- fallback-policy tests for accelerated requests on CUDA, MPS, and CPU-only
  hosts
- regression tests that pin the launch-policy surface from Stage 2 so
  environment-gating additions do not break authoring-safe policy contracts

## Stage 5: Trainer Build And Minimal Vertical Slice

Primary folders:

- `cpp/`
- `cpp/main/`
- `cpp/registries/`
- `cpp/models/`
- `cpp/train_loops/`
- `cpp/optimizers/`
- `cpp/losses/`
- `src/cnn_workbench/bootstrap/` (CMake build orchestration)
- `tests/`

Goal:

- Introduce the `build` command, C++ source tree, and the smallest real
  `cnnwb_train` that can consume one resolved config and execute one training
  job with the documented narrow contract.

Design rationale:

- Stage 4 downloaded LibTorch and verified the environment. This stage adds the
  C++ code and the `build` command together so execution of `build` always has
  real source to compile. This avoids a throwaway stub binary in Stage 4.

In scope:

- `build` command: CMake configuration, compilation, and binary production
  at `build/<platform_tag>/bin/cnnwb_train`
- environment-scoped build roots under `build/<platform_tag>/`
- build reuses LibTorch artifacts cached by Stage 4 and refuses unsupported
  environments with actionable diagnostics
- resolved-config parsing on the C++ side
- registry bootstrap for required component families
- phase 1 built-ins for the default general-purpose path
- minimal checkpoint writing
- `metrics.csv` production
- fast failure for unknown registered components and obvious shape errors

Out of scope:

- multi-dataset batch orchestration
- git patch capture
- compare and matrix support
- FPGA-specific components
- resume and fine-tune checkpoint loading

Done when:

- `build` produces a working binary from the C++ source tree using the
  LibTorch dependency downloaded in Stage 4
- `cnnwb_train --resolved-config <path> --output-dir <path>` works for a tiny
  known-good config
- the trainer writes the minimum successful outputs it owns
- startup failures are clear when a requested component is not registered

Independent test gate:

- build tests verifying CMake configuration and binary production
- C++ smoke test against a tiny resolved config fixture
- tests for registry lookup failures
- tests for minimum metrics and checkpoint outputs

## Stage 6: Local Run Orchestration (Scratch Runs)

Primary folders:

- `src/cnn_workbench/runs/`
- `src/cnn_workbench/artifacts/`
- `src/cnn_workbench/policies/`
- `src/cnn_workbench/resolve/`
- `runs/`
- `tests/`

Goal:

- Connect the Python orchestration layer to the real trainer so one experiment
  can execute locally as an ordered parent batch with complete artifacts.
  This stage covers scratch-mode training only. Resume and fine-tune support
  follows in Stage 7.

Design rationale:

- Resume and fine-tune introduce their own validation rules, checkpoint
  resolution logic, and manifest recording requirements. Splitting them out
  keeps this stage focused on the core orchestration loop and its failure
  modes, which are independently valuable and testable.

In scope:

- `run_local` for `initialization.mode = "scratch"` only
- parent batch expansion into ordered child dataset runs
- sequential local execution
- `run_manifest.json`, `summary.json`, and batch summary generation
- git commit, dirty-state, and patch capture
- stop-on-failure behavior
- recording of requested training runtime, resolved backend, deploy target, and
  fallback state in runtime artifacts
- teeing trainer logs into `train.log`

Out of scope:

- resume and fine-tune launch handling (Stage 7)
- matrix expansion
- comparison reporting
- FPGA-target deployment validation

Done when:

- `run_local --experiment <id>` executes a full parent batch end to end for
  scratch-mode experiments
- successful and failed child runs both produce the required artifact set
- dirty-tree rules differ correctly between short and full runs
- stop-on-failure and not-started marking match the plan contract

Independent test gate:

- integration tests for successful local batch execution on tiny datasets
- failure-path tests for trainer crash, dataset prepare failure, and dirty-tree
  policy rejection
- artifact schema assertions for manifest, summary, and batch summary files
- assertions that CPU-fallback short runs are distinguishable from true
  accelerated runs
- regression tests that pin the git-policy surface from Stages 2 and 4 so
  run-time policy additions do not break earlier contracts

## Stage 7: Resume And Fine-Tune Extension

Primary folders:

- `src/cnn_workbench/runs/`
- `src/cnn_workbench/resolve/`
- `src/cnn_workbench/policies/`
- `tests/`

Goal:

- Extend `run_local` to support `initialization.mode = "resume"` and
  `initialization.mode = "finetune"`, including checkpoint resolution,
  validation, and manifest recording.

In scope:

- symbolic checkpoint reference resolution into concrete paths
- `resume` mode: load model, optimizer, and scheduler state from a prior
  checkpoint
- `finetune` mode: load model weights only, start a new training job with
  fresh optimizer and scheduler state
- validation that `resume` and `finetune` require a resolvable
  `checkpoint_source`
- strict versus non-strict model load behavior
- manifest recording of `initialization_mode` and `checkpoint_source`
- resumed runs create new child run folders that record the source checkpoint

Out of scope:

- matrix expansion
- comparison reporting
- FPGA-target deployment validation

Done when:

- `run_local` with `initialization.mode = "resume"` continues training from a
  prior checkpoint with correct optimizer and scheduler state
- `run_local` with `initialization.mode = "finetune"` loads model weights and
  starts a new job with fresh optimizer state
- checkpoint resolution failures produce actionable diagnostics
- manifests and summaries correctly record initialization provenance

Independent test gate:

- resume tests proving optimizer and scheduler state are restored
- fine-tune tests proving model weights load but optimizer state is fresh
- validation tests for missing or incompatible checkpoint sources
- manifest assertions proving source checkpoint is recorded correctly
- strict versus non-strict model load behavior tests

## Stage 8: Comparison And Matrix Workflows

Primary folders:

- `configs/matrices/`
- `src/cnn_workbench/runs/`
- `src/cnn_workbench/compare/`
- `reports/`
- `tests/`

Goal:

- Add the experiment-analysis loop: systematic sweeps and artifact-backed
  comparisons, plus one shared deployment-validation harness for CPU,
  accelerated, and FPGA targets.

In scope:

- `run_matrix`
- deterministic matrix variant id generation
- matrix override recording in manifests
- `compare --experiments ...`
- dataset-aware, profile-aware, and deployment-track-aware comparison rules
- shared deployment smoke validation: export, load, tiny-sample inference, and
  target-compatibility checks
- optional report emission into `reports/`

Out of scope:

- FPGA-specific math or deployment behavior beyond the shared smoke harness

Done when:

- a tracked matrix definition can expand into multiple run variants without id
  collisions
- compare can summarize the latest completed runs without silently mixing
  datasets, profiles, or tracks
- comparison output is strong enough to support promotion decisions for new base
  versions

Independent test gate:

- matrix expansion tests for deterministic ids and duplicate rejection
- compare tests for missing dataset handling and profile separation
- deployment-track-aware comparison tests proving accelerated-target,
  CPU-targeted, and FPGA-targeted runs remain labeled
- deployment smoke-harness tests proving CPU and accelerated targets share the
  same validation contract

## Stage 9: FPGA-Targeted Deployment Extension

Primary folders:

- `experiments/200_fpga_base_v1/`
- `cpp/math/`
- `cpp/models/`
- `cpp/activations/` or equivalent shared component folders
- `src/cnn_workbench/resolve/`
- `src/cnn_workbench/compare/`
- `tests/`

Goal:

- Implement the FPGA-targeted deployment path as a real extension of the shared
  system, not a forked one-off path.

In scope:

- `200_fpga_base_v1` shared defaults
- FPGA-compatible activations, norms, quantization behavior, and export-profile
  validation hooks layered onto the shared deployment smoke harness
- deployment-track-aware constraints for `fpga_int8_v1`
- compare labeling and validation specific to the FPGA-targeted path

Out of scope:

- Azure execution
- a second public optimizer path unless there is a proven need

Done when:

- FPGA-targeted experiments resolve and validate through the same core path as
  accelerated-target and CPU-targeted experiments
- trainer components required by the FPGA profile are selectable through config
- compare output makes accelerated-target, CPU-targeted, and FPGA-targeted runs
  distinguishable and honest

Independent test gate:

- resolution tests for FPGA-base inheritance and constraint enforcement
- trainer smoke tests for FPGA-specific registered components
- comparison tests covering mixed accelerated-target, CPU-targeted, and
  FPGA-targeted result sets

## Stage Exit Rule

Do not start the next stage until the current stage has:

- green automated tests for its acceptance gate
- no placeholder code in the stage's critical path
- at least one short example in `README.md` or adjacent docs showing the new
  capability
- unresolved scope pushed forward explicitly instead of left ambiguous

## Suggested Future Split

Detailed stage plans now live under `plans/stages/`:

- `plans/stages/01_foundation/plan.md`
- `plans/stages/02_authoring_and_resolution/plan.md`
- `plans/stages/03_datasets/plan.md`
- `plans/stages/04_environment_and_libtorch/plan.md`
- `plans/stages/05_trainer_build_and_vertical_slice/plan.md`
- `plans/stages/06_local_scratch_runs/plan.md`
- `plans/stages/07_resume_and_finetune/plan.md`
- `plans/stages/08_compare_and_matrix/plan.md`
- `plans/stages/09_fpga_deployment/plan.md`

Use those files for stage-specific implementation prompts and keep this document
as the compact sequencing and acceptance overview. That keeps delivery planning
separate from the runtime code layout while preserving the planning history in
the repo.
