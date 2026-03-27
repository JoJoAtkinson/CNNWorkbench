# Example Map: FPGA Promotion

## Story

A contributor wants to target FPGA deployment without leaving the shared system
and needs explicit rules for what qualifies as a promotion-grade result.

## Rules

- `REQ-012`: FPGA-targeted work stays inside the shared architecture
- `REQ-013`: not every exploratory FPGA experiment becomes upstream history
- `CON-010`: FPGA deploy profiles stay flat and explicit
- `R4`: FPGA promotion criteria must remain explicit in prose
- `R10`: FPGA validation results stay anchored in text-first artifacts

## Examples

- An FPGA-targeted experiment resolves through the same core path as an
  accelerated-target experiment but receives extra deploy-profile checks.
- A promising FPGA run is discussed through compare output, notes, and hardware
  gate evidence before any promotion decision is made.
- A non-FPGA experiment may still use FPGA-friendly shared components without
  being mislabeled as an FPGA-targeted run.

## Questions

- none

Canonical IDs: ACC-006, REQ-012, REQ-013, CON-010, R4, R10
