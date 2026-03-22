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
- baseline test harness and initial CI placeholder wiring

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

## Done Criteria

- all planned CLI modules import cleanly
- the contract objects validate basic required fields
- seed roots are present and consistent with the documented hierarchy
- the repository has a clear test entrypoint for later stages to build on

## Test Gate

- import smoke tests for every planned CLI module
- unit tests for domain model validation
- unit tests for artifact version field injection
- repository layout tests asserting that the tracked seed files exist

## Handoff To Stage 2

- Stage 2 should be able to build scaffolding, validation, and resolution logic
  on the shared contracts without redefining schema or artifact ownership.
