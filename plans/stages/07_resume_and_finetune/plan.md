# Stage 7 Plan: Resume And Fine-Tune

This stage extends local execution beyond scratch runs by adding checkpoint-based
initialization with clear provenance.

## Primary Folders

- `src/cnn_workbench/runs/`
- `src/cnn_workbench/resolve/`
- `src/cnn_workbench/policies/`
- `cpp/`
- `tests/`

## Purpose

- support `resume` and `finetune` as first-class initialization modes
- keep checkpoint resolution in Python and checkpoint loading in the trainer
- make provenance visible in manifests and summaries

## Dependencies

- Stage 2 initialization contract
- Stage 5 trainer binary and checkpoint output handling
- Stage 6 local run orchestration and artifact writing

## Scope

- symbolic checkpoint reference resolution into concrete paths
- trainer-side checkpoint loading for model, optimizer, and scheduler state
- `resume` mode with model, optimizer, and scheduler restoration
- `finetune` mode with model-weight loading and fresh optimizer state
- validation for missing or incompatible checkpoint sources
- strict versus non-strict model load behavior
- manifest and summary recording of initialization provenance

## Out Of Scope

- matrix expansion
- comparison reporting
- FPGA-target deployment validation

## Deliverables

- contributors can continue or adapt previous runs without ad hoc flags
- checkpoint provenance is visible in runtime artifacts
- initialization errors fail before ambiguous trainer behavior occurs
- the C++ trainer can load checkpoint state through the same narrow resolved
  config contract it already uses for scratch runs

## Coverage

- Implements: `REQ-010`
- Constrains: `CON-005`, `CON-011`, `CON-012`, `CON-018`
- Verifies: `ACC-005`, `R1`, `R2`, `R10`

## Done Criteria

- `resume` restores model and optimizer state correctly
- `finetune` starts a new job with loaded weights and fresh optimizer state
- resumed runs write new child-run folders that record source checkpoints
- symbolic checkpoint references remain keyed by `experiment_id` even when
  experiment folders are grouped

## Test Gate

- resume tests proving optimizer and scheduler state are restored
- fine-tune tests proving model weights load but optimizer state is fresh
- validation tests for missing or incompatible checkpoint sources
- manifest assertions proving source checkpoint is recorded correctly
- strict versus non-strict model load behavior tests
- tests proving grouped experiment folders do not change
  `latest:<experiment_id>` checkpoint lookup

## Collaboration Risks

- `R1`: Stage 7 checkpoint-based runs preserve the same clean-checkout
  provenance guarantees as scratch runs; resumed and fine-tuned runs still
  require a traceable git state for canonical full runs.
- `R2`: Short runs remain a valid fast-feedback loop for verifying that
  checkpoint initialization succeeds before committing to longer canonical runs.
- `R10`: Runtime artifacts for resumed and fine-tuned runs — manifests,
  summaries, and logs — stay text-first and versioned; checkpoint provenance is
  recorded through those same artifacts rather than opaque side state.

## Handoff To Stage 8

- Stage 8 should be able to compare and matrix-expand runs that include scratch,
  resume, and fine-tune provenance.

Canonical IDs: REQ-010, CON-005, CON-018
