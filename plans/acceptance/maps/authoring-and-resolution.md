# Example Map: Authoring And Resolution

## Story

A contributor needs to create or adjust an experiment without touching shared
runtime code and must be able to inspect the exact runtime effect before any
training occurs.

## Rules

- `REQ-001`: experiments are config-first and derive from tracked parents
- `REQ-004`: scaffold, check, and resolve work on authoring-only machines
- `REQ-005`: validation output is aggregated and machine-readable
- `CON-001`: template and finished experiment history do not change runtime
  meaning in place
- `CON-002`: runtime and deployment target stay separate

## Examples

- A contributor scaffolds `102_accelerated_wider_model` from
  `100_accelerated_base_v1` and receives the next repo-local ID plus
  `experiment.toml`, `model.cpp`, and `notes.md`.
- A contributor runs `resolve --diff-from-parent` and sees both the authored
  delta and the resolved runtime effect for each dataset child run.
- A contributor on an authoring-only machine can still use `new_experiment`,
  `check`, and `resolve`.

## Questions

- `UNK-001`: how much of the resolved child-run contract will later be reused
  unchanged for Azure submission?

Canonical IDs: ACC-001, REQ-001, REQ-004, REQ-005, CON-001, CON-002, UNK-001
