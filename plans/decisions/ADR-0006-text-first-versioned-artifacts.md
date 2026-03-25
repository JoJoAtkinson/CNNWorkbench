# ADR-0006: Text-First Versioned Artifacts

## Status

accepted

## Context

The project depends on Git-friendly review surfaces for both runtime outputs and
planning outputs. The current docs already treat manifests, summaries, reports,
and plans as text artifacts that should remain easy to inspect.

## Decision

Keep runtime, compare, and planning artifacts text-first and versioned. Use
small machine-readable ledgers for canonical truth and human-readable Markdown
for explanation, with neither replaced by opaque binary state.

## Consequences

- Artifact schemas and report shapes need explicit version policy.
- Derived visualization outputs such as TensorBoard event logs may exist, but
  they remain regenerable convenience artifacts rather than the canonical
  review surface.
- Planning can become self-checking without giving up readable long-form docs.
- Future automation should validate text artifacts rather than invent a hidden
  second source of truth.

## Supersedes

- none

## Related IDs

- REQ-009
- REQ-011
- REQ-014
- REQ-015
- REQ-016
- REQ-017
- REQ-018
- REQ-022
- CON-005
- CON-016
- ADR-0010
