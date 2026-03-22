# Stage 6 Plan: Local Scratch Runs

This stage connects Python orchestration to the real trainer for scratch-mode
local runs and completes the runtime artifact story for the common fast path.

## Purpose

- make `run_local` work end to end for scratch-mode experiments
- complete batch expansion, launch, artifact writing, and failure handling
- make short runs the normal contributor feedback loop

## Dependencies

- Stage 2 authoring and resolution
- Stage 3 dataset preparation
- Stage 4 launch policy and environment detection
- Stage 5 working trainer binary

## Scope

- `run_local` for `initialization.mode = "scratch"` only
- parent batch expansion into ordered child dataset runs
- sequential local execution
- `run_manifest.json`, `summary.json`, and batch summary generation
- git commit, dirty-state, and patch capture
- stop-on-failure behavior
- runtime artifact fields for requested training runtime, resolved backend,
  deploy target, and fallback state
- trainer log teeing into `train.log`

## Out Of Scope

- resume and fine-tune launch handling
- matrix expansion
- comparison reporting
- FPGA-target deployment validation beyond normal artifact capture

## Deliverables

- contributors can run a short batch and inspect the resulting artifacts
- failed child runs still produce meaningful summaries
- CPU-fallback short runs are visible and cannot be mistaken for true
  accelerated runs

## Done Criteria

- `run_local --run-profile short` works end to end for scratch-mode experiments
- successful and failed child runs both produce the required artifact set
- dirty-tree and stop-on-failure policies behave as documented

## Test Gate

- integration tests for successful local batch execution on tiny datasets
- failure-path tests for trainer crash, dataset prepare failure, and dirty-tree
  policy rejection
- artifact schema assertions for manifest, summary, and batch summary files
- failure-path assertions proving that pre-trainer and trainer-crash cases still
  write a valid failure `summary.json`
- assertions that CPU-fallback short runs are distinguishable from accelerated
  runs

## Handoff To Stage 7

- Stage 7 should extend the run orchestration path with checkpoint-based
  initialization without rewriting local run ownership.
