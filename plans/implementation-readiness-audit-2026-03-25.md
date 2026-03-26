# Implementation Readiness Audit

Date: 2026-03-25

## Verdict

Not ready for implementation sign-off yet.

The architecture and stage order are mostly coherent: all accepted `REQ-*` and
`CON-*` items are present in `trace.csv`, every stage plan has the required
sections, and there are no open blocking `UNK-*` entries. The blocking issue is
planning integrity, not missing ideas. The current planning layer is not yet
self-checking enough to safely serve as the implementation source of truth.

## Findings

### 1. Critical: canonical `source_refs` are stale

- I found 19 broken Markdown `source_refs` in the canonical registers.
- All 19 failures point at non-existent anchors in `README.md`.
- Examples:
  - `REQ-001` points at `README.md#mental-model`
  - `REQ-002` points at `README.md#architecture`
  - `REQ-011` points at `README.md#comparison-and-test-expectations`
  - `CON-003` points at `README.md#architecture`
  - `UNK-004` points at `README.md#task-aliases-and-ci`
- Impact:
  - register-to-narrative trace is not auditable
  - reviewers cannot reliably verify why a canonical item exists
  - the planning layer looks linked, but many links are dead

### 2. Critical: `REQ-015` is not actually satisfied in the major narrative docs

- Section-level `Canonical IDs:` coverage is incomplete in the docs that are
  supposed to be the main human entrypoints:
  - `README.md`: 0/17 `##` sections with `Canonical IDs:`
  - `plan.md`: 8/29
  - `plan-stages.md`: 4/13
  - `CONTRIBUTING.md`: 6/9
  - `plans/collaboration-risk-matrix.md`: 1/11
  - `plans/mock_implementation_learned.md`: 0/10
- The worst gaps are the newcomer and sequencing docs:
  - `README.md` has no `Canonical IDs:` lines at all
  - the per-stage overview sections in `plan-stages.md` do not carry their own
    section-local canonical IDs
- Impact:
  - the narrative layer still behaves like a parallel source of truth
  - maintainers cannot use the docs themselves to validate whether prose still
    matches the registers

### 3. High: acceptance tags and trace rows disagree

- 4 of the 9 acceptance feature files are missing tags for IDs that
  `plans/trace/trace.csv` says they verify.
- 2 feature files carry extra tags that are not reflected in trace.
- Concrete mismatches:
  - `ACC-001` is tagged with `REQ-001`, `REQ-004`, `REQ-005`, `CON-001`,
    `CON-002`, but trace also says it verifies `REQ-002` and `CON-003`
  - `ACC-003` is missing `CON-003`
  - `ACC-006` is missing `REQ-003`
  - `ACC-007` is missing `CON-005`
  - `ACC-008` and `ACC-009` include extra tags not reflected in trace
- Impact:
  - verification surfaces are no longer self-describing
  - future executable-spec work will inherit ambiguity about what each feature
    is meant to verify

### 4. High: Stage 7 violates the stage-coverage rule

- `REQ-016` says every stage `Coverage` section must list `REQ-*`, `CON-*`,
  `ACC-*`, and `R*` identifiers.
- `plans/stages/07_resume_and_finetune/plan.md` lists:
  - `REQ-010`
  - `CON-005`
  - `ACC-005`
- It lists no `R*` identifiers and has no `## Collaboration Risks` section.
- This is not a harmless omission. Stage 7 changes checkpoint provenance,
  manifest content, and batch failure behavior. Those are exactly the kinds of
  concerns the collaboration-risk layer is supposed to make explicit.

### 5. Medium: the human checksum report overstates current consistency

- `plans/trace/coverage.md` reports:
  - no stage coverage problems
  - no collaboration-risk mapping gaps
  - a clean planning-consistency posture
- In practice, the same repo still has:
  - dead canonical `source_refs`
  - narrative docs that miss most section-level `Canonical IDs:`
  - feature-tag vs trace drift
  - a stage plan that does not satisfy the `R*` coverage rule
- Impact:
  - the checksum report is not yet trustworthy as a release gate for planning
    completeness

## Stage Snapshot

| Stage | Status | Notes |
| --- | --- | --- |
| 1 | Not ready | Stage 1 owns the planning consistency layer, and the repo currently fails `REQ-015` plus the source-ref audit above. |
| 2 | Ready after planning cleanup | Stage plan is detailed and usable, but `ACC-001` trace/tag drift needs to be corrected first. |
| 3 | Ready after planning cleanup | Stage plan is internally coherent; no stage-local blocker found beyond repo-wide traceability debt. |
| 4 | Ready after planning cleanup | Stage plan is coherent, but `ACC-003` is under-tagged relative to trace. |
| 5 | Ready after planning cleanup | One of the stronger stage plans; depends mainly on repo-wide planning integrity fixes. |
| 6 | Ready after planning cleanup | Stage plan is strong and specific; blocked only by repo-wide planning integrity issues. |
| 7 | Not ready | Missing collaboration-risk coverage makes the stage fail its own planning contract. |
| 8 | Ready after planning cleanup | Scope is coherent, but it depends on acceptance and checksum artifacts that currently drift. |
| 9 | Ready after planning cleanup | Stage plan is coherent, but `ACC-006` is missing a trace-linked requirement tag. |

## What Looks Solid

- All 22 accepted requirements have both stage links and verification links in
  `plans/trace/trace.csv`.
- All 16 accepted constraints have at least one verification target.
- All 9 stage plans include non-empty `Coverage`, `Done Criteria`, and
  `Test Gate` sections.
- No open `UNK-*` item is marked blocking.
- The newer architecture boundary work around experiment-owned `model.cpp`,
  production portability, and TensorBoard projection is materially clearer than
  the older parts of the planning set.

## Recommended Fix Order

1. Repair the broken `source_refs` in the canonical registers.
2. Bring `README.md`, `plan.md`, `plan-stages.md`, `CONTRIBUTING.md`, and the
   risk matrix into real `REQ-015` compliance with section-local
   `Canonical IDs:` lines.
3. Realign acceptance feature tags with trace rows, or remove the incorrect
   trace links if the current feature scope is intentional.
4. Add collaboration-risk coverage to Stage 7 and update the risk register,
   trace, and checksum report to match.
5. Refresh `plans/trace/coverage.md` only after the above cleanup, so the
   checksum report becomes trustworthy again.
