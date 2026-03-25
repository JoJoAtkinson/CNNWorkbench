# ADR-0001: Config-First Experiments

## Status

accepted

## Context

CNN Workbench is meant to make experiment creation cheaper than shared-runtime
code changes. The top-level plan and contributor docs already assume that most
experiment work should happen through tracked experiment folders and reusable
registries rather than per-experiment code forks.

## Decision

The project will treat experiments as config-first artifacts for training and
execution behavior. Experiment history is expressed through tracked bases and
derived experiments, while shared behavior lives in reusable Python
orchestration and reusable C++ code, and each experiment owns its own
architecture-defining `model.cpp`.

## Consequences

- Stage 1 and Stage 2 must seed and preserve the experiment-root structure.
- Contributor guidance routes experiment-only work toward config changes first.
- Per-experiment runtime code forks are treated as an architecture regression.
- The narrower boundary for what belongs in config versus shared model code is
  further refined by ADR-0007 rather than implied here.
- The experiment-local model definition file and base-only non-base lineage are
  further refined by ADR-0008 rather than implied here.

## Supersedes

- none

## Related IDs

- REQ-001
- REQ-003
- REQ-004
- REQ-013
- REQ-020
- REQ-021
- CON-001
- CON-002
- CON-013
- CON-014
- CON-015
- ADR-0007
- ADR-0008
- ADR-0009
