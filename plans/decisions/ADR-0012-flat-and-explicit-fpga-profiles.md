# ADR-0012: Flat And Explicit FPGA Profiles

## Status

accepted

## Context

The FPGA deployment path needs explicit constraint and promotion behavior that
contributors and reviewers can inspect without reconstructing hidden profile
lineage. The planning layer already treats deploy-target identity as explicit
config, and FPGA-friendly shared components such as `shift_activation`,
`barrel_shift_norm`, and `qat_int8` can already be selected directly by
experiment-owned `model.cpp` files using the shared C++ library.

The open question was whether future FPGA deploy profiles should gain
inheritance or composition once more than one profile exists. That would add a
second configuration graph inside the deployment path and make it harder to see
which exact constraints govern a given experiment.

## Decision

FPGA deploy profiles stay flat and explicit. They are named profiles selected
directly by config, and they do not inherit or compose implicitly.

This means:

- `constraints_profile` continues to identify one explicit FPGA deploy profile
  such as `fpga_int8_v1`
- adding a new FPGA profile means defining a new full named rule set rather
  than layering it on top of another profile
- shared C++ components remain reusable across tracks, and experiment-owned
  `model.cpp` files choose which shared components to compose
- FPGA-specific validation fires because an experiment explicitly targets an
  FPGA deploy profile, not because the system infers FPGA intent from notes,
  naming, or hidden profile ancestry
- if two profiles share logic, that shared logic should live in explicit
  validation helpers or shared C++ components, not in profile inheritance

## Consequences

- Stage 9 validation and compare behavior stay easy to audit because each FPGA
  experiment points at one named profile with no hidden parent chain.
- The resolver and validation layers do not need a second inheritance model for
  deploy profiles.
- Contributors adding a new FPGA profile must state its full intended rules
  directly, which raises the review bar but keeps the contract legible.
- The distinction between architecture selection in `model.cpp` and deployment
  constraints in config remains clear.

## Supersedes

- none

## Related IDs

- REQ-012
- CON-010
- UNK-003
