# Example Map: Authoring And Resolution

## Story

A contributor needs to create or adjust an experiment without touching shared
runtime code and must be able to inspect the exact runtime effect before any
training occurs.

## Rules

- `REQ-001`: experiments are config-first and derive from tracked parents
- `REQ-004`: scaffold, check, and resolve work on authoring-only machines
- `REQ-005`: validation output is aggregated and machine-readable
- `REQ-023`: canonical command selection stays on `experiment.id` even when
  experiments are grouped under organization folders
- `CON-001`: template and finished experiment history do not change runtime
  meaning in place
- `CON-002`: runtime and deployment target stay separate
- `CON-018`: group folders are organization-only and ids remain repo-unique

## Examples

- A contributor scaffolds `102_accelerated_wider_model` from
  `100_accelerated_base_v1` and receives the next repo-local ID plus
  `experiment.toml`, `model.cpp`, and `notes.md`.
- A contributor runs `resolve --diff-from-parent` and sees both the authored
  delta and the resolved runtime effect for each dataset child run.
- A contributor on an authoring-only machine can still use `new_experiment`,
  `check`, and `resolve`.
- A contributor moves `202_fpga_shift_activation` under
  `experiments/fpga/int8/202_fpga_shift_activation/`, and `check --experiment
  202_fpga_shift_activation` still finds it without requiring the path.
- If two grouped folders contain the same `experiment.id`, validation fails
  before command execution continues.

## Questions

- `UNK-001`: how much of the resolved child-run contract will later be reused
  unchanged for Azure submission?

Canonical IDs: ACC-001, REQ-001, REQ-004, REQ-005, REQ-023, CON-001, CON-002, CON-018, UNK-001
