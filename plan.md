# CNN Workbench Plan

This project uses one canonical LibTorch training runner. Local execution comes
first, and Azure pipeline support comes second without changing the core runner
contract. The design goal is to keep the same experiment model, resolved run
shape, and output artifacts whether training is launched on a laptop or
submitted to Azure.

Delivery sequencing lives in `plan-stages.md`. Detailed per-stage plans live
under `plans/stages/`. This file stays focused on the full target design and
contracts.

## Core Decisions

- Experiments are config-first, not per-experiment C++ subclasses.
- The Python-resolved child config is the single source of truth for runtime
  defaults, inheritance, dataset selection, and environment-specific values.
- CUDA-capable Windows/Linux environments should use Docker as the canonical
  local execution path so host toolchain differences fail early and
  reproducibly.
- A Dev Container should sit on top of the same Docker image or Compose service
  when interactive editor-based debugging is needed for the CUDA path.
- Apple Silicon MPS development should use a native macOS path rather than the
  Docker path.
- Native host execution is optional and must pass the same preflight checks as
  the containerized path before build or training.
- `000_template` is the global schema root and is never runnable.
- The workbench has three common versioned base roots:
  - `100_accelerated_base_v1` for accelerated-target deployment.
  - `200_fpga_base_v1` for FPGA-targeted deployment.
  - `300_cpu_base_v1` for CPU-targeted deployment.
- Finished experiments and finished bases are immutable.
- When a broad discovery should become common for future work, create a new base
  version instead of editing the old base.
- Python handles orchestration, batching, scaffolding, dataset preparation, and
  comparison.
- C++ handles one resolved child training job at a time.
- Operator-facing commands should fail with actionable diagnostics rather than
  low-context toolchain errors.
- Full runs validate at epoch boundaries only.
- Optional short runs validate at item milestones and stop early.
- Python expands short-run schedule math into explicit milestone counts so the
  C++ trainer does not own Fibonacci or escalation logic.
- Reproducibility uses tracked experiment folders plus git state capture, not
  per-run source snapshots.
- Canonical full runs should come from a clean git tree by default. Dirty-tree
  full runs require an explicit override.
- Phase 1 training supports `cpu` and `accelerated` runtime intent.
- `accelerated` is a logical runtime intent that resolves to CUDA in supported
  NVIDIA environments and MPS on supported Apple Silicon environments.
- CPU training is a valid first-class path for short runs, local debugging, and
  one-image-at-a-time experimentation intended to approximate FPGA-oriented
  training constraints.
- If `train_runtime = "accelerated"` is requested and no accelerated backend is
  available, short or explicit local debug runs may fall back to CPU with a
  warning. Canonical full runs must fail unless CPU was explicitly requested.
- Unsupported platforms may still scaffold, resolve, compare, and prepare
  datasets, but `doctor` and `check` should make it explicit when local
  training is unavailable.

## Repository Shape

- `pyproject.toml`
  - Python dependencies and `uv` entrypoints.
- `compose.yaml`
  - canonical local container entrypoint for reproducible authoring and
    training.
- `docker/`
  - Dockerfiles and helper assets for the local workbench container image.
- `.devcontainer/`
  - recommended editor/debugger entrypoint that attaches to the same canonical
    Docker environment.
- `Makefile`
  - optional task aliases for common developer workflows such as `doctor`,
    `build`, `check`, `test`, and example local runs.
- `scripts/`
  - project-owned bootstrap entrypoints for initial setup
  - `bootstrap.sh` for macOS and Linux
  - `bootstrap.ps1` for Windows
  - responsible for installing `uv` when missing, installing or selecting the
    project Python via `uv`, running `uv sync`, and printing the next required
    `doctor` or `build` step for the detected environment
- `experiments/`
  - Git-tracked experiment definitions.
- `configs/datasets.toml`
  - Shared dataset catalog keyed by logical dataset name.
- `configs/matrices/`
  - optional tracked sweep definitions for repeatable parameter matrices.
- `datasets/`
  - Ignored local dataset storage such as `datasets/numbers/`.
- `references/`
  - tracked external design notes, inspiration links, and target-specific
    compatibility references that inform shared implementation choices.
- `reports/`
  - tracked or generated comparison summaries, experiment review notes, and
    promotion recommendations for new base versions.
- `third_party/`
  - Ignored local bootstrap dependencies such as
    `third_party/libtorch/<platform_tag>/`.
- `build/`
  - Ignored local CMake output such as
    `build/<platform_tag>/bin/cnnwb_train`.
- `src/cnn_workbench/`
  - Python orchestration package for bootstrap, scaffolding, resolve, local run,
    comparison, and later Azure submission.
  - `cli/`
    - thin entrypoints only
  - `domain/`
    - shared typed contracts for authored experiments, resolved child runs,
      batch plans, environment reports, and comparison inputs
  - `bootstrap/`
    - environment-scoped LibTorch bootstrap, CMake build orchestration, and
      build-root selection
  - `policies/`
    - reusable preflight, environment-gating, and git-policy verdicts consumed
      by `doctor`, `build`, `check`, and `run_local`
  - `doctor/`
    - environment detection, compatibility checks, and actionable diagnostics
  - `check/`
    - experiment validation, run-profile validation, and parent-diff summaries
  - `scaffold/`
    - experiment and base scaffolding logic
  - `resolve/`
    - pure inheritance, merge, validation, and resolved child-config generation
  - `datasets/`
    - dataset catalog lookup, metadata loading, optional
      `ensure_dataset()` preparation, and dataset-owned prepare helpers
  - `runs/`
    - batch expansion, queue execution, artifact writing, and failure handling
  - `compare/`
    - dataset-aware, profile-aware, and deployment-track-aware summaries
  - `artifacts/`
    - versioned artifact schemas plus TOML/JSON read-write helpers for
      resolved configs, manifests, summaries, and compare inputs
  - future Azure submission module
    - translates shared resolved child-run contracts into Azure jobs without
      redefining experiment semantics
- `cpp/`
  - Shared LibTorch training code and binary entrypoint.
- `tests/`
  - Contract tests for orchestration, schema validation, and trainer-facing
    resolved configs.
- `.github/workflows/`
  - CI smoke tests for the Python orchestration layer, schema validation, and
    non-accelerated contract checks.
- `runs/`
  - Ignored runtime artifacts for parent batch runs and child dataset runs.

Recommended `cpp/` layout:

- `cpp/layers/`
  - reusable layers and blocks
- `cpp/losses/`
  - reusable loss builders
- `cpp/math/`
  - low-level reusable numeric primitives such as quantizers, shift activations,
    barrel-shift normalization helpers, or other target-specific math
- `cpp/models/`
  - backbone and head implementations
- `cpp/optimizers/`
  - optimizer builders
- `cpp/registries/`
  - registry declarations and registration helpers
- `cpp/schedulers/`
  - scheduler builders
- `cpp/train_loops/`
  - reusable training-loop implementations
- `cpp/main/`
  - binary entrypoint and explicit registration bootstrap

## Shared Domain Model

The plan should make the Python-side contract types explicit so the same run
semantics are not reimplemented in every command.

Required shared models:

- `ExperimentConfig`
  - typed representation of one authored `experiment.toml`
- `DatasetSpec`
  - dataset catalog entry plus discovered runtime metadata
- `ResolvedChildRun`
  - one fully resolved experiment plus one dataset plus one run profile
- `BatchPlan`
  - ordered collection of `ResolvedChildRun` items for one launch
- `EnvironmentReport`
  - detected environment facts and capability flags from `doctor`
- `LaunchVerdict`
  - reusable preflight and policy decision returned by `policies/`
- `RunManifest`
  - typed metadata for one executed child run
- `CompareInput`
  - normalized artifact-backed input shape used by the comparison layer

Ownership rules:

- `check`, `resolve`, `runs`, `compare`, and future Azure submission should all
  depend on the same domain contracts rather than passing raw nested dicts
- the resolved child run is the machine-facing unit of execution
- the authored experiment folder remains the human-facing source of truth
- one distributed node or local worker should receive one `ResolvedChildRun`,
  not a partially resolved authored experiment

## Build And Bootstrap

Phase 1 bootstrap is split into environment verification, Python dependency
install, and a project-owned build step:

- initial contributor setup should use project-owned wrapper scripts rather than
  assuming one universal shell entrypoint across all platforms
  - `scripts/bootstrap.sh` is the canonical bootstrap path for macOS and Linux
  - `scripts/bootstrap.ps1` is the canonical bootstrap path for Windows
  - there is no requirement to maintain one shell script that runs unchanged on
    Windows, macOS, and Linux because PowerShell and POSIX shell setup are
    materially different
- the bootstrap wrappers should:
  - install `uv` with the official platform installer when `uv` is missing
  - use `uv` to install or select the project Python toolchain
  - run `uv sync`
  - print the correct next action for the environment, typically `doctor`
    followed by `build` on train-capable hosts
  - stop short of pretending compiler, Docker, CUDA, or MPS requirements are
    solved if they are not; those remain `doctor`-validated prerequisites

- `docker compose build workbench`
  - builds the canonical local container image
- `uv run python -m cnn_workbench.cli.doctor`
  - verifies host or container compatibility before any expensive build work
- `uv sync`
  - installs Python dependencies from `pyproject.toml`
- `uv run python -m cnn_workbench.cli.build`
  - downloads the correct LibTorch package into
    `third_party/libtorch/<platform_tag>/`
  - configures the C++ trainer with CMake
  - builds the trainer binary at `build/<platform_tag>/bin/cnnwb_train`
  - reuses existing bootstrap artifacts when possible instead of redownloading
    or rebuilding blindly
  - keeps CUDA-container and native-host bootstrap artifacts separate so one
    environment does not clobber another
  - reruns critical compatibility checks and fails with actionable remediation if
    the current environment cannot support the requested training runtime

## Supported Local Environments

Phase 1 should document the supported runtime paths clearly:

- Accelerated CUDA path
  - Docker container on a supported Linux or WSL host with NVIDIA GPU access
  - Docker Compose available
  - NVIDIA Container Toolkit or equivalent GPU passthrough configured
- Recommended interactive development path for accelerated CUDA
  - Dev Container attached to the same Dockerfile or Compose service used by the
    CUDA path
  - used for stepping through Python orchestration code, attaching C++ debuggers,
    and keeping editor tooling aligned with the runtime environment
- Accelerated MPS path
  - native macOS host on Apple Silicon
  - PyTorch and LibTorch configured for MPS-backed execution on the host
  - no Docker or Dev Container dependency for accelerated training
- CPU training path
  - native host with a compatible Python, compiler, CMake, and LibTorch stack
  - intended for explicit CPU runs and accelerated-fallback short/debug runs
- Authoring-only path
  - unsupported training hosts may still scaffold, resolve, compare, and prepare
    datasets
  - `doctor` must report this explicitly instead of allowing a confusing build
    or training failure later

`doctor` should report at least:

- whether the current process is running in the CUDA container path, the Dev
  Container, or the native host
- whether accelerated training is available
- whether CUDA is available
- whether MPS is available
- whether CPU training is available
- detected Python, CMake, compiler, Docker, CUDA, MPS, CPU, and LibTorch runtime
  details
- whether the selected LibTorch package matches the environment
- which concrete backend `train_runtime = "accelerated"` would resolve to in the
  current environment
- whether an accelerated request would fall back to CPU for short/debug runs
- clear next actions when a requirement is missing or incompatible

Command gating after `doctor`:

- supported accelerated or CPU-capable states may run `uv sync`,
  `build`, `new_experiment`, `check`, `resolve`, `run_local`, `compare`, and
  `prepare_datasets`
- authoring-only states may run `uv sync`, `new_experiment`, `check`,
  `resolve`, `compare`, and `prepare_datasets`, but must not run `build` or
  `run_local`
- incompatible states stop until the reported environment issue is fixed

## Preflight And Policy Ownership

Environment capability checks and launch policy should live in one reusable
module rather than being re-derived independently in each CLI command.

Required policy responsibilities:

- evaluate the current `EnvironmentReport`
- apply command-specific capability gates such as authoring-only versus
  train-capable states
- enforce git cleanliness rules for short and full runs
- validate whether the requested run profile is launchable
- return one structured `LaunchVerdict` containing blocking errors, warnings,
  and next actions

Command usage rules:

- `doctor` produces the canonical `EnvironmentReport`
- `build`, `check`, and `run_local` consume the same `policies/` logic instead
  of keeping separate copies of capability rules
- `run_matrix` reuses the same launch-policy path as `run_local`
- command-specific messaging may differ, but the policy decision must come from
  one source of truth

Dev Container guidance:

- the Dev Container should reuse the same Dockerfile or Compose service as the
  CUDA execution path rather than defining a second environment
- Docker is the CUDA execution contract
- the Dev Container is the preferred developer experience for debugging inside
  the CUDA path
- the Dev Container is not the primary acceleration path for Apple MPS; native
  macOS remains the MPS development path

## Experiment Hierarchy

Each tracked experiment lives in its own folder:

- `experiments/<experiment_id>/experiment.toml`
- `experiments/<experiment_id>/notes.md`

`experiment.kind` values:

- `template`
  - only valid for `000_template`
  - never runnable
- `base`
  - versioned root for a family of experiments
  - may be runnable if it defines a full configuration
- `experiment`
  - normal derived experiment

Recommended root examples:

- `000_template`
- `100_accelerated_base_v1`
- `200_fpga_base_v1`
- `300_cpu_base_v1`

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

Rules:

- `experiment.id` must equal the folder name.
- `000_template` is reserved and not directly runnable.
- Every tracked experiment, including bases, requires `notes.md`.
- Derived experiments should be minimal override files. Do not copy the full
  parent config into a child experiment.
- Finished experiments are immutable.
- Finished bases are immutable.
- A new common pattern should become a new base version, not a patch to an old
  base.

## Deployment Track Model

The deployment track is inherited from the base root and stays stable through
the chain. Training runtime is selected separately.

Required `track` fields:

- `deploy_target`
  - `accelerated`, `fpga`, or `cpu`
- `constraints_profile`
  - named target profile such as `accelerated_default`, `fpga_int8_v1`, or
    `cpu_default`

Required runtime selection:

- `train_runtime`
  - `cpu` or `accelerated`

Track rules:

- `100_accelerated_base_v1` owns the accelerated-target defaults.
- `200_fpga_base_v1` owns the FPGA-targeted defaults.
- `300_cpu_base_v1` owns the CPU-targeted defaults.
- Non-base child experiments inherit `track` from the parent chain and must not
  switch deployment target mid-chain.
- If you want to move from accelerated-target deployment to FPGA-targeted or
  CPU-targeted deployment, start from the corresponding base or create a new
  base version.
- `train_runtime` is selected independently for authoring, resolution, and run
  policy. It does not redefine the inherited deployment track.
- a base may provide a default `train_runtime`, but that default remains a
  runtime choice rather than part of the deployment-track identity.

## Inheritance And Merge Semantics

Inheritance is a single linear chain, for example:

- `111_accelerated_alt_activation -> 110_accelerated_base_v2 -> 100_accelerated_base_v1 -> 000_template`

Merge rules:

- Tables merge recursively by key.
- Scalar values replace inherited values.
- Arrays replace inherited arrays as a whole.
- Absent keys inherit from the parent.
- Empty arrays clear an inherited list.
- Unknown sections or keys are validation errors.
- Circular inheritance is a validation error.
- Missing parents are validation errors.

Important authoring rule:

- Authored experiment configs should not use raw ordered layer arrays to define
  architecture because array replacement breaks the minimal-override design.
- Use named stage tables such as `[model.stage1]`, `[model.stage2]`, and
  `[model.stage3]` in source experiment files.
- The resolved config may materialize explicit stage order or layer arrays if
  that simplifies trainer construction, because inheritance no longer applies at
  runtime.

These rules apply identically for local and Azure launch paths.

## Scaffolding Workflow

Phase 1 should include a project-owned experiment scaffolder:

```bash
cnn_workbench.cli.new_experiment --parent 100_accelerated_base_v1 --slug wider_model
```

Required behavior:

- validates the parent experiment exists
- infers the track from the parent
- chooses the next available experiment id in the same track
- creates `experiments/<id>/`
- writes `experiment.toml`
- writes commented starter override blocks for common edits such as `train`,
  `model.stage*`, and `short_run`
- writes `notes.md` from a template

Recommended notes template sections:

- hypothesis
- parent
- fields under test
- run plan
- expected signal
- actual outcome

Additional scaffold mode:

```bash
cnn_workbench.cli.new_experiment --parent 100_accelerated_base_v1 --slug accelerated_base_v2 --kind base
```

This creates a new base version derived from the previous base when a discovery
should become the new common root for future experiments.

## Phase 1 Author Config Surface

The canonical Phase 1 authored schema is:

- `[experiment]`
  - `id`
  - `name`
  - `extends`
  - `kind`
- `[metadata]`
  - `tags`
  - `status`
  - `owner`
- `[runtime]`
  - `train_runtime`
    - `cpu` or `accelerated`
- `[track]`
  - normally authored only in `base` experiments
  - `deploy_target`
  - `constraints_profile`
- `[batch]`
  - `dataset_targets`
  - `stop_on_failure`
- `[model]`
  - `backbone`
  - `head`
  - `block`
  - `norm`
  - `activation`
  - `width`
  - `depth`
  - `dropout`
- `[model.stage1]`, `[model.stage2]`, `[model.stage3]`, ...
  - `enabled`
  - `out_channels`
  - `blocks`
  - `stride`
  - `pool`
- `[optimizer]`
  - `name`
  - `learning_rate`
  - `weight_decay`
- `[scheduler]`
  - `name`
- `[loss]`
  - `name`
  - `label_smoothing`
- `[train]`
  - `epochs`
  - `batch_size`
  - `seed`
  - `val_split`
- `[train_loop]`
  - `name`
  - `precision`
  - `gradient_accumulation_steps`
  - `grad_clip_norm`
  - `freeze_backbone_epochs`
- `[checkpoint]`
  - `save_best`
  - `save_last`
  - `save_every_epochs`
- `[initialization]`
  - `mode`
  - `checkpoint_source`
  - `load_optimizer_state`
  - `load_scheduler_state`
  - `strict_model_load`
- `[short_run]`
  - `enabled`
  - `max_items`
  - `schedule`
  - `base_items`
  - `explicit_eval_items`
- `[quantization]`
  - `mode`
  - `weight_bits`
  - `activation_bits`
  - `fake_quant`
- `[deployment]`
  - `export_profile`
  - `validate_target_inference`

The goal is to keep common experiment work inside config even when the user is
changing:

- optimizer behavior
- loss behavior
- checkpoint initialization behavior
- train-loop behavior
- stage-level model structure
- quantization strategy
- deployment-target constraints

Runtime source-of-truth rule:

- `runtime.train_runtime` is the authoritative execution intent for training
- authored experiments should not also choose a separate `train.device`
- Python may derive trainer-facing backend arguments from `runtime`, but the
  authored config should expose only one runtime selector

## Canonical Roots And Defaults

### `000_template`

`000_template` is the global schema root and lowest-level default source:

```toml
[experiment]
id = "000_template"
name = "Template"
kind = "template"

[metadata]
tags = []
status = "template"
owner = ""

[runtime]
train_runtime = "accelerated"

[batch]
dataset_targets = ["numbers", "fashion"]
stop_on_failure = true

[model]
backbone = "staged_cnn"
head = "linear_head"
block = "conv_bn_relu"
norm = "batch_norm"
activation = "relu"
width = 32
depth = 2
dropout = 0.0

[model.stage1]
enabled = true
out_channels = 32
blocks = 2
stride = 1
pool = "max2"

[model.stage2]
enabled = true
out_channels = 64
blocks = 2
stride = 1
pool = "max2"

[optimizer]
name = "adam"
learning_rate = 0.001
weight_decay = 0.0

[scheduler]
name = "none"

[loss]
name = "cross_entropy"
label_smoothing = 0.0

[train]
epochs = 5
batch_size = 128
seed = 42
val_split = 0.2

[train_loop]
name = "supervised_classifier"
precision = "fp32"
gradient_accumulation_steps = 1
grad_clip_norm = 0.0
freeze_backbone_epochs = 0

[checkpoint]
save_best = true
save_last = true
save_every_epochs = 0

[initialization]
mode = "scratch"
checkpoint_source = ""
load_optimizer_state = false
load_scheduler_state = false
strict_model_load = true

[short_run]
enabled = true
max_items = 10000
schedule = "fibonacci"
base_items = 250
explicit_eval_items = []

[quantization]
mode = "none"
weight_bits = 32
activation_bits = 32
fake_quant = false

[deployment]
export_profile = "none"
validate_target_inference = false
```

Optimizer documentation requirement:

- document `adam` as the default public optimizer for the repo
- place the implementation in a dedicated shared class, not in a model-specific
  or inspiration-specific codepath
- explain in the plan and eventual repo docs how a user changes
  `optimizer.name` and optimizer hyperparameters in `experiment.toml`
- note directly in the class documentation that the baseline behavior is
  effectively copied from `torch.optim.Adam`

### `100_accelerated_base_v1`

The accelerated base owns the shared defaults for accelerated-target
deployment:

```toml
[experiment]
id = "100_accelerated_base_v1"
name = "Accelerated Base v1"
extends = "000_template"
kind = "base"

[runtime]
train_runtime = "accelerated"

[track]
deploy_target = "accelerated"
constraints_profile = "accelerated_default"
```

### `200_fpga_base_v1`

The FPGA base owns the shared defaults for FPGA-targeted deployment:

```toml
[experiment]
id = "200_fpga_base_v1"
name = "FPGA Base v1"
extends = "000_template"
kind = "base"

[runtime]
train_runtime = "accelerated"

[track]
deploy_target = "fpga"
constraints_profile = "fpga_int8_v1"

[model]
activation = "shift_activation"
norm = "barrel_shift_norm"

[quantization]
mode = "qat_int8"
weight_bits = 8
activation_bits = 8
fake_quant = true

[deployment]
export_profile = "fpga_int8_v1"
validate_target_inference = true
```

### `300_cpu_base_v1`

The CPU base owns the shared defaults for CPU-targeted deployment:

```toml
[experiment]
id = "300_cpu_base_v1"
name = "CPU Base v1"
extends = "000_template"
kind = "base"

[runtime]
train_runtime = "cpu"

[track]
deploy_target = "cpu"
constraints_profile = "cpu_default"
```

`fpga_int8_v1` is the named compatibility profile for the inspiration project
path under `inspiration_sources/FPGAResNet18-LibTorch/`. The exact shared-code
implementation may grow, but the profile is where common FPGA rules live. It is
the correct place for shared defaults such as:

- INT8 quantized weights
- fake quantization with straight-through estimation
- shift-style activations
- barrel-shift or other FPGA-compatible normalization
- export or validation behavior required for the target

Optimizer policy for the FPGA track:

- use the same public `adam` optimizer path by default unless there is a clear
  reason to introduce a track-specific optimizer
- do not make an inspiration-project optimizer the default public choice for
  this repo
- if an FPGA-only optimizer is introduced later, document it as an advanced or
  internal experiment path rather than the main learning-oriented default

## Resolution Contract

The configuration boundary is:

1. the `000_template` defaults and the experiment `extends` chain
2. the selected tracked experiment id
3. the dataset catalog entry for the child run
4. explicit CLI overrides

Python resolves those inputs into one fully materialized child config per
dataset child run. The resolved child config is the only configuration file
consumed by the C++ trainer.

Python contract rules:

- `resolve/` should produce typed `ResolvedChildRun` instances first
- TOML serialization into `resolved_config.toml` is an artifact concern owned by
  `artifacts/`, not the primary in-memory model
- `runs/` should execute a `BatchPlan` built from `ResolvedChildRun` items
- future Azure submission should reuse the same `BatchPlan` and
  `ResolvedChildRun` contracts used locally

### Resolved Config Format

- File format: TOML
- File name inside each child run: `resolved_config.toml`
- C++ CLI: `cnnwb_train --resolved-config <path> --output-dir <path>`

Required resolved sections:

- `[experiment]`
  - `id`
  - `name`
  - `extends`
  - `kind`
  - `batch_id`
  - `child_id`
  - `execution_mode`
  - `run_profile`
- `[metadata]`
  - `tags`
  - `status`
  - `owner`
- `[runtime]`
  - `train_runtime`
  - `resolved_backend`
    - `cpu`, `cuda`, or `mps`
  - `fallback_applied`
- `[track]`
  - `deploy_target`
  - `constraints_profile`
- `[dataset]`
  - `name`
  - `root`
  - `prepare_entrypoint`
  - `sentinel` if configured
  - `input_channels`
  - `num_classes`
- `[model]`
  - `backbone`
  - `head`
  - `block`
  - `norm`
  - `activation`
  - `width`
  - `depth`
  - `dropout`
  - `stage_order`
- `[model.stage1]`, `[model.stage2]`, ...
  - stage parameters after inheritance resolution
- `[optimizer]`
  - `name`
  - `learning_rate`
  - `weight_decay`
- `[scheduler]`
  - `name`
- `[loss]`
  - `name`
  - `label_smoothing`
- `[train]`
  - `epochs`
  - `batch_size`
  - `seed`
  - `val_split`
- `[train_loop]`
  - `name`
  - `precision`
  - `gradient_accumulation_steps`
  - `grad_clip_norm`
  - `freeze_backbone_epochs`
- `[checkpoint]`
  - `save_best`
  - `save_last`
  - `save_every_epochs`
- `[initialization]`
  - `mode`
  - `checkpoint_source`
  - `load_optimizer_state`
  - `load_scheduler_state`
  - `strict_model_load`
- `[quantization]`
  - `mode`
  - `weight_bits`
  - `activation_bits`
  - `fake_quant`
- `[deployment]`
  - `export_profile`
  - `validate_target_inference`
- `[short_run]` when `experiment.run_profile = "short"`
  - `max_items`
  - `eval_items`

The resolved config may include additional metadata later, but these sections
are the minimum contract for Phase 1.

Execution-mode rules:

- `execution_mode = "preview"` for `resolve`
- `execution_mode = "local"` for `run_local`
- `execution_mode = "azure"` for future Azure submission
- launched artifact folders use only `local` or `azure`

Preview-resolution rules:

- `resolve` should accept `--run-profile full|short` so preview output matches
  the profile the user plans to launch
- preview resolution does not create a batch folder
- preview resolution uses deterministic placeholders such as
  `batch_id = "preview"` and `child_id = "preview_01_numbers"`
- preview resolution should stay pure by default and read dataset metadata
  without mutating the workspace
- if dataset metadata is missing, plain `resolve` should report that clearly and
  instruct the user to run `prepare_datasets` or opt into
  `resolve --ensure-datasets`
- `resolve --ensure-datasets` may invoke the same idempotent dataset-prepare
  path used by `run_local` when dataset metadata is missing
- preview resolution should surface resolved initialization state clearly so a
  user can verify whether the run starts from scratch, resumes a checkpoint, or
  fine-tunes from pretrained weights before launching the trainer
- preview resolution should surface the requested training runtime, resolved
  backend, and whether a CPU fallback would occur before launch
- when `--run-profile short` is requested, preview output must include the
  fully expanded `short_run.eval_items`
- `resolve --diff-from-parent` should show the authored override delta alongside
  the fully resolved child configs so users can review both the minimal source
  change and the effective runtime contract

## Run Metadata And Tags

Machine-readable metadata complements `notes.md`; it does not replace it.

Required Phase 1 metadata fields:

- `metadata.tags`
  - string list for filtering and comparison, such as `["baseline", "fpga",
    "qat", "shortlist"]`
- `metadata.status`
  - short workflow state such as `planned`, `active`, `complete`, `promoted`,
    or `template`
- `metadata.owner`
  - optional author or maintainer label

Rules:

- tags should be lightweight labels, not long freeform notes
- tags are inherited like other config fields, but child experiments may replace
  the full tag list to keep intent explicit
- `notes.md` remains the place for hypothesis, narrative reasoning, and outcome
  analysis
- `compare` should be able to display experiment tags and optionally filter on
  them later without changing the artifact contract
- `run_manifest.json` and `summary.json` should include resolved tags so run
  artifacts remain searchable even if an experiment is later superseded

## Resume And Fine-Tune Contract

Phase 1 should define checkpoint initialization explicitly so Python and the
LibTorch trainer share one contract.

Author-facing config uses:

- `initialization.mode`
  - `scratch`, `resume`, or `finetune`
- `initialization.checkpoint_source`
  - path to a checkpoint artifact or a symbolic run reference resolved by Python
- `initialization.load_optimizer_state`
  - usually `true` for `resume`, usually `false` for `finetune`
- `initialization.load_scheduler_state`
  - usually `true` for `resume`, usually `false` for `finetune`
- `initialization.strict_model_load`
  - whether missing or extra model keys are treated as errors

Semantics:

- `scratch` starts from newly initialized weights and ignores checkpoint fields
- `resume` continues the same training job semantics from an earlier checkpoint,
  including optimizer and scheduler state when available
- `finetune` loads model weights from a checkpoint but starts a new training job
  with new run identity and fresh optimizer or scheduler state unless explicitly
  overridden
- Python resolves symbolic checkpoint references into a concrete checkpoint path
  before invoking the trainer
- the resolved child config is the only initialization contract passed to the
  C++ trainer; Python should not pass a second ad hoc checkpoint flag that can
  drift from the resolved config

Validation rules:

- `resume` and `finetune` require a resolvable checkpoint source
- `resume` should fail if the checkpoint is incompatible with the resolved model
  shape or required optimizer state
- `finetune` may allow partial model loads when
  `initialization.strict_model_load = false`
- a resumed run creates a new child run folder with its own manifest and must
  record the source checkpoint it resumed from

Trainer responsibilities:

- the LibTorch trainer reads initialization settings from
  `resolved_config.toml`
- it loads model weights and optional optimizer or scheduler state according to
  the resolved initialization mode
- it fails fast with actionable diagnostics when checkpoint loading is
  impossible or incompatible

## Dataset Catalog Contract

The shared dataset catalog lives in `configs/datasets.toml` and defines the
logical datasets available to experiments.

Implementation location rule:

- dataset prepare helpers belong under `src/cnn_workbench/datasets/`
- Phase 1 should not rely on standalone root-level download scripts as a second
  competing dataset-preparation path

Required dataset fields:

- `root`
  - local dataset root, for example `datasets/numbers`
- `prepare_entrypoint`
  - Python entrypoint owned by `src/cnn_workbench/datasets/`, using
    `module:function` syntax
- `sentinel`
  - optional completion marker used by `ensure_dataset()`

Runtime metadata such as `input_channels` and `num_classes` should normally be
derived by the Python prepare step and written into the resolved child
config, rather than hardcoded in `configs/datasets.toml`.

Phase 1 persistence contract:

- each dataset prepare step writes `<dataset_root>/metadata.json`
- `metadata.json` must contain at least `input_channels` and `num_classes`
- the resolver reads `metadata.json` and copies those values into
  `resolved_config.toml`
- if preparation succeeds but `metadata.json` is missing or invalid, resolution
  fails

Expected Phase 1 entries:

- `numbers`
  - MNIST digits
- `fashion`
  - Fashion-MNIST

Dataset preparation behavior:

- `ensure_dataset()` is idempotent
- if the dataset is present, preparation is skipped
- if the dataset is missing or `metadata.json` is missing, the configured helper
  is invoked automatically by `run_local`, `run_matrix`, or
  `resolve --ensure-datasets`
- plain `resolve` should stay pure by default and report missing dataset
  metadata rather than mutating the workspace
- `run_local` calls `ensure_dataset()` before each child dataset run starts
- `prepare_datasets` exists for users who want to do the same work explicitly
  before resolve or training
- dataset metadata lookup should be exposed through a shared provider interface
  so `resolve/` and `runs/` reuse the same metadata-loading code without sharing
  download side effects
- local and Azure follow the same dataset preparation contract

## Trainer Contract

The C++ trainer remains narrow:

```bash
cnnwb_train --resolved-config <path> --output-dir <path>
```

The trainer reads only the resolved child config plus the output directory. It
does not reapply experiment inheritance, guess datasets, or maintain a
competing set of behavior defaults.

Runtime rule:

- the trainer should treat `runtime.train_runtime` as the requested training
  intent and `runtime.resolved_backend` as the concrete backend it should use
- it should not interpret a second user-authored device selector from somewhere
  else in the config

Output responsibilities:

- the C++ trainer writes `metrics.csv` directly into `--output-dir`
- Python launches the trainer as a subprocess and tees trainer stdout and stderr
  into the child run's `train.log` while still streaming to the console
- Python writes `summary.json` after process exit using trainer exit state plus
  produced artifacts

### Registry And Factory Pattern

Phase 1 should use one explicit registry per component family rather than
hardcoded string switches spread across the trainer.

Required registry families:

- backbones
- heads
- blocks
- norms
- activations
- losses
- train loops
- optimizers
- schedulers

Optimizer registry note:

- the default registered optimizer should be `adam`, backed by a standalone
  shared class intended to be easy to read and modify
- optimizer registration docs should show contributors how to add a second
  optimizer without changing the trainer loop or hiding behavior inside a model
  path

Recommended pattern:

- each family owns a `static std::unordered_map<std::string, FactoryFn>`
- each factory takes only the typed spec it needs, such as `BackboneSpec`,
  `HeadSpec`, `BlockSpec`, `LossSpec`, `TrainLoopSpec`, `OptimizerSpec`, or
  `SchedulerSpec`
- Python resolves the full child config, but the trainer should slice that into
  narrow family-specific specs before construction so unrelated config fields do
  not leak into every component
- registration happens in one obvious bootstrap path under `cpp/registries/`
- trainer startup fails fast if a requested component is missing

Coupling rule:

- shared C++ components should not depend on the whole parsed config tree when a
  smaller family-specific contract is sufficient
- adding an unrelated config field should not force changes across multiple
  component constructors

### Phase 1 Built-Ins

Phase 1 requires at least these reusable built-ins:

- `staged_cnn`
  - default general-purpose backbone
- `linear_head`
  - standard classifier head
- `conv_bn_relu`
  - default general-purpose block
- `batch_norm`
  - default general-purpose norm
- `relu`
  - default general-purpose activation
- `cross_entropy`
  - default loss
- `supervised_classifier`
  - default train loop
- `adam`
  - default optimizer
- `none`
  - default scheduler

Optimizer exposure rules:

- the repo-default public optimizer should be `adam`
- `adam` should live in a standalone shared class under `cpp/optimizers/`
  rather than being hidden inside a model-specific training path
- the shared `adam` implementation should be written and documented as a
  learning-friendly reference that users can inspect and modify
- optimizer docs should explain how to register and select a different
  optimizer through config without editing the trainer loop
- the `adam` class docs should explicitly state that it is effectively copying
  the behavior of `torch.optim.Adam`, with any intentional deviations called
  out clearly
- inspiration-project optimizer code under
  `inspiration_sources/FPGAResNet18-LibTorch/` may inform private experiments,
  but it should not define the public optimizer surface of this repo

Important relationship:

- built-ins such as `staged_cnn`, `conv_bn_relu`, `batch_norm`, and `relu`
  define reusable implementation families in shared code
- base experiments such as `100_accelerated_base_v1`, `200_fpga_base_v1`, and
  `300_cpu_base_v1` own the
  selected defaults and stage-level structure for a track
- derived experiments should usually change stage tables or named components in
  config, not replace the entire implementation family
- when a broad architecture discovery should become standard for future work,
  create a new base version instead of mutating the old base

The FPGA track may add shared components such as:

- `shift_activation`
- `barrel_shift_norm`
- `qat_int8`
- FPGA-specific blocks or backbones derived from the inspiration profile

These are still shared reusable components, not per-experiment forks.

FPGA-specific optimizer policy:

- the front-facing learning and experimentation path should continue to use
  `adam` as the default optimizer
- the optimizer found in the FPGA inspiration project should not be treated as a
  standard public built-in for this repo
- if an FPGA-only optimizer is needed later, keep it clearly scoped to that
  track and document it as advanced or internal behavior rather than the main
  public default

## Short Run Resolution

Short runs are a separate run profile, not an extra validation mode folded into
normal full-epoch training.

Author-facing config uses:

- `short_run.enabled`
- `short_run.max_items`
- `short_run.schedule`
- `short_run.base_items`
- `short_run.explicit_eval_items`

Resolution rules:

- full runs ignore the `short_run` section entirely
- `--run-profile short` requires `short_run.enabled = true`
- `short_run.max_items` must be a positive integer
- `short_run.max_items` is a soft ceiling: the trainer finishes the current
  batch, then stops once `items_seen >= max_items`
- if `short_run.explicit_eval_items` is non-empty, it is used exactly
- otherwise Python expands `short_run.schedule` plus `short_run.base_items` into
  a strictly increasing `short_run.eval_items` list capped at
  `short_run.max_items`
- Phase 1 only requires `schedule = "fibonacci"`
- `schedule = "fibonacci"` means Fibonacci multiples of `base_items`:
  `1x, 2x, 3x, 5x, 8x, 13x, ...`, filtered to values `<= max_items`
- the trainer consumes only the resolved `short_run.eval_items` list

## Matrix And Sweep Execution

Repeatable parameter sweeps should be first-class, but they should not weaken
the tracked-experiment model.

Design intent:

- tracked experiment folders remain the canonical place for durable hypotheses,
  notes, and promoted results
- matrix or sweep runs are primarily for exploratory work and systematic search
- when a sweep result matters, the winning configuration should be promoted into
  a normal tracked experiment or a new base version

Recommended tracked input:

- `configs/matrices/<name>.toml`
  - defines one base experiment id plus a set of override axes or explicit
    combinations

Recommended CLI:

```bash
cnn_workbench.cli.run_matrix --experiment 101_accelerated_baseline --matrix configs/matrices/wider_search.toml --run-profile short
```

Required behavior:

- Python expands the matrix into multiple resolved child-run batches without
  changing the C++ trainer contract
- each matrix member has a deterministic synthetic variant id derived from the
  base experiment id plus the selected overrides
- each matrix member writes normal run artifacts, including resolved config,
  manifest, logs, metrics, and summary
- matrix runs should default to short profiles unless the operator explicitly
  requests full runs
- matrix expansion must record the exact override set for each member in
  `run_manifest.json`
- matrix expansion should reject ambiguous override collisions and duplicate
  generated variant ids

Promotion rule:

- a matrix result does not become the new long-term source of truth by itself
- after review, a meaningful winner should be scaffolded as a normal tracked
  experiment or promoted into a new base version

## Execution Model

### Local

- accelerated CUDA execution is usually launched inside the project Docker
  container
- when a developer wants editor-integrated stepping or debugger attach for the
  CUDA path, they should prefer opening the repo in the Dev Container backed by
  that same container definition
- accelerated MPS execution is launched from the native macOS host, not the
  Docker container
- CPU execution is launched from the native host and is a supported explicit
  path for short runs, debugging, and one-image-at-a-time experimentation
- local execution resolves one experiment into a parent batch
- that batch expands into ordered child dataset jobs such as `01_numbers` and
  `02_fashion`
- local execution always runs child jobs one at a time
- local concurrency defaults to `1`
- operator commands require an explicit experiment id
- `check --experiment <id>` is the explicit author-facing preflight for config,
  run-profile, dataset, and git-policy validation
- `run_local` should invoke the same validation automatically before launching a
  batch
- if `train_runtime = "accelerated"` is requested and no accelerated backend is
  available, short or explicit local debug runs may fall back to CPU with a
  warning; canonical full runs must fail instead
- before each child dataset run starts, Python calls `ensure_dataset()`

### Git Cleanliness Policy

Short exploratory runs:

- may run from a dirty tree
- must still capture git dirty state and patch files

Canonical full runs:

- should require a clean git tree by default
- may support `--allow-dirty` for exceptional cases
- must always record `git_commit`, `git_dirty`, and saved patch files

This is the primary mechanism that keeps experiments and framework changes from
being lost.

### Failure Policy

The default batch policy is:

```toml
[batch]
stop_on_failure = true
```

For local execution:

- the batch stops on the first failed child run
- remaining queued child runs are marked `not_started`
- no later child run is launched after the first failure

When `stop_on_failure = false`:

- local execution continues launching later child runs even after an earlier
  child fails
- `batch_summary.json.status` becomes `partial` when a batch has both successes
  and failures
- `batch_summary.json.status` remains `failed` when every launched child fails
- `batch_summary.json.status` remains `succeeded` when every launched child
  succeeds

### Azure

Azure is not implemented in Phase 1, but its contract is fixed now:

- Azure submits one child job per dataset child run
- the same experiment definition and resolved child-run contract used locally is
  reused in Azure
- Azure decides actual parallelism based on available cluster capacity
- each Azure child job prepares only the dataset it needs
- after a child run fails, jobs that have not started should not be launched and
  running siblings should receive a cancellation request

## Artifact Contract

Each launched experiment produces a parent batch folder:

- `runs/<experiment_id>/<batch_id>_<execution_mode>_<run_profile>/`

Each child dataset run must include:

- `experiment_source.toml`
- `resolved_config.toml`
- `run_manifest.json`
- `train.log`
- `summary.json`

Successful child runs must also include:

- `metrics.csv`
- `checkpoints/best.pt`
- `checkpoints/last.pt`

Artifact ownership rules:

- `artifacts/` should own versioned schemas plus all TOML/JSON read-write logic
- `resolve/`, `runs/`, `compare/`, and future Azure code should use shared
  artifact serializers instead of open-coded file handling
- every persisted artifact should include a schema version so contract changes
  can be detected explicitly rather than inferred from missing keys

Minimum Phase 1 versioned artifacts:

- `resolved_config.toml`
  - include `schema.resolved_config_version`
- `run_manifest.json`
  - include `schema.run_manifest_version`
- `summary.json`
  - include `schema.summary_version`
- batch summary artifacts
  - include a matching schema version field

`run_manifest.json` minimum fields:

- `experiment_id`
- `batch_id`
- `child_id`
- `dataset`
- `execution_mode`
- `run_profile`
- `tags`
- `train_runtime`
- `resolved_backend`
- `fallback_applied`
- `deploy_target`
- `git_commit`
- `git_dirty`
- `git_patch_paths`
- `initialization_mode`
- `checkpoint_source`

If the run came from a matrix expansion, `run_manifest.json` should also record:

- `matrix_name`
- `matrix_variant_id`
- `matrix_overrides`

`git_patch_paths` lists any non-empty patch files written into the child run
folder, such as `git_diff_working.patch` and `git_diff_staged.patch`.

`metrics.csv` minimum required columns:

- `step_kind`
- `step_index`
- `items_seen`
- `split`
- `loss`
- `accuracy`
- `examples`
- `duration_seconds`

`summary.json` minimum fields:

- `status`
- `dataset`
- `run_profile`
- `steps_completed`
- `items_seen`
- `best_step_kind`
- `best_step_index`
- `best_val_loss`
- `best_val_accuracy`
- `duration_seconds`
- `best_checkpoint`
- `last_checkpoint`
- `tags`
- `train_runtime`
- `resolved_backend`
- `fallback_applied`
- `deploy_target`
- `initialization_mode`
- `checkpoint_source`

## Comparison Contract

The comparison layer is dataset-aware, profile-aware, and deployment-track-aware.

Selection rules:

- `compare --experiments 101_accelerated_baseline` summarizes the latest
  completed full batch for that experiment
- `compare --experiments 100_accelerated_base_v1 102_accelerated_wider_model` compares the
  latest completed full batch from each experiment
- `compare --experiments ... --run-profile short` compares short batches only
- compare output should display experiment tags and initialization mode so a
  resumed or fine-tuned run is not misread as a scratch baseline
- compare output should display requested training runtime, resolved backend,
  fallback state, and deploy target so CPU-fallback short runs are not misread
  as true accelerated runs
- if an experiment has no completed batch, compare errors clearly
- if one experiment is missing a dataset child run that another experiment has,
  compare shows that dataset as missing rather than silently dropping it
- compare does not silently mix `short` and `full`
- compare should surface deployment-track metadata so accelerated-target,
  CPU-targeted, and FPGA-targeted runs are not misread as equivalent targets

Recommended future filter support:

- `compare --tag <tag>` for narrowing reports to a subset of experiments or run
  artifacts
- `compare --matrix <name>` for summarizing a recorded sweep as one table

Comparison output should answer:

- whether accuracy or loss improved
- on which dataset it improved or regressed
- whether training speed changed
- whether a new experiment should become the next base

## Validation And Error Handling

The resolver, scaffolder, and launcher should fail fast on:

- missing `experiment.toml` or `notes.md`
- `experiment.id` and folder-name mismatch
- invalid `experiment.kind`
- unknown or circular `extends`
- `000_template` containing an `extends` field
- `000_template` passed as a runnable experiment id
- unknown dataset ids in `dataset_targets`
- empty `dataset_targets`
- invalid `metadata.tags` types or non-string tag entries
- invalid `initialization.mode`
- `initialization.mode = "resume"` or `"finetune"` without a checkpoint source
- invalid `val_split` outside `(0.0, 1.0)`
- invalid `short_run.max_items`
- unsupported `short_run.schedule`
- `--run-profile short` with `short_run.enabled = false`
- non-increasing `short_run.explicit_eval_items`
- `short_run.explicit_eval_items` values greater than `short_run.max_items`
- invalid matrix definitions, duplicate matrix variant ids, or conflicting
  matrix-generated overrides
- unknown sections or keys
- invalid types for known keys
- authored raw `model.layers` arrays in source experiment configs
- non-base experiments overriding `track`
- cross-track inheritance, such as an accelerated-target chain extending an
  FPGA-targeted base or a CPU-targeted chain extending an accelerated-target
  base
- unsupported local training environments detected by `doctor` or `check`
- requested accelerated training when the current host or container does not
  expose a usable CUDA or MPS backend and CPU fallback is not allowed for the
  requested run type
- full runs launched from a dirty tree without an explicit dirty override

The trainer should fail fast on:

- unknown registered `model.backbone`
- unknown registered `model.head`
- unknown registered `model.block`
- unknown registered `model.norm`
- unknown registered `model.activation`
- unknown registered `loss.name`
- unknown registered `train_loop.name`
- unknown registered `optimizer.name`
- unknown registered `scheduler.name`
- invalid tensor shapes that can be detected before the training loop starts

Failure handling rules:

- `doctor` failures should identify the failed requirement, the detected
  environment, and the next concrete remediation step
- fallback warnings should appear only when accelerated training was requested
  and a short/debug local run resolves to CPU
- `build` failures should preserve the compatibility context that led to the
  failure instead of surfacing only a low-level tool error
- `check` failures should enumerate every blocking experiment issue in one pass
  and report whether the chosen run profile is launchable
- dataset preparation failure marks that child run failed before training starts
- trainer crash marks that child run failed
- the Python layer writes a failure `summary.json` for child runs that fail
  before the trainer can produce normal outputs
- with `stop_on_failure = true`, remaining local child runs become `not_started`
- with `stop_on_failure = false`, remaining local child runs stay eligible to
  run

## Orchestration Boundaries

The Python layer should stay modular. Do not build one giant orchestrator that
owns every responsibility.

Preferred split:

- `cli/`
  - thin entrypoints only
- `domain/`
  - typed shared contracts consumed across orchestration modules
- `bootstrap/`
  - environment-scoped LibTorch bootstrap, CMake build orchestration, and
    build-root selection
- `policies/`
  - reusable launch policy and preflight verdicts
- `doctor/`
  - environment inspection, compatibility reporting, and remediation messages
- `check/`
  - experiment validation, git-policy checks, and parent-diff summaries
- `scaffold/`
  - experiment and base scaffolding
- `resolve/`
  - experiment inheritance, config merge, override application, and resolved
    child-config generation
- `datasets/`
  - dataset catalog lookup and `ensure_dataset()` preparation
- `runs/`
  - batch expansion, queue execution, artifact writing, git-state capture, and
    failure handling
- `compare/`
  - dataset-aware, profile-aware, and deployment-track-aware summaries and
    comparisons
- `artifacts/`
  - versioned serializers and loaders for runtime files
- future Azure submission module
  - translates resolved child runs into Azure jobs without redefining
    experiment, dataset, or artifact semantics

Implementation constraints:

- the same logic should not be reimplemented separately for local and Azure
  flows
- launchers may differ, but resolve, dataset preparation, artifact contracts,
  and child-run semantics should remain shared
- scaffolding, resolution, run orchestration, and comparison should remain
  separate modules even if one CLI command invokes several of them in sequence
- cross-module communication should use typed domain contracts rather than raw
  TOML dicts where practical
- file serialization and deserialization should flow through `artifacts/`
  instead of each module reading and writing runtime files independently
- launch gating should flow through `policies/` instead of each command
  duplicating environment and git checks
- Python remains responsible for experiment expansion, matrix generation,
  checkpoint resolution, and artifact bookkeeping
- the LibTorch C++ binary remains a narrow execution engine that consumes one
  resolved child config at a time

## CLI Surface

Phase 1 Python entrypoints should be:

- `cnn_workbench.cli.doctor`
  - verifies host or container compatibility and emits the canonical
    `EnvironmentReport` used by later policy checks
- `cnn_workbench.cli.build`
  - performs the project-owned LibTorch download and CMake build using
    environment-scoped `third_party/libtorch/<platform_tag>/` and
    `build/<platform_tag>/` roots
  - is valid only when shared launch policy reports a supported training
    environment
- `cnn_workbench.cli.new_experiment --parent <id> --slug <slug> [--kind base|experiment]`
  - creates a new experiment or base folder and writes starter files,
    commented override snippets, and notes scaffolding
- `cnn_workbench.cli.check --experiment <id> [--run-profile full|short]`
  - validates the experiment chain, run-profile eligibility, git policy, and
    dataset targets before launch through shared policy and validation logic
  - may print a concise diff from the parent experiment for review
- `cnn_workbench.cli.resolve --experiment <id> [--run-profile full|short] [--diff-from-parent] [--ensure-datasets]`
  - resolves the requested experiment id into one resolved child config per
    dataset target
  - stays pure by default and reports missing dataset metadata without mutating
    the workspace
  - may prepare missing datasets only when `--ensure-datasets` is explicitly
    requested
  - uses preview placeholders instead of creating a real batch
  - prints the resolved configs to stdout
  - does not create a batch folder or launch training
- `cnn_workbench.cli.run_local --experiment <id> [--run-profile full|short] [--allow-dirty]`
  - runs the same shared preflight validation as `check`
  - resolves the experiment, prepares datasets as needed, launches the batch
  locally, and writes run artifacts
  - may fall back from requested accelerated training to CPU only for
    short/debug local runs, and must record that fallback in runtime artifacts
- `cnn_workbench.cli.run_matrix --experiment <id> --matrix <path> [--run-profile full|short] [--allow-dirty]`
  - expands a tracked matrix definition into multiple concrete run variants
  - resolves each variant through the same Python path used by `run_local`
  - writes normal run artifacts for each variant without changing the trainer
    contract
- `cnn_workbench.cli.compare --experiments <id>... [--run-profile full|short]`
  - reads completed batch artifacts and produces dataset-aware comparisons
- `cnn_workbench.cli.prepare_datasets <dataset_id>...`
  - prepares datasets without creating a batch or launching training

## Developer Task Aliases And CI

Strong experiment repos usually provide one obvious command layer and at least a
small CI safety net. This project should do the same.

Recommended task aliases:

- `make doctor`
  - runs the Python environment check entrypoint
- `make build`
  - runs the project-owned bootstrap and CMake build
- `make check EXPERIMENT=<id>`
  - validates one experiment before launch
- `make test`
  - runs orchestration and schema contract tests
- `make compare EXPERIMENTS="<id> <id>"`
  - runs the comparison entrypoint

Rules:

- task aliases are thin wrappers over the canonical Python CLI entrypoints
- aliases must not introduce a second source of truth for arguments or behavior
- Docker-path examples may provide container-aware aliases, but those aliases
  should still call the same CLI modules after entering the container

CI expectations:

- CI should run Python linting or formatting checks once those tools are chosen
- CI should run orchestration tests that do not require a GPU
- CI should validate example experiment configs and dataset catalog schema
- CI should verify that `resolve` and `check` still satisfy the documented
  artifact and validation contracts
- accelerated-backed training may remain outside normal CI for Phase 1, but contract
  tests must keep the Python-to-C++ interface stable across CPU and accelerated
  runtime selection

## Reports And References

Experiment-heavy repos benefit from a durable place for decision records and
comparison output, especially when multiple runs may lead to a new base version.

Recommended usage:

- `references/`
  - inspiration repos, FPGA-target compatibility notes, and external design
    constraints that shape shared code
- `reports/`
  - generated or curated experiment summaries, comparison tables, and
    recommendations about whether a result should become the next base

Rules:

- `references/` is for durable input context; it should not become a dump of
  copied source trees
- `reports/` is for human-readable summaries derived from run artifacts; it does
  not replace the canonical machine-readable data under `runs/`
- comparison tooling may later gain an option to emit Markdown reports into
  `reports/` without changing the core artifact contract

## Testing Requirements

Phase 1 should include contract tests for the orchestration layer, not just the
trainer binary.

Phase 1 C++ validation strategy:

- the canonical trainer test path is Python-driven binary smoke and integration
  testing against tiny resolved-config fixtures
- a separate C++ unit-test framework is optional later, but it is not required
  to satisfy the Phase 1 contract boundary
- the primary goal is to keep the Python-to-C++ interface stable and observable
  at the actual trainer boundary rather than to maximize internal class-level
  test granularity early

Minimum required coverage:

- `doctor` environment classification and actionable error reporting
- Docker-path versus native-host compatibility detection
- CUDA-path versus native-MPS-path detection
- explicit CPU-path detection and fallback-policy reporting
- experiment id and folder-name matching
- experiment inheritance resolution and merge semantics
- track inheritance and non-base track override rejection
- runtime source-of-truth enforcement so `runtime.train_runtime` is not
  shadowed by a second device selector
- scaffolder behavior and notes template creation
- scaffolder commented override snippets for common edits including `short_run`
- base-version creation workflow
- metadata tag propagation into resolved configs and run artifacts
- requested runtime, resolved backend, deploy target, and fallback recording in
  resolved configs and run artifacts
- dataset catalog lookup and `ensure_dataset()` idempotency
- batch expansion order from `dataset_targets`
- preview resolution placeholders and `--diff-from-parent` output
- resume and fine-tune resolution, validation, and manifest recording
- short-run milestone expansion from author config to resolved `eval_items`
- matrix expansion into deterministic variants and duplicate-id rejection
- local stop-on-failure behavior and `not_started` marking
- dirty-tree recording for short runs
- clean-tree enforcement for canonical full runs
- artifact layout and required manifest files
- metrics and summary schema production
- dataset-aware comparison behavior
- profile-aware comparison behavior so `short` and `full` do not mix silently
- deployment-track-aware comparison behavior so accelerated-target, CPU-targeted,
  and FPGA-targeted runs are clearly labeled
- compare behavior that distinguishes accelerated runs from CPU-fallback runs

The purpose of these tests is to prevent documentation drift, hidden defaults,
and orchestration regressions as the system grows.
