# AGENTS.md

This file gives repo-specific instructions for agents working in
`/Users/joe/GitHub/CNNWorkbench`.

## Repo State

- This repo is still plan-first.
- The tracked source of truth is the planning set, not an implemented product.
- Do not invent runtime behavior casually. If a real gap appears, capture it in
  the planning layer as an unknown or a proposed decision instead of silently
  making up policy.

## Canonical Planning Layer

The planning source of truth is split on purpose.

- `plans/registers/requirements.yaml`
  - stable `REQ-*` obligations and expected system behavior
- `plans/registers/constraints.yaml`
  - stable `CON-*` invariants, must-not-break rules, and separations
- `plans/registers/assumptions.yaml`
  - `ASM-*` beliefs currently treated as true but reviewable later
- `plans/registers/unknowns.yaml`
  - `UNK-*` unresolved questions, with owner, target stage, and blocking flag
- `plans/registers/collaboration_risks.yaml`
  - canonical `R1` through `R10` collaboration and review risks
- `plans/decisions/`
  - ADRs for durable rationale and architecture-shaping decisions
- `plans/acceptance/`
  - example maps for volatile areas and tagged `.feature` files for stable flows
- `plans/trace/trace.csv`
  - canonical relationship index between IDs
- `plans/trace/coverage.md`
  - human checksum report for the planning layer

Narrative docs are still important, but they are not the only atomic source of
truth:

- `plan.md`
  - architecture and contract narrative
- `plan-stages.md`
  - stage ordering and exit rules
- `plans/stages/*/plan.md`
  - stage-specific execution specs
- `README.md`
  - newcomer-facing operating model
- `CONTRIBUTING.md`
  - contributor workflow and review guidance
- `plans/collaboration-risk-matrix.md`
  - human-readable summary of `R1` through `R10`
- `plans/mock_implementation_learned.md`
  - intake log of implementation-discovered clarifications

## How To Classify A Change

Use the narrowest canonical artifact that fits the change.

- Update `REQ-*` when the change adds, removes, or changes a durable
  obligation, user-visible behavior, or acceptance-critical contract.
  Requirements need a measurable `fit_criterion`.
- Update `CON-*` when the change affects a must-not-break invariant, ownership
  boundary, compatibility rule, immutability rule, or policy separation.
- Update `ASM-*` when the change affects something the project is currently
  assuming is true, but which could later be validated or invalidated.
- Update `UNK-*` when the change reveals an unresolved question, missing policy,
  or future decision that should not be guessed. Set `blocking: true` only when
  a stage cannot honestly be treated as ready without resolving it.
- Update `R*` only when the change affects collaboration, reviewability,
  reproducibility, setup clarity, artifact ownership, or similar human process
  risks.
- Add or update an ADR when rationale changed, when an architecture-shaping
  decision became explicit, or when one decision supersedes another.
- Update acceptance maps or `.feature` files when examples, stable scenarios, or
  verification expectations changed.

Do not put durable architecture rules only in prose if they should really be a
`REQ-*`, `CON-*`, `ASM-*`, `UNK-*`, `R*`, or ADR.

## Required Update Order

When a planning or implementation change affects the design, update artifacts in
this order:

1. Update the affected register entry under `plans/registers/`.
2. Update the related ADR under `plans/decisions/` if rationale changed.
3. Update `plans/trace/trace.csv`.
4. Review and update `plans/trace/coverage.md`.
5. Update the affected stage plan under `plans/stages/`.
6. Update the relevant narrative docs such as `plan.md`, `plan-stages.md`,
   `README.md`, `CONTRIBUTING.md`, or
   `plans/collaboration-risk-matrix.md`.
7. If the clarification came from implementation experience, append the
   absorbed canonical IDs to the matching item in
   `plans/mock_implementation_learned.md`.
8. Only then implement code or treat the planning change as complete.

Do not update `plan.md` first for an atomic contract change if the canonical
register entry has not been updated yet.

## Trace Rules

`plans/trace/trace.csv` uses:

- `from_id,to_id,relationship,notes`

Allowed relationships:

- `refines`
- `constrains`
- `decided_by`
- `implemented_in_stage`
- `verified_by`
- `explained_in`
- `supersedes`

Minimum trace expectations:

- Every accepted `REQ-*` must link to at least one stage through
  `implemented_in_stage`.
- Every accepted `REQ-*` must link to at least one acceptance artifact or other
  verification surface through `verified_by`.
- Every accepted `CON-*` must have at least one verification target.
- Every ADR should link to at least one `REQ-*`, `CON-*`, or `ASM-*`.
- If something is superseded, update trace rows and narrative references
  accordingly.

## Stage Plan Rules

Every stage plan under `plans/stages/` must keep:

- a non-empty `Coverage` section
- a non-empty `Done Criteria` section
- a non-empty `Test Gate` section

The `Coverage` section should list:

- implemented `REQ-*`
- applicable `CON-*`
- relevant `ACC-*`
- relevant `R*`

If a stage depends on an open blocking `UNK-*`, do not treat that stage as
ready or complete.

## Narrative Doc Rules

Narrative docs explain and summarize. They should not become the only place a
rule exists.

- Keep `Canonical IDs:` lines current when a section changes.
- If a prose section introduces a new durable rule, first decide whether that
  rule belongs in a register or ADR.
- Do not create a separate `architecture.md`; `plan.md` already fills that role
  for this repo.

## Acceptance Artifact Rules

- Use `plans/acceptance/maps/` for volatile areas with rules, examples, and open
  questions.
- Use `plans/acceptance/features/` for stable end-to-end expectations.
- Every stable scenario should carry an `@ACC-*` tag plus linked `@REQ-*` and,
  when relevant, `@CON-*` tags.
- Feature files are planning artifacts first and future executable specs second.

## Learned-Notes Rules

`plans/mock_implementation_learned.md` is an intake log, not the canonical
ledger.

- Keep the discovered question and resolution summary.
- End each resolved item with `Canonical IDs:` showing which register entries,
  ADRs, or stages absorbed the clarification.
- If the clarification changed durable policy, make sure the canonical register
  and trace were updated before editing the learned-notes file.

## Quick Review Checklist

Before finishing a planning change, confirm:

- IDs are unique and use the right prefixes.
- Every changed `REQ-*` still has a rationale and fit criterion.
- Every changed `CON-*` still has a rationale and a verification target.
- Every changed `UNK-*` still has owner, target stage, and blocking flag.
- Every changed ADR still lists related IDs.
- `trace.csv` reflects the new or changed relationships.
- `coverage.md` still honestly describes gaps.
- Affected stage plans still have aligned Coverage, Done Criteria, and Test Gate
  sections.
- Affected narrative docs still point back to canonical IDs.

If uncertain whether a change is a requirement, constraint, assumption, or
unknown, prefer the following rule:

- obligation or promised behavior: `REQ-*`
- invariant or must-not-break rule: `CON-*`
- currently believed premise: `ASM-*`
- unresolved question: `UNK-*`
