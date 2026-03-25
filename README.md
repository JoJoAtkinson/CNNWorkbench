# CNN Workbench

CNN Workbench is a CNN experimentation platform where the output is code you
own: when an experiment produces the result you want, you copy `model.cpp` and
the shared C++ library into your production repo and compile. The workbench
stays in the lab; your model code goes to production.

## Why Not Just Export?

ONNX is a reasonable answer for standard GPU or CPU inference — it produces a
portable graph that any compliant runtime can load, with no Python dependency
at the production end. Where it breaks down is hardware-constrained targets.

ONNX defines a standardized, versioned operator set that runtimes implement.
Shift activations, barrel-shift normalization, and power-of-2 quantization
schemes that map cleanly to FPGA logic are not in that set. The existence of
projects like QONNX — which adds new operator types specifically for
arbitrary-precision quantization — illustrates the gap: people extend ONNX
precisely because the base set is not sufficient for hardware-constrained
designs. You can work around this with custom ONNX operators, but custom ops
must be implemented by each target runtime, which shifts the burden rather than
eliminating it, and most FPGA vendor toolchains won't carry them. The
alternative — approximating non-standard ops using standard ONNX nodes — can
alter numerical behaviour, especially in quantized or hardware-constrained
designs where exact arithmetic is the point.

The deeper issue is that an export artifact is designed for execution, not
co-design. ONNX graphs are inspectable, but they are not a source-level
representation suited for hardware-aware modification. Your production team
gets a graph they can run and inspect, but not one designed for adapting shift
widths, changing quantization modes, or fitting a particular FPGA build system.
`model.cpp` gives them source: they can read the architecture, see exactly what
shift widths and quantization modes are in play, and adapt it without any
dependency on this workbench or its runtime.

## How It Works

Each experiment owns a `model.cpp` that defines its architecture using shared
C++ library primitives. Training and execution settings live separately in
TOML config that the Python orchestrator resolves before each run. The two
stay separate so the model artifact that leaves the workbench is already clean.

Experiments run locally first to shorten the iteration cycle. Cloud submission
is a planned second path that consumes the same resolved config contract.

## Why LibTorch

- **Cross-target in one codebase**: accelerated GPU (CUDA and MPS),
  FPGA-targeted, and CPU training paths without forking by target.
- **FPGA-compatible arithmetic**: INT8 quantization, shift activations, and
  barrel-shift normalization live in the same C++ layer as architecture, so
  hardware constraints are enforced where they belong.
- **Standalone execution**: worker nodes run the compiled `cnnwb_train` binary
  with bundled LibTorch libraries — no Python environment needed at training
  time.

## Supported Targets

The workbench is meant to support three common experiment roots:

- accelerated target: deploy to an accelerated inference path
- FPGA target: deploy to 8-bit FPGA inference
- CPU target: deploy to CPU inference with a first-class CPU-oriented base

The project is intentionally config-first for training and execution behavior.
An experiment should usually be a new folder plus small TOML changes and an
experiment-local `model.cpp`, not a fork of the shared C++ library. The
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

## TPU / XLA: What This Repo Does and Does Not Do

TPUs (Tensor Processing Units) are Google-designed hardware accelerators built
for machine learning workloads. For matrix-heavy ML operations they are
significantly faster than CPU and in some workloads more cost-effective than
GPU. They are a legitimate deployment target, and some engineers evaluating
this repo will have TPU in mind either for training or inference.

This repo's output is a C++ artifact you own and ship: `model.cpp` plus
supporting shared C++ code that compiles against LibTorch and goes directly
into a production build. That is the primary design goal. TPU is not a
first-class target here, and that is intentional rather than an oversight.
Adding TPU/XLA as a first-class concern would pull the design toward a
Python/XLA-centered workflow, which is the opposite of what this repo is for.

**Why `model.cpp` does not map directly to TPU**

TPUs do not execute LibTorch C++. The standard TPU path runs through
PyTorch/XLA — a Python library that traces PyTorch operations and compiles them
to XLA (Google's Accelerated Linear Algebra runtime) for dispatch to TPU
hardware. That is a separate ecosystem from the C++ LibTorch stack this
workbench is built on.

**The theoretical export path, if you need it**

If you have experiments here and genuinely need a TPU path, the route is:
keep or reconstruct the model as a standard PyTorch model in Python, use
`torch.export` to produce a portable representation, then convert it through
`torch_xla` or StableHLO tooling into the XLA ecosystem. This is possible in
theory and is the correct approach for that goal — but it is a separate project
from what this repo produces, and it means leaving the C++ artifact story
behind.

**What does transfer**

The training discipline enforced here — INT8 weight ranges, constrained
numeric formats, architectures that avoid fixed-point-unfriendly operations —
is not FPGA-specific. Integer accelerators including TPUs benefit from the same
preparation. If you have used this repo to develop quantization-aware
experiments, that understanding and those architectural choices are reusable
knowledge when approaching a TPU project. The artifact does not transfer
directly; the design thinking does.

**Bottom line**

If your real goal is TPU as a primary production or research target, build that
path in Python with PyTorch/XLA. That is the natural home for it, and this repo
is not the right place to force that workflow. If your goal is owning and
shipping a C++ artifact with hardware-constrained inference characteristics,
this repo is designed for exactly that.

## Key Concepts

Before running experiments, it helps to know what each piece is called. These terms appear throughout the Quick Start and CLI commands.

There are six concepts in this project:

- `template`
  - `experiments/000_template/`
  - Global schema root and lowest-level defaults
  - Never runnable directly
- `base experiment`
  - A versioned, immutable root for a family of experiments
  - Example: `100_accelerated_base_v1`, `200_fpga_base_v1`, or
    `300_cpu_base_v1`
- `derived experiment`
  - A tracked folder in a repo that extends a base
  - Owns the specific hypothesis under test and its experiment-local
    `model.cpp`
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

`doctor` reports your environment state, detected hardware (CUDA, MPS, or CPU), and what needs to be fixed before any build or training starts.

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
```

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

Creates `experiments/<id>/` with `experiment.toml`, a copy of the base `model.cpp`, and a `notes.md` template.

Ids are repo-local. If a fork-owned experiment is promoted upstream, the upstream repo assigns the next available id before merge.

Example generated files:

```toml
[experiment]
id = "102_accelerated_wider_model"
name = "Accelerated Wider Model"
extends = "100_accelerated_base_v1"
kind = "experiment"

# Common non-architecture override snippets:
# [short_run]
# max_items = 5000
```

```cpp
// experiments/102_accelerated_wider_model/model.cpp
#include "cpp/models/staged_cnn.hpp"

auto build_model() {
    return make_staged_cnn({
        {64, 64, 2, 1},
        {64, 96, 3, 2},
        {96, 256, 2, 2},
        {256, 512, 2, 2},
    });
}
```

### 4. Edit the scaffolded model.cpp and the fields under test

For model structure work, edit the scaffolded `model.cpp`. Use
`experiment.toml` for training, runtime, dataset, and optimizer settings. Do
not hand-copy unrelated parent sections into the child experiment, and do not
build a new experiment on top of another non-base experiment.

Example:

```cpp
auto build_model() {
    return make_staged_cnn({
        {64, 64, 2, 1},
        {64, 96, 3, 2},   // widened experiment stage
        {96, 256, 2, 2},
        {256, 512, 2, 2},
    });
}
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

`check` validates the inheritance chain, dataset targets, and run-profile eligibility. `resolve` walks the full inheritance chain and prints the complete child configs for inspection without creating a batch. Use `--diff-from-parent` to see only what the experiment overrides. If dataset metadata is missing, `resolve` says so — run `prepare_datasets` first or pass `--ensure-datasets`.

`resolve` is part of the normal author workflow, not a debugging-only command.

### 6. Build the experiment, then run a short batch first

```bash
uv run python -m cnn_workbench.cli.build \
  --experiment 102_accelerated_wider_model
```

Downloads and verifies LibTorch for your platform if needed, then builds the C++ trainer under `build/<platform_tag>/<experiment_id>/`. Rebuilds are fingerprint-based — changing `experiment.toml` training settings does not trigger a rebuild, but changes to `model.cpp` or shared C++ do.

```bash
uv run python -m cnn_workbench.cli.run_local \
  --experiment 102_accelerated_wider_model \
  --run-profile short
```

Use `short` for early feedback on new configs, `model.cpp` edits, or shared
library changes before a canonical full run. `run_local` should rerun the same
blocking checks as `check` before it launches the batch. If
`train_runtime = "accelerated"` is requested and no accelerated backend is
available, short local runs may fall back to CPU with a warning. Canonical full
runs should fail until CPU is explicitly selected. If the experiment binary or
LibTorch bootstrap artifacts are missing or stale, `run_local` should trigger
the same build flow automatically before launch. Python also translates the
trainer's raw `metrics.csv` into TensorBoard event logs so contributors can
inspect progress without giving the trainer TensorBoard-specific dependencies.

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
  - extend a base in the same track

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

## Dataset Preparation

Dataset preparation runs automatically when you call `run_local`. To prepare ahead of time without launching training:

```bash
uv run python -m cnn_workbench.cli.prepare_datasets numbers fashion
```

`resolve` stays pure by default and only prepares datasets when `--ensure-datasets` is passed explicitly.

## Short Runs

Short runs are a separate run profile, not extra validation mixed into the
normal full-run epoch loop.

Use `short` when you want early feedback after the first few hundred or few
thousand training items without paying for a full canonical run.

The template enables short runs by default with a Fibonacci-based milestone schedule, so a newly scaffolded experiment can use `--run-profile short` immediately.

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
- `tensorboard/`
  - Python-generated TensorBoard event logs derived from `metrics.csv`
- `checkpoints/best.pt`
- `checkpoints/last.pt`

The purpose of this layout is to answer, without digging through git history:

- what was run
- on which dataset
- with which resolved settings
- from which code state
- what result it produced

TensorBoard event logs are a derived visualization surface, not the canonical
review artifact. The source of truth remains the text-first runtime outputs
such as `metrics.csv`, `run_manifest.json`, and `summary.json`.

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

That is the mechanism that prevents experiments from being lost while still making fork-shared runs traceable.

## Comparing Results

Results are grouped by dataset and clearly labeled with their deployment target and run profile. The `compare` command will not silently mix short and full runs or collapse results from different targets, so accelerated, CPU-fallback, and FPGA-targeted runs stay distinguishable.

## CLI Reference

All available commands:

```bash
uv run python -m cnn_workbench.cli.doctor
uv run python -m cnn_workbench.cli.build --experiment 102_accelerated_wider_model
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

## Task Aliases

Optional `make` shortcuts for common commands:

```bash
make build EXPERIMENT=102_accelerated_wider_model
make check EXPERIMENT=102_accelerated_wider_model
make test
make compare EXPERIMENTS="100_accelerated_base_v1 102_accelerated_wider_model"
```
