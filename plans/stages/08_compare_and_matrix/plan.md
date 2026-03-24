# Stage 8 Plan: Compare And Matrix

This stage adds the experiment-analysis loop and the shared deployment
validation harness used across deployment targets.

## Purpose

- make repeatable sweeps first-class without replacing tracked experiments
- support promotion decisions without assuming every exploratory result becomes
  upstream history
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
- versioned machine-readable compare report output
- dataset-aware, profile-aware, and deployment-track-aware comparison rules
- shared deployment smoke validation: export, load, tiny-sample inference, and
  target-compatibility checks
- optional report emission into `reports/` for sharing and promotion decisions

## Out Of Scope

- FPGA-specific math or deployment behavior beyond the shared smoke harness
- upstreaming every shared experiment by default
- `compare --tag` and `compare --matrix` future filter support

## Deliverables

- contributors can run sweeps without weakening the tracked-experiment model or
  assuming every sweep result becomes upstream history
- compare can distinguish deployment target, requested runtime, resolved
  backend, and fallback state
- compare output remains a text-first, versioned artifact suitable for review
  and promotion decisions
- deployment validation uses one common contract instead of separate per-target
  paths

## Done Criteria

- matrix definitions expand into deterministic variants without collisions
- compare never silently mixes datasets, profiles, or deployment targets
- compare and reports are strong enough to support promotion discussions for
  curated upstream experiments
- compare emits or writes the documented versioned report shape when report
  output is requested
- deployment smoke validation works for CPU and accelerated targets through one
  shared interface

## Test Gate

- matrix expansion tests for deterministic ids and duplicate rejection
- compare tests for missing dataset handling and profile separation
- compare report-schema tests for the versioned machine-readable output
- deployment-track-aware comparison tests proving accelerated-target,
  CPU-targeted, and FPGA-targeted runs remain labeled
- deployment smoke-harness tests proving CPU and accelerated targets share the
  same validation contract

## Collaboration Risks

- `R2`: Stage 8 keeps exploratory sweeps reviewable by promoting only durable
  winners into tracked experiments.
- `R4`: Stage 8 turns promotion reasoning into explicit reports instead of ad
  hoc discussion alone.
- `R10`: Stage 8 keeps compare and report outputs text-first and versioned so
  they remain good collaboration surfaces.

## Handoff To Stage 9

- Stage 9 should layer FPGA-specific deployment constraints onto the shared
  smoke harness instead of inventing a separate validation universe.
