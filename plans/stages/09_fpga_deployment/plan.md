# Stage 9 Plan: FPGA Deployment Extension

This stage implements the FPGA-targeted deployment path as a true extension of
the shared system rather than a separate project.

## Purpose

- make the FPGA-targeted base real
- keep FPGA math and validation in the same shared C++ layer as deployment
- preserve one framework across accelerated, CPU, and FPGA-targeted work

## Dependencies

- Stage 5 trainer and registries
- Stage 8 shared deployment smoke harness

## Primary Folders

- `experiments/200_fpga_base_v1/`
- `cpp/math/`
- `cpp/layers/`
- `cpp/models/`
- `src/cnn_workbench/resolve/`
- `src/cnn_workbench/compare/`
- `tests/`

## Scope

- `200_fpga_base_v1` shared defaults
- FPGA-compatible activations, norms, quantization behavior, and export-profile
  validation hooks layered onto the shared deployment smoke harness
- deployment-track-aware constraints for `fpga_int8_v1`
- compare labeling and validation specific to the FPGA-targeted path

## Out Of Scope

- Azure execution
- a second public optimizer path unless there is a proven need

## Deliverables

- contributors can express FPGA-targeted experiments without forking the system
- the same shared architecture supports FPGA-targeted and non-FPGA-targeted
  work
- FPGA-targeted validation is honest and explicit without becoming a separate
  project

## Done Criteria

- FPGA-targeted experiments resolve and validate through the same core path as
  accelerated-target and CPU-targeted experiments
- trainer components required by the FPGA profile are selectable through config
- compare output keeps FPGA-targeted results visibly distinct from the other
  deployment targets

## Test Gate

- resolution tests for FPGA-base inheritance and constraint enforcement
- trainer smoke tests for FPGA-specific registered components
- comparison tests covering mixed accelerated-target, CPU-targeted, and
  FPGA-targeted result sets

## Completion Note

- Once this stage is complete, the repo should support the full FPGA-first but
  flexible cross-target architecture described in the top-level design docs.
