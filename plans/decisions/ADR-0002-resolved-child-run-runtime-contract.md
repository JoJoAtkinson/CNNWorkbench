# ADR-0002: Resolved Child Run As Runtime Contract

## Status

accepted

## Context

The project wants one machine-facing contract that can survive local execution,
comparison, and future Azure submission without each caller reinterpreting
authored experiments independently.

## Decision

The resolved child run is the only runtime contract the trainer consumes.
Python resolution owns authored config interpretation, dataset expansion, and
run-profile materialization before the trainer sees a child run. The resolved
child run covers training and execution settings only; model architecture is
compiled from the experiment's `model.cpp` before runtime.

## Consequences

- CLI commands should share domain models instead of raw dict conventions.
- The C++ trainer must not reach back into authored experiment folders.
- The resolved contract excludes model graph structure, quantization settings,
  and other architecture-defining fields that now live in C++ model code.
- Remote execution, local execution, and comparison all depend on the same
  resolved artifact shape.

## Supersedes

- none

## Related IDs

- REQ-002
- REQ-005
- REQ-006
- REQ-008
- REQ-009
- REQ-010
- CON-003
- CON-007
- ADR-0007
- ADR-0008
