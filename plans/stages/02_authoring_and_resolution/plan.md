# Stage 2 Plan: Authoring And Resolution

This stage makes the repo useful before training exists. The outcome is an
author workflow that can scaffold experiments, validate them, and preview the
exact child-run contract the trainer would receive.

## Purpose

- make experiments editable without touching the trainer
- make inheritance and validation explicit
- make `resolve` the inspectable contract boundary for contributors

## Dependencies

- Stage 1 foundation and shared contracts

## Scope

- `new_experiment`
- experiment inheritance and merge semantics
- recursive experiment discovery under `experiments/` with grouping folders
  treated as organization-only
- base-only lineage for non-base experiments
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
- explicit authoring guidance that `experiment.toml` is for training and
  execution settings while `model.cpp` is for architecture
- scaffolded experiment-local `model.cpp` files copied from the chosen base
- copied `model.cpp` templates that keep the documented
  `build_model(int64_t input_channels, int64_t num_classes)` surface and
  file-scope `kExperimentId` convention
- preview surfacing of initialization state so contributors can verify scratch,
  resume, and fine-tune intent before launch
- `notes.md` scaffolding with required experiment sections
- repo-local id allocation, promotion-aware scaffold behavior, and
  `metadata.owner` expectations for shared or promoted experiments
- path-independent experiment lookup by repo-unique `experiment.id`
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
- scaffolded experiments own an explicit `model.cpp` architecture file in their
  own folder
- scaffolded experiment folders stay the durable tracked source contributors
  commit and share for authored experiment changes
- scaffolded `model.cpp` files preserve the documented build-model signature
  and provenance convention from the selected base
- `check` reports all blocking config issues in one pass
- `resolve` prints one fully materialized child config per dataset target
- `resolve --diff-from-parent` shows both the authored delta and runtime effect
- the author-facing workflow is usable on an authoring-only machine
- repo-local scaffolding works without assuming one globally coordinated id
  space across forks
- optional grouping folders do not change canonical experiment selection
- preview output makes initialization state explicit even before the operational
  resume/finetune path exists

## Coverage

- Implements: `REQ-001`, `REQ-002`, `REQ-004`, `REQ-005`, `REQ-013`,
  `REQ-020`, `REQ-021`, `REQ-023`
- Constrains: `CON-001`, `CON-002`, `CON-011`, `CON-013`, `CON-014`,
  `CON-015`, `CON-018`
- Verifies: `ACC-001`, `ACC-009`, `R2`, `R4`, `R5`

## Done Criteria

- the authored config surface is enforced as documented
- authored config stays limited to training and execution concerns
- non-base experiments keep a copied `model.cpp` from a base and edit that file
  for architecture changes
- scaffolded experiment folders remain the durable authored source that is
  committed with any related shared-code change
- experiment lookup works by repo-unique `experiment.id` regardless of optional
  grouping folders under `experiments/`
- duplicate experiment ids anywhere under `experiments/` fail validation
- scaffolded `model.cpp` keeps dataset-dependent `input_channels` and
  `num_classes` as build-model parameters rather than hardcoded constants
- non-base experiments cannot use another non-base experiment as their parent
- runtime and deployment-target separation is visible in the resolved output
- resolved output excludes model graph structure and quantization knobs
- non-base experiments cannot switch deployment target mid-chain
- short and full preview resolution differ where the plan requires them to
- JSON-capable validation output matches the documented `errors` array contract
- unsupported legacy authored syntax fails with an actionable error instead of
  being rewritten in place

## Test Gate

- scaffolder tests for repo-local experiment id allocation and notes template
  creation
- discovery tests for grouped experiment folders and duplicate id rejection
- validation tests for documented authoring failures
- validation tests for the structured JSON `errors` output shape
- resolution tests for inheritance, merge rules, and deployment-track
  restrictions
- resolution tests for `train_runtime` versus `deploy_target` separation
- resolution tests proving model architecture and quantization fields are not
  present in the resolved child run contract
- scaffold tests proving non-base experiments receive copied `model.cpp` files
  from a base parent
- scaffold tests proving copied `model.cpp` files retain the documented
  `build_model(...)` signature and `kExperimentId` provenance constant
- validation tests rejecting non-base experiment parents
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

Canonical IDs: REQ-001, REQ-002, REQ-004, REQ-005, REQ-013, REQ-020, REQ-021, REQ-023, CON-001, CON-002, CON-011, CON-013, CON-014, CON-015, CON-018, ADR-0013
