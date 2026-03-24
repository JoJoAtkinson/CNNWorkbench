# Stage 2 Plan: Authoring And Resolution

This stage makes the repo useful before training exists. The outcome is a
config-first author workflow that can scaffold experiments, validate them, and
preview the exact child-run contract the trainer would receive.

## Purpose

- make experiments editable without touching the trainer
- make inheritance and validation explicit
- make `resolve` the inspectable contract boundary for contributors

## Dependencies

- Stage 1 foundation and shared contracts

## Scope

- `new_experiment`
- experiment inheritance and merge semantics
- schema validation and error aggregation
- structured JSON validation output for `check` and `resolve`
- deployment-track inheritance rules
- separation of `runtime.train_runtime` from `track.deploy_target`
- `check --experiment`
- `resolve --run-profile full|short`
- `resolve --diff-from-parent`
- preview placeholders such as `batch_id = "preview"`
- short-run milestone expansion into explicit `eval_items`
- resolved runtime metadata such as requested training runtime, resolved backend,
  and fallback state
- preview surfacing of initialization state so contributors can verify scratch,
  resume, and fine-tune intent before launch
- `notes.md` scaffolding with required experiment sections
- repo-local id allocation, promotion-aware scaffold behavior, and
  `metadata.owner` expectations for shared or promoted experiments
- hard-fail behavior for unsupported legacy authored syntax under the current
  engine contract

## Out Of Scope

- real dataset preparation
- environment capability checks for training
- C++ trainer invocation
- run artifact folders under `runs/`

## Deliverables

- contributors can create a new experiment from the right base in the current
  repo or fork
- `check` reports all blocking config issues in one pass
- `resolve` prints one fully materialized child config per dataset target
- `resolve --diff-from-parent` shows both the authored delta and runtime effect
- the author-facing workflow is usable on an authoring-only machine
- repo-local scaffolding works without assuming one globally coordinated id
  space across forks
- preview output makes initialization state explicit even before the operational
  resume/finetune path exists

## Done Criteria

- the authored config surface is enforced as documented
- runtime and deployment-target separation is visible in the resolved output
- non-base experiments cannot switch deployment target mid-chain
- short and full preview resolution differ where the plan requires them to
- JSON-capable validation output matches the documented `errors` array contract
- unsupported legacy authored syntax fails with an actionable error instead of
  being rewritten in place

## Test Gate

- scaffolder tests for repo-local experiment id allocation and notes template
  creation
- validation tests for documented authoring failures
- validation tests for the structured JSON `errors` output shape
- resolution tests for inheritance, merge rules, and deployment-track
  restrictions
- resolution tests for `train_runtime` versus `deploy_target` separation
- preview tests asserting initialization fields are surfaced clearly, including
  default scratch-mode resolution
- tests covering `metadata.owner` handling for shared or promoted experiments
- tests proving unsupported legacy authored syntax is rejected cleanly
- short-run expansion tests including Fibonacci handling

## Collaboration Risks

- `R2`: Stage 2 owns the smallest reviewable authoring surface through
  scaffold, validation, and `resolve --diff-from-parent`.
- `R4`: Stage 2 makes validation, ownership, and migration rules explicit
  instead of leaving them implicit in implementation.
- `R5`: Stage 2 keeps repo-local ids, promotion expectations, and
  `metadata.owner` behavior aligned with the curated-upstream contribution model.

## Handoff To Stage 3

- Stage 3 replaces fixture dataset metadata with real dataset catalog and
  preparation logic without changing the resolved contract shape.
