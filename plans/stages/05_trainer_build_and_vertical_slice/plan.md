# Stage 5 Plan: Trainer Build And Minimal Vertical Slice

This stage introduces the C++ source tree, the build command, and the smallest
real `cnnwb_train` that proves the Python-to-C++ contract works.

## Purpose

- turn the planned C++ trainer into a real build target
- validate the narrow `resolved_config -> trainer -> output-dir` contract
- establish the registry and family-specific construction pattern
- prove the largest single implementation-volume stage without spilling trainer
  semantics back into Python

## Dependencies

- Stage 1 foundation
- Stage 2 resolved-config contract
- Stage 4 environment detection and LibTorch bootstrap

## Scope

- `build` command with CMake configuration and compilation
- minimum supported CMake version `3.26`
- canonical trainer target name `cnnwb_train`
- supported build types `Debug`, `RelWithDebInfo`, and `Release`
- environment-scoped build roots under `build/<platform_tag>/`
- build fingerprinting under `build/<platform_tag>/build_fingerprint.json`
- resolved-config parsing on the C++ side
- registry bootstrap for required component families
- phase 1 built-ins for the default general-purpose path
- minimum trainer-owned outputs such as `metrics.csv` and checkpoints
- fast failure for missing registration or obvious shape errors

## Out Of Scope

- multi-dataset orchestration
- git patch capture
- compare and matrix support
- FPGA-specific components beyond what the minimal vertical slice requires
- resume and fine-tune checkpoint loading

## Deliverables

- contributors can build the trainer from the repo instead of a reference repo
- `cnnwb_train --resolved-config <path> --output-dir <path>` works for a tiny
  fixture
- adding the second component to a registry family has a clear extension path
- Phase 1 establishes one canonical trainer test path: Python-driven binary
  smoke and integration tests against tiny resolved-config fixtures
- config-only experiment changes do not trigger unnecessary trainer rebuilds

## Done Criteria

- `build` produces a working binary from the tracked C++ source tree
- the minimal trainer writes the outputs it owns directly
- missing registered components fail with clear diagnostics
- rebuild decisions are fingerprint-based and include tracked C++, CMake,
  toolchain, lock-file, and trainer-boundary schema inputs

## Test Gate

- build tests verifying CMake configuration and binary production
- tests verifying the CMake floor, canonical target name, and supported build
  types
- Python-driven trainer smoke tests that invoke the built binary against tiny
  resolved-config fixtures
- registry lookup failure tests
- tests for minimum metrics and checkpoint outputs
- tests proving config-only experiment changes do not trigger a rebuild while
  tracked C++, CMake, lock-file, or schema changes do
- no separate C++ unit-test framework is required in Phase 1; if a lightweight
  C++ harness is added later, it is secondary to the trainer-boundary tests

## Collaboration Risks

- `R1`: Stage 5 keeps the build path repeatable across clean checkouts.
- `R6`: Stage 5 keeps build ownership in the documented environment-scoped
  roots rather than ad hoc local layouts.
- `R8`: Stage 5 owns the C++ build floor, target identity, and fingerprint
  contract that keep toolchain behavior stable.

## Handoff To Stage 6

- Stage 6 should be able to orchestrate the trainer locally without changing the
  trainer contract.
