# Planning Coverage Report

This report is the human checksum for the planning layer. It is hand-maintained
for now and should eventually become tool-checked once the repo grows an
implementation-side CI surface for planning artifacts.

## Summary

- Accepted requirements: 22
- Accepted constraints: 16
- Active collaboration risks: 10
- Open unknowns: 4
- Open blocking unknowns: 0
- ADRs: 10 accepted, 0 superseded, 0 proposed
- Acceptance IDs: 9

Canonical IDs: REQ-018, REQ-019, REQ-020, REQ-021, REQ-022, CON-009, CON-013, CON-014, CON-015, CON-016, ACC-007, ACC-008, ACC-009

## Coverage Status

- Orphan requirements: none
- Accepted requirements without a stage link: none
- Accepted requirements without verification: none
- Accepted constraints without verification target: none
- Stage plans missing coverage sections: none
- Stage plans missing R* items in Coverage: none (Stage 7 fixed to include R1, R2, R10)
- Stage plans missing Collaboration Risks section: none (Stage 7 section added)
- Collaboration risks without mapped owning stages: none
- Model-structure boundary coverage: `REQ-019`, `CON-013`, `ADR-0007`, and
  `ACC-008` are all linked through Stage 5, including the narrow
  `build_model(...)` dataset-input boundary
- Experiment-owned model-definition coverage: `REQ-020`, `CON-014`,
  `ADR-0008`, and `ACC-009` are all linked through Stage 2, including copied
  model entrypoint and provenance conventions
- Production-portability coverage: `REQ-021`, `CON-015`, `ADR-0009`, and
  `ACC-009` are linked through Stage 2 and Stage 5, including trainer-supplied
  dataset metadata at the portable model boundary
- TensorBoard projection coverage: `REQ-022`, `CON-016`, `ADR-0010`, and
  `ACC-004` are linked through Stage 6

Canonical IDs: REQ-016, REQ-018, CON-009

## Blocking Unknowns By Stage

- `STAGE-01`: none
- `STAGE-02`: none
- `STAGE-03`: none
- `STAGE-04`: none
- `STAGE-05`: none
- `STAGE-06`: none
- `STAGE-07`: none
- `STAGE-08`: none
- `STAGE-09`: none

Open non-blocking unknowns:

- `UNK-001`: Azure submission contract details
- `UNK-002`: future compare filter surface
- `UNK-003`: possible future FPGA profile composition
- `UNK-004`: when to automate planning checks in CI

Canonical IDs: UNK-001, UNK-002, UNK-003, UNK-004, CON-009

## Supersession Watch

- Superseded requirements still referenced by live docs: none
- Superseded ADRs still referenced by live docs: none
- Deprecated constraints still referenced by live docs: none

Current risk: because this report is manual, `UNK-004` remains open until the
register and trace checks are automated.

Canonical IDs: REQ-018, UNK-004

## Risk Mapping Check

- `R1` through `R10` are present in the canonical collaboration risk register.
- Each active risk has at least one mapped owning stage in `trace.csv`.
- The human-readable risk summary still lives in
  `plans/collaboration-risk-matrix.md`.

Canonical IDs: R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, REQ-018

## Review Checklist

- Confirm any changed rule first updated a canonical register entry.
- Confirm rationale changes touched the related ADR.
- Confirm new or changed IDs appear in `trace.csv`.
- Confirm planning narrative docs (plan.md, plan-stages.md, stage plans) point
  back to the relevant canonical IDs. README.md is an end-user entrypoint and
  does not carry `Canonical IDs:` lines.
- Confirm every affected stage plan still has aligned Coverage, Done Criteria,
  and Test Gate sections.

Canonical IDs: REQ-014, REQ-015, REQ-016, REQ-018, ACC-007
