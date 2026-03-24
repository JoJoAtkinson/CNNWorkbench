# CNN Workbench

CNN Workbench is a local-first, LibTorch-based experiment workbench for CNN
training.

One rule drives the whole design: Python resolves human-authored inputs into one
TOML config per dataset child run, and that resolved config is the only runtime
contract the C++ trainer consumes.

Why LibTorch:

- FPGA-first motivation: low-level arithmetic can live in the same C++ layer as
  FPGA-oriented deployment constraints.
- Flexible cross-target architecture: the same framework can still support
  accelerated and CPU-targeted experiments without forking the project by
  target.
- Standalone C++ execution path: worker nodes can run `cnnwb_train` with
  bundled LibTorch libraries instead of depending on a full Python/PyTorch
  environment.

The workbench is meant to support three common experiment roots:

- accelerated target: deploy to an accelerated inference path
- FPGA target: deploy to 8-bit FPGA inference using the inspiration profile
  under `inspiration_sources/FPGAResNet18-LibTorch/`
- CPU target: deploy to CPU inference with a first-class CPU-oriented base

The project is intentionally config-first. An experiment should usually be a
new folder plus small config changes, not a fork of the C++ codebase. The
upstream repo is curated: most experiment-only work should live in branches or
forks and be shared by link, while upstream mainly absorbs reusable framework
changes and selected promoted experiments.

For Phase 1, there are three intended local training paths:

- accelerated CUDA on Windows/Linux uses Docker as the recommended execution
  path
- accelerated MPS on Apple Silicon uses the native macOS host path
- CPU training on a compatible native host is a supported first-class path for
  short runs, debugging, and one-image-at-a-time experimentation

For interactive development, debugging, and stepping through the code on the
CUDA path, the recommended experience is a Dev Container that reuses that same
Docker environment.

Planning source of truth:

- canonical atomic records live under `plans/registers/`
- durable rationale lives under `plans/decisions/`
- trace and checksum reporting live under `plans/trace/`
- this README remains the newcomer-facing narrative entrypoint

Canonical IDs: REQ-001, REQ-002, REQ-003, REQ-013, REQ-014, REQ-015, CON-003, CON-005

## Goals

- A new user can create a baseline experiment.
- A new user can derive a second experiment from the baseline.
- A user can change hyperparameters, model structure, layer selection, or
  reusable training behavior without cloning the whole codebase.
- A user can make deployment-targeted changes for accelerated, FPGA, and CPU
  targets without rewriting earlier experiments.
- A user can run experiments locally.
- A user can compare results across experiments without digging through git
  history.
- The same resolved child-run contract can later be used for Azure.

Canonical IDs: REQ-001, REQ-002, REQ-003, REQ-009, REQ-011, REQ-012

## Mental Model

There are six important concepts in this project:

- `template`
  - `experiments/000_template/`
  - Global schema root and lowest-level defaults
  - Never runnable directly
- `base experiment`
  - A versioned, immutable root for a family of experiments
  - Example: `100_accelerated_base_v1`, `200_fpga_base_v1`, or
    `300_cpu_base_v1`
- `derived experiment`
  - A tracked folder in a repo that extends a base or another experiment
  - Owns the specific hypothesis under test
- `batch run`
  - One launch of one experiment
  - Expands into one child run per dataset in `dataset_targets`
- `child run`
  - One concrete training job for one dataset, such as `numbers` or `fashion`
- `shared implementation`
  - Reusable Python orchestration and reusable C++ LibTorch modules
  - Experiments configure these pieces; they do not fork them

The key machine-facing distinction is:

- the authored experiment folder is for humans
- the resolved child run is the transferable execution contract used locally or
  on a remote node

Canonical IDs: REQ-001, REQ-002, CON-001, CON-003

## Architecture

The maintainable split is:

- Python owns authored config loading, inheritance resolution, dataset
  expansion, policy checks, batch planning, artifact bookkeeping, and future
  Azure submission
- C++ with LibTorch owns one resolved child run at a time
- shared Python domain contracts define the in-memory shapes used across
  `check`, `resolve`, `run_local`, `compare`, and later Azure submission
- versioned artifact serializers own `resolved_config.toml`,
  `run_manifest.json`, and `summary.json`
- launch gating lives in one shared policy layer rather than being repeated in
  each command

Canonical IDs: REQ-002, REQ-007, REQ-008, REQ-009, CON-003, CON-005

## Planned Repository Layout

```text
CNNWorkbench/
├── .github/
│   └── workflows/
├── README.md
├── plan.md
├── pyproject.toml
├── compose.yaml
├── .devcontainer/
│   └── devcontainer.json
├── docker/
│   └── workbench.Dockerfile
├── experiments/
│   ├── 000_template/
│   │   ├── experiment.toml
│   │   └── notes.md
│   ├── 100_accelerated_base_v1/
│   │   ├── experiment.toml
│   │   └── notes.md
│   ├── 101_accelerated_baseline/
│   │   ├── experiment.toml
│   │   └── notes.md
│   ├── 200_fpga_base_v1/
│   │   ├── experiment.toml
│   │   └── notes.md
│   ├── 300_cpu_base_v1/
│   │   ├── experiment.toml
│   │   └── notes.md
│   └── 201_fpga_baseline/
│       ├── experiment.toml
│       └── notes.md
├── configs/
│   ├── datasets.toml
│   ├── libtorch.lock.toml
│   ├── matrices/
│   └── schemas/
│       └── datasets_catalog.schema.json
├── datasets/
├── references/
├── reports/
├── third_party/
│   └── libtorch/
│       ├── linux-cuda/
│       ├── linux-cpu/
│       ├── macos-cpu/
│       └── macos-mps/
├── build/
│   ├── linux-cuda/
│   │   └── bin/
│   ├── linux-cpu/
│   │   └── bin/
│   ├── macos-cpu/
│   │   └── bin/
│   └── macos-mps/
│       └── bin/
├── src/cnn_workbench/
│   ├── cli/
│   ├── bootstrap/
│   ├── domain/
│   ├── policies/
│   ├── check/
│   ├── compare/
│   ├── datasets/
│   ├── doctor/
│   ├── resolve/
│   ├── runs/
│   ├── scaffold/
│   └── artifacts/
├── cpp/
│   ├── layers/
│   ├── losses/
│   ├── main/
│   ├── math/
│   ├── models/
│   ├── optimizers/
│   ├── registries/
│   ├── schedulers/
│   └── train_loops/
├── tests/
└── runs/
```

`datasets/`, `third_party/`, `build/`, and `runs/` are local runtime areas and
should be ignored by git. `configs/`, `references/`, `reports/`, and
`.github/workflows/` are tracked.

## Sharing And Promotion

The upstream `experiments/` tree is intentionally curated.

- Most experiment-only work should stay in a branch or fork by default.
- Share experiment work by linking the repo, commit, experiment folder, and
  compare or report output in GitHub discussions, issues, or Discord.
- Open upstream pull requests mainly for reusable Python or C++ changes, docs,
  tests, new maintained bases, or explicitly requested promoted experiments.
- `new_experiment` allocates the next id in the repo you are currently using.
  Fork-local ids are local; a promoted experiment may be renumbered when it is
  merged upstream.
- Use `metadata.owner` as a stable GitHub handle or organization label when an
  experiment is meant to be shared outside a private workspace.
- GitHub pull requests compare one branch against upstream. Other experiment
  branches can stay in the fork and do not have to be merged upstream.

## Requirements

The accelerated CUDA-path requirements are:

- Docker Engine or Docker Desktop with the Compose plugin
- a supported CUDA-backed Docker runtime for Phase 1 training
  - the canonical path is Linux or WSL with NVIDIA GPU access
- `uv` available inside the workbench container or Dev Container

The accelerated MPS-path requirements are:

- Apple Silicon macOS host
- Python 3.10+
- `uv`
- CMake 3.26+
- a C++17-capable compiler
- a compatible PyTorch and LibTorch MPS stack verified by `doctor`

The CPU native-host requirements are:

- Python 3.10+
- `uv`
- CMake 3.26+
- a C++17-capable compiler
- a compatible LibTorch and runtime stack verified by `doctor`

The initial datasets are:

- `numbers` = MNIST digits
- `fashion` = Fashion-MNIST

## Compatibility And Preflight

Docker and Dev Container serve different roles:

- Docker is the canonical runtime contract for local accelerated CUDA build and
  training.
- A Dev Container is the recommended editor/debugger workflow when you want to
  step through Python orchestration, attach debuggers, or keep local tooling in
  sync with the CUDA runtime.
- The Dev Container should point at the same Dockerfile or Compose service,
  rather than defining a second environment.
- MPS acceleration on Apple Silicon should use the native macOS host path, not
  the Docker or Dev Container path.

Phase 1 has six practical environment states:

- supported accelerated CUDA environment
  - can scaffold, resolve, compare, and train through Docker or the Dev
    Container
- supported accelerated MPS environment
  - can scaffold, resolve, compare, and train from the native macOS host
- supported CPU training environment
  - can scaffold, resolve, compare, and train from the native host after
    `doctor` confirms the required runtime stack
- supported compatible native-host training environment
  - can scaffold, resolve, compare, and train from the native host after
    `doctor` confirms the required runtime stack
- authoring-only environment
  - can scaffold, resolve, compare, and prepare datasets
  - cannot launch canonical training
- incompatible environment
  - must fail before build or training starts

The intended behavior is that `doctor` reports which state you are in before a
long build or a failed training launch. It should identify the detected
platform, whether accelerated or CPU training is available, whether CUDA or MPS
is available, whether Docker, Dev Container, or native host mode is in use, and
the next concrete fix when something is missing. It should also make clear when
an accelerated short request would fall back to CPU.

Command notation used below:

- if you are using the CUDA Docker path, enter the workbench shell first and
  then run the same `uv run ...` commands shown later
- if you are using a CUDA Dev Container, run the same commands from the
  container terminal inside your editor
- if you are using the native macOS MPS path, run the same commands directly on
  the host after `doctor` passes
- if you are using a CPU native-host path, run the same commands directly after
  `doctor` passes

## Quick Start

This is the intended first-run flow once the project is implemented.

### 1. Enter the supported environment and run preflight checks

CUDA Docker path:

```bash
docker compose build workbench
docker compose run --rm workbench bash
uv run python -m cnn_workbench.cli.doctor
```

Native macOS MPS path:

```bash
uv run python -m cnn_workbench.cli.doctor
```

Expected behavior:

- The command reports whether you are in a supported accelerated CUDA
  environment, a supported accelerated MPS environment, a supported CPU
  training environment, a supported compatible native-host environment, an
  authoring-only environment, or an incompatible environment.
- The command reports detected Python, compiler, CMake, Docker, CUDA, MPS, CPU,
  and LibTorch compatibility details.
- The command reports whether `train_runtime = "accelerated"` would resolve to
  CUDA or MPS, and whether a short local run would fall back to CPU.
- Failures explain what is missing before build or training begins.

Recommended development workflow:

- use Docker directly when you only need reproducible CUDA CLI execution
- use the Dev Container when you want the same CUDA environment plus
  editor-based debugging and stepping
- use the native host path when you want Apple Silicon MPS acceleration
- use the native host CPU path when you want explicit CPU training or
  one-image-at-a-time experimentation
- if `doctor` reports a supported accelerated or CPU-capable training state,
  continue to workspace bootstrap and training
- if `doctor` reports `authoring-only`, you may still scaffold, check, resolve,
  compare, and prepare datasets, but you should skip `build` and `run_local`
- if `doctor` reports `incompatible`, stop and fix the reported environment
  issue before proceeding

### 2. Bootstrap the workspace when training is available

```bash
uv sync
uv run python -m cnn_workbench.cli.build
```

Expected behavior:

- Python dependencies are installed.
- The build step rechecks critical compatibility assumptions before doing heavy
  work.
- The correct LibTorch package is downloaded for the current platform into an
  environment-scoped root such as `third_party/libtorch/linux-cuda/`,
  `third_party/libtorch/macos-mps/`, or `third_party/libtorch/macos-cpu/`.
- The selected LibTorch package comes from the project-wide lock file at
  `configs/libtorch.lock.toml`, and the archive is checksum-verified before
  extraction.
- The C++ trainer is configured and built into an environment-scoped output such
  as `build/linux-cuda/bin/cnnwb_train` or `build/macos-cpu/bin/cnnwb_train`.
- The canonical trainer target is `cnnwb_train`.
- Rebuilds are fingerprint-based. Config-only experiment changes do not rebuild
  the C++ binary, but changes to tracked C++, CMake, toolchain, lock-file, or
  artifact-schema inputs do.

If `doctor` reports `authoring-only`, run only:

```bash
uv sync
```

Then continue with `new_experiment`, `check`, `resolve`, `compare`, and
`prepare_datasets`. Do not run `build` or `run_local` from that state.

### 3. Scaffold a new experiment from the correct base

Accelerated-target example:

```bash
uv run python -m cnn_workbench.cli.new_experiment \
  --parent 100_accelerated_base_v1 \
  --slug wider_model
```

FPGA-target example:

```bash
uv run python -m cnn_workbench.cli.new_experiment \
  --parent 200_fpga_base_v1 \
  --slug int8_shift_activation
```

CPU-target example:

```bash
uv run python -m cnn_workbench.cli.new_experiment \
  --parent 300_cpu_base_v1 \
  --slug cpu_debug_profile
```

Expected behavior:

- The launcher picks the next available experiment id in the same track in the
  current repo checkout.
- A new folder is created under `experiments/`.
- `experiment.toml` is created with `experiment.id`, `experiment.name`, and
  `experiment.extends`.
- `experiment.toml` includes commented starter blocks for common overrides such
  as `model.stage*`, `train`, and `short_run`.
- `notes.md` is created from a template with sections for hypothesis, parent,
  fields under test, run plan, expected signal, and outcome.

Ids are repo-local. If a fork-owned experiment is promoted upstream, the
upstream repo assigns the next available id in that track before merge.

Example generated file:

```toml
[experiment]
id = "102_accelerated_wider_model"
name = "Accelerated Wider Model"
extends = "100_accelerated_base_v1"
kind = "experiment"

# Common override snippets:
# [model.stage2]
# out_channels = 96
#
# [short_run]
# max_items = 5000
```

### 4. Author only the fields under test

For simple model structure changes, update only the relevant stage or training
section. Do not copy the full parent config into the child experiment.

Example:

```toml
[experiment]
id = "102_accelerated_wider_model"
name = "Accelerated Wider Model"
extends = "100_accelerated_base_v1"
kind = "experiment"

[model.stage2]
out_channels = 96
```

### 5. Check and resolve before running

```bash
uv run python -m cnn_workbench.cli.check \
  --experiment 102_accelerated_wider_model \
  --run-profile short

uv run python -m cnn_workbench.cli.resolve \
  --experiment 102_accelerated_wider_model \
  --run-profile short \
  --diff-from-parent
```

Expected behavior:

- `check` validates the inheritance chain, dataset targets, run-profile
  eligibility, and git-policy rules before launch.
- JSON-capable validation output uses a top-level `errors` array whose entries
  contain `code`, `path`, `severity`, `message`, and optional `hint`.
- Python resolves the full inheritance chain.
- Dataset metadata is merged into one resolved child config per dataset.
- The resolved configs are printed for inspection without creating a batch.
- Preview output uses deterministic placeholder ids such as
  `batch_id = "preview"` and `child_id = "preview_01_numbers"`.
- `--diff-from-parent` shows the minimal authored overrides alongside the fully
  resolved child configs.
- When `--run-profile short` is used, the output includes the expanded
  `short_run.eval_items` schedule.
- `resolve` stays pure by default. If dataset metadata is missing, it reports
  that clearly and you can run `prepare_datasets` first or opt into
  `resolve --ensure-datasets`.

`resolve` is part of the normal author workflow, not a debugging-only command.

### 6. Run a short batch first

```bash
uv run python -m cnn_workbench.cli.run_local \
  --experiment 102_accelerated_wider_model \
  --run-profile short
```

Use `short` for early feedback on new configs or shared-code changes before a
canonical full run. `run_local` should rerun the same blocking checks as
`check` before it launches the batch. If `train_runtime = "accelerated"` is
requested and no accelerated backend is available, short local runs may fall
back to CPU with a warning. Canonical full runs should fail until CPU is
explicitly selected. If the trainer binary or LibTorch bootstrap artifacts are
missing or stale, `run_local` should trigger the same bootstrap/build flow
automatically before launch.

### 7. Commit in your branch or fork, then run the canonical full batch

Normal workflow:

1. Create the experiment folder in your current repo or fork.
2. Make any shared-code change needed for new reusable layers, losses, train
   loops, or FPGA-compatible math.
3. Run `check`.
4. Run `resolve`.
5. Run `short`.
6. Commit the experiment folder and any required shared-code change together in
   your branch or fork so the run is reproducible.
7. If the change adds reusable project behavior, open an upstream PR with the
   reusable code, docs, and tests. Keep experiment-only history in the fork
   unless the experiment is being promoted.
8. Run the full batch from a clean tree.

Full runs should default to a clean git tree. A dirty-tree override should be
explicit, and the run manifest should always record the commit, dirty flag, and
saved patch files.

### 8. Compare results

```bash
uv run python -m cnn_workbench.cli.compare \
  --experiments 100_accelerated_base_v1 102_accelerated_wider_model
```

Expected behavior:

- Results are grouped by dataset.
- `short` and `full` runs are never mixed silently.
- Deployment-target, requested-runtime, resolved-backend, and fallback metadata
  are surfaced so accelerated, CPU, and FPGA-targeted runs are not confused.
- The comparison view answers whether the new experiment improved, regressed,
  or should become the next base.

## Base Hierarchy And Tracks

The hierarchy is:

- `000_template`
  - global schema root
  - not runnable
- `100_accelerated_base_v1`
  - canonical base for accelerated-target deployment
- `200_fpga_base_v1`
  - canonical base for FPGA-targeted deployment
- `300_cpu_base_v1`
  - canonical base for CPU-targeted deployment
- derived experiments
  - extend a base or another experiment in the same track

In the upstream repo, this hierarchy is curated rather than exhaustive.

Suggested track bands:

- `100` series = accelerated-target deployment
- `200` series = FPGA-targeted deployment
- `300` series = CPU-targeted deployment

Example hierarchy:

```text
000_template
├── 100_accelerated_base_v1
│   ├── 101_accelerated_baseline
│   ├── 102_accelerated_wider_model
│   └── 110_accelerated_base_v2
│       └── 111_accelerated_alt_activation
├── 200_fpga_base_v1
│   ├── 201_fpga_baseline
│   ├── 202_fpga_shift_activation
│   └── 210_fpga_base_v2
│       └── 211_fpga_quant_block_sweep
└── 300_cpu_base_v1
    ├── 301_cpu_baseline
    └── 302_cpu_debug_profile
```

When a broad improvement should become common for future work, create a new base
version instead of editing the older base. That keeps historical experiments
valid without reconstructing old behavior from git history.

## How To Change Behavior

There are five expected levels of change.

### 1. Change only training settings

Use `experiment.toml` when changing:

- epochs
- batch size
- optimizer selection
- optimizer hyperparameters
- scheduler selection
- seed
- validation split
- checkpoint cadence

Use `train_runtime`, not a second per-experiment device flag, when changing the
training runtime. If a run belongs on a different deployment target, start from
a different base or create a new base version.

### 2. Change model composition through config

Use `experiment.toml` when selecting different reusable modules by name or
changing stage-level structure.

The authored config should use named stage tables, not raw layer arrays, so a
child experiment can override one stage without copying the rest of the
architecture.

Example:

```toml
[model]
backbone = "staged_cnn"
head = "linear_head"
block = "conv_bn_relu"
norm = "batch_norm"
activation = "relu"
width = 32
depth = 2
dropout = 0.10

[model.stage1]
out_channels = 32
blocks = 2
pool = "max2"

[model.stage2]
out_channels = 64
blocks = 2
pool = "max2"
```

### 3. Change reusable training behavior through config

Training behavior is not limited to optimizer and scheduler. The documented
config surface should include reusable sections such as:

- `[loss]`
- `[train_loop]`
- `[quantization]`
- `[deployment]`

Example:

```toml
[loss]
name = "cross_entropy"
label_smoothing = 0.0

[train_loop]
name = "supervised_classifier"
precision = "amp"
gradient_accumulation_steps = 1
grad_clip_norm = 0.0
freeze_backbone_epochs = 0

[quantization]
mode = "none"

[deployment]
export_profile = "none"
validate_target_inference = false
```

### 4. Add new reusable shared components

When config is not enough, add shared code instead of embedding one-off code in
an experiment folder.

Expected workflow:

1. Add the new reusable component in shared C++ code.
2. Register it in the relevant registry.
3. Expose its parameters in the documented schema.
4. Reference it by name from the experiment config.
5. Create a new experiment that selects it.

Likely component families:

- backbones and heads
- blocks, layers, and nodes
- losses
- train loops
- optimizers and schedulers
- low-level math and quantization primitives

### 5. Change the underlying math

If you need to change the actual numeric behavior of a node, activation,
quantizer, or normalization rule, treat it as shared framework work:

- implement it in shared code
- test it directly
- expose it through registries and config
- create an experiment that selects it

The FPGA track is the main example of this level. It may need INT8 quantized
weights, fake quantization with STE, shift activations, barrel-shift
normalization, or other hardware-compatible math from the inspiration project.

## Deployment Base Defaults

`100_accelerated_base_v1` should own defaults for:

- `runtime.train_runtime = "accelerated"`
- `track.deploy_target = "accelerated"`
- `track.constraints_profile = "accelerated_default"`
- `quantization.mode = "none"`
- `deployment.export_profile = "none"`

`200_fpga_base_v1` should own defaults for:

- `runtime.train_runtime = "accelerated"`
- `track.deploy_target = "fpga"`
- `track.constraints_profile = "fpga_int8_v1"`
- inspiration-profile defaults needed for 8-bit FPGA compatibility

`300_cpu_base_v1` should own defaults for:

- `runtime.train_runtime = "cpu"`
- `track.deploy_target = "cpu"`
- `track.constraints_profile = "cpu_default"`
- `quantization.mode = "none"`
- `deployment.export_profile = "none"`

The FPGA base is where inspiration-project rules belong. That includes shared
defaults such as:

- INT8-oriented quantization behavior
- power-of-2 or shift-based activation choices
- barrel-shift or other FPGA-compatible normalization choices
- deployment/export checks for the FPGA target

Child experiments inherit the deployment target from the base. They should not
switch from accelerated-target to FPGA-targeted or CPU-targeted deployment
partway through an `extends` chain. If you need a new common target pattern,
create a new base version.

## Dataset Preparation

`dataset_targets` refers to logical dataset ids from `configs/datasets.toml`,
not hardcoded trainer flags.

The dataset catalog is versioned. `configs/datasets.toml` carries a top-level
`[schema]` table with `catalog_version = "1.0.0"`, and the tracked schema
reference lives at `configs/schemas/datasets_catalog.schema.json`.

Dataset preparation helpers should live under `src/cnn_workbench/datasets/`, not
as a second set of standalone root-level scripts.

The intended behavior is:

1. Resolve the dataset id from the catalog.
2. Read cached runtime metadata when it is already present.
3. If files or metadata are missing, report that state clearly.
4. `prepare_datasets`, `run_local`, or `resolve --ensure-datasets` may run the
   configured Python prepare entrypoint.
5. Read runtime metadata such as `input_channels` and `num_classes`.
6. `resolve` uses that metadata to print complete preview configs without
   creating a batch.
7. `run_local` starts training only after preparation succeeds.

Dataset preparation should be automatic and idempotent during `run_local`. The
explicit helper is:

```bash
uv run python -m cnn_workbench.cli.prepare_datasets numbers fashion
```

Use that command when you want to prepare datasets ahead of time without
launching training.

`resolve` stays pure by default and only prepares datasets when
`--ensure-datasets` is explicitly requested.

Dataset cache reuse requires both valid `metadata.json` and the configured
sentinel marker when one is defined. Phase 1 dataset metadata is strict:
`metadata.json` contains exactly `input_channels` and `num_classes`.

## Short Runs

Short runs are a separate run profile, not extra validation mixed into the
normal full-run epoch loop.

Use `short` when you want early feedback after the first few hundred or few
thousand training items without paying for a full canonical run.

The intended default is that short runs are enabled in the template with a sane
Fibonacci-based schedule so a newly scaffolded experiment can use `--run-profile
short` immediately.

Author-facing options should include:

- `short_run.enabled`
- `short_run.max_items`
- `short_run.schedule`
- `short_run.base_items`
- `short_run.explicit_eval_items`

The intended default schedule is Fibonacci multiples of `base_items`, expanded
by Python into explicit milestone counts before calling the trainer.

## Run Artifacts

Each launch should write a parent batch under:

```text
runs/<experiment_id>/<batch_id>_<execution_mode>_<run_profile>/
```

`execution_mode` should be `local` for local launches and `azure` for future
remote launches. `resolve` uses `execution_mode = "preview"` without creating a
batch folder.

Each child run should always include:

- `experiment_source.toml`
- `resolved_config.toml`
- `run_manifest.json`
- `summary.json`

`train.log` exists only when the trainer process actually launches. Pre-trainer
failures still write `experiment_source.toml`, `resolved_config.toml`,
`run_manifest.json`, and `summary.json`.

Successful child runs should also include:

- `metrics.csv`
- `checkpoints/best.pt`
- `checkpoints/last.pt`

The purpose of this layout is to answer, without digging through git history:

- what was run
- on which dataset
- with which resolved settings
- from which code state
- what result it produced

Persisted runtime artifacts are versioned. Semantic-version compatibility
applies to runtime artifacts such as `resolved_config.toml`, `run_manifest.json`,
and `summary.json`; authored `experiment.toml` stays on the current supported
schema and is not treated as a backward-compatible artifact format.

## Reproducibility And Git Discipline

Within a given repo, each experiment folder is tracked source of truth. Runtime
output is not. The upstream repo intentionally contains only curated bases,
examples, and promoted experiments.

Normal author workflow:

1. Scaffold from the correct base in your current repo or fork.
2. Edit only the config fields under test.
3. Make any shared-code change needed for new reusable behavior.
4. Run `check`.
5. Run `resolve`.
6. Run a `short` batch.
7. Commit the experiment folder and shared code together in your branch or
   fork.
8. Run the canonical `full` batch.
9. Compare against the parent base or prior experiment.

Every child run should save:

- the raw `experiment_source.toml`
- the resolved child config
- source repo URL when available
- git commit
- git dirty status
- any saved patch files for dirty runs

That is the mechanism that prevents experiments from being lost while still
making fork-shared runs traceable.

## Comparison And Test Expectations

Comparison should stay dataset-aware, profile-aware, and deployment-track-aware:

- never silently mix `short` and `full`
- never silently collapse `numbers` and `fashion`
- clearly label accelerated-target, CPU-targeted, and FPGA-targeted runs
- clearly label requested runtime, resolved backend, and CPU-fallback runs

FPGA-targeted comparisons use two tiers of validation:

- shared smoke validation checks export, load, inference-artifact presence, and
  target compatibility
- promotion-grade FPGA decisions add a hardware gate covering export operator
  whitelist compatibility, quantization or calibration validity, latency budget
  compliance, and resource or utilization budget compliance when hardware
  reports it

Implementation work should include contract tests for:

- scaffolding and base-version creation
- inheritance and track validation
- train-runtime versus deploy-target separation
- dataset preparation idempotency
- short-run milestone resolution
- artifact production
- comparison behavior across datasets, profiles, tracks, and fallback states

## Planned CLI Surface

These are the intended commands:

```bash
uv run python -m cnn_workbench.cli.doctor
uv run python -m cnn_workbench.cli.build
uv run python -m cnn_workbench.cli.new_experiment --parent 100_accelerated_base_v1 --slug wider_model
uv run python -m cnn_workbench.cli.new_experiment --parent 200_fpga_base_v1 --slug int8_shift_activation
uv run python -m cnn_workbench.cli.new_experiment --parent 300_cpu_base_v1 --slug cpu_debug_profile
uv run python -m cnn_workbench.cli.new_experiment --parent 100_accelerated_base_v1 --slug accelerated_base_v2 --kind base
uv run python -m cnn_workbench.cli.check --experiment 102_accelerated_wider_model --run-profile short
uv run python -m cnn_workbench.cli.resolve --experiment 102_accelerated_wider_model --run-profile short --diff-from-parent
uv run python -m cnn_workbench.cli.run_local --experiment 102_accelerated_wider_model
uv run python -m cnn_workbench.cli.run_local --experiment 102_accelerated_wider_model --run-profile short
uv run python -m cnn_workbench.cli.compare --experiments 100_accelerated_base_v1 102_accelerated_wider_model
uv run python -m cnn_workbench.cli.prepare_datasets numbers fashion
```

Command expectations:

- `doctor` verifies environment compatibility and reports actionable fixes.
- `build` uses environment-scoped bootstrap and build roots so Docker CUDA and
  native-host artifacts do not overwrite each other.
- `build` uses the project-wide LibTorch lock file, verifies archive checksums,
  and rebuilds only when the build fingerprint changes.
- `new_experiment` scaffolds the folder, config, and notes template using the
  next available id in the current repo track.
- `new_experiment` also includes commented starter overrides for common edits.
- `check` is the normal pre-run validation step.
- `resolve` is the normal pre-run inspection step and stays pure unless
  `--ensure-datasets` is requested.
- `run_local` resolves, prepares datasets, launches the batch, and writes
  artifacts.
- `run_local` reruns the same blocking checks as `check`.
- `run_local` may fall back from requested accelerated training to CPU only for
  short local runs, and that fallback must remain visible in artifacts.
- `compare` reads completed batch artifacts only.
- `prepare_datasets` prepares named datasets without launching training.

The C++ trainer should stay narrow:

```bash
cnnwb_train --resolved-config <path> --output-dir <path>
```

## Task Aliases And CI

Optional task aliases should stay thin wrappers over the canonical Python CLI
entrypoints. The intended examples are:

```bash
make build
make check EXPERIMENT=102_accelerated_wider_model
make test
make compare EXPERIMENTS="100_accelerated_base_v1 102_accelerated_wider_model"
```

The minimum tracked CI surface is at least one workflow under
`.github/workflows/` that runs `make test`.

Canonical IDs: REQ-008, CON-008, R3, R9

## Documentation Review Checklist

Before implementation, this README should still feel correct to a new user:

- Can a user tell which base to extend?
- Is it obvious when to create a new base version instead of editing an old
  base?
- Are the supported CUDA-container and native-MPS paths clear enough that
  environment problems fail in `doctor` instead of deep in the build?
- Is the CPU training path clear enough for one-image-at-a-time experimentation?
- Is `resolve` clearly part of the normal workflow?
- Is `check` clearly part of the normal workflow?
- Is it obvious when config is enough and when shared C++ code is required?
- Is training behavior covered by named config sections instead of implied code
  edits?
- Is the runtime source of truth clear enough that a user is not choosing both a
  training runtime and a separate device flag?
- Is the deploy-target model called out explicitly enough for accelerated, CPU,
  and FPGA targets?
- Is the commit workflow clear enough that experiments are not lost?

If the answer to any of these is no, update `plan.md` first, then update this
README, and only then implement code.

Now also confirm the canonical planning layer is still aligned:

- did the changed rule update the relevant `REQ-*`, `CON-*`, `ASM-*`, `UNK-*`,
  or `R*` entry first?
- if the rationale changed, did the related ADR change too?
- did `plans/trace/trace.csv` and `plans/trace/coverage.md` stay current?

Canonical IDs: REQ-014, REQ-015, REQ-018, ACC-007, CON-009
