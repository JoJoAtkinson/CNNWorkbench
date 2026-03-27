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
- git commit, source repo url, dirty-state, and patch capture
- non-git sentinel values for provenance fields when `.git` is unavailable
- stop-on-failure behavior
- runtime artifact fields for requested training runtime, resolved backend,
  deploy target, and fallback state
- trainer log teeing into `train.log`
- Python-owned TensorBoard event-log generation from trainer-produced
  `metrics.csv`
- auto-bootstrap and auto-build before launch when LibTorch or the trainer
  binary is missing or stale
- pre-trainer failure artifact writing before the trainer process starts

## Out Of Scope

- resume and fine-tune launch handling
- matrix expansion
- comparison reporting
- FPGA-target deployment validation beyond normal artifact capture

## Deliverables

- contributors can run a short batch and inspect the resulting artifacts
- contributors can point TensorBoard at Python-generated event logs derived
  from trainer metrics
- failed child runs still produce meaningful summaries
- runtime artifacts retain enough provenance to trace back to the originating
  repo when available
- grouped experiment folders do not change `run_local --experiment <id>` or the
  `runs/<experiment_id>/` artifact root
- CPU-fallback short runs are visible and cannot be mistaken for true
  accelerated runs
- `run_local` can trigger the same bootstrap and build flow automatically before
  launch instead of requiring a separate manual build step

## Coverage

- Implements: `REQ-009`, `REQ-022`
- Constrains: `CON-004`, `CON-005`, `CON-011`, `CON-012`, `CON-016`,
  `CON-018`
- Verifies: `ACC-004`, `R1`, `R2`, `R7`, `R10`

## Done Criteria

- `run_local --run-profile short` works end to end for scratch-mode experiments
- successful and failed child runs both produce the required artifact set
- successful runs produce TensorBoard event logs from trainer-owned raw metrics
  without requiring the trainer to write TensorBoard format directly
- non-git runs record the documented sentinel provenance values and still
  proceed normally
- pre-trainer failures still write `experiment_source.toml`,
  `resolved_config.toml`, `run_manifest.json`, and `summary.json`
- grouped experiment folders do not change canonical experiment selection or
  the `runs/<experiment_id>/` artifact path
- dirty-tree and stop-on-failure policies behave as documented

## Test Gate

- integration tests for successful local batch execution on tiny datasets
- failure-path tests for trainer crash, dataset prepare failure, and dirty-tree
  policy rejection
- artifact schema assertions for manifest, summary, and batch summary files,
  including source-repo provenance
- tests proving Python generates TensorBoard event logs from `metrics.csv`
  rather than requiring TensorBoard-specific logic in the trainer
- tests proving non-git execution records the documented sentinel provenance
  values
- tests proving `run_local` triggers bootstrap and build automatically when the
  required artifacts are missing or stale
- tests proving grouped experiment folders still resolve through
  `run_local --experiment <id>` without changing artifact roots
- failure-path assertions proving that pre-trainer and trainer-crash cases still
  write a valid failure `summary.json`
- failure-path assertions proving pre-trainer failures omit `train.log` while
  still writing the other required artifacts
- assertions that CPU-fallback short runs are distinguishable from accelerated
  runs

## Collaboration Risks

- `R1`: Stage 6 preserves the clean-checkout run path by auto-running required
  bootstrap and build steps before launch.
- `R2`: Stage 6 keeps short runs as the normal fast-feedback loop before larger
  changes are promoted.
- `R7`: Stage 6 keeps runtime artifacts clearly separate from tracked source.
- `R10`: Stage 6 keeps manifests, summaries, and other text artifacts as the
  canonical review surface for run outcomes.

## Handoff To Stage 7

- Stage 7 should extend the run orchestration path with checkpoint-based
  initialization without rewriting local run ownership.

Canonical IDs: REQ-009, REQ-022, CON-004, CON-005, CON-011, CON-012, CON-016, CON-018
