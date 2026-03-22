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
- platform-tag selection and cache reuse logic
- canonical Docker and Dev Container definitions
- baseline Docker and Dev Container definitions that are expected to expand in
  Stage 5 once the trainer build dependencies become concrete
- accelerated-to-CPU fallback policy evaluation for short/debug local runs

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

## Done Criteria

- `doctor` reports accelerated availability, CPU availability, resolved backend
  selection, and whether a short/debug accelerated request would fall back to
  CPU
- Docker and Dev Container reuse the same CUDA-path definition, with the
  explicit expectation that Stage 5 may extend those definitions for concrete
  trainer build requirements
- LibTorch downloads are environment-scoped and reusable

## Test Gate

- unit tests for environment classification and policy verdict generation
- tests for supported versus authoring-only versus blocked command gating
- bootstrap tests for platform-tag selection and cache reuse behavior
- fallback-policy tests for accelerated requests on CUDA, MPS, and CPU-only
  hosts

## Handoff To Stage 5

- Stage 5 should be able to compile the trainer against the downloaded LibTorch
  artifacts without redefining environment detection or bootstrap ownership.
