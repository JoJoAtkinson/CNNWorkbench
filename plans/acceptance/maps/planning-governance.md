# Example Map: Planning Governance

## Story

Maintainers need to evolve the planning set without reintroducing drift between
the long-form docs, stage plans, decisions, and collaboration guidance.

## Rules

- `REQ-014`: update registers before ADRs, trace, and narrative docs
- `REQ-015`: major narrative sections point back to canonical IDs
- `REQ-016`: every stage plan carries explicit coverage
- `REQ-017`: stable flows use tagged scenarios and volatile areas use example
  maps
- `REQ-018`: the planning set publishes a checksum-style coverage report
- `CON-009`: stages cannot be treated as ready while blocking unknowns remain

## Examples

- A clarified build rule updates `CON-006`, the related ADR, the trace rows, and
  only then the narrative build sections.
- A new stage change cannot be merged if its stage plan has no Coverage section.
- A planning review can open `trace/coverage.md` and see whether any accepted
  requirement lacks verification.

## Questions

- `UNK-004`: when should the planning consistency checks become automated in CI?

Canonical IDs: ACC-007, REQ-014, REQ-015, REQ-016, REQ-017, REQ-018, CON-009, UNK-004
