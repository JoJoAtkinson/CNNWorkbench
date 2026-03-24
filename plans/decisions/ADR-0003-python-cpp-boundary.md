# ADR-0003: Python Orchestration And C++ Trainer Boundary

## Status

accepted

## Context

The planning set repeatedly distinguishes human-authored config handling from
single-run trainer execution. Without a durable boundary, policy checks, dataset
logic, and comparison behavior would be reimplemented across layers.

## Decision

Python owns authored config loading, inheritance resolution, dataset expansion,
policy checks, batch planning, artifact orchestration, and comparison. C++
owns one resolved child run at a time and stays focused on trainer-time model,
optimizer, scheduler, loss, and loop behavior.

## Consequences

- Contribution routing stays legible in docs and stage plans.
- The runtime layer remains narrow enough for smoke testing at the trainer
  boundary.
- Shared orchestration behavior should not be rebuilt inside the trainer.

## Supersedes

- none

## Related IDs

- REQ-002
- REQ-004
- REQ-008
- CON-003
