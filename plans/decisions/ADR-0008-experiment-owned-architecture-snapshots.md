# ADR-0008: Experiment-Owned C++ Model Definition Files

## Status

accepted

## Context

The planning set makes shared library code the place where parameterized block
and layer implementations live, but each experiment needs to define its own
model architecture — its stage composition, channel widths, block counts, and
activation choices — in a way that is visible at a glance and does not require
reconstructing long inheritance chains.

Contributors want each experiment to show its own model structure clearly,
especially the dimensions and composition that are most likely to change during
architecture exploration. They also want future base evolution to avoid
silently rewriting the architecture of existing experiments.

A key motivation is production portability: a successful experiment's model
code plus the shared C++ library must compile in a production repo without any
dependency on the Python orchestration framework or TOML config parsing.

## Decision

Each experiment owns a C++ model definition file (`model.cpp`) that defines
the experiment's architecture using shared library primitives with explicit
numerical values. The shared library provides parameterized building blocks
with no magic numbers; the experiment model code provides the concrete values.

This means:

- each experiment folder contains `experiment.toml` (training/execution config),
  `model.cpp` (architecture definition), and `notes.md`
- `model.cpp` uses shared library types directly with explicit dimensions,
  block counts, strides, and activation choices — code as config
- scaffolding copies the base experiment's `model.cpp` as a starter template
  for new experiments
- non-base experiments extend a base, not another non-base experiment
- the build is per-experiment: compiling the experiment's `model.cpp` with the
  shared library and trainer entrypoint into a per-experiment binary
- experiments do not fork the shared library, trainer loop, or orchestration
  code; only the model definition is experiment-local

## Consequences

- Reviewers can inspect an experiment folder and see its architecture at a
  glance in `model.cpp` without reconstructing inheritance chains.
- Later base changes do not silently mutate the architecture of historical
  experiments because each experiment owns its own `model.cpp`.
- The project accepts per-experiment C++ model files as intentional
  code-as-config, not as code duplication.
- The experiment's `model.cpp` plus the shared library form a
  production-portable artifact that compiles without the framework.
- Per-experiment compilation produces per-experiment binaries.
- Stage 2 must scaffold `model.cpp` from the base template alongside
  `experiment.toml` and `notes.md`.
- Shared library implementation remains the only place for reusable block,
  layer, optimizer, and trainer behavior.
- The resolved child run scope narrows to training and execution config only;
  the binary already has the model compiled in.

## Supersedes

- none

## Related IDs

- REQ-001
- REQ-008
- REQ-020
- REQ-021
- CON-014
- CON-015
- ADR-0001
- ADR-0007
- ADR-0009
