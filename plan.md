# CNN Workbench Plan

This project uses a shared LibTorch training framework with per-experiment
model binaries. Local execution comes first, and Azure pipeline support comes
second without changing the core runner contract. The design goal is to keep
the same experiment model, resolved run shape, and output artifacts whether
training is launched on a laptop or submitted to Azure.

Delivery sequencing lives in `plan-stages.md`. Detailed per-stage plans live
under `plans/stages/`. This file stays focused on the full target design and
contracts.

Planning source of truth:

- canonical atomic rules live in `plans/registers/`
- durable rationale lives in `plans/decisions/`
- verification and coverage links live in `plans/trace/`
- this document remains the narrative architecture and contract explanation

Canonical IDs: REQ-014, REQ-015, REQ-018, CON-005

## Core Decisions

- Experiments are config-first for training and execution behavior, but each
  experiment owns a `model.cpp` that defines its architecture.
- The Python-resolved child config is the single source of truth for runtime
  defaults, inheritance, dataset selection, and environment-specific values,
  but not for model architecture.
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
- The upstream repo is curated. Most experiment-only work should live in
  branches or forks and be shared by link rather than merged upstream by
  default.
- Upstream pull requests should usually carry reusable framework changes, docs,
  tests, new maintained bases, or explicitly requested promoted experiments.
- Experiment ids are authoritative only within the repo that assigns them. When
  a fork-owned experiment is promoted upstream, it may be renumbered to the
  next upstream id in the same track before merge.
- Python handles orchestration, batching, scaffolding, dataset preparation, and
  comparison.
- C++ handles one resolved child training job at a time.
- Operator-facing commands should fail with actionable diagnostics rather than
  low-context toolchain errors.
- Full runs validate at epoch boundaries only.
- Optional short runs validate at item milestones and stop early.
- Python expands short-run schedule math into explicit milestone counts so the
  C++ trainer does not own Fibonacci or escalation logic.
- Reproducibility uses tracked experiment folders in the repo that owns them —
  `experiment.toml`, experiment-owned `model.cpp`, and `notes.md` — plus git
  state capture, not per-run source snapshots.
- Canonical full runs should come from a clean git tree by default. Dirty-tree
  full runs require an explicit override.
- Phase 1 training supports `cpu` and `accelerated` runtime intent.
- `accelerated` is a logical runtime intent that resolves to CUDA in supported
  NVIDIA environments and MPS on supported Apple Silicon environments.
- CPU training is a valid first-class path for short runs, local debugging, and
  one-image-at-a-time experimentation intended to approximate FPGA-oriented
  training constraints.
- If `train_runtime = "accelerated"` is requested and no accelerated backend is
  available, short local runs may fall back to CPU with a
  warning. Canonical full runs must fail unless CPU was explicitly requested.
- Unsupported platforms may still scaffold, resolve, compare, and prepare
  datasets, but `doctor` and `check` should make it explicit when local
  training is unavailable.

Canonical IDs: REQ-001, REQ-002, REQ-003, REQ-007, REQ-013, CON-001, CON-003, CON-004, CON-011, CON-012

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
  - Git-tracked experiment definitions for the current repo.
  - the upstream repo keeps a curated subset of community work rather than
    mirroring every fork
  - each experiment folder contains `experiment.toml`, `model.cpp`, and
    `notes.md`
- `configs/datasets.toml`
  - Shared dataset catalog keyed by logical dataset name.
- `configs/libtorch.lock.toml`
  - project-wide pinned LibTorch version plus expected archive checksums.
- `configs/matrices/`
  - optional tracked sweep definitions for repeatable parameter matrices.
- `datasets/`
  - Ignored local dataset storage such as `datasets/numbers/`.
- `references/`
  - tracked external design notes, inspiration links, and target-specific
    compatibility references that inform shared implementation choices.
- `reports/`
  - tracked or generated comparison summaries, experiment review notes, and
    promotion recommendations for curated upstream experiments and new base
    versions.
- `third_party/`
  - Ignored local bootstrap dependencies such as
    `third_party/libtorch/<platform_tag>/`.
- `build/`
  - Ignored local CMake output such as
    `build/<platform_tag>/<experiment_id>/bin/cnnwb_train`.
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

Canonical IDs: REQ-003, REQ-008, REQ-013, CON-003, CON-005, CON-006, CON-008

## Shared Domain Model

The plan should make the Python-side contract types explicit so the same run
semantics are not reimplemented in every command.

Required shared models:

- `ExperimentConfig`
  - typed representation of one authored `experiment.toml`
  - validates the canonical Phase 1 authored sections:
    `experiment`, `metadata`, `runtime`, `batch`, `optimizer`, `scheduler`,
    `loss`, `train`, `train_loop`, `checkpoint`, `initialization`,
    `short_run`, and `deployment`
  - base experiments also author `track`; derived experiments inherit it
  - all fields are mandatory from Stage 1; no deferred fields
- `ExperimentModelSource`
  - typed metadata for one authored `model.cpp`
  - validates that each tracked experiment has exactly one architecture source
    file alongside `experiment.toml`
- `DatasetSpec`
  - dataset catalog entry plus discovered runtime metadata
- `ResolvedChildRun`
  - one fully resolved experiment plus one dataset plus one run profile
  - validates `run_profile in {"full", "short"}` and
    `execution_mode in {"preview", "local", "azure"}`
- `BatchPlan`
  - ordered collection of `ResolvedChildRun` items for one launch
  - validates at least one child is present
- `EnvironmentReport`
  - detected environment facts and capability flags from `doctor`
  - requires `platform_tag` and `environment_kind`
- `LaunchVerdict`
  - reusable preflight and policy decision returned by `policies/`
  - invariant: `allowed=true` cannot coexist with blocking errors
- `RunManifest`
  - typed metadata for one executed child run, including source-repo
    provenance and optional matrix fields (`matrix_name`,
    `matrix_variant_id`, `matrix_overrides`)
  - validates `train_runtime in {"cpu", "accelerated"}` and
    `resolved_backend in {"cpu", "cuda", "mps"}`
- `CompareInput`
  - normalized artifact-backed input shape used by the comparison layer
  - validates `run_profile` and requires at least one dataset summary

All domain models include a `validate()` method that runs structural checks at
construction time. Models are fully defined in Stage 1 and exercised
incrementally as later stages introduce their callers.

Ownership rules:

- `check`, `resolve`, `runs`, `compare`, and future Azure submission should all
  depend on the same domain contracts rather than passing raw nested dicts
- the resolved child run is the machine-facing unit of execution
- the authored experiment folder remains the human-facing source of truth
- the authored experiment folder includes both training/runtime TOML and the
  sibling `model.cpp` architecture source
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
    followed by `build --experiment <id>` on train-capable hosts
  - stop short of pretending compiler, Docker, CUDA, or MPS requirements are
    solved if they are not; those remain `doctor`-validated prerequisites

- `docker compose build workbench`
  - builds the canonical local container image
- `uv run python -m cnn_workbench.cli.doctor`
  - verifies host or container compatibility before any expensive build work
- `uv sync`
  - installs Python dependencies from `pyproject.toml`
- `uv run python -m cnn_workbench.cli.build --experiment <id>`
  - downloads the correct LibTorch package into
    `third_party/libtorch/<platform_tag>/`
  - configures the C++ trainer with CMake
  - builds the selected experiment binary at
    `build/<platform_tag>/<experiment_id>/bin/cnnwb_train`
  - reuses existing bootstrap artifacts when possible instead of redownloading
    or rebuilding blindly
  - keeps CUDA-container and native-host bootstrap artifacts separate so one
    environment does not clobber another
  - reruns critical compatibility checks and fails with actionable remediation if
    the current environment cannot support the requested training runtime

LibTorch lock and update policy:

- the project uses one project-wide LibTorch lock file at
  `configs/libtorch.lock.toml`; there is no per-experiment LibTorch pinning
- the lock file records the exact LibTorch version and expected SHA256 checksum
  per supported package variant
- `build` and LibTorch bootstrap must verify downloaded archives against the
  tracked checksum before extraction
- `doctor` and `build` may warn when a newer LibTorch release exists, but they
  must never auto-upgrade the pinned project version

CMake and rebuild contract:

- the minimum supported CMake version is `3.26`
- the per-experiment trainer entrypoint remains `cnnwb_train`
- Phase 1 must support at least `Debug`, `RelWithDebInfo`, and `Release`
  build types
- stale-binary detection uses
  `build/<platform_tag>/<experiment_id>/build_fingerprint.json`
- the build fingerprint must include:
  - all `cpp/**` source files
  - the selected experiment's `model.cpp`
  - top-level `CMakeLists.txt` plus any tracked CMake configuration files
  - `platform_tag`, compiler or toolchain identity, and selected build type
  - `configs/libtorch.lock.toml`
  - runtime artifact schema-version constants used by the trainer boundary
- `experiment.toml` training and execution changes must not participate in the
  build fingerprint; TOML-only changes do not trigger a rebuild
- if the stored fingerprint differs from the current fingerprint, `build` must
  reconfigure and rebuild automatically

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
  - intended for explicit CPU runs and accelerated-fallback short runs
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
- whether an accelerated request would fall back to CPU for short runs
- clear next actions when a requirement is missing or incompatible

Environment classification precedence:

1. `CNNWB_ENV_KIND` override takes highest precedence when set
2. `DEVCONTAINER=1` → `dev_container`
3. `CNNWB_CUDA_CONTAINER=1` → `cuda_container`
4. Darwin + arm64/aarch64 + MPS available → `native_macos_mps`
5. CPU available → `native_cpu`
6. Otherwise → `authoring_only`

When both Dev Container and CUDA container markers are set simultaneously, Dev
Container wins because that is the interactive development use case and takes
precedence for environment classification and reporting.

Environment probes use `CNNWB_*` environment variables:

- `CNNWB_SYSTEM`, `CNNWB_MACHINE` for platform identification
- `CNNWB_ENV_KIND` for explicit override
- `CNNWB_CUDA_AVAILABLE`, `CNNWB_MPS_AVAILABLE`, `CNNWB_CPU_AVAILABLE` for
  capability flags
- `CNNWB_CUDA_CONTAINER` for container detection
- `DEVCONTAINER` for Dev Container detection

`platform_tag` format: `{system}_{machine}_{environment_kind}` where system
uses `macos` instead of `darwin` and machine maps `x86_64` to `x64` and
`aarch64` to `arm64`.

Run profiles:

- Only `"short"` and `"full"` are valid run profiles
- `"debug"` is not a formal run profile
- CPU fallback for accelerated requests applies only when
  `run_profile == "short"`

Command gating after `doctor`:

- the policy module defines two explicit command sets:
  `AUTHORING_ONLY_ALLOWED = {"doctor", "new_experiment", "check", "resolve",
  "compare", "prepare_datasets"}` and
  `TRAINING_COMMANDS = {"build", "run_local", "run_matrix"}`
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

Each tracked experiment in a given repo lives in its own folder. That folder
may sit directly under `experiments/` or under optional grouping folders used
only for organization:

- `experiments/<experiment_id>/experiment.toml`
- `experiments/<group>/<experiment_id>/experiment.toml`
- `experiments/<group>/<experiment_id>/notes.md`

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

Optional organization example:

- `experiments/fpga/int8/202_fpga_shift_activation/`
- `experiments/research/wide_models/102_accelerated_wider_model/`

Rules:

- `experiment.id` must equal the leaf folder name.
- `experiment.id` values are repo-unique regardless of grouping path.
- `000_template` is reserved and not directly runnable.
- Every tracked experiment, including bases, requires `notes.md`.
- Every tracked experiment, including bases, requires `model.cpp`.
- Optional grouping folders are organization-only and do not imply deployment
  target, runtime intent, or inheritance behavior.
- Non-base experiments extend a base rather than another non-base experiment.
- Non-base experiments keep an explicit `model.cpp` copied from that base so
  model structure is readable in the experiment itself.
- Finished experiments are immutable.
- Finished bases are immutable.
- A new common pattern should become a new base version, not a patch to an old
  base.

## Upstream Curation, Forks, And Promotion

The upstream `experiments/` tree is curated project history, not a mirror of
every community fork.

Rules:

- Most experiment-only work should happen in a branch or fork by default.
- Community sharing should normally use links to the repo, commit, experiment
  folder, and compare or report output in GitHub discussions, issues, or
  Discord rather than an upstream pull request.
- Upstream pull requests should normally merge reusable Python or C++ changes,
  docs, tests, new maintained bases, or explicitly requested promoted
  experiments.
- GitHub pull requests compare one branch against upstream. Other experiment
  branches may remain in the fork and do not have to be merged upstream.
- Once an experiment is promoted into upstream, it becomes part of the curated
  immutable experiment history and follows the normal immutability rules.

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
- Base versions may extend earlier bases or `000_template`, but non-base
  experiments always extend a base.
- Scaffolded non-base experiments intentionally materialize `model.cpp`
  instead of inheriting architecture only implicitly.

Important authoring rule:

- Authored `experiment.toml` should not define model architecture.
- Use `model.cpp` to make stage composition, dimensions, block counts, and
  quantization choices explicit in source.
- Shared library code defines reusable block internals, connection patterns,
  and low-level math rather than turning TOML into a graph language.
- Later base changes should not silently rewrite the scaffolded `model.cpp` of
  an existing experiment.
- The resolved config excludes model graph structure because inheritance no
  longer applies to compiled architecture at runtime.

These rules apply identically for local and Azure launch paths.

Canonical IDs: REQ-001, REQ-020, REQ-021, REQ-023, CON-013, CON-014, CON-015, CON-018, ADR-0013

## Scaffolding Workflow

Phase 1 should include a project-owned experiment scaffolder:

```bash
cnn_workbench.cli.new_experiment --parent 100_accelerated_base_v1 --slug wider_model
```

Required behavior:

- validates the parent experiment exists
- requires non-base experiments to choose a base parent
- infers the track from the parent
- chooses the next available experiment id in the same track within the current
  repo checkout
- creates `experiments/<id>/`
- leaves grouping folders out of the canonical scaffold contract; contributors
  may later move the experiment folder under organization-only namespaces
  without changing the experiment id
- writes `experiment.toml`
- copies the selected base `model.cpp` into the new experiment so architecture
  is explicit from the start
- writes commented starter override blocks for common non-architecture edits
  such as `train` and `short_run`
- writes `notes.md` from a template

Experiment id allocation rules:

- the track band is `(parent_prefix // 100) * 100`
- for `--kind base`: candidate starts at the next multiple of 10 after the
  current maximum in the band (`((current_max // 10) + 1) * 10`)
- for `--kind experiment`: candidate is `current_max + 1`
- the candidate increments until an unused prefix is found
- gaps in the numbering are consumed by the next scaffold operation in that
  repo
- ids are repo-local and are not globally coordinated across forks
- when a fork-owned experiment is promoted upstream, upstream assigns the next
  available id in that track before merge
- promotion-time renumbering changes the upstream id, not the experiment's
  authored meaning or notes intent

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
- `[deployment]`
  - `export_profile`
  - `validate_target_inference`

The goal is to keep common experiment work inside config even when the user is
changing:

- optimizer behavior
- loss behavior
- checkpoint initialization behavior
- train-loop behavior
- deployment-target constraints

Config boundary rule:

- config is the right place for epochs, dataset targets, runtime intent,
  deployment target, optimizer, scheduler, loss, train-loop, checkpoint, and
  deployment settings
- config is not the place for model graph structure, stage layout, activation
  or normalization selection, quantization settings, or arbitrary
  layer-by-layer graph authoring
- those architecture details stay in `model.cpp` plus the shared C++ library so
  contributors can inspect and modify real model behavior without turning the
  schema into a programming language

Portability boundary test:

- **Forward:** pick up `model.cpp` and the shared C++ library and compile them
  in a production repo against LibTorch only. Any setting the model needs in
  that environment must live in `model.cpp` — it cannot live in TOML because
  TOML stays in the workbench.
- **Inverse:** when you pick up `model.cpp`, are there settings you would need
  to delete because they only made sense during experimentation? Those belong
  in TOML. Learning rate, batch size, dataset targets, and train-loop selection
  are experiment concerns, not model concerns.
- `qat_int8` is the canonical example of a setting that must live in
  `model.cpp`: the bit widths and fake-quant behavior travel to production and
  cannot be separated from the model without breaking it. A `[quantization]`
  TOML section would make the model incomplete without the resolution pipeline.

Per-experiment architecture surface:

- every experiment folder includes `model.cpp`
- `model.cpp` defines stage composition, dimensions, block counts, strides,
  head shape, activation or normalization choices, and quantization behavior
- the shared C++ library provides parameterized building blocks with no magic
  numbers
- `build_model(int64_t input_channels, int64_t num_classes)` takes
  dataset-dependent values as parameters; they are not architecture constants
  and must not be hardcoded — they arrive from the resolved child config's
  `[dataset]` section at trainer build time
- each `model.cpp` should declare a `constexpr std::string_view kExperimentId`
  at file scope; see the provenance note below

Illustrative `model.cpp` shape:

```cpp
#include "cpp/models/heads/linear_head.hpp"
#include "cpp/models/primitives/activations.hpp"
#include "cpp/models/primitives/blocks.hpp"
#include "cpp/models/primitives/norms.hpp"
#include "cpp/models/quantization/qat.hpp"
#include "cpp/models/staged_cnn.hpp"

namespace cnnwb::model {

constexpr std::string_view kExperimentId = "101_accelerated_wider_model";

auto build_model(int64_t input_channels, int64_t num_classes) -> models::CompiledModel {
    using namespace models;

    StagedCnnBuilder model{
        .provenance_id = kExperimentId,
    };

    model.stem(
        conv_bn_relu({
            .in_channels = input_channels,
            .out_channels = 32,
            .kernel_size = 3,
            .stride = 1,
            .padding = 1,
            .norm = batch_norm(),
            .activation = relu(),
        }));

    model.stage(
        make_stage({
            .name = "stage1",
            .in_channels = 32,
            .out_channels = 64,
            .blocks = 2,
            .stride = 1,
            .block = conv_bn_relu,
            .norm = batch_norm,
            .activation = relu,
        }));

    model.stage(
        make_stage({
            .name = "stage2",
            .in_channels = 64,
            .out_channels = 96,
            .blocks = 3,
            .stride = 2,
            .block = conv_bn_relu,
            .norm = batch_norm,
            .activation = relu,
        }));

    model.stage(
        make_stage({
            .name = "stage3",
            .in_channels = 96,
            .out_channels = 256,
            .blocks = 2,
            .stride = 2,
            .block = conv_bn_relu,
            .norm = batch_norm,
            .activation = relu,
        }));

    model.stage(
        make_stage({
            .name = "stage4",
            .in_channels = 256,
            .out_channels = 512,
            .blocks = 2,
            .stride = 2,
            .block = conv_bn_relu,
            .norm = batch_norm,
            .activation = relu,
        }));

    model.head(
        linear_head({
            .in_features = 512,
            .out_features = num_classes,
            .dropout = 0.10,
        }));

    model.quantization(
        qat_int8({
            .weight_bits = 8,
            .activation_bits = 8,
            .fake_quant = true,
            .per_channel_weights = true,
        }));

    return model.build();
}

}  // namespace cnnwb::model
```

Experiment provenance:

The copy-paste mechanism that ships `model.cpp` to production severs the git
history between the workbench repo and the production repo. Once the file is
copied there is no automated link back to the originating experiment.

`kExperimentId` is a compile-time constant that travels with the model. It
compiles into the binary and is visible in any debugger or via `strings`. When
a production engineer asks "where did this model come from?", this constant is
the answer.

Rules:

- every `model.cpp` should declare `constexpr std::string_view kExperimentId`
  at file scope with the experiment's canonical id
- the `StagedCnnBuilder` accepts this as `provenance_id` so it can surface in
  model metadata and checkpoints
- removing `kExperimentId` when copying to production is permitted; retaining
  it is strongly encouraged for traceability
- this is an engineering convention backed by documentation, not enforced by
  `check` or build tooling — the workbench cannot reach into a production repo
  to verify it was kept

Runtime source-of-truth rule:

- `runtime.train_runtime` is the authoritative execution intent for training
- authored experiments should not also choose a separate `train.device`
- Python may derive trainer-facing backend arguments from `runtime`, but the
  authored config should expose only one runtime selector

Canonical IDs: REQ-001, REQ-019, REQ-020, CON-002, CON-013, CON-014

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

[deployment]
export_profile = "none"
validate_target_inference = false
```

The template also carries a `model.cpp` that defines the default staged CNN
architecture used as the starting point for new bases and experiments.

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

[deployment]
export_profile = "fpga_int8_v1"
validate_target_inference = true
```

The FPGA base `model.cpp` changes the shared model composition to use the
FPGA-compatible activation, normalization, and quantization behavior required
by the profile.

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
implementation may grow, but FPGA deploy profiles remain flat explicit named
profiles rather than a hierarchy. The profile is where common FPGA rules live.
It is the correct place for shared defaults such as:

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
consumed by the per-experiment C++ trainer at runtime; model architecture is
already compiled into that binary.

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
- `[deployment]`
  - `export_profile`
  - `validate_target_inference`
- `[short_run]` when `experiment.run_profile = "short"`
  - `max_items`
  - `eval_items`

The resolved config may include additional metadata later, but these sections
are the minimum contract for Phase 1. It does not include model graph
structure, quantization settings, or stage composition because those belong to
the compiled experiment `model.cpp`.

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
- `resolve --ensure-datasets` is all-or-nothing: any dataset preparation failure
  raises an exception and aborts the entire resolution
- preview resolution should surface resolved initialization state clearly so a
  user can verify whether the run starts from scratch, resumes a checkpoint, or
  fine-tunes from pretrained weights before launching the trainer
- preview resolution should surface the requested training runtime, resolved
  backend, and whether a CPU fallback would occur before launch
- preview runtime metadata uses deterministic placeholders before environment
  detection is available: `resolved_backend = "cuda"` and
  `fallback_applied = false` for `accelerated`, `resolved_backend = "cpu"` and
  `fallback_applied = false` for `cpu`
- when `--run-profile short` is requested, preview output must include the
  fully expanded `short_run.eval_items`
- `resolve --diff-from-parent` should show the authored override delta alongside
  the fully resolved child configs so users can review both the minimal source
  change and the effective runtime contract

Diff-from-parent output contract:

- `parent`: parent experiment id
- `child`: child experiment id
- `authored_delta`: flat dict of child's authored keys using dotted-key notation
- `runtime_effect`: dict of `{dotted_key: {parent: value, resolved: value}}`
  for each key whose resolved value differs from the parent's resolved value
- `resolved_children`: list of fully rendered child configs

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
- shared or promoted experiments should set `metadata.owner` to a stable GitHub
  handle or organization label
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
  - symbolic format: `latest:<experiment_id>[:<dataset_name>[:best|last]]`
  - `experiment_id` remains the canonical id even if the experiment folder is
    grouped under organization-only namespaces
  - default dataset: current child's dataset name when omitted
  - default checkpoint: `best` when omitted
  - resolution walks `runs/<experiment_id>/`, selects latest batch dir (sorted),
    finds child dir matching `_<dataset>`, returns
    `checkpoints/<checkpoint_name>.pt`
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
  with new run identity and fresh optimizer or scheduler state
- `finetune` always uses fresh optimizer and scheduler state regardless of the
  `load_optimizer_state` and `load_scheduler_state` flags: the initialization
  mode takes precedence over the load flags and conflicting values are silently
  normalized
- `resume` respects both `load_optimizer_state` and `load_scheduler_state` flags
- Python resolves symbolic checkpoint references into a concrete checkpoint path
  before invoking the trainer
- the resolved child config is the only initialization contract passed to the
  C++ trainer; Python should not pass a second ad hoc checkpoint flag that can
  drift from the resolved config

Checkpoint compatibility criteria:

- `model_state` key must exist in the checkpoint
- when `strict_model_load = true`: `model_backbone` in the checkpoint must
  match the compiled experiment model definition
- when `mode = "resume"` and `load_optimizer_state = true`: `optimizer_state`
  key must exist in the checkpoint
- when `mode = "resume"` and `load_scheduler_state = true`: `scheduler_state`
  key must exist in the checkpoint

Validation rules:

- `resume` and `finetune` require a resolvable checkpoint source
- `resume` should fail if the checkpoint is incompatible with the resolved model
  shape or required optimizer state
- `finetune` may allow partial model loads when
  `initialization.strict_model_load = false`
- a resumed run creates a new child run folder with its own manifest and must
  record the source checkpoint it resumed from

Provenance recording:

- run artifacts store only the resolved absolute checkpoint path, not the
  original symbolic reference
- after resolution, `initialization.checkpoint_source` in the resolved config
  and manifest contains the concrete filesystem path

Multi-dataset resume behavior:

- checkpoint resolution happens per-child in the execution loop
- if one child's checkpoint resolution fails, that child gets `status="failed"`
  with a `checkpoint_validation_failed` error
- the batch continues or stops per `stop_on_failure`
- each dataset's checkpoint is resolved independently

Trainer responsibilities:

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

Catalog schema contract:

- `configs/datasets.toml` includes a top-level `[schema]` table with
  `catalog_version = "1.0.0"`
- the authoritative tracked schema reference for the catalog lives at
  `configs/schemas/datasets_catalog.schema.json`
- changing required fields or field meanings in `configs/datasets.toml`
  requires a catalog-version bump and schema update

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
- `metadata.json` must contain exactly `input_channels` and `num_classes` in
  Phase 1
- the resolver reads `metadata.json` and copies those values into
  `resolved_config.toml`
- if preparation succeeds but `metadata.json` is missing or invalid, resolution
  fails
- additional dataset metadata keys are not part of the Phase 1 contract; adding
  any new keys requires an explicit plan update and, if persisted, a catalog
  schema-version bump

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

Sentinel and repair semantics:

- `ensure_dataset()` uses both `metadata.json` validity and sentinel presence as
  the cache gate: both must be present and valid to skip preparation
- if either `metadata.json` is missing/invalid or the sentinel is missing, the
  prepare function is re-invoked regardless of existing data files (repair in
  place)
- if `metadata.json` is invalid and data files exist, the prepare function
  re-runs idempotently—this is repair, not hard failure
- `resolve --ensure-datasets` uses all-or-nothing semantics: any single dataset
  preparation failure aborts the entire resolution
- `run_local` uses per-child semantics: a dataset preparation failure marks that
  child run as failed with `dataset_prepare_failed` and the batch continues or
  stops per `stop_on_failure`

## Trainer Contract

The C++ trainer remains narrow:

```bash
cnnwb_train --resolved-config <path> --output-dir <path>
```

The trainer reads only the resolved child config plus the output directory. The
selected experiment binary already contains that experiment's `model.cpp` and
the shared C++ model library; it does not reapply experiment inheritance, guess
datasets, or maintain a competing set of behavior defaults.

Input strictness rule:

- the trainer should ignore unknown keys and sections in the resolved config
- it reads only the specific config paths it needs via section/key lookup
- unknown fields pass through silently, providing forward compatibility so
  Python-side config additions do not require trainer changes

Runtime rule:

- the trainer should treat `runtime.train_runtime` as the requested training
  intent and `runtime.resolved_backend` as the concrete backend it should use
- it should not interpret a second user-authored device selector from somewhere
  else in the config

Exit-code semantics:

- `0` = success, training completed and artifacts written
- `2` = validation or configuration error (unknown registered component, shape
  error, initialization error)
- Python treats any non-zero exit code as `status = "failed"`

Output responsibilities:

- the C++ trainer writes `metrics.csv` directly into `--output-dir`
- Python launches the trainer as a subprocess and tees trainer stdout and stderr
  into the child run's `train.log` while still streaming to the console
- Python writes `summary.json` after process exit using trainer exit state plus
  produced artifacts

Checkpoint file schema:

- checkpoint files (`.pt`) use PyTorch serialization in the real implementation
  but must contain these top-level keys:
  - `model_state` (required)
  - `optimizer_state` (required for resume with `load_optimizer_state`)
  - `scheduler_state` (required for resume with `load_scheduler_state`)
  - `model_backbone` (used for strict model load validation)
- `validate_checkpoint_for_mode()` checks these keys to determine compatibility
  before the trainer loads the checkpoint

### Registry And Factory Pattern

Phase 1 should use one explicit registry per component family rather than
hardcoded string switches spread across the trainer.

Required registry families:

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
- model composition helpers may use ordinary shared-library code rather than
  config-facing registries because experiment `model.cpp` files call those
  helpers directly

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
- backbone code should make stage composition obvious rather than hiding model
  shape inside long opaque sequential chains
- block code should make the internal layer order and connection pattern obvious
  enough that contributors can modify block math without searching unrelated
  trainer code
- experiment `model.cpp` files should remain readable production artifacts
  rather than thin wrappers around a second config interpreter

Coupling rule:

- shared C++ components should not depend on the whole parsed config tree when a
  smaller family-specific contract is sufficient
- adding an unrelated config field should not force changes across multiple
  component constructors

### Phase 1 Built-Ins

Phase 1 requires at least these shared model-library primitives:

- `make_stage`
  - reusable stage builder with explicit dimensions and block counts
- `conv_bn_relu`
  - default general-purpose block implementation
- `batch_norm`
  - default general-purpose normalization helper
- `relu`
  - default general-purpose activation helper
- `linear_head`
  - standard classifier head helper

Phase 1 also requires these config-driven runtime built-ins:

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

- shared model primitives such as `make_stage`, `conv_bn_relu`, `batch_norm`,
  and `relu` define reusable implementation in shared code
- base experiments such as `100_accelerated_base_v1`, `200_fpga_base_v1`, and
  `300_cpu_base_v1` own the starting `model.cpp` and training defaults for a
  track
- derived experiments should usually change their copied `model.cpp` or
  training TOML, not replace the shared library
- experiment `model.cpp` files choose how to compose shared primitives, while
  the shared library defines the real block internals and layer order
- when a broad architecture discovery should become standard for future work,
  create a new base version instead of mutating the old base

Canonical IDs: REQ-001, REQ-019, CON-003, CON-013

The FPGA track may add shared components such as:

- `shift_activation`
- `barrel_shift_norm`
- `qat_int8`
- FPGA-specific blocks, stage helpers, or backbones derived from the
  inspiration profile

These are still shared reusable components, not per-experiment forks.

FPGA component reuse rules:

- non-FPGA deploy targets may use FPGA-friendly components
  (`shift_activation`, `barrel_shift_norm`) without validation warnings
- these components are registered globally in the trainer registry
- constraint enforcement only fires for FPGA-profile experiments; other tracks
  are unconstrained about which registered components they select

FPGA profile model:

- FPGA deploy profiles are flat explicit named profiles
- FPGA deploy profiles do not inherit or compose implicitly
- new FPGA profiles are introduced as new full named rule sets rather than
  layered descendants of an existing profile

FPGA fallback policy:

- FPGA-targeted experiments with `train_runtime = "accelerated"` follow the
  same CPU fallback policy as all other tracks
- short runs may fall back to CPU when no CUDA/MPS backend is available
- full runs must fail unless CPU was explicitly requested
- no FPGA-specific fallback override exists

FPGA-specific optimizer policy:

- the front-facing learning and experimentation path should continue to use
  `adam` as the default optimizer
- the optimizer found in the FPGA inspiration project should not be treated as a
  standard public built-in for this repo
- if an FPGA-only optimizer is needed later, keep it clearly scoped to that
  track and document it as advanced or internal behavior rather than the main
  public default

Canonical IDs: REQ-012, CON-010, ADR-0012

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
  notes, and promoted results within a repo
- matrix or sweep runs are primarily for exploratory work and systematic search
- when a sweep result matters, the winning configuration should be promoted into
  a normal tracked experiment or a new base version
- fork-local sweeps and matrix definitions are normal and do not need to be
  merged upstream by default
- upstream should track only curated matrix definitions needed for maintained
  evaluation sets or promotion reproduction

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

Matrix definition schema:

- `name`: optional matrix name; defaults to file stem
- `axes`: dict of `key → [values]` for cartesian product expansion; each axis
  must be a non-empty list
- `variants`: explicit list of `{overrides: {...}}` tables for manual
  combinations
- both `axes` and `variants` may coexist: axes-expanded variants come first,
  then explicit variants are appended
- duplicate override sets are rejected
- at least one variant must result from the expansion

Matrix variant-id algorithm:

- canonical JSON: `json.dumps(overrides, sort_keys=True, separators=(",", ":"))`
- SHA1 hash of canonical JSON, first 10 hex characters
- variant id format: `{base_experiment}__mx_{sha1_hex[:10]}`
- duplicate hash collisions are detected and rejected

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
- `batch_id` uses UTC timestamp format `%Y%m%d%H%M%S`
- batch folder name is `{batch_id}_local_{run_profile}`
- local execution always runs child jobs one at a time
- local concurrency defaults to `1`
- operator commands require an explicit experiment id
- `check --experiment <id>` is the explicit author-facing preflight for config,
  run-profile, dataset, and git-policy validation
- `run_local` should invoke the same validation automatically before launching a
  batch
- `run_local` auto-triggers `ensure_libtorch()` and `build_trainer_binary()`
  before launching training; users do not need to run `build` separately first
- if `train_runtime = "accelerated"` is requested and no accelerated backend is
  available, short local runs may fall back to CPU with a
  warning; canonical full runs must fail instead
- before each child dataset run starts, Python calls `ensure_dataset()`

### Git And Source Provenance Policy

Short exploratory runs:

- may run from a dirty tree
- must still capture git dirty state, source repo url when available, and patch
  files

Canonical full runs:

- should require a clean git tree by default
- may support `--allow-dirty` for exceptional cases
- must always record `git_commit`, `source_repo_url` when available,
  `git_dirty`, and saved patch files

Non-git behavior:

- when `.git` does not exist, git info returns `commit = "nogit"`,
  `source_repo_url = ""`, `dirty = false`, `working_patch = ""`,
  `staged_patch = ""`
- the run proceeds normally with these sentinel values; no warning or failure

This is the primary mechanism that keeps experiments and framework changes from
being lost while still making fork-shared work traceable.

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

Batch status algebra:

- all children `succeeded` → `"succeeded"`
- all launched children `failed` → `"failed"`
- mixed `succeeded` and `failed` → `"partial"`
- all children `not_started` (preflight-only) → `"failed"`
- the return value uses `ok = batch_status in {"succeeded", "partial"}`

Pre-trainer failure artifacts:

- when a child run fails before the trainer launches (dataset prepare failure,
  policy rejection, checkpoint validation failure), Python still writes
  `run_manifest.json` and `summary.json` with `status = "failed"` and the
  `resolved_config.toml`
- `experiment_source.toml` is written before any failure path when the source
  file exists
- `train.log` is only produced when the trainer subprocess actually runs

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

Here `experiment_id` is the canonical experiment id, not a filesystem path.

Each child dataset run must include:

- `experiment_source.toml`
- `resolved_config.toml`
- `run_manifest.json`
- `train.log`
- `summary.json`

Successful child runs must also include:

- `metrics.csv`
- `tensorboard/`
  - Python-generated TensorBoard event logs derived from trainer-written raw
    metrics
- `checkpoints/best.pt`
- `checkpoints/last.pt`

Artifact ownership rules:

- `artifacts/` should own versioned schemas plus all TOML/JSON read-write logic
- `resolve/`, `runs/`, `compare/`, and future Azure code should use shared
  artifact serializers instead of open-coded file handling
- every persisted artifact should include a schema version so contract changes
  can be detected explicitly rather than inferred from missing keys

Artifact schema compatibility policy:

- semantic-version compatibility applies to persisted runtime artifacts only;
  authored `experiment.toml` files stay on the current supported schema and do
  not carry a backward-compatibility promise
- additive optional fields may increment the minor version within the same major
- removing, renaming, or changing the meaning or type of a required field must
  increment the major version
- readers must accept older minor versions within the same major when the
  required fields they consume are still present
- readers may reject unknown major versions explicitly with an actionable error

Derived visualization artifact policy:

- TensorBoard event logs are convenience outputs generated by Python from
  canonical runtime artifacts such as `metrics.csv` and `summary.json`
- TensorBoard event logs are not the canonical review surface and do not
  replace the text-first artifact contract
- TensorBoard event logs may be regenerated when the canonical raw artifacts
  are still present

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
- `source_repo_url`
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

TensorBoard projection rule:

- Python is responsible for reading `metrics.csv` and writing TensorBoard event
  logs for visualization
- the C++ trainer does not write TensorBoard event files directly

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
- `source_repo_url`
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

Latest completed batch selection:

- list batch directories matching `_local_{run_profile}` suffix under
  `runs/<experiment_id>/`
- reverse-sort by directory name (timestamp-based ordering)
- select the first batch whose `batch_summary.json` has
  `status in {"succeeded", "partial"}`
- if no qualifying batch exists, compare errors clearly

Compare output schema:

- versioned via `versioned_compare_report()`
- top-level fields: `run_profile`, `experiments` (list of ids), `rows`
- each row: `dataset`, `experiments.{id}` containing:
  - `status` (`"succeeded"`, `"failed"`, or `"missing"`)
  - `best_val_accuracy`, `best_val_loss`, `duration_seconds`
  - `tags`, `initialization_mode`
  - `train_runtime`, `resolved_backend`, `fallback_applied`
  - `deploy_target`, `matrix_variant_id`
  - `smoke_validation` (deployment smoke results)
- datasets present in some experiments but not others get
  `{"status": "missing"}` rather than being silently dropped

Deployment smoke-validation criteria:

- `export_ok`: checkpoint file (`best.pt`) exists
- `load_ok`: checkpoint file is parseable
- `inference_ok`: `metrics.csv` exists
- `target_compatible`: for FPGA targets, validates the experiment `model.cpp`
  plus `deployment.export_profile` satisfy the `fpga_int8_v1` profile; for
  non-FPGA targets, always `true`
- `passed`: all four criteria must be `true`

FPGA hardware gate:

- shared smoke validation is always the Phase 1 baseline
- promotion-grade FPGA decisions require an additional hardware gate
- the hardware gate must check:
  - export operator whitelist compatibility
  - quantization or calibration validity for the target flow
  - latency budget compliance on the target hardware path
  - resource or utilization budget compliance when hardware reports it

Cross-track comparison:

- compare allows mixed deploy targets in the same comparison
- each experiment row includes `deploy_target` so downstream consumers can make
  informed ranking decisions
- no warnings or blocks are issued for cross-track comparisons

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
- `experiment.id` and leaf-folder-name mismatch
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
- authored TOML model or quantization sections in source experiment configs
- non-base experiments overriding `track`
- cross-track inheritance, such as an accelerated-target chain extending an
  FPGA-targeted base or a CPU-targeted chain extending an accelerated-target
  base
- unsupported local training environments detected by `doctor` or `check`
- requested accelerated training when the current host or container does not
  expose a usable CUDA or MPS backend and CPU fallback is not allowed for the
  requested run type
- full runs launched from a dirty tree without an explicit dirty override
- unsupported legacy authored syntax under the current engine contract

The trainer should fail fast on:

- missing shared model primitive or helper referenced by the experiment
  `model.cpp`
- unknown registered `loss.name`
- unknown registered `train_loop.name`
- unknown registered `optimizer.name`
- unknown registered `scheduler.name`
- invalid tensor shapes that can be detected before the training loop starts

Failure handling rules:

- `doctor` failures should identify the failed requirement, the detected
  environment, and the next concrete remediation step
- fallback warnings should appear only when accelerated training was requested
  and a short local run resolves to CPU
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

Structured JSON error schema:

- commands that support JSON output emit a top-level `errors` array
- each error object uses these fields:
  - `code`: stable machine-readable error identifier
  - `path`: dotted config path, artifact path, or empty string when not
    path-specific
  - `severity`: `error` or `warning`
  - `message`: human-readable failure description
  - `hint`: optional remediation guidance for common, known fixes
- human-readable CLI output may present the same failures in prose, but JSON
  mode must preserve the structured fields above

Unsupported old authored syntax policy:

- old tracked experiments are immutable and should not be rewritten in place
- if a historical authored config uses syntax that the current engine no longer
  supports, the current engine should hard-fail with an actionable error
- exact historical replay should use the matching repo revision and dependency
  lock for that historical run
- reruns under the current engine should be created as a new tracked experiment
  and retrained from scratch rather than mutating the historical experiment

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
  checkpoint resolution, artifact bookkeeping, and TensorBoard event-log
  generation from trainer-owned raw metrics
- the LibTorch C++ binary remains a narrow execution engine that consumes one
  resolved child config at a time

## CLI Surface

Phase 1 Python entrypoints use `python -m` module invocations, not console
scripts. No console script packaging is required.

Phase 1 Python entrypoints should be:

- for commands that accept experiments, `<id>` always means the canonical
  repo-unique `experiment.id`; lookup ignores optional grouping folders under
  `experiments/`

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
    short local runs, and must record that fallback in runtime artifacts
- `cnn_workbench.cli.run_matrix --experiment <id> --matrix <path> [--run-profile full|short] [--allow-dirty]`
  - expands a tracked matrix definition into multiple concrete run variants
  - resolves each variant through the same Python path used by `run_local`
  - writes normal run artifacts for each variant without changing the trainer
    contract
- `cnn_workbench.cli.compare --experiments <id>... [--run-profile full|short]`
  - reads completed batch artifacts and produces dataset-aware comparisons
- `cnn_workbench.cli.prepare_datasets <dataset_id>...`
  - prepares datasets without creating a batch or launching training

Canonical IDs: REQ-004, REQ-023, CON-018, ADR-0013

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

- the minimum tracked CI surface is at least one workflow file under
  `.github/workflows/` that runs the canonical command `make test`
- CI should run Python linting or formatting checks once those tools are chosen
- CI should run orchestration tests that do not require a GPU
- CI should validate example experiment configs and dataset catalog schema
- CI should verify that `resolve` and `check` still satisfy the documented
  artifact and validation contracts
- accelerated-backed training may remain outside normal CI for Phase 1, but contract
  tests must keep the Python-to-C++ interface stable across CPU and accelerated
  runtime selection

Canonical IDs: REQ-008, CON-008, R3, R8, R9

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

Canonical IDs: REQ-011, REQ-013, REQ-017, CON-005

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
- scaffolder behavior, repo-local id allocation, and notes template creation
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
- source repo url recording in runtime artifacts when available
- artifact layout and required manifest files
- metrics and summary schema production
- dataset-aware comparison behavior
- profile-aware comparison behavior so `short` and `full` do not mix silently
- deployment-track-aware comparison behavior so accelerated-target, CPU-targeted,
  and FPGA-targeted runs are clearly labeled
- compare behavior that distinguishes accelerated runs from CPU-fallback runs

Canonical IDs: REQ-004, REQ-005, REQ-006, REQ-007, REQ-008, REQ-009, CON-002, CON-003, CON-004, CON-007

The purpose of these tests is to prevent documentation drift, hidden defaults,
and orchestration regressions as the system grows.
