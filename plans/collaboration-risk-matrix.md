# Collaboration Risk Matrix

This file is a thin audit layer over
[README.md](/Users/joe/GitHub/CNNWorkbench/README.md),
[CONTRIBUTING.md](/Users/joe/GitHub/CNNWorkbench/CONTRIBUTING.md),
[plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md),
[plan-stages.md](/Users/joe/GitHub/CNNWorkbench/plan-stages.md), and the
relevant stage plans. It does not define new runtime behavior; it verifies that
the planning surfaces stay aligned on the collaboration model.

## How To Use This File

- `Current source of truth` points at the docs or stage plans that currently own
  the contract.
- `Pass test` is the objective audit check for that risk.
- `Remaining gap` should stay short. If it says `none`, the risk is currently
  aligned and future edits must preserve that alignment.
- `Stage owners` identifies the stage plans that must keep the risk enforced in
  their `Done Criteria`, `Test Gate`, or `Collaboration Risks` sections.

## R1: Reproducibility

- Current source of truth:
  [README.md](/Users/joe/GitHub/CNNWorkbench/README.md),
  [CONTRIBUTING.md](/Users/joe/GitHub/CNNWorkbench/CONTRIBUTING.md),
  [plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md),
  [plans/stages/01_foundation/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/01_foundation/plan.md),
  [plans/stages/04_environment_and_libtorch/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/04_environment_and_libtorch/plan.md),
  [plans/stages/05_trainer_build_and_vertical_slice/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/05_trainer_build_and_vertical_slice/plan.md),
  [plans/stages/06_local_scratch_runs/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/06_local_scratch_runs/plan.md)
- Pass test:
  the setup flow, bootstrap ownership, and fresh-checkout expectations match
  across the top-level docs and the four stage owners.
- Remaining gap:
  none after the current alignment pass; future setup-flow edits must update all
  four stage owners together.
- Stage owners:
  Stage 1, Stage 4, Stage 5, Stage 6

## R2: Reviewable Change Size

- Current source of truth:
  [README.md](/Users/joe/GitHub/CNNWorkbench/README.md),
  [CONTRIBUTING.md](/Users/joe/GitHub/CNNWorkbench/CONTRIBUTING.md),
  [plans/stages/02_authoring_and_resolution/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/02_authoring_and_resolution/plan.md),
  [plans/stages/06_local_scratch_runs/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/06_local_scratch_runs/plan.md),
  [plans/stages/08_compare_and_matrix/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/08_compare_and_matrix/plan.md)
- Pass test:
  the docs consistently require smallest-change-surface edits,
  `resolve --diff-from-parent`, and short-run-first validation before broader
  promotion or comparison decisions.
- Remaining gap:
  none; this risk now depends on future contributors keeping the authoring and
  comparison docs in sync.
- Stage owners:
  Stage 2, Stage 6, Stage 8

## R3: Trusted CI And Test Gates

- Current source of truth:
  [plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md),
  [plan-stages.md](/Users/joe/GitHub/CNNWorkbench/plan-stages.md),
  [plans/stages/01_foundation/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/01_foundation/plan.md)
- Pass test:
  the minimum CI surface stays identical everywhere and every stage still ends
  with an automated gate.
- Remaining gap:
  none; Stage 1 and the staged-delivery plan now carry the CI baseline.
- Stage owners:
  Stage 1 and the staged-delivery plan

## R4: Explicit Rationale And Documentation

- Current source of truth:
  [README.md](/Users/joe/GitHub/CNNWorkbench/README.md),
  [CONTRIBUTING.md](/Users/joe/GitHub/CNNWorkbench/CONTRIBUTING.md),
  [plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md),
  [plans/stages/02_authoring_and_resolution/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/02_authoring_and_resolution/plan.md),
  [plans/stages/03_datasets/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/03_datasets/plan.md),
  [plans/stages/08_compare_and_matrix/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/08_compare_and_matrix/plan.md),
  [plans/stages/09_fpga_deployment/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/09_fpga_deployment/plan.md)
- Pass test:
  architecture rationale, promotion rules, schema decisions, and versioned
  artifact expectations stay documented in prose rather than inferred from
  implementation alone.
- Remaining gap:
  none after this doc pass; future contract changes must update both the
  relevant stage plan and the top-level docs.
- Stage owners:
  Stage 2, Stage 3, Stage 8, Stage 9

## R5: Ownership And Review Routing

- Current source of truth:
  [CONTRIBUTING.md](/Users/joe/GitHub/CNNWorkbench/CONTRIBUTING.md),
  [plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md),
  [plans/stages/01_foundation/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/01_foundation/plan.md),
  [plans/stages/02_authoring_and_resolution/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/02_authoring_and_resolution/plan.md)
- Pass test:
  fork-vs-upstream ownership, promoted-experiment handling, and reviewer-facing
  change surfaces agree across the collaboration docs and the authoring stages.
- Remaining gap:
  none; the curated-upstream model is now explicit.
- Stage owners:
  Stage 1, Stage 2

## R6: Repo Topology And Bootstrap Simplicity

- Current source of truth:
  [README.md](/Users/joe/GitHub/CNNWorkbench/README.md),
  [plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md),
  [plans/stages/01_foundation/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/01_foundation/plan.md),
  [plans/stages/04_environment_and_libtorch/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/04_environment_and_libtorch/plan.md),
  [plans/stages/05_trainer_build_and_vertical_slice/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/05_trainer_build_and_vertical_slice/plan.md)
- Pass test:
  the repo shape, bootstrap path, and build-root split are described once and
  repeated consistently without hidden side repos or alternate mandatory flows.
- Remaining gap:
  none; audit this risk whenever bootstrap or build-root ownership changes.
- Stage owners:
  Stage 1, Stage 4, Stage 5

## R7: Generated Artifacts And Local Data Staying Out Of Git

- Current source of truth:
  [README.md](/Users/joe/GitHub/CNNWorkbench/README.md),
  [plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md),
  [.gitignore](/Users/joe/GitHub/CNNWorkbench/.gitignore),
  [plans/stages/01_foundation/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/01_foundation/plan.md),
  [plans/stages/03_datasets/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/03_datasets/plan.md),
  [plans/stages/06_local_scratch_runs/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/06_local_scratch_runs/plan.md)
- Pass test:
  the documented local runtime directories are ignore-listed, tracked artifact
  paths are not described as disposable runtime output, and the ignore rules do
  not contradict the tracked-versus-local story told by the docs.
- Remaining gap:
  none; verify this risk on any future change to artifact paths or local cache
  layout.
- Stage owners:
  Stage 1, Stage 3, Stage 6

## R8: C++ Toolchain And ABI Stability

- Current source of truth:
  [plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md),
  [plans/stages/04_environment_and_libtorch/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/04_environment_and_libtorch/plan.md),
  [plans/stages/05_trainer_build_and_vertical_slice/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/05_trainer_build_and_vertical_slice/plan.md)
- Pass test:
  lockfile, checksum verification, CMake floor, trainer target name, build
  types, and fingerprint inputs match between the top-level plan and the two
  owning stages.
- Remaining gap:
  none; future toolchain changes must update Stage 4, Stage 5, and the top
  plan together.
- Stage owners:
  Stage 4, Stage 5

## R9: Python Environment Discipline

- Current source of truth:
  [README.md](/Users/joe/GitHub/CNNWorkbench/README.md),
  [CONTRIBUTING.md](/Users/joe/GitHub/CNNWorkbench/CONTRIBUTING.md),
  [plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md),
  [plans/stages/01_foundation/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/01_foundation/plan.md),
  [plans/stages/04_environment_and_libtorch/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/04_environment_and_libtorch/plan.md)
- Pass test:
  `uv`, project bootstrap scripts, and `python -m` entrypoints remain the only
  documented Python setup path across the core docs and the owning stages.
- Remaining gap:
  none; this risk should be re-audited whenever setup instructions change.
- Stage owners:
  Stage 1, Stage 4

## R10: Git-Friendly Collaboration Surfaces

- Current source of truth:
  [README.md](/Users/joe/GitHub/CNNWorkbench/README.md),
  [plan.md](/Users/joe/GitHub/CNNWorkbench/plan.md),
  [plans/stages/01_foundation/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/01_foundation/plan.md),
  [plans/stages/06_local_scratch_runs/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/06_local_scratch_runs/plan.md),
  [plans/stages/08_compare_and_matrix/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/08_compare_and_matrix/plan.md),
  [plans/stages/09_fpga_deployment/plan.md](/Users/joe/GitHub/CNNWorkbench/plans/stages/09_fpga_deployment/plan.md)
- Pass test:
  text-based configs, manifests, summaries, and reports remain the canonical
  review surface, and no opaque generated artifact is promoted to source of
  truth.
- Remaining gap:
  none; keep reports and runtime artifacts versioned and text-first.
- Stage owners:
  Stage 1, Stage 6, Stage 8, Stage 9
