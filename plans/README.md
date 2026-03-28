# Project Plans

This folder is the long-lived home for planning artifacts that explain what the
repo is meant to become and how it should be built out over time.

Keep these files in the repo. Do not clean them up just because parts of the
project have been implemented. The plans are part of the project history and are
useful for:

- reconstructing why the architecture looks the way it does
- generating or regenerating parts of the project with an LLM or another agent
- reviewing whether implementation still matches the intended design
- auditing whether the contribution model remains easy to follow

Canonical IDs: REQ-014, REQ-015, REQ-018, ASM-001, ASM-006

## Canonical Layer

The canonical planning records now live under `plans/` as small registers and
linked artifacts:

- `plans/registers/`
  - atomic requirements, constraints, assumptions, unknowns, and collaboration
    risks
- `plans/decisions/`
  - ADRs that preserve project-shaping rationale
- `plans/acceptance/`
  - example maps for volatile areas and tagged feature files for stable flows
- `plans/trace/`
  - machine-readable trace links plus the human checksum report

Structured registers are the source of truth for atomic planning statements.
Markdown remains the source of truth for explanation, sequencing, and
onboarding. When the design changes, those Markdown narratives should be
rewritten in place so `plan.md`, `plan-stages.md`, and stage plans remain
current and reconstructable rather than drifting into fragment-only updates.

Canonical IDs: REQ-014, REQ-015, REQ-017, REQ-018, CON-005

## Canonical Entry Points

- [plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md)
  - full target design and contracts
- [plan-stages.md](/Users/joe/GitHub/CNNWorkbench/plan-stages.md)
  - stage ordering, dependencies, and acceptance gates
- [plans/registers/requirements.yaml](/Users/joe/GitHub/CNNWorkbench/plans/registers/requirements.yaml)
  - canonical `REQ-*` ledger
- [plans/registers/constraints.yaml](/Users/joe/GitHub/CNNWorkbench/plans/registers/constraints.yaml)
  - canonical `CON-*` ledger
- [plans/registers/collaboration_risks.yaml](/Users/joe/GitHub/CNNWorkbench/plans/registers/collaboration_risks.yaml)
  - canonical `R1` through `R10` ledger
- [plans/trace/trace.csv](/Users/joe/GitHub/CNNWorkbench/plans/trace/trace.csv)
  - requirement, decision, stage, and acceptance links
- [plans/trace/coverage.md](/Users/joe/GitHub/CNNWorkbench/plans/trace/coverage.md)
  - human checksum summary of planning consistency
- [plans/collaboration-risk-matrix.md](/Users/joe/GitHub/CNNWorkbench/plans/collaboration-risk-matrix.md)
  - cross-cutting collaboration audit keyed by `R1` through `R10`
- [plans/mock_implementation_learned.md](/Users/joe/GitHub/CNNWorkbench/plans/mock_implementation_learned.md)
  - implementation-discovered decisions that have already been folded back into
    the planning contract
- `plans/stages/*/plan.md`
  - per-stage implementation plans derived from the staged delivery plan

Canonical IDs: REQ-014, REQ-015, REQ-018, R1, R4, R10

## Stage Files

- [plans/stages/01_foundation/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/01_foundation/plan.md)
  - repository skeleton, typed contracts, CLI wiring, test harness
- [plans/stages/02_authoring_and_resolution/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/02_authoring_and_resolution/plan.md)
  - scaffolding, validation, inheritance, preview resolution
- [plans/stages/03_datasets/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/03_datasets/plan.md)
  - dataset catalog, metadata, and preparation helpers
- [plans/stages/04_environment_and_libtorch/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/04_environment_and_libtorch/plan.md)
  - `doctor`, environment classification, LibTorch download, fallback policy
- [plans/stages/05_trainer_build_and_vertical_slice/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/05_trainer_build_and_vertical_slice/plan.md)
  - `build`, minimal trainer, registries, and trainer smoke path
- [plans/stages/06_local_scratch_runs/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/06_local_scratch_runs/plan.md)
  - local scratch runs, artifacts, and failure handling
- [plans/stages/07_resume_and_finetune/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/07_resume_and_finetune/plan.md)
  - checkpoint initialization modes and provenance
- [plans/stages/08_compare_and_matrix/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/08_compare_and_matrix/plan.md)
  - compare, matrix expansion, and shared deployment smoke validation
- [plans/stages/09_fpga_deployment/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/09_fpga_deployment/plan.md)
  - FPGA-targeted deployment extension on top of the shared system

Canonical IDs: REQ-016

## Working Rule

When planning or implementation changes the design:

1. update the affected register under `plans/registers/`
2. update the related ADR under `plans/decisions/` if rationale changed
3. update `plans/trace/trace.csv` and review `plans/trace/coverage.md`
4. update [plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md) and the affected
   stage file under `plans/stages/`, rewriting the changed sections in place so
   they read as the current design rather than append-only amendments
5. update [plans/collaboration-risk-matrix.md](/Users/joe/GitHub/CNNWorkbench/plans/collaboration-risk-matrix.md) if the change affects setup flow, artifact ownership, reviewability, or other collaboration-critical behavior
6. update contributor-facing docs such as
   [README.md](/Users/joe/GitHub/CNNWorkbench/README.md) and
   [CONTRIBUTING.md](/Users/joe/GitHub/CNNWorkbench/CONTRIBUTING.md)
7. only then implement or revise code

Canonical IDs: REQ-014, REQ-015, REQ-018, CON-009
