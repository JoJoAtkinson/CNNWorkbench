# Example Map: Model Structure Boundary

## Story

A contributor needs to change CNN structure or math without getting trapped
between an underpowered config surface and unreadable shared code.

## Rules

- `REQ-019`: shared model code keeps backbone, stage, block, and layer
  structure visually obvious
- `CON-013`: TOML owns training and execution settings while C++ defines model
  structure and quantization
- `REQ-001`: experiment history stays config-first rather than per-experiment
  code copies
- `CON-003`: model implementation still respects the Python/C++ boundary

## Examples

- A contributor changes stage widths or block counts by editing an experiment's
  `model.cpp` without forking the shared library.
- A contributor adds a new block family in shared code, references it from an
  experiment `model.cpp`, and does not rewrite the trainer loop.
- A contributor changes block internals or optimizer math in shared code because
  that behavior is not modeled as TOML architecture config.

## Questions

- none for Phase 1; the boundary is explicit rather than deferred.

Canonical IDs: ACC-008, REQ-019, CON-013, REQ-001, CON-003
