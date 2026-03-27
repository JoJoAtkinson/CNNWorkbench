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
- flat explicit named FPGA deploy profiles without inheritance or composition
- FPGA-compatible activations, norms, quantization behavior, and export-profile
  validation hooks layered onto the shared deployment smoke harness
- deployment-track-aware constraints for `fpga_int8_v1`
- promotion-grade FPGA hardware gate criteria layered on top of the shared smoke
  validation baseline
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
- promotion-grade FPGA decisions use an explicit hardware gate instead of
  unstated reviewer judgment

## Coverage

- Implements: `REQ-003`, `REQ-012`, `REQ-013`
- Constrains: `CON-010`
- Verifies: `ACC-006`, `R4`, `R10`

## Done Criteria

- FPGA-targeted experiments resolve and validate through the same core path as
  accelerated-target and CPU-targeted experiments
- trainer components required by the FPGA profile are selectable through config
- compare output keeps FPGA-targeted results visibly distinct from the other
  deployment targets
- FPGA profiles remain flat explicit named profiles without hidden inheritance
  or composition rules
- promotion-grade FPGA review checks operator whitelist compatibility,
  quantization or calibration validity, latency budget, and hardware-reported
  resource or utilization budget when available

## Test Gate

- resolution tests for FPGA-base inheritance and constraint enforcement
- profile-selection tests proving FPGA profiles do not inherit or compose
  implicitly
- trainer smoke tests for FPGA-specific registered components
- hardware-gate tests covering the required promotion-grade FPGA criteria
- comparison tests covering mixed accelerated-target, CPU-targeted, and
  FPGA-targeted result sets

## Collaboration Risks

- `R4`: Stage 9 keeps FPGA promotion criteria explicit and reviewable in the
  plan instead of leaving them to unstated judgment.
- `R10`: Stage 9 keeps FPGA validation and comparison outcomes anchored in
  versioned, text-first artifacts rather than opaque side channels.

## Completion Note

- Once this stage is complete, the repo should support the full FPGA-first but
  flexible cross-target architecture described in the top-level design docs.

Canonical IDs: REQ-003, REQ-012, REQ-013, CON-010, ADR-0012
