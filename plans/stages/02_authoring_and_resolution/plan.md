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

## Out Of Scope

- real dataset preparation
- environment capability checks for training
- C++ trainer invocation
- run artifact folders under `runs/`

## Deliverables

- contributors can create a new experiment from the right base
- `check` reports all blocking config issues in one pass
- `resolve` prints one fully materialized child config per dataset target
- `resolve --diff-from-parent` shows both the authored delta and runtime effect
- the author-facing workflow is usable on an authoring-only machine
- preview output makes initialization state explicit even before the operational
  resume/finetune path exists

## Done Criteria

- the authored config surface is enforced as documented
- runtime and deployment-target separation is visible in the resolved output
- non-base experiments cannot switch deployment target mid-chain
- short and full preview resolution differ where the plan requires them to

## Test Gate

- scaffolder tests for experiment id allocation and notes template creation
- validation tests for documented authoring failures
- resolution tests for inheritance, merge rules, and deployment-track
  restrictions
- resolution tests for `train_runtime` versus `deploy_target` separation
- preview tests asserting initialization fields are surfaced clearly, including
  default scratch-mode resolution
- short-run expansion tests including Fibonacci handling

## Handoff To Stage 3

- Stage 3 replaces fixture dataset metadata with real dataset catalog and
  preparation logic without changing the resolved contract shape.
