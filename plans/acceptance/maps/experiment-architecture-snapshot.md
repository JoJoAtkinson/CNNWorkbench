# Example Map: Experiment-Owned C++ Model Definition

## Story

A contributor wants to create a new CNN experiment from a tracked base and be
able to inspect or change the experiment's model structure without depending on
another experiment folder or reverse-engineering a deep inheritance chain.

## Rules

- `REQ-020`: non-base experiments own an explicit architecture-facing C++
  model definition in their own `model.cpp`.
- `REQ-021`: the experiment `model.cpp` plus the shared library remain
  production-portable.
- `CON-014`: non-base experiments extend a base, not another experiment.
- `CON-015`: portable model code excludes framework dependencies.

## Examples

- A contributor scaffolds from `100_accelerated_base_v1` and receives an
  `experiment.toml`, `model.cpp`, and `notes.md`, with `model.cpp` copied from
  that base.
- A contributor edits stage widths, block counts, or quantization settings in
  the new experiment's `model.cpp` without copying trainer-loop code.
- A later `110_accelerated_base_v2` changes its default `model.cpp`, but the
  earlier scaffolded experiment keeps its own copied model definition
  unchanged.
- A contributor tries to scaffold an experiment from `101_accelerated_baseline`
  and is told to extend a base instead.
- A contributor can copy the experiment's `model.cpp` plus the shared C++
  library into a production repo without bringing TOML architecture parsing.

## Open Questions

- none

Canonical IDs: ACC-009, REQ-020, REQ-021, CON-014, CON-015, REQ-001
