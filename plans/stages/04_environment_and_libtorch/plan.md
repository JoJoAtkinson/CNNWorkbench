# Stage 4 Plan: Environment Detection And LibTorch Download

This stage makes environment support explicit and adds the project-owned
dependency bootstrap path without requiring the trainer code to exist yet.

## Purpose

- classify contributor and runtime environments early
- make `doctor` the contributor entrypoint
- download and cache the correct LibTorch distribution per platform

## Dependencies

- Stage 1 foundation
- Stage 2 authoring-safe policy surface

## Scope

- `doctor`
- shared launch policy evaluation
- environment classification for CUDA container, Dev Container, native macOS
  MPS, CPU-capable native host, compatible native host, and authoring-only host
- LibTorch download into `third_party/libtorch/<platform_tag>/`
- project-wide `configs/libtorch.lock.toml` parsing and checksum verification
- platform-tag selection and cache reuse logic
- canonical Docker and Dev Container definitions
- baseline Docker and Dev Container definitions that are expected to expand in
  Stage 5 once the trainer build dependencies become concrete
- accelerated-to-CPU fallback policy evaluation for short local runs
- warning-only handling for newer LibTorch releases outside the pinned lock

## Out Of Scope

- CMake configuration and `build` command
- C++ source code
- full trainer feature set
- local batch execution
- comparison reports

## Deliverables

- `doctor` explains what environment the contributor is in
- unsupported environments fail before heavy build work
- LibTorch bootstrap succeeds and caches cleanly per platform
- accelerated runtime intent can be resolved to CUDA or MPS where supported
- LibTorch bootstrap follows the project lock file instead of ad hoc version
  selection

## Done Criteria

- `doctor` reports accelerated availability, CPU availability, resolved backend
  selection, and whether a short accelerated request would fall back to CPU
- Docker and Dev Container reuse the same CUDA-path definition, with the
  explicit expectation that Stage 5 may extend those definitions for concrete
  trainer build requirements
- LibTorch downloads are environment-scoped and reusable
- the selected LibTorch archive is checksum-verified before extraction and
  newer releases never auto-upgrade the pinned project version

## Test Gate

- unit tests for environment classification and policy verdict generation
- tests for supported versus authoring-only versus blocked command gating
- bootstrap tests for platform-tag selection and cache reuse behavior
- lockfile parsing and checksum verification tests
- tests proving newer LibTorch releases surface as warnings rather than
  auto-upgrades
- fallback-policy tests for accelerated requests on CUDA, MPS, and CPU-only
  hosts

## Collaboration Risks

- `R1`: Stage 4 keeps environment setup and bootstrap deterministic from a clean
  checkout.
- `R6`: Stage 4 owns the supported bootstrap paths and avoids hidden alternate
  dependency flows.
- `R8`: Stage 4 pins toolchain-adjacent LibTorch inputs through the lock file
  and checksum policy.
- `R9`: Stage 4 keeps Python bootstrap on the documented `uv` path.

## Handoff To Stage 5

- Stage 5 should be able to compile the trainer against the downloaded LibTorch
  artifacts without redefining environment detection or bootstrap ownership.
