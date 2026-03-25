# Example Map: Runtime And Artifacts

## Story

A contributor needs short runs, provenance, and compare outputs that are honest
about what actually ran and easy to review in Git-friendly formats.

## Rules

- `REQ-009`: local scratch runs write the required artifact set for success and
  failure
- `REQ-022`: Python translates trainer-written raw metrics into TensorBoard
  event logs
- `REQ-010`: checkpoint-based initialization is resolved and recorded before
  launch
- `REQ-011`: compare and matrix workflows preserve dataset, profile, target,
  runtime, and fallback distinctions
- `CON-004`: only `short` and `full` are valid Phase 1 run profiles
- `CON-005`: manifests, summaries, and compare reports stay text-first and
  versioned
- `CON-016`: TensorBoard event logs remain derived visualization artifacts
- `CON-011`: reproducibility relies on tracked experiments plus git provenance
- `CON-012`: canonical full runs default to clean trees

## Examples

- A failed pre-trainer child run still writes `resolved_config.toml`,
  `run_manifest.json`, and `summary.json`.
- A successful child run writes `metrics.csv`, and Python derives TensorBoard
  event logs from that file without requiring the trainer to know the
  TensorBoard event format.
- A short accelerated request on a CPU-only environment shows explicit fallback
  in the run artifacts.
- A compare report labels mixed accelerated, CPU-targeted, and FPGA-targeted
  experiments without collapsing them into one score.

## Questions

- `UNK-002`: which future compare filters, if any, should become part of the
  stable report surface?

Canonical IDs: ACC-004, ACC-005, REQ-009, REQ-010, REQ-011, REQ-022, CON-004, CON-005, CON-011, CON-012, CON-016, UNK-002
