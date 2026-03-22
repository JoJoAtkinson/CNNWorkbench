# Stage 8 Plan: Compare And Matrix

This stage adds the experiment-analysis loop and the shared deployment
validation harness used across deployment targets.

## Purpose

- make repeatable sweeps first-class without replacing tracked experiments
- make comparison artifact-aware and honest about profiles, targets, and
  fallback state
- add one shared deployment smoke-validation concept for CPU, accelerated, and
  FPGA targets

## Dependencies

- Stage 6 local run artifacts
- Stage 7 initialization provenance

## Scope

- `run_matrix`
- deterministic matrix variant id generation
- matrix override recording in manifests
- `compare --experiments ...`
- dataset-aware, profile-aware, and deployment-track-aware comparison rules
- shared deployment smoke validation: export, load, tiny-sample inference, and
  target-compatibility checks
- optional report emission into `reports/`

## Out Of Scope

- FPGA-specific math or deployment behavior beyond the shared smoke harness
- `compare --tag` and `compare --matrix` future filter support

## Deliverables

- contributors can run sweeps without weakening the tracked-experiment model
- compare can distinguish deployment target, requested runtime, resolved
  backend, and fallback state
- deployment validation uses one common contract instead of separate per-target
  paths

## Done Criteria

- matrix definitions expand into deterministic variants without collisions
- compare never silently mixes datasets, profiles, or deployment targets
- deployment smoke validation works for CPU and accelerated targets through one
  shared interface

## Test Gate

- matrix expansion tests for deterministic ids and duplicate rejection
- compare tests for missing dataset handling and profile separation
- deployment-track-aware comparison tests proving accelerated-target,
  CPU-targeted, and FPGA-targeted runs remain labeled
- deployment smoke-harness tests proving CPU and accelerated targets share the
  same validation contract

## Handoff To Stage 9

- Stage 9 should layer FPGA-specific deployment constraints onto the shared
  smoke harness instead of inventing a separate validation universe.
