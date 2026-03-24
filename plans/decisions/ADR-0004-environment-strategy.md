# ADR-0004: Environment Strategy By Capability

## Status

accepted

## Context

The project needs repeatable contributor setup across CUDA, MPS, CPU, and
authoring-only environments, but those paths do not share the same platform
constraints.

## Decision

Use Docker or a Dev Container as the canonical accelerated CUDA path, native
macOS for Apple Silicon MPS, and native CPU hosts for explicit CPU or
authoring-only work. `doctor` is the contributor entrypoint that classifies the
environment before build or training begins.

## Consequences

- Environment guidance and policy checks stay explicit instead of implicit in
  shell scripts.
- CUDA, MPS, CPU, and authoring-only workflows can share one project without
  pretending they have identical prerequisites.
- The docs must keep runtime fallback rules and unsupported-environment
  behavior visible.

## Supersedes

- none

## Related IDs

- REQ-007
- REQ-008
- CON-004
- CON-006
- CON-008
- ASM-002
- ASM-003
