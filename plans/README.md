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

## Canonical Entry Points

- [plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md)
  - full target design and contracts
- [plan-stages.md](/Users/joe/GitHub/CNNWorkbench/plan-stages.md)
  - stage ordering, dependencies, and acceptance gates
- `plans/stages/*/plan.md`
  - per-stage implementation plans derived from the staged delivery plan

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

## Working Rule

When implementation changes the design:

1. update [plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md) if the contract or architecture changes
2. update the affected stage file under `plans/stages/`
3. update contributor-facing docs such as
   [README.md](/Users/joe/GitHub/CNNWorkbench/README.md) and
   [CONTRIBUTING.md](/Users/joe/GitHub/CNNWorkbench/CONTRIBUTING.md)
4. only then implement or revise code
