# Stage 1 Plan: Foundation And Contract Skeleton

This stage creates the minimum repository shape needed for every later stage.
It should leave the repo installable, testable, and ready for contract-first
implementation work.

## Purpose

- establish the Python package skeleton
- define shared contract types in one place
- create artifact version helpers before runtime files exist
- seed the tracked experiment roots and config files that later stages depend on

## Dependencies

- none

## Scope

- `pyproject.toml` and initial `uv` entrypoints
- `src/cnn_workbench/` package skeleton with thin CLI entrypoints
- typed shared models for `ExperimentConfig`, `ResolvedChildRun`, `BatchPlan`,
  `EnvironmentReport`, `LaunchVerdict`, `RunManifest`, and `CompareInput`
- artifact schema version constants and read/write helpers
- tracked seed content for `000_template`, `100_accelerated_base_v1`,
  `200_fpga_base_v1`, and `300_cpu_base_v1`
- baseline test harness, task aliases, and minimum CI wiring
- baseline `.gitignore` coverage for local runtime roots such as `datasets/`,
  `runs/`, `build/`, and `third_party/`
- contributor-facing repo-shape rules that keep the upstream experiment tree
  curated rather than exhaustive

## Out Of Scope

- experiment inheritance logic
- dataset download or metadata preparation
- environment detection
- C++ build or training
- local run orchestration

## Deliverables

- a fresh checkout can install Python dependencies and import the CLI modules
- the shared domain contracts live in one module boundary instead of raw dicts
- the seed experiment roots and config directories exist in tracked files
- artifact versioning is defined before runtime serializers multiply
- `uv` and `python -m` are the only documented Python entrypoints in the stage 1
  scaffold
- the repo has one minimum CI entrypoint and one clear tracked-versus-local
  directory boundary

## Done Criteria

- all planned CLI modules import cleanly
- the contract objects validate basic required fields
- seed roots are present and consistent with the documented hierarchy
- the repository has a clear test entrypoint for later stages to build on
- at least one workflow under `.github/workflows/` runs `make test`
- local runtime directories named in the top-level docs are ignored by git

## Test Gate

- import smoke tests for every planned CLI module
- unit tests for domain model validation
- unit tests for artifact version field injection
- repository layout tests asserting that the tracked seed files exist
- repository checks asserting the CI workflow exists and the documented
  local-only runtime directories are ignore-listed

## Collaboration Risks

- `R1`: Stage 1 must establish the canonical `uv` and `python -m` bootstrap
  path used by later stages.
- `R3`: Stage 1 owns the minimum CI surface and the first repo-wide test
  contract.
- `R5`: Stage 1 defines the curated upstream experiment tree and the main change
  surfaces contributors review against.
- `R6`: Stage 1 fixes the top-level repo shape so later stages do not invent
  alternate bootstrap or storage layouts.
- `R7`: Stage 1 defines which runtime roots stay out of git.
- `R9`: Stage 1 keeps Python environment setup on one documented path.
- `R10`: Stage 1 keeps tracked text artifacts and docs as the canonical review
  surface.

## Handoff To Stage 2

- Stage 2 should be able to build scaffolding, validation, and resolution logic
  on the shared contracts without redefining schema or artifact ownership.
