# Acceptance Artifacts

This folder holds the human-readable acceptance layer for the planning set.

Working rules:

- Use `maps/` for volatile or discovery-heavy areas that still benefit from
  explicit rules, examples, and open questions.
- Use `features/` for stable end-to-end expectations that are likely to become
  executable later.
- Every stable scenario uses one `@ACC-*` tag and links back to at least one
  `@REQ-*` and, when relevant, one `@CON-*`.
- Feature files are planning artifacts first. They may become executable later,
  but they are not treated as runtime code today.
- Example maps should reference `UNK-*` items when a rule is intentionally
  unresolved.

Current acceptance IDs:

- `ACC-001`: scaffold and resolve an experiment chain
- `ACC-002`: prepare datasets and surface runtime metadata
- `ACC-003`: diagnose environments and build the trainer
- `ACC-004`: run local scratch batches with provenance and failure artifacts
- `ACC-005`: resume, fine-tune, and compare runs
- `ACC-006`: validate FPGA-targeted experiments through the shared system
- `ACC-007`: maintain the planning consistency layer itself
- `ACC-008`: keep model composition readable and extensible in shared code
- `ACC-009`: scaffold experiment-owned C++ model definitions and portable artifacts

Canonical IDs: REQ-017, REQ-018, REQ-019, REQ-020, REQ-021, ASM-004, CON-005, CON-009, CON-013, CON-014, CON-015
