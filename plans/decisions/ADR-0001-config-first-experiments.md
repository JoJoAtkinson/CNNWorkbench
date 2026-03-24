# ADR-0001: Config-First Experiments

## Status

accepted

## Context

CNN Workbench is meant to make experiment creation cheaper than shared-runtime
code changes. The top-level plan and contributor docs already assume that most
experiment work should happen through tracked experiment folders and reusable
registries rather than per-experiment code forks.

## Decision

The project will treat experiments as config-first artifacts. Experiment
history is expressed through tracked bases and derived experiments, while shared
behavior lives in reusable Python orchestration and reusable C++ trainer code.

## Consequences

- Stage 1 and Stage 2 must seed and preserve the experiment-root structure.
- Contributor guidance routes experiment-only work toward config changes first.
- Per-experiment runtime code forks are treated as an architecture regression.

## Supersedes

- none

## Related IDs

- REQ-001
- REQ-003
- REQ-004
- REQ-013
- CON-001
- CON-002
