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
owns one resolved child run at a time and stays focused on the compiled
experiment model plus trainer-time optimizer, scheduler, loss, and loop
behavior.

## Consequences

- Contribution routing stays legible in docs and stage plans.
- The runtime layer remains narrow enough for smoke testing at the trainer
  boundary.
- Shared orchestration behavior should not be rebuilt inside the trainer.
- Visualization-specific integrations such as TensorBoard event-log generation
  stay in Python rather than becoming trainer dependencies.
- Shared C++ code remains the place where model graph structure, block
  internals, layer order, quantization behavior, and optimizer math are
  implemented once the resolved config reaches the trainer.

## Supersedes

- none

## Related IDs

- REQ-002
- REQ-004
- REQ-008
- REQ-019
- REQ-021
- REQ-022
- CON-003
- CON-013
- CON-015
- CON-016
- ADR-0007
- ADR-0010
