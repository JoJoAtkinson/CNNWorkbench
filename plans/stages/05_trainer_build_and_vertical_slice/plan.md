# Stage 5 Plan: Trainer Build And Minimal Vertical Slice

This stage introduces the C++ source tree, the build command, and the smallest
real per-experiment trainer binary that proves the Python-to-C++ contract
works.

## Purpose

- turn the planned C++ trainer into a real build target
- validate the narrow `resolved_config -> trainer -> output-dir` contract
- establish the shared-library composition pattern plus non-model registries
- prove the largest single implementation-volume stage without spilling trainer
  semantics back into Python

## Dependencies

- Stage 1 foundation
- Stage 2 resolved-config contract
- Stage 4 environment detection and LibTorch bootstrap

## Scope

- `build` command with CMake configuration and compilation
- minimum supported CMake version `3.26`
- supported build types `Debug`, `RelWithDebInfo`, and `Release`
- environment-scoped and experiment-scoped build roots
- build fingerprinting under
  `build/<platform_tag>/<experiment_id>/build_fingerprint.json`
- Python-side experiment lookup by canonical id before selecting the concrete
  `model.cpp` source path for the build
- resolved-config parsing on the C++ side
- trainer-side handoff of resolved dataset metadata into the experiment
  `build_model(int64_t input_channels, int64_t num_classes)` entrypoint
- experiment `model.cpp` compilation plus shared-library linking
- registry bootstrap for non-model component families
- phase 1 built-ins for the default general-purpose path
- minimum trainer-owned outputs such as `metrics.csv` and checkpoints
- fast failure for missing registration or obvious shape errors
- readable shared backbone and block composition that makes stage order, block
  repetition, and block internals easy to inspect
- shared-library portability that avoids Python or TOML-parser dependencies

## Out Of Scope

- multi-dataset orchestration
- git patch capture
- compare and matrix support
- FPGA-specific components beyond what the minimal vertical slice requires
- resume and fine-tune checkpoint loading

## Deliverables

- contributors can build the trainer from the repo instead of a reference repo
- a per-experiment trainer binary works for a tiny fixture
- the trainer can supply dataset-dependent input channels and class count to
  the compiled experiment model without reintroducing TOML-defined architecture
- adding the second reusable block family stays localized to shared model code
- adding the second non-model component to a registry family has a clear
  extension path
- reviewers can inspect shared code and clearly see stage composition, block
  composition, and where block math changes belong
- Phase 1 establishes one canonical trainer test path: Python-driven binary
  smoke and integration tests against tiny resolved-config fixtures
- training-config-only experiment changes do not trigger unnecessary rebuilds,
  while `model.cpp` changes do

## Coverage

- Implements: `REQ-002`, `REQ-008`, `REQ-019`, `REQ-021`
- Constrains: `CON-003`, `CON-006`, `CON-013`, `CON-015`, `CON-018`
- Verifies: `ACC-003`, `ACC-008`, `ACC-009`, `R1`, `R6`, `R8`

## Done Criteria

- `build --experiment <id>` produces a working per-experiment binary from the
  tracked C++ source tree plus that experiment's `model.cpp`
- `build --experiment <id>` works even when the selected experiment folder is
  nested under an organization-only group path
- the trainer passes dataset metadata into the experiment model entrypoint
  without hardcoding those values in `model.cpp` or re-parsing TOML for
  architecture
- the minimal trainer writes the outputs it owns directly
- the shared code organization makes stage composition, block composition, and
  block-family extension easy for a reviewer to follow
- the shared library remains compilable without Python or TOML-parser
  dependencies
- missing registered components fail with clear diagnostics
- rebuild decisions are fingerprint-based and include tracked C++, CMake,
  toolchain, lock-file, trainer-boundary schema inputs, and the selected
  experiment's `model.cpp`

## Test Gate

- build tests verifying CMake configuration and binary production
- tests verifying the CMake floor, per-experiment build contract, and supported
  build types
- Python-driven trainer smoke tests that invoke the built binary against tiny
  resolved-config fixtures
- trainer smoke tests proving resolved dataset metadata feeds
  `build_model(...)` inputs while model structure and quantization remain
  compiled C++ concerns
- registry lookup failure tests for non-model component families
- tests or review fixtures proving a second block family can be added through a
  localized shared component path rather than trainer-loop rewrites
- tests for minimum metrics and checkpoint outputs
- tests proving training-config-only experiment changes do not trigger a
  rebuild while tracked C++, CMake, lock-file, schema, or selected `model.cpp`
  changes do
- tests proving grouped experiment folders do not change id-based build
  selection or experiment-scoped build-root naming
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

Canonical IDs: REQ-002, REQ-008, REQ-019, REQ-021, CON-003, CON-006, CON-013, CON-015, CON-018
